import SwiftUI

/// Holds the paid-only route while Superwall owns the purchase surface.
///
/// This view contains no pricing, plans, benefits, or purchase controls. It only
/// presents the remote campaign and keeps the app locked if that presentation is
/// dismissed or unavailable. RevenueCat entitlement state is the sole unlock.
struct RemotePaywallGate: View {
    var source: Analytics.PaywallSource = .relaunch
    let onEntitled: () -> Void

    @State private var store = PurchaseStore.shared
    @State private var showsRetry = false
    @State private var presentationSequence = 0

    var body: some View {
        NightSurface(intensity: 0.7) {
            VStack(spacing: Nightwatch.Space.l) {
                if showsRetry {
                    Text("paywall.error.unavailable")
                        .font(Nightwatch.TypeScale.body)
                        .foregroundStyle(Nightwatch.Palette.night.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        presentationSequence += 1
                    } label: {
                        Text("paywall.continue")
                            .font(Nightwatch.TypeScale.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Nightwatch.Space.m)
                            .background(
                                Nightwatch.Palette.ctaGreen,
                                in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                            )
                            .foregroundStyle(.white)
                    }
                } else {
                    ProgressView()
                        .tint(Nightwatch.Palette.ctaGreen)
                        .controlSize(.large)
                        .accessibilityLabel(Text("paywall.continue"))
                }
            }
            .padding(.horizontal, Nightwatch.Space.xl)
            .frame(maxWidth: 420)
        }
        .task(id: presentationSequence) {
            await presentPaywall()
        }
        .onChange(of: store.isEntitled) { _, isEntitled in
            if isEntitled { onEntitled() }
        }
    }

    private func presentPaywall() async {
        Analytics.paywallViewed(source: source)
        await store.refresh()
        guard !store.isEntitled else {
            onEntitled()
            return
        }

        showsRetry = false
        PaywallPresenter.presentOnboardingPaywall {
            Task { @MainActor in
                await store.refresh()
                if store.isEntitled {
                    onEntitled()
                } else {
                    showsRetry = true
                }
            }
        }
    }
}
