// SPEC: Flow 2 ("crew strip showing who's posted today") · Flow 6 (member strip: streak + today-dot; ⏸ when paused) · Flow 10
// (absent for solo — the parent passes nil and renders nothing). WRITTEN — UNVERIFIED (needs Mac). T024

import SwiftUI

struct CrewStrip: View {
    let members: [MemberDot]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                ForEach(members) { member in
                    VStack(spacing: EmberTokens.Spacing.space4) {
                        ZStack(alignment: .bottomTrailing) {
                            AvatarView(displayName: member.displayName, image: nil, photoKey: member.profilePhotoKey)
                            Circle()
                                .fill(member.paused ? EmberColors.hairline : (member.postedToday ? EmberColors.ember : EmberColors.missedGray))
                                .frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
                                .overlay(Circle().stroke(EmberColors.canvas, lineWidth: EmberTokens.Size.hairline))
                        }
                        Text(member.paused ? "⏸" : "\(member.streak)").font(.caption.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                    }
                    // 6.3 — the strip is a STATUS display, not a control: a 40 pt avatar that looks tappable and does
                    // nothing is a false affordance. Marking it as an image tells VoiceOver the same truth the eye gets,
                    // and nothing here invites a tap that has no destination. (The Crew tab is where a member opens.)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("\(member.displayName), streak \(member.streak), \(member.paused ? "paused" : (member.postedToday ? "posted today" : "not yet today"))")
                }
            }
            .padding(.vertical, EmberTokens.Spacing.space4)
        }
    }
}
