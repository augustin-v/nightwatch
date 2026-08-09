import SwiftUI
import FactoryKit
import RevenueCat

/// The paywall.
///
/// This is a hard-paywall app, so this screen is not an upsell placed beside
/// the product: it *is* the product's front door, and every user meets it. It
/// therefore gets the app's own visual system rather than FactoryKit's shell,
/// which is a structural placeholder with stock type and grey cards.
///
/// Three deliberate choices:
///
/// - **No close control, and none hidden in a corner.** A dismissible hard
///   paywall is just a broken hard paywall. The honest version says what it
///   costs and gives a real restore path.
/// - **Prices come from StoreKit, never from the string catalog.** The
///   bundled copy is a fallback for the offline first launch only. A hardcoded
///   "$39.99/year" is wrong in seven of this app's eight languages.
/// - **The value lines are the three things the app actually does**, in the
///   order the product answers them. Generic benefit bullets would be filler.
struct PaywallView: View {
    var source: Analytics.PaywallSource = .relaunch
    let onEntitled: () -> Void

    @State private var store = PurchaseStore.shared
    @State private var selectedPlan: PaywallPlanChoice = .annual
    @State private var legalDocument: LegalDocumentChoice?
    @Environment(\.palette) private var palette

    var body: some View {
        NightSurface(intensity: 0.7) {
            content
        }
        .task {
            Analytics.paywallViewed(source: source)
            await store.refresh()
            guard !store.isEntitled else {
                onEntitled()
                return
            }
            PaywallPresenter.presentOnboardingPaywall()
        }
        .sheet(item: $legalDocument) { document in
            NavigationStack {
                LegalDocumentView(title: document.title, markdown: document.markdown)
            }
            .preferredColorScheme(.dark)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // The pitch fills whatever height the footer leaves it: headline
            // anchored to the top, value lines resting just above the fold,
            // and the slack in between rather than pooled underneath. In a
            // long language the same block simply scrolls instead.
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Nightwatch.Space.xl) {
                        headline
                        Spacer(minLength: Nightwatch.Space.xl)
                        valueLines
                    }
                    .padding(.horizontal, Nightwatch.Space.l)
                    .padding(.top, Nightwatch.Space.xxl)
                    .padding(.bottom, Nightwatch.Space.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            // The commitment half is pinned. On a small phone in a long
            // language the value copy can scroll, but the price and the button
            // must never be something the user has to go looking for.
            footer
        }
    }

    // MARK: - Top half

