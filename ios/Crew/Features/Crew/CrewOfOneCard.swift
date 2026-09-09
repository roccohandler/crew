// SPEC: A5 (owner-directed 2026-09-08) — a crew of one: under the strip an ink card with the privacy promise, Invite friends
// (the system share sheet, Flow 6) and Copy link for the Captain; members read "Ask your Captain for the link." · Part III
// law ① (ink acts, never orange) · E3 (only your crew sees this). Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct CrewOfOneCard: View {
    let crew: CrewDTO
    let isCaptain: Bool
    let onCopyLink: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Label("Only your crew sees this.", systemImage: "lock").font(.headline).foregroundStyle(EmberColors.inkText)
                Text("Send the link and your first post lands here for them.").font(.body).foregroundStyle(EmberColors.secondaryText)
                if isCaptain, let link = crew.inviteLink, let url = URL(string: link) {
                    ShareLink(item: url, message: Text("Join my crew on Crew: \(crew.name) \(crew.emoji)")) {
                        Text("Invite friends").font(.headline)
                            .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
                            .foregroundStyle(EmberColors.primaryButtonLabel)
                            .background(EmberColors.primaryButtonFill, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
                    }
                    Button("Copy link", action: onCopyLink).font(.subheadline).foregroundStyle(EmberColors.inkText)
                        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                } else if !isCaptain {
                    Text("Ask your Captain for the link.").font(.body).foregroundStyle(EmberColors.inkText)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
