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
                            // SPEC: spec:290 ("the EMPTY today-dot") · 6.5 — H016/A17.4. Posted is a FILLED ember dot;
                            // not-posted is a HOLLOW ring, which is what the spec already called for. Before this the
                            // two differed by COLOUR ALONE (ember vs missedGray at 2.53:1 on a card), so the single
                            // fact this dot carries was invisible in grayscale and failed the 3:1 gate at once. The
                            // one stroke does both jobs: a canvas halo separates a filled dot from the avatar behind
                            // it, and an ink-gray ring IS the empty state. A paused member reads as not-posted here —
                            // the ⏸ in the numeral below carries that distinction, and it is the honest reading.
                            Circle()
                                .fill(member.postedToday ? EmberColors.ember : EmberColors.card)
                                .frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
                                .overlay(Circle().strokeBorder(member.postedToday ? EmberColors.canvas : EmberColors.secondaryText, lineWidth: EmberTokens.Size.hairline))
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
        // H006: the strip had per-member labels but NO container label, so VoiceOver entered a run of avatars with no
        // idea what it had entered. `.contain` keeps each member reachable as its own element underneath.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crew today")
    }
}
