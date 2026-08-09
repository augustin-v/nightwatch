import SwiftUI
import AuroraCore

/// The app's main screen (spec §3/§4): one verdict, the named limiting
/// factor, the best-viewing window, four factor rows, and an hourly strip.
/// Renders from a hardcoded sample `NightVerdict` — real fetching and
/// location wiring is Phase 3b.
struct TonightView: View {
    private let verdict = SampleNight.verdict

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    verdictCard
                    factorRows
                    hourlyStrip
                }
                .padding()
            }
            .navigationTitle(Text("tonight.title"))
        }
    }

    /// Locale-aware "band accessibility label" and "best window range"
    /// strings, built from a localized `%@`-style template substituted with
    /// already-locale-formatted values — never raw string concatenation,
    /// per STANDARDS.md §11.
    private var bandAccessibilityLabel: String {
        let template = String(localized: "tonight.band.accessibilityLabel")
        return String(format: template, verdict.band.localizedLabel)
    }

    private func bestWindowRangeText(_ window: ClosedRange<Date>) -> String {
        let template = String(localized: "tonight.bestWindow.range")
        let start = window.lowerBound.formatted(date: .omitted, time: .shortened)
        let end = window.upperBound.formatted(date: .omitted, time: .shortened)
        return String(format: template, start, end)
    }

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verdict.band.localizedLabel)
                .font(.largeTitle.bold())
                .accessibilityLabel(Text(verbatim: bandAccessibilityLabel))

            Text(verdict.limitingFactor.localizedSentence)
                .font(.body)
                .foregroundColor(.secondary)

            if let window = verdict.bestWindow {
                Text(verbatim: bestWindowRangeText(window))
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("tonight.bestWindow.none")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var factorRows: some View {
        let peak = verdict.hourly.max(by: { $0.combined < $1.combined })
        return VStack(alignment: .leading, spacing: 12) {
            Text("tonight.factors.heading")
                .font(.headline)
            factorRow(title: String(localized: "tonight.factor.activity"), value: peak?.activity ?? 0)
            factorRow(title: String(localized: "tonight.factor.clouds"), value: peak?.clouds ?? 0)
            factorRow(title: String(localized: "tonight.factor.darkness"), value: peak?.darkness ?? 0)
            factorRow(title: String(localized: "tonight.factor.moon"), value: peak?.moon ?? 0)
        }
    }

    private func factorRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value / 100, format: .percent.precision(.fractionLength(0)))
                .foregroundColor(.secondary)
        }
    }

    private var hourlyStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("tonight.hourlyStrip.heading")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(verdict.hourly, id: \.date) { hour in
                        VStack(spacing: 6) {
                            Text(hour.date, format: .dateTime.hour())
                                .font(.caption)
                            Text(hour.combined / 100, format: .percent.precision(.fractionLength(0)))
                                .font(.caption.bold())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}
