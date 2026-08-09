import SwiftUI
import AuroraCore

/// The one thing the whole app exists to show: tonight's answer.
///
/// Hierarchy is deliberate and ranked: the band word is the answer, the score
/// arc is the confidence behind it, the limiting-factor sentence is the *why*
/// (the thing competitors never say), and the window is what you actually act
/// on. Nothing else is allowed near it.
///
/// It sits directly on the night background with no container. A card would
/// draw a box around the one thing that should feel like the screen itself,
/// and the score is already encoded by the backdrop's tint, so the box was
/// carrying no information the type and the arc were not already carrying.
struct VerdictHero: View {
    let band: VisibilityBand
    let peakScore: Double
    let limitingFactor: LimitingFactor
    let bestWindow: ClosedRange<Date>?

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.l) {
            HStack(alignment: .top, spacing: Nightwatch.Space.l) {
                VStack(alignment: .leading, spacing: Nightwatch.Space.s) {
                    Text("tonight.verdict.eyebrow")
                        .font(Nightwatch.TypeScale.caption)
                        .textCase(.uppercase)
                        .kerning(1.2)
                        .foregroundStyle(palette.textTertiary)

                    Text(band.localizedLabel)
                        .font(Nightwatch.TypeScale.verdict)
                        .foregroundStyle(palette.textPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ScoreArc(score: peakScore)
                    .frame(width: 96, height: 96)
                    .accessibilityHidden(true)
            }

            Text(limitingFactor.localizedSentence)
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            windowRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: accessibilitySummary))
    }

    private var windowRow: some View {
        HStack(spacing: Nightwatch.Space.s) {
            Image(systemName: bestWindow == nil ? "moon.zzz" : "clock")
                .font(.body.weight(.semibold))
                .foregroundStyle(bestWindow == nil ? palette.textTertiary : palette.rampColor(for: peakScore))
                .accessibilityHidden(true)

            if let window = bestWindow {
                Text(verbatim: Self.windowText(window))
                    .font(Nightwatch.TypeScale.emphasis)
                    .foregroundStyle(palette.textPrimary)
            } else {
                Text("tonight.bestWindow.none")
                    .font(Nightwatch.TypeScale.body)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilitySummary: String {
        let template = String(localized: "tonight.verdict.accessibilitySummary")
        let window: String
        if let bestWindow {
            window = Self.windowText(bestWindow)
        } else {
            window = String(localized: "tonight.bestWindow.none")
        }
        return String(format: template, band.localizedLabel, limitingFactor.localizedSentence, window)
    }

    /// A complete localized range string built from a single templated key
    /// with pre-formatted, locale-aware endpoints — never glued together.
    static func windowText(_ window: ClosedRange<Date>) -> String {
        let template = String(localized: "tonight.bestWindow.range")
        return String(
            format: template,
            window.lowerBound.formatted(date: .omitted, time: .shortened),
            window.upperBound.formatted(date: .omitted, time: .shortened)
        )
    }
}

/// A single arc showing a night's peak score. No numbers competing with the
/// band word: the figure inside is small and secondary on purpose.
///
/// Shared with the Nights-ahead cards, which draw it smaller. The line width
/// scales with the frame rather than being fixed, because a 10pt stroke on a
/// 56pt dial reads as a doughnut instead of an arc.
struct ScoreArc: View {
    let score: Double
    var lineWidth: CGFloat = 10
    var showsLabel = true

    @Environment(\.palette) private var palette

    var body: some View {
        let fraction = min(max(score, 0), 100) / 100
        // A centred stroke paints half its width outside the circle's frame.
        // Inside a padded card that went unnoticed; directly on the screen it
        // hung over the right edge.
        return ZStack {
            Circle()
                .stroke(palette.hairline, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [
                            palette.rampColor(for: score * 0.4),
                            palette.rampColor(for: score)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * fraction)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showsLabel {
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(Nightwatch.TypeScale.title)
                    .foregroundStyle(palette.textPrimary)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(lineWidth / 2)
    }
}
