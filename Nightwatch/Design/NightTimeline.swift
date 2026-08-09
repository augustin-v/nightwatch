import SwiftUI
import AuroraCore

/// The night, hour by hour, as one continuous ribbon.
///
/// A row of grey chips would technically carry the same numbers, but the
/// question the user is asking — "when should I be outside?" — is a question
/// about *shape*, so the shape is what gets drawn. The fill is the verdict
/// ramp, so the good hours are literally the bright part of the curve, and the
/// best window is marked because that is the actionable bit.
struct NightTimeline: View {
    let hours: [HourlyVisibilityScore]
    let bestWindow: ClosedRange<Date>?

    @Environment(\.palette) private var palette

    private var peak: Double { hours.map(\.combined).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            Text("tonight.hourlyStrip.heading")
                .font(Nightwatch.TypeScale.sectionHeading)
                .foregroundStyle(palette.textSecondary)

            // A night that never leaves zero has no shape to draw. Plotting
            // it anyway leaves a tall black rectangle under the heading that
            // looks like a rendering failure, so say the flat thing instead.
            if peak > 0 {
                VStack(spacing: Nightwatch.Space.s) {
                    ribbon
                        .frame(height: 132)
                    axis
                }
            } else {
                Text("tonight.hourlyStrip.flat")
                    .font(Nightwatch.TypeScale.body)
                    .foregroundStyle(palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("tonight.hourlyStrip.heading"))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    private var ribbon: some View {
        Canvas { context, size in
            guard hours.count > 1 else { return }

            let stepX = size.width / CGFloat(hours.count - 1)
            func point(_ index: Int) -> CGPoint {
                let score = min(max(hours[index].combined, 0), 100) / 100
                return CGPoint(x: CGFloat(index) * stepX, y: size.height * (1 - score))
            }

            // Best-window band behind the curve, so the recommendation reads
            // as context rather than another line competing for attention.
            if let window = bestWindow,
               let firstIndex = hours.firstIndex(where: { $0.date >= window.lowerBound }),
               let lastIndex = hours.lastIndex(where: { $0.date <= window.upperBound }),
               lastIndex >= firstIndex {
                let rect = CGRect(
                    x: CGFloat(firstIndex) * stepX,
                    y: 0,
                    width: max(CGFloat(lastIndex - firstIndex) * stepX, 2),
                    height: size.height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 8),
                    with: .color(palette.textPrimary.opacity(0.07))
                )
            }

            var line = Path()
            line.move(to: point(0))
            for index in 1..<hours.count {
                let previous = point(index - 1)
                let current = point(index)
                // Horizontal-tangent cubic: smooth without overshooting into
                // impossible negative scores between samples.
                let controlOffset = (current.x - previous.x) / 2
                line.addCurve(
                    to: current,
                    control1: CGPoint(x: previous.x + controlOffset, y: previous.y),
                    control2: CGPoint(x: current.x - controlOffset, y: current.y)
                )
            }

            var area = line
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.addLine(to: CGPoint(x: 0, y: size.height))
            area.closeSubpath()

            context.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [
                        palette.rampColor(for: peak).opacity(0.45),
                        palette.rampColor(for: peak).opacity(0.02)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            context.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [
                        palette.rampColor(for: hours.first?.combined ?? 0),
                        palette.rampColor(for: peak),
                        palette.rampColor(for: hours.last?.combined ?? 0)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )

            if let peakIndex = hours.indices.max(by: { hours[$0].combined < hours[$1].combined }) {
                let p = point(peakIndex)
                context.fill(
                    Path(ellipseIn: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)),
                    with: .color(palette.rampColor(for: peak))
                )
                context.stroke(
                    Path(ellipseIn: CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)),
                    with: .color(palette.rampColor(for: peak).opacity(0.4)),
                    lineWidth: 2
                )
            }
        }
        .drawingGroup()
    }

    /// Only the endpoints and the peak are labelled. Labelling every hour
    /// would be unreadable at this width in any language.
    private var axis: some View {
        HStack {
            if let first = hours.first {
                Text(first.date, format: .dateTime.hour())
            }
            Spacer()
            if let peakHour = hours.max(by: { $0.combined < $1.combined }) {
                Text(peakHour.date, format: .dateTime.hour())
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            if let last = hours.last {
                Text(last.date, format: .dateTime.hour())
            }
        }
        .font(Nightwatch.TypeScale.caption)
        .monospacedDigit()
        .foregroundStyle(palette.textTertiary)
    }

    private var accessibilityValue: String {
        guard let peakHour = hours.max(by: { $0.combined < $1.combined }) else {
            return String(localized: "tonight.bestWindow.none")
        }
        let template = String(localized: "tonight.hourlyStrip.accessibilityValue")
        return String(
            format: template,
            peakHour.date.formatted(date: .omitted, time: .shortened),
            (peakHour.combined / 100).formatted(.percent.precision(.fractionLength(0)))
        )
    }
}
