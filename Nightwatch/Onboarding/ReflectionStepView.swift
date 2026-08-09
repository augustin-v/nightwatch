import SwiftUI

/// Screen 7 — the personalized "your plan" beat, computed entirely on
/// device from the latitude-band answer (spec §5, ONBOARDING.md's CalAI
/// reference pattern). No network call, no server round trip.
struct ReflectionStepView: View {
    let realisticNightsPerYear: Int
    let onContinue: () -> Void

    /// The count is formatted through `.formatted()` (locale-aware grouping)
    /// and substituted into a localized `%@` template — never string-glued —
    /// so the catalog holds one exact, unambiguous key per STANDARDS.md §11.
    private var reflectionTitle: String {
        let template = String(localized: "onboarding.reflection.title")
        return String(format: template, realisticNightsPerYear.formatted())
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(verbatim: reflectionTitle)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("onboarding.reflection.subtitle")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button(action: onContinue) {
                Text("onboarding.reflection.continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
