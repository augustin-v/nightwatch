import SwiftUI
import AuroraCore

/// The app's main screen: tonight's answer, why, and when.
///
/// Composition order mirrors how the question is actually asked — "is it worth
/// it?", then "why not / why yes?", then "when exactly?". Anything that does
/// not answer one of those three is not on this screen.
struct TonightView: View {
    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false
    @State private var model = TonightModel()

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }
    private var palette: Nightwatch.Palette { .forMode(mode) }

    var body: some View {
        NavigationStack {
            content
                .background(background.ignoresSafeArea())
                .toolbar { nightVisionToggle }
                .toolbarBackground(palette.background, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
        }
        .nightwatchTheme(mode)
        .tint(palette.rampColor(for: currentPeakScore))
        .preferredColorScheme(.dark)
        .task { await model.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingNight()
        case .needsLocation:
            EmptyNightState(
                symbol: "location.slash",
                title: "tonight.empty.needsLocation.title",
                message: "tonight.empty.needsLocation.message"
            )
        case .unavailable:
            EmptyNightState(
                symbol: "wifi.slash",
                title: "tonight.empty.unavailable.title",
                message: "tonight.empty.unavailable.message"
            )
        case .ready(let report):
            report_ScrollView(report)
        }
    }

    private func report_ScrollView(_ report: NightForecastReport) -> some View {
        let verdict = report.verdict
        let peakHour = verdict.hourly.max(by: { $0.combined < $1.combined })
        return ScrollView {
            VStack(alignment: .leading, spacing: Nightwatch.Space.xl) {
                header(for: report)

                VerdictHero(
                    band: verdict.band,
                    peakScore: peakHour?.combined ?? 0,
                    limitingFactor: verdict.limitingFactor,
                    bestWindow: verdict.bestWindow
                )

                if let peakHour, let reading = report.reading(at: peakHour.date) {
                    FactorBreakdown(
                        hour: peakHour,
                        reading: reading,
                        limitingFactor: verdict.limitingFactor
                    )
                }

                NightTimeline(hours: verdict.hourly, bestWindow: verdict.bestWindow)

                attribution
            }
            .padding(.horizontal, Nightwatch.Space.l)
            .padding(.top, Nightwatch.Space.s)
            // Clears the floating tab bar; without it the timeline card is
            // cut off by the chrome at the bottom of the screen.
            .padding(.bottom, Nightwatch.Space.xxl * 2)
        }
        .refreshable { await model.refresh() }
    }

    /// Place, date, and — the part most forecast apps omit — how old the
    /// numbers are. A confident verdict computed from eight-hour-old cloud
    /// data is worse than an honest one.
    private func header(for report: NightForecastReport) -> some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.xs) {
            Text(report.nightOf, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(Nightwatch.TypeScale.title)
                .foregroundStyle(palette.textPrimary)

            let freshness = DataFreshness.combined(report.activityFreshness, report.cloudFreshness)
            if let label = freshness.localizedRelativeLabel {
                Text(verbatim: label)
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(freshness.isStale ? palette.warning : palette.textTertiary)
            } else {
                Text("tonight.freshness.unavailable")
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// MET Norway's CC BY 4.0 terms require visible attribution wherever their
    /// data is shown, not only in Settings.
    private var attribution: some View {
        Text("tonight.attribution")
            .font(Nightwatch.TypeScale.caption)
            .foregroundStyle(palette.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentPeakScore: Double {
        guard case .ready(let report) = model.state else { return 0 }
        return report.verdict.hourly.map(\.combined).max() ?? 0
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
        let accent = palette.rampColor(for: currentPeakScore)
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

// MARK: - States

private struct LoadingNight: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: Nightwatch.Space.m) {
            ProgressView()
                .controlSize(.large)
            Text("tonight.loading")
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty states get real content rather than a blank screen — each one says
/// what happened and what the user can do about it.
private struct EmptyNightState: View {
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: Nightwatch.Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(palette.textTertiary)
                .accessibilityHidden(true)

            Text(title)
                .font(Nightwatch.TypeScale.title)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Nightwatch.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
