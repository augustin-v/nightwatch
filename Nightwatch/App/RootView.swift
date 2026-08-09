import SwiftUI

/// Routes between onboarding and the app's main surface. Only Tonight and
/// Settings exist as real screens at this stage (spec §3's other premium
/// screens — Nights ahead, Oval map, Places, Alerts — are later work);
/// this scaffold only needs the required-screen set to be reachable.
struct RootView: View {
    @State private var appState = AppState()

    var body: some View {
        if appState.hasCompletedOnboarding {
            TabView {
                TonightView()
                    .tabItem {
                        Label {
                            Text("tab.tonight")
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                    }
                SettingsView(appState: appState)
                    .tabItem {
                        Label {
                            Text("tab.settings")
                        } icon: {
                            Image(systemName: "gearshape")
                        }
                    }
            }
        } else {
            OnboardingFlowView {
                appState.hasCompletedOnboarding = true
            }
        }
    }
}
