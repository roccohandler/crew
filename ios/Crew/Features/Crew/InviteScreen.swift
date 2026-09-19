// SPEC: Flow 6 · A27 (b) (owner-approved 2026-09-18) as drawn by A28 (f) — the Invite sheet does ONLY invite: send the link and copy
// the code (A21.3 / W4: the same inviteToken, for a friend who will paste it). Renaming, replacing the link, removing a member and
// leaving moved to Manage crew. The system's sheet (on `card`, 28 pt top corners, the grabber): the crew's name at sheet-title
// weight with Done on its row, its size, the code and "Copy code" as text, and one filled "Send invite link" (the system share
// sheet) at the sheet's foot. "Crew full" and the link that is the Captain's to send (S13) stay explicit. R-092: the code is SF Pro
// like every word (§4: a monospace is the owner's to ask for), its label states instead of instructing (A28 (e)). R-095: Done on
// the title row (it sat alone on a toolbar row, off the gutter) and the primary bottom-anchored. WRITTEN — UNVERIFIED. T031 · R5

import SwiftUI

struct InviteScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if let crew = model.crew {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                            Text("\(crew.name) \(crew.emoji)").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityAddTraits(.isHeader)
                            Spacer(minLength: EmberTokens.Spacing.space8)
                            TextActionButton(title: "Done", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { dismiss() }
                        }
                        Text(numerals: "\(model.members.count) of \(SpecConstants.crewMaxMembers) in the crew").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    }
                    if model.members.count >= SpecConstants.crewMaxMembers {
                        Text(numerals: "Crew full — \(SpecConstants.crewMaxMembers) is the max.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                    } else if crew.inviteLink != nil, let code = model.inviteCodeText {
                        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                            Text("The code works too").typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
                            Text(numerals: code).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink).textSelection(.enabled).accessibilityIdentifier("inviteCode")
                            TextActionButton(title: "Copy code", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { model.copyInviteCode() }
                        }
                    } else if crew.inviteLink == nil, !model.isCaptain {
                        Text("Ask your Captain for the link.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink) // the link is the Captain's (S13)
                    }
                    if let notice = model.noticeLine {
                        Text(notice).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Spacing.space32)
                .padding(.bottom, EmberTokens.Spacing.space16)
            }
        }
        .background(EmberColors.card.ignoresSafeArea())
        // SPEC: 6.3 · 6.7 — the one filled button at the sheet's foot, in the thumb zone
        .crewBottomBar(surface: EmberColors.card) {
            if let crew = model.crew, model.members.count < SpecConstants.crewMaxMembers, let link = crew.inviteLink, let url = URL(string: link) {
                ShareLink(item: url, message: Text("Join my crew on Crew: \(crew.name) \(crew.emoji)")) {
                    Text("Send invite link").typeRole(EmberTokens.Typography.primaryLabel)
                        .foregroundStyle(EmberColors.onInk)
                        .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.primaryHeight)
                        .background(EmberColors.ink, in: Capsule()) // the one filled button: the system's primary capsule
                }
            }
        }
        .tint(EmberColors.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
