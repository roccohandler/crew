// SPEC: A5 (owner-directed 2026-09-08) as drawn by A28 (f) — a crew of one: under the strip the system's card with the privacy
// promise, the one filled "Invite friends" (the system share sheet, Flow 6) and "Copy link" as text for the Captain; members read
// "Ask your Captain for the link." · Part III law ① (ink acts, never orange) · E3 (only your crew sees this). Screens hold ZERO
// logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). R5

import SwiftUI

struct CrewOfOneCard: View {
    let crew: CrewDTO
    let isCaptain: Bool
    let onCopyLink: () -> Void

    var body: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Label("Only your crew sees this.", systemImage: "lock").typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Text("Send the link and your first post lands here for them.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isCaptain, let link = crew.inviteLink, let url = URL(string: link) {
                    ShareLink(item: url, message: Text("Join my crew on Crew: \(crew.name) \(crew.emoji)")) {
                        Text("Invite friends").typeRole(EmberTokens.Typography.primaryLabel)
                            .foregroundStyle(EmberColors.onInk)
                            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.primaryHeight)
                            .background(EmberColors.ink, in: Capsule()) // the system's primary capsule
                    }
                    TextActionButton(title: "Copy link", role: EmberTokens.Typography.textButton, action: onCopyLink).frame(maxWidth: .infinity)
                } else if !isCaptain {
                    Text("Ask your Captain for the link.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
