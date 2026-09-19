// SPEC: Flow 6 — CREW PULSE "4/5 today" + the member strip (streak + today-dot + ⏸); V37 pulse · A8 (owner-directed
// 2026-09-08): never a zero as a verdict — "No posts yet today" instead of "0/5 today". A28 (b), (f) · R5: the crew's name is an
// eyebrow, and a full pulse is ink, never accent (accent lives in three places, none of them here). WRITTEN — UNVERIFIED. T031

import SwiftUI

struct MemberStrip: View {
    let crewName: String
    let emoji: String
    let pulse: PulseDTO
    let members: [MemberDot]

    // SPEC: A8 — {n}/{m} today when n ≥ 1; No posts yet today when n = 0 (secondary ink, never red)
    private var pulseLine: String { pulse.posted == 0 ? "No posts yet today" : "\(pulse.posted)/\(pulse.total) today" }
    private var fullPulse: Bool { pulse.posted == pulse.total && pulse.total > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(crewName) \(emoji)").typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary) // uppercase by its role
                Spacer()
                Text(numerals: pulseLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(fullPulse ? EmberColors.ink : EmberColors.inkSecondary)
                    .accessibilityLabel(pulse.posted == 0 ? "No posts yet today" : "\(pulse.posted) of \(pulse.total) posted today")
            }
            CrewStrip(members: members)
        }
    }
}