    private var headline: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.m) {
            Text("paywall.headline")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("paywall.subheadline")
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Symbols, not decoration: each one is the icon of the tab it refers to,
    /// so the promise and the thing delivered look like the same app.
    private var valueLines: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.l) {
            valueLine("sparkles", "paywall.value.tonight", tint: palette.ramp[3])
            valueLine("bell.badge", "paywall.value.alerts", tint: palette.ramp[2])
            valueLine("globe.europe.africa", "paywall.value.oval", tint: palette.ramp[4])
        }
    }

    private func valueLine(_ symbol: String, _ key: LocalizedStringKey, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Nightwatch.Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            Text(key)
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Bottom half

    private var footer: some View {
        VStack(spacing: Nightwatch.Space.m) {
            planRow(.annual)
            planRow(.weekly)

            if let failure = store.failureMessage {
                Text(verbatim: failure)
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.warning)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }

            purchaseButton
            legalRow
        }
        .padding(.horizontal, Nightwatch.Space.l)
        .padding(.top, Nightwatch.Space.l)
        .padding(.bottom, Nightwatch.Space.s)
        .background(alignment: .top) {
            // A hairline instead of a card. The footer needs to read as a
            // separate, heavier region without becoming a floating panel.
            Rectangle()
                .fill(palette.hairline)
                .frame(height: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: store.failureMessage)
    }

    private func planRow(_ plan: PaywallPlanChoice) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack(spacing: Nightwatch.Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Nightwatch.Space.s) {
                        Text(plan.titleKey)
                            .font(Nightwatch.TypeScale.emphasis)
                            .foregroundStyle(palette.textPrimary)

                        if plan == .annual, let badge = savingsBadge {
                            Text(verbatim: badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Nightwatch.Palette.night.background)
                                .padding(.horizontal, Nightwatch.Space.s)
                                .padding(.vertical, 2)
                                .background(palette.positive, in: Capsule())
                        }
                    }

                    Text(verbatim: priceText(for: plan))
                        .font(Nightwatch.TypeScale.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer(minLength: Nightwatch.Space.s)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Nightwatch.Palette.ctaGreen : palette.hairline)
            }
            .padding(Nightwatch.Space.m)
            .background(
                RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                    .fill(isSelected ? palette.surfaceRaised : palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                            .strokeBorder(
                                isSelected ? Nightwatch.Palette.ctaGreen : .clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var purchaseButton: some View {
        Button {
            Task {
                await store.purchase(selectedPlan, source: source)
                if store.isEntitled { onEntitled() }
            }
        } label: {
            ZStack {
                // The label stays in the layout while spinning so the button
                // does not change height mid-purchase.
                Text("paywall.continue")
                    .font(Nightwatch.TypeScale.emphasis)
                    .opacity(store.isPurchasing ? 0 : 1)

                if store.isPurchasing {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Nightwatch.Space.m)
            .background(Nightwatch.Palette.ctaGreen, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))
            .foregroundStyle(.white)
        }
        .disabled(store.isPurchasing || store.isRestoring || product(for: selectedPlan) == nil)
        .padding(.top, Nightwatch.Space.xs)
    }

    /// Apple requires the renewal terms and links to be on the purchase
    /// screen itself, not buried in Settings. Restore sits here too because a
    /// hard paywall with no visible restore is a rejection.
    private var legalRow: some View {
        VStack(spacing: Nightwatch.Space.s) {
            Text("paywall.renewalTerms")
                .font(.caption2)
                .foregroundStyle(palette.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Nightwatch.Space.m) {
                Button {
                    Task {
                        if await store.restore() { onEntitled() }
                    }
                } label: {
                    Text("paywall.restorePurchases")
                }
                .disabled(store.isPurchasing || store.isRestoring)

                Button { legalDocument = .terms } label: { Text("settings.terms.title") }
                Button { legalDocument = .privacy } label: { Text("settings.privacyPolicy.title") }
            }
            .font(Nightwatch.TypeScale.caption)
            .foregroundStyle(palette.textSecondary)
        }
    }

    // MARK: - Prices

    /// The real localized store price when RevenueCat has answered. When it
    /// has not, the row is explicit and the purchase control stays disabled.
    private func priceText(for plan: PaywallPlanChoice) -> String {
        guard let product = product(for: plan) else {
            return String(localized: "paywall.error.unavailable")
        }
        return String(
            format: String(localized: plan.pricePerPeriodKey),
            product.localizedPriceString
        )
    }

    /// Shown only when both prices are known and the saving is real. A
    /// "Best value" badge that is not backed by arithmetic is a claim, and
    /// this one is checkable: 39.99 a year against 9.99 a week is 92%.
    private var savingsBadge: String? {
        guard
            let annual = store.annual?.storeProduct,
            let weekly = store.weekly?.storeProduct
        else { return nil }

        let weeklyYearly = weekly.price * 52.1775
        guard weeklyYearly > 0 else { return nil }
        let saved = 1 - (annual.price as Decimal) / weeklyYearly
        guard saved > 0.05 else { return nil }

        let percent = Int((saved as NSDecimalNumber).doubleValue * 100)
        return String(format: String(localized: "paywall.annual.savings"), percent.formatted())
    }

    private func product(for plan: PaywallPlanChoice) -> RevenueCat.StoreProduct? {
        switch plan {
        case .annual: store.annual?.storeProduct
        case .weekly: store.weekly?.storeProduct
        }
    }
}

private extension PaywallPlanChoice {
    var titleKey: LocalizedStringKey {
        switch self {
        case .annual: "paywall.annual.title"
        case .weekly: "paywall.weekly.title"
        }
    }

    var pricePerPeriodKey: String.LocalizationValue {
        switch self {
        case .annual: "paywall.annual.pricePerPeriod"
        case .weekly: "paywall.weekly.pricePerPeriod"
        }
    }

    var fallbackPriceKey: String.LocalizationValue {
        switch self {
        case .annual: "paywall.annual.priceLabel"
        case .weekly: "paywall.weekly.priceLabel"
        }
    }
}

/// Which legal document the sheet is showing.
enum LegalDocumentChoice: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms: String(localized: "settings.terms.title")
        case .privacy: String(localized: "settings.privacyPolicy.title")
        }
    }

    var markdown: String {
        switch self {
        case .terms: LegalDocuments.termsMarkdown
        case .privacy: LegalDocuments.privacyPolicyMarkdown
        }
    }
}
