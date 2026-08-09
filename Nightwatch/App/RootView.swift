import SwiftUI

/// Routes between onboarding, the paywall, and the app.
///
/// This is a hard paywall, not a freemium app: onboarding hands straight to
/// the paywall and there is no way past it except paying or restoring. So the
/// paywall is a *stage of the root route*, not a sheet over the app. A sheet
/// can be swiped away, and anything reachable behind it would be free.
///
/// Because everyone inside has paid, no screen carries a locked state. Five
/// tabs, each a genuinely separate question: tonight, the nights after it,
/// where the oval is, which place, and everything else. Alerts deliberately
/// do not get a tab. They are a setting, reachable from the bell on Tonight,
/// because that is the screen you are on when you decide you want to be told.
struct RootView: View {
    @State private var appState = AppState()
    @State private var purchases = PurchaseStore.shared

    var body: some View {
        if !appState.hasCompletedOnboarding {
            OnboardingFlowView {
                appState.hasCompletedOnboarding = true
            }
        } else if !purchases.isEntitled {
            // Reached by someone who finished onboarding on an earlier launch
            // and never subscribed, and by anyone whose subscription lapsed.
            // The entitlement is RevenueCat's answer, seeded from the last
            // known value so a paying user does not see this flash on launch.
            PaywallView(source: .relaunch) {}
        } else {
            tabs
                .task { await purchases.refresh() }
        }
    }

    private var tabs: some View {
        TabView {
            TonightView()
                .tabItem {
                    Label { Text("tab.tonight") } icon: { Image(systemName: "sparkles") }
                }

            NightsAheadView()
                .tabItem {
                    Label { Text("tab.nights") } icon: { Image(systemName: "calendar") }
                }

            OvalMapView()
                .tabItem {
                    Label { Text("tab.map") } icon: { Image(systemName: "globe.europe.africa") }
                }

            PlacesView()
                .tabItem {
                    Label { Text("tab.places") } icon: { Image(systemName: "mappin.and.ellipse") }
                }

            SettingsView()
                .tabItem {
                    Label { Text("tab.settings") } icon: { Image(systemName: "gearshape") }
                }
        }
    }
}
