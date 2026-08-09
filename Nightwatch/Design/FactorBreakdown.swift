import SwiftUI
import AuroraCore

/// The four inputs behind the verdict, each with its own meter.
///
/// The limiting factor is visually marked rather than merely listed. That
/// single affordance is the product's whole argument: incumbents show you a Kp
/// number, this shows you which of the four things is actually stopping you.
struct FactorBreakdown: View {
    let hour: HourlyVisibilityScore
    /// The physical readings behind `hour`. Each row shows the real-world
    /// measurement rather than its internal sub-score: "80%" next to the word
    /// Clouds reads as "it is 80% cloudy", which is the opposite of what an
    /// 80/100 cloud sub-score means. Showing the reading removes the
    /// ambiguity, and it is the number an experienced chaser wants anyway.
    let reading: HourlyVisibilityInput
    let limitingFactor: LimitingFactor

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            Text("tonight.factors.heading")
                .font(Nightwatch.TypeScale.sectionHeading)
                .foregroundStyle(palette.textSecondary)

            VStack(spacing: Nightwatch.Space.l) {
                row(.activity, value: hour.activity, symbol: "sparkles", reading: activityReading)
                row(.clouds, value: hour.clouds, symbol: "cloud", reading: cloudReading)
                row(.darkness, value: hour.darkness, symbol: "moon.stars", reading: darknessReading)
                row(.moon, value: hour.moon, symbol: "moonphase.waning.gibbous", reading: moonReading)
            }
        }
    }

    /// Each reading is a complete localized phrase from a single templated
    /// key with one pre-formatted, locale-aware value — never concatenated.
    private var activityReading: String {
        String(format: String(localized: "tonight.reading.activity"),
               reading.forecastKp.formatted(.number.precision(.fractionLength(0...1))))
    }

    private var cloudReading: String {
        String(format: String(localized: "tonight.reading.clouds"),
               (reading.cloudFraction / 100).formatted(.percent.precision(.fractionLength(0))))
    }

    /// Sun altitude carries an explicit sign. Without it "Sun 36°" and
    /// "Sun -14°" look like the same kind of number, when one means broad
    /// daylight and the other means astronomical twilight.
    private var darknessReading: String {
        let degrees = Measurement(value: reading.solarAltitude, unit: UnitAngle.degrees)
            .formatted(.measurement(
                width: .narrow,
                usage: .asProvided,
                numberFormatStyle: .number
                    .precision(.fractionLength(0))
                    .sign(strategy: .always(includingZero: false))
            ))
        return String(format: String(localized: "tonight.reading.darkness"), degrees)
    }

    private var moonReading: String {
        String(format: String(localized: "tonight.reading.moon"),
               reading.moonIllumination.formatted(.percent.precision(.fractionLength(0))))
    }

    private func row(_ factor: LimitingFactor, value: Double, symbol: String, reading: String) -> some View {
        let isLimiting = factor == limitingFactor
        return HStack(spacing: Nightwatch.Space.m) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 22)
                .foregroundStyle(isLimiting ? palette.warning : palette.textTertiary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Nightwatch.Space.xs + 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(factor.localizedFactorName)
                        .font(isLimiting ? Nightwatch.TypeScale.emphasis : Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textPrimary)

                    if isLimiting {
                        Text("tonight.factors.limitingBadge")
                            .font(Nightwatch.TypeScale.caption)
                            .foregroundStyle(palette.warning)
                            .padding(.horizontal, Nightwatch.Space.s)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(palette.warning.opacity(0.15))
                            )
                    }

                    Spacer(minLength: Nightwatch.Space.s)

                    Text(verbatim: reading)
                        .font(Nightwatch.TypeScale.caption)
                        .monospacedDigit()
                        .foregroundStyle(palette.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                Meter(value: value, isLimiting: isLimiting)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: accessibilityLabel(factor, reading: reading, isLimiting: isLimiting)))
    }

    private func accessibilityLabel(_ factor: LimitingFactor, reading: String, isLimiting: Bool) -> String {
        let key: String.LocalizationValue = isLimiting
            ? "tonight.factors.accessibility.limiting"
            : "tonight.factors.accessibility.normal"
        return String(format: String(localized: key), factor.localizedFactorName, reading)
    }
}

private struct Meter: View {
    let value: Double
    let isLimiting: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { geo in
            let fraction = min(max(value, 0), 100) / 100
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.hairline)
                Capsule()
                    .fill(isLimiting ? palette.warning : palette.rampColor(for: value))
                    .frame(width: max(geo.size.width * fraction, fraction > 0 ? 4 : 0))
            }
        }
        .frame(height: 6)
    }
}

extension LimitingFactor {
    /// Short noun for the meter row, distinct from `localizedSentence`, which
    /// is the full explanatory line under the verdict.
    var localizedFactorName: String {
        switch self {
        case .activity: return String(localized: "tonight.factor.activity")
        case .clouds: return String(localized: "tonight.factor.clouds")
        case .darkness: return String(localized: "tonight.factor.darkness")
        case .moon: return String(localized: "tonight.factor.moon")
        case .none: return String(localized: "tonight.factor.none")
        }
    }
}
