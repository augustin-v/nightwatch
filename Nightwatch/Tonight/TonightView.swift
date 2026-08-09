import SwiftUI
import AuroraCore

/// The app's main screen: tonight's answer, why, and when.
///
/// Composition order mirrors how the question is actually asked — "is it worth
/// it?", then "why not / why yes?", then "when exactly?". Anything that does
/// not answer one of those three is not on this screen.
///
/// Data is still the sample night; the live `NightForecastService` lands with
/// the Phase 3b data layer and replaces `verdict` without changing this view's
/// shape.
struct TonightView: View {
    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false

    private let verdict = SampleNight.verdict

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }

    private var palette: Nightwatch.Palette { .forMode(mode) }

    /// The hour the verdict is actually about — the peak of the night, not
    /// whatever hour happens to be first in the array.
    private var peakHour: HourlyVisibilityScore? {
        verdict.hourly.max(by: { $0.combined < $1.combined })
    }

    /// The physical readings for the peak hour, so the factor rows can show
    /// real measurements instead of internal sub-scores.
    private var peakReading: HourlyVisibilityInput? {
        guard let peakHour else { return nil }
        return SampleNight.inputs.first { $0.date == peakHour.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Nightwatch.Space.xl) {
                    header

                    VerdictHero(
                        band: verdict.band,
                        peakScore: peakHour?.combined ?? 0,
                        limitingFactor: verdict.limitingFactor,
                        bestWindow: verdict.bestWindow
                    )

                    if let peakHour, let peakReading {
                        FactorBreakdown(
                            hour: peakHour,
                            reading: peakReading,
                            limitingFactor: verdict.limitingFactor
                        )
                    }

                    NightTimeline(hours: verdict.hourly, bestWindow: verdict.bestWindow)
                }
                .padding(.horizontal, Nightwatch.Space.l)
                .padding(.top, Nightwatch.Space.s)
                // Clears the floating tab bar; without it the timeline card is
                // cut off by the chrome at the bottom of the screen.
                .padding(.bottom, Nightwatch.Space.xxl * 2)
            }
            .background(background.ignoresSafeArea())
            .toolbar { nightVisionToggle }
            .toolbarBackground(palette.background, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .nightwatchTheme(mode)
        .tint(palette.rampColor(for: peakHour?.combined ?? 0))
        .preferredColorScheme(.dark)
    }

    /// Place and date lead, because the same night has a different answer 200
    /// km away and the user needs to know which sky this is about.
    private var header: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.xs) {
            Text(verbatim: SampleNight.placeName)
                .font(Nightwatch.TypeScale.title)
                .foregroundStyle(palette.textPrimary)

            Text(verdict.hourly.first?.date ?? .now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(Nightwatch.TypeScale.caption)
                .foregroundStyle(palette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One tap from the main screen, per the product decision that night
    /// vision is a first-class mode rather than a buried setting — outside in
    /// the dark, nobody is going digging through Settings for it.
    private var nightVisionToggle: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    nightVisionEnabled.toggle()
                }
            } label: {
                Image(systemName: nightVisionEnabled ? "eye.fill" : "eye")
                    .foregroundStyle(nightVisionEnabled ? palette.textPrimary : palette.textSecondary)
            }
            .accessibilityLabel(Text("tonight.nightVision.accessibilityLabel"))
            .accessibilityValue(Text(nightVisionEnabled ? "common.on" : "common.off"))
        }
    }

    /// A single soft aurora wash from the top, tinted by tonight's verdict.
    /// It is the only decorative element on the screen and it still encodes
    /// information — on a dead night it is almost invisible.
    private var background: some View {
        let accent = palette.rampColor(for: peakHour?.combined ?? 0)
        return ZStack {
            palette.background
            RadialGradient(
                colors: [accent.opacity(0.18), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
        }
    }
}

#Preview("Worth watching") {
    TonightView()
}
