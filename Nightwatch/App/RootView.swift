import SwiftUI

/// Routes between onboarding and the app's main surface.
///
/// Five tabs is the iOS maximum before the system collapses into "More", and
/// each of these is a genuinely separate question rather than a section of
/// another screen: tonight, the nights after it, where the oval is, which
/// place, and everything else. Alerts deliberately do *not* get a tab. They
/// are a setting, and they are reachable from the bell on Tonight because
/// that is the screen you are on when you decide you want to be told.
struct RootView: View {
    @State private var appState = AppState()

    var body: some View {
        if appState.hasCompletedOnboarding {
            TabView {
                TonightView(appState: appState)
                    .tabItem {
                        Label { Text("tab.tonight") } icon: { Image(systemName: "sparkles") }
                    }

                NightsAheadView(appState: appState)
                    .tabItem {
                        Label { Text("tab.nights") } icon: { Image(systemName: "calendar") }
                    }

                OvalMapView(appState: appState)
                    .tabItem {
                        Label { Text("tab.map") } icon: { Image(systemName: "globe.europe.africa") }
                    }

                PlacesView(appState: appState)
                    .tabItem {
                        Label { Text("tab.places") } icon: { Image(systemName: "mappin.and.ellipse") }
                    }

                SettingsView(appState: appState)
                    .tabItem {
                        Label { Text("tab.settings") } icon: { Image(systemName: "gearshape") }
                    }
            }
        } else {
            OnboardingFlowView {
                appState.hasCompletedOnboarding = true
            }
        }
    }
}
