import SwiftUI

/// Where Settings' "Manage Subscription" row leads.
///
/// One question first, then Apple's own subscription management. There is no
/// discount offer and no second screen arguing with the decision: this app is
/// a hard paywall with two honest prices, and a save-offer would only be an
/// admission that the first price was wrong. The question exists because
/// knowing *why* people leave is worth one tap; it is skippable, and the
/// button that leaves is never hidden behind answering it.
///
/// Only the preset reason code is transmitted. Whatever is typed in the
/// detail field stays on this device.
struct ManageSubscriptionFlow: View {
    @Environment(\.palette) private var palette
    @State private var selected: CancellationReasonChoice?
    @State private var detail = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Nightwatch.Space.xl) {
                header
                reasons
                detailField
                continueButton
            }
            .padding(.horizontal, Nightwatch.Space.l)
            .padding(.top, Nightwatch.Space.l)
            .padding(.bottom, Nightwatch.Space.xxl)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle(Text("cancel.navigationTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(palette.background, for: .navigationBar)
        .task { Analytics.cancellationStarted() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.s) {
            Text("cancel.reasonPrompt")
                .font(Nightwatch.TypeScale.title)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("cancel.optional")
                .font(Nightwatch.TypeScale.caption)
                .foregroundStyle(palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reasons: some View {
        VStack(spacing: Nightwatch.Space.s) {
            ForEach(CancellationReasonChoice.allCases) { reason in
                let isSelected = selected == reason
                Button {
                    selected = isSelected ? nil : reason
                } label: {
                    HStack(spacing: Nightwatch.Space.m) {
                        Text(reason.labelKey)
                            .font(isSelected ? Nightwatch.TypeScale.emphasis : Nightwatch.TypeScale.body)
                            .foregroundStyle(palette.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: Nightwatch.Space.s)

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? Nightwatch.Palette.ctaGreen : palette.hairline)
                    }
                    .padding(Nightwatch.Space.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                            .fill(palette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                                    .strokeBorder(
                                        isSelected ? Nightwatch.Palette.ctaGreen.opacity(0.5) : .clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }

    private var detailField: some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.s) {
            TextField(text: $detail, axis: .vertical) {
                Text("cancel.detailPlaceholder")
            }
            .textFieldStyle(.plain)
            .font(Nightwatch.TypeScale.body)
            .foregroundStyle(palette.textPrimary)
            .lineLimit(3...6)
            .padding(Nightwatch.Space.m)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))

            // Said plainly, because a free-text box on a cancellation screen
            // invites people to write things they would not want sent
            // anywhere.
            Text("cancel.detailPrivacy")
                .font(.caption2)
                .foregroundStyle(palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var continueButton: some View {
        Button {
            if let selected {
                Analytics.cancellationReason(selected.reasonCode)
            }
            openNativeSubscriptionManagement()
        } label: {
            Text("cancel.continueToAppStore")
                .font(Nightwatch.TypeScale.emphasis)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Nightwatch.Space.m)
                .background(palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))
                .foregroundStyle(palette.textPrimary)
        }
        .buttonStyle(.plain)
    }

    /// Apple owns cancellation. The app's job is to get out of the way once
    /// it has asked its one question.
    private func openNativeSubscriptionManagement() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }
}

/// The preset reasons. `reasonCode` is the stable analytics slug and is the
/// only part of this screen that is ever transmitted.
enum CancellationReasonChoice: String, CaseIterable, Identifiable {
    case tooExpensive
    case didntUseIt
    case foundBetterApp
    case technicalIssues
    case forecastWrong
    case other

    var id: String { rawValue }

    var reasonCode: String {
        switch self {
        case .tooExpensive: "too_expensive"
        case .didntUseIt: "didnt_use_it"
        case .foundBetterApp: "found_better_app"
        case .technicalIssues: "technical_issues"
        case .forecastWrong: "forecast_wrong"
        case .other: "other"
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .tooExpensive: "cancel.reason.tooExpensive"
        case .didntUseIt: "cancel.reason.didntUseIt"
        case .foundBetterApp: "cancel.reason.foundBetterApp"
        case .technicalIssues: "cancel.reason.technicalIssues"
        case .forecastWrong: "cancel.reason.forecastWrong"
        case .other: "cancel.reason.other"
        }
    }
}
