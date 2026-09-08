// SPEC: Flow 6 — CREW PULSE "4/5 today" + the member strip (streak + today-dot + ⏸); V37 pulse. WRITTEN — UNVERIFIED. T031

import SwiftUI

struct MemberStrip: View {
    let crewName: String
    let emoji: String
    let pulse: PulseDTO
    let members: [MemberDot]

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            HStack {
                Text("\(crewName.uppercased()) \(emoji)").font(.headline).foregroundStyle(EmberColors.inkText)
                Spacer()
                Text("\(pulse.posted)/\(pulse.total) today").font(.subheadline.monospacedDigit()).foregroundStyle(pulse.posted == pulse.total && pulse.total > 0 ? EmberColors.emberText : EmberColors.secondaryText)
                    .accessibilityLabel("\(pulse.posted) of \(pulse.total) posted today")
            }
            CrewStrip(members: members)
        }
    }
}
