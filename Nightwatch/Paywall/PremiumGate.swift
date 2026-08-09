import SwiftUI

/// The locked state for a premium screen.
///
/// A greyed-out screenshot behind a padlock is the obvious pattern and it is
/// the wrong one here: the whole product is about not wasting a cold night, so
/// a locked screen that shows a *fake* forecast would undercut the one thing
/// the app is selling. Instead each locked screen states plainly what it
/// would tell you, in the app's own visual language, and gets out of the way.
///
/// It is deliberately the same composition on all four screens. Four
/// differently-shaped upsells would read as four different apps.
struct LockedFeature: View {
    let symbol: String
    let title: LocalizedStringKey
    let promise: LocalizedStringKey
    /// Two or three concrete specifics. Not marketing adjectives: the actual
    /// things the screen does once it is unlocked.
    let specifics: [LocalizedStringKey]
    let onUnlock: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: Nightwatch.Space.xl) {
            Spacer(minLength: 0)

            VStack(spacing: Nightwatch.Space.l) {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(palette.ramp[2])
                    .frame(width: 76, height: 76)
                    .background(
                        Circle()
                            .fill(palette.ramp[2].opacity(0.12))
                            .overlay(Circle().strokeBorder(palette.ramp[2].opacity(0.3), lineWidth: 1))
                    )
                    .accessibilityHidden(true)

                VStack(spacing: Nightwatch.Space.s) {
                    Text(title)
                        .font(Nightwatch.TypeScale.title)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(promise)
                        .font(Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Nightwatch.Space.s) {
                    ForEach(Array(specifics.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .firstTextBaseline, spacing: Nightwatch.Space.m) {
                            Circle()
                                .fill(palette.ramp[2])
                                .frame(width: 5, height: 5)
                                .accessibilityHidden(true)
                            Text(line)
                                .font(Nightwatch.TypeScale.body)
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Nightwatch.Space.l)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.card))
            }

            Spacer(minLength: Nightwatch.Space.l)
                .frame(maxHeight: Nightwatch.Space.xxl)

            Button(action: onUnlock) {
                Text("premium.unlock")
                    .font(Nightwatch.TypeScale.emphasis)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: Nightwatch.Radius.chip))
        }
        .padding(.horizontal, Nightwatch.Space.l)
        .padding(.bottom, Nightwatch.Space.xxl * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// What a premium screen's load is keyed on.
///
/// Keying only on the selected place was a real bug: buying a subscription
/// while looking at a locked screen left it spinning forever, because nothing
/// re-ran the load after the entitlement flipped. The entitlement is part of
/// the trigger, not just a condition inside it.
struct ForecastTrigger: Equatable {
    let placeID: SavedPlace.ID?
    let isPremium: Bool
}

/// Presents the paywall over any premium surface and flips the entitlement on
/// a successful purchase. Centralised so the four premium screens cannot
/// drift into four slightly different purchase hand-offs.
struct PremiumSheet: ViewModifier {
    @Binding var isPresented: Bool
    let appState: AppState

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            PaywallView {
                appState.isPremium = true
                isPresented = false
            }
        }
    }
}

extension View {
    func premiumSheet(isPresented: Binding<Bool>, appState: AppState) -> some View {
        modifier(PremiumSheet(isPresented: isPresented, appState: appState))
    }
}
