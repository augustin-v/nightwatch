import SwiftUI
import AuroraCore

/// The next three nights, so a trip can actually be planned.
///
/// Tonight answers "coat on or not?". This screen answers a different
/// question: "which night this week?" So it is a comparison surface, not
/// three copies of the Tonight card. Every night gets the same fixed shape at
/// the same vertical rhythm, which is what makes them scannable against each
/// other, and the score dial is the only element that changes size-of-signal.
struct NightsAheadView: View {
    let appState: AppState

    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false
    @State private var model = NightsAheadModel()
    @State private var services = AppServices.shared
    @State private var showingPaywall = false

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }
    private var palette: Nightwatch.Palette { .forMode(mode) }

    var body: some View {
        NavigationStack {
            content
                .background(palette.background.ignoresSafeArea())
                .navigationTitle(Text("nights.title"))
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(palette.background, for: .navigationBar)
        }
        .nightwatchTheme(mode)
        .tint(Nightwatch.Palette.ctaGreen)
        .preferredColorScheme(.dark)
        .premiumSheet(isPresented: $showingPaywall, appState: appState)
        .task(id: ForecastTrigger(placeID: services.selectedPlaceID, isPremium: appState.isPremium)) {
            if appState.isPremium { await model.syncToActiveLocation() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !appState.isPremium {
            LockedFeature(
                symbol: "calendar",
                title: "nights.locked.title",
                promise: "nights.locked.promise",
                specifics: [
                    "nights.locked.specific.compare",
                    "nights.locked.specific.window",
                    "nights.locked.specific.reason"
                ],
                onUnlock: { showingPaywall = true }
            )
        } else {
            switch model.state {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .needsLocation:
                unavailable("nights.empty.needsLocation")
            case .unavailable:
                unavailable("nights.empty.unavailable")
            case .ready(let reports):
                ScrollView {
                    LazyVStack(spacing: Nightwatch.Space.l) {
                        ForEach(reports, id: \.nightOf) { report in
                            NightCard(report: report)
                        }
                    }
                    .padding(.horizontal, Nightwatch.Space.l)
                    .padding(.bottom, Nightwatch.Space.xxl * 2)
                }
                .refreshable { await model.refresh() }
            }
        }
    }

    private func unavailable(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(Nightwatch.TypeScale.body)
            .foregroundStyle(palette.textSecondary)
            .multilineTextAlignment(.center)
            .padding(Nightwatch.Space.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One night, in the fixed shape every other night on this screen shares.
private struct NightCard: View {
    let report: NightForecastReport

    @Environment(\.palette) private var palette

    private var peakScore: Double { report.verdict.hourly.map(\.combined).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            Text(report.nightOf, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(Nightwatch.TypeScale.caption)
                .textCase(.uppercase)
                .kerning(1.1)
                .foregroundStyle(palette.textTertiary)

            HStack(alignment: .center, spacing: Nightwatch.Space.l) {
                VStack(alignment: .leading, spacing: Nightwatch.Space.xs) {
                    Text(report.verdict.band.localizedLabel)
                        .font(Nightwatch.TypeScale.title)
                        .foregroundStyle(palette.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(report.verdict.limitingFactor.localizedSentence)
                        .font(Nightwatch.TypeScale.caption)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ScoreArc(score: peakScore, lineWidth: 6)
                    .frame(width: 58, height: 58)
                    .accessibilityHidden(true)
            }

            // A night that never leaves zero draws a flat line along the
            // bottom of its box, which reads as a divider rule rather than
            // data. There is no shape to show, so nothing is shown.
            if peakScore > 0 {
                NightSparkline(hours: report.verdict.hourly)
                    .frame(height: 34)
                    .accessibilityHidden(true)
            }

            windowChip
        }
        .padding(Nightwatch.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Nightwatch.Radius.card)
                .fill(palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Nightwatch.Radius.card)
                        .strokeBorder(palette.rampColor(for: peakScore).opacity(0.28), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
    }

    private var windowChip: some View {
        HStack(spacing: Nightwatch.Space.s) {
            Image(systemName: report.verdict.bestWindow == nil ? "moon.zzz" : "clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    report.verdict.bestWindow == nil
                        ? palette.textTertiary
                        : palette.rampColor(for: peakScore)
                )
                .accessibilityHidden(true)

            if let window = report.verdict.bestWindow {
                Text(verbatim: VerdictHero.windowText(window))
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.textPrimary)
            } else {
                Text("tonight.bestWindow.none")
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.textTertiary)
            }
        }
        .padding(.horizontal, Nightwatch.Space.m)
        .padding(.vertical, Nightwatch.Space.s)
        .background(palette.surfaceRaised, in: Capsule())
    }
}

/// The night's shape at a glance. Stroke only, no area fill: the filled
/// ribbon is the Tonight screen's signature and repeating it here would flatten
/// the difference between the two surfaces.
private struct NightSparkline: View {
    let hours: [HourlyVisibilityScore]

    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { context, size in
            guard hours.count > 1 else { return }
            let stepX = size.width / CGFloat(hours.count - 1)
            var path = Path()
            for (index, hour) in hours.enumerated() {
                let score = min(max(hour.combined, 0), 100) / 100
                let point = CGPoint(x: CGFloat(index) * stepX, y: size.height * (1 - score))
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            let peak = hours.map(\.combined).max() ?? 0
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        palette.rampColor(for: peak * 0.35),
                        palette.rampColor(for: peak)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

@MainActor
@Observable
final class NightsAheadModel {
    enum State: Equatable {
        case loading
        case needsLocation
        case ready([NightForecastReport])
        case unavailable
    }

    private(set) var state: State = .loading

    private let services: AppServices
    private var hasStarted = false
    private var loadedCoordinate: GeoCoordinate?

    /// Three nights, matching the spec. Beyond that the Kp forecast's own
    /// skill falls off fast enough that another card would be decoration
    /// rather than information.
    private let nightCount = 3

    init(services: AppServices = .shared) {
        self.services = services
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await load()
    }

    func refresh() async {
        await load(force: true)
    }

    func syncToActiveLocation() async {
        guard hasStarted else { return await start() }
        guard services.activeCoordinate != loadedCoordinate else { return }
        state = .loading
        await load(force: true)
    }

    private func load(force: Bool = false) async {
        // Tonight owns the permission prompt and the bounded wait for a first
        // fix. By the time this tab is opened either a coordinate exists or
        // the user has declined, so this screen just reports what it finds.
        guard let coordinate = services.activeCoordinate else {
            state = .needsLocation
            return
        }

        loadedCoordinate = coordinate

        if !force, case .loading = state,
           let cached = await services.forecastService.cachedReports(count: nightCount, at: coordinate) {
            state = .ready(cached)
        }

        let reports = await services.forecastService.refreshReports(
            count: nightCount,
            at: coordinate,
            now: Date()
        )
        state = reports.isEmpty ? .unavailable : .ready(reports)
    }
}
