import SwiftUI
import UserNotifications
import AuroraCore

/// Alert settings.
///
/// The threshold is expressed as a verdict band, not a number, because "wake
/// me at 55" is meaningless and "wake me when it is worth watching" is the
/// actual decision. The band buttons are the same words and the same ramp
/// colours used on the Tonight screen, so the setting and the thing it
/// controls are visibly the same scale.
struct AlertsView: View {
    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false
    @AppStorage(AlertSettings.enabledKey) private var alertsEnabled = false
    @AppStorage(AlertSettings.thresholdKey) private var threshold = AlertSettings.defaultThreshold
    @AppStorage(AlertSettings.quietEnabledKey) private var quietHoursEnabled = false
    @AppStorage(AlertSettings.quietStartKey) private var quietStart = AlertSettings.defaultQuietStart
    @AppStorage(AlertSettings.quietEndKey) private var quietEnd = AlertSettings.defaultQuietEnd

    @Environment(\.dismiss) private var dismiss

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }
    private var palette: Nightwatch.Palette { .forMode(mode) }

    var body: some View {
        NavigationStack {
            content
                .background(palette.background.ignoresSafeArea())
                .navigationTitle(Text("alerts.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(palette.background, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { dismiss() } label: { Text("common.done") }
                    }
                }
        }
        .nightwatchTheme(mode)
        .tint(Nightwatch.Palette.ctaGreen)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Nightwatch.Space.xl) {
                masterToggle
                thresholdSection
                    .opacity(alertsEnabled ? 1 : 0.4)
                    .disabled(!alertsEnabled)
                quietSection
                    .opacity(alertsEnabled ? 1 : 0.4)
                    .disabled(!alertsEnabled)
                footnote
            }
            .padding(.horizontal, Nightwatch.Space.l)
            .padding(.bottom, Nightwatch.Space.xxl)
        }
        .task { Analytics.featureUsed(.alertsOpened) }
        .onChange(of: alertsEnabled) { _, enabled in
            if enabled { Task { await AlertSettings.requestAuthorizationIfNeeded() } }
            Analytics.featureUsed(enabled ? .alertsEnabled : .alertsDisabled)
            AlertSettings.rescheduleNow()
        }
        .onChange(of: threshold) { _, _ in
            // The chosen band is not sent. How often people move it is the
            // useful signal, and it needs no property to be useful.
            Analytics.featureUsed(.alertThresholdChanged)
            AlertSettings.rescheduleNow()
        }
        .onChange(of: quietHoursEnabled) { _, enabled in
            if enabled { Analytics.featureUsed(.quietHoursEnabled) }
            AlertSettings.rescheduleNow()
        }
        .onChange(of: quietStart) { _, _ in AlertSettings.rescheduleNow() }
        .onChange(of: quietEnd) { _, _ in AlertSettings.rescheduleNow() }
    }

    private var masterToggle: some View {
        Toggle(isOn: $alertsEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("alerts.enabled.title")
                    .font(Nightwatch.TypeScale.emphasis)
                    .foregroundStyle(palette.textPrimary)
                Text("alerts.enabled.subtitle")
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Nightwatch.Palette.ctaGreen)
        .padding(Nightwatch.Space.m)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))
        .padding(.top, Nightwatch.Space.m)
    }

    private var thresholdSection: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            sectionHeading("alerts.threshold.heading")

            VStack(spacing: Nightwatch.Space.s) {
                ForEach(AlertSettings.selectableBands, id: \.band) { option in
                    bandRow(option)
                }
            }
            .padding(Nightwatch.Space.m)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.card))
        }
    }

    private func bandRow(_ option: AlertSettings.BandOption) -> some View {
        let isSelected = threshold == option.score
        return Button {
            threshold = option.score
        } label: {
            HStack(spacing: Nightwatch.Space.m) {
                Circle()
                    .fill(palette.rampColor(for: option.score))
                    .frame(width: 10, height: 10)

                // Band name over its frequency hint rather than beside it.
                // Side by side, the longest band word pushed its hint onto a
                // second line and the three rows stopped lining up.
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.band.localizedLabel)
                        .font(isSelected ? Nightwatch.TypeScale.emphasis : Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textPrimary)

                    Text(option.frequencyHint)
                        .font(Nightwatch.TypeScale.caption)
                        .foregroundStyle(palette.textTertiary)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: Nightwatch.Space.s)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Nightwatch.Palette.ctaGreen : palette.hairline)
            }
            .padding(.vertical, Nightwatch.Space.s)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var quietSection: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            sectionHeading("alerts.quiet.heading")

            VStack(spacing: Nightwatch.Space.m) {
                Toggle(isOn: $quietHoursEnabled) {
                    Text("alerts.quiet.toggle")
                        .font(Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textPrimary)
                }
                .tint(Nightwatch.Palette.ctaGreen)

                if quietHoursEnabled {
                    hourStepper("alerts.quiet.from", value: $quietStart)
                    hourStepper("alerts.quiet.to", value: $quietEnd)
                }
            }
            .padding(Nightwatch.Space.m)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.card))
        }
    }

    /// Whole hours only. Alerts are pre-scheduled from an hourly forecast, so
    /// a minute-precision picker would promise a resolution the underlying
    /// data does not have.
    private func hourStepper(_ label: LocalizedStringKey, value: Binding<Int>) -> some View {
        Stepper(value: value, in: 0...23) {
            HStack {
                Text(label)
                    .font(Nightwatch.TypeScale.body)
                    .foregroundStyle(palette.textSecondary)
                Spacer()
                Text(verbatim: AlertSettings.hourText(value.wrappedValue))
                    .font(Nightwatch.TypeScale.emphasis)
                    .monospacedDigit()
                    .foregroundStyle(palette.textPrimary)
            }
        }
    }

    private func sectionHeading(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(Nightwatch.TypeScale.sectionHeading)
            .foregroundStyle(palette.textSecondary)
    }

    /// States the latency ceiling instead of hiding it. The app has no server,
    /// so an alert can only be as current as the last background wake iOS
    /// granted. Saying so is the difference between a limitation and a bug
    /// report.
    private var footnote: some View {
        Text("alerts.footnote")
            .font(Nightwatch.TypeScale.caption)
            .foregroundStyle(palette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// One place that knows where alert preferences live, so the UI, the
/// composition root and the background task cannot disagree about a key name.
enum AlertSettings {
    static let enabledKey = "alertsEnabled"
    static let thresholdKey = "alertThreshold"
    static let quietEnabledKey = "quietHoursEnabled"
    static let quietStartKey = "quietHoursStart"
    static let quietEndKey = "quietHoursEnd"

    static let defaultThreshold: Double = 55
    static let defaultQuietStart = 1
    static let defaultQuietEnd = 6

    struct BandOption {
        let band: VisibilityBand
        let score: Double
        let frequencyHint: LocalizedStringKey
    }

    /// Only the three bands worth waking someone for. "No chance" and "Slim"
    /// are not offered as alert thresholds on purpose: an app that notifies
    /// you about a slim chance is an app you turn notifications off for.
    /// Computed rather than stored: `LocalizedStringKey` is not `Sendable`,
    /// and a static array of them would be shared mutable state as far as
    /// strict concurrency is concerned.
    static var selectableBands: [BandOption] {
        [
        BandOption(band: .worthWatching, score: 25, frequencyHint: "alerts.frequency.often"),
        BandOption(band: .strong, score: 55, frequencyHint: "alerts.frequency.sometimes"),
        BandOption(band: .rare, score: 80, frequencyHint: "alerts.frequency.rarely")
        ]
    }

    static func hourText(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    nonisolated static var quietHours: QuietHours? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: quietEnabledKey) else { return nil }
        return QuietHours(
            startHour: defaults.object(forKey: quietStartKey) as? Int ?? defaultQuietStart,
            endHour: defaults.object(forKey: quietEndKey) as? Int ?? defaultQuietEnd
        )
    }

    nonisolated static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }
    static func applyNotificationAuthorization(
        granted: Bool,
        defaults: UserDefaults = .standard
    ) {
        guard granted else { return }
        defaults.set(true, forKey: enabledKey)
        if defaults.object(forKey: thresholdKey) == nil {
            defaults.set(defaultThreshold, forKey: thresholdKey)
        }
    }


    static func requestAuthorizationIfNeeded() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    /// Applying a settings change immediately rather than waiting for the next
    /// background wake, which could be hours away. Without this, turning the
    /// threshold down would appear to do nothing all evening.
    static func rescheduleNow() {
        Task.detached(priority: .utility) {
            await AppServices.makeBackgroundCoordinator().refreshAndRescheduleAlerts()
        }
    }
}
