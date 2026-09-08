// SPEC: S01 — a stale (> a day) in-progress session triggers the stale-session prompt: keep going or discard; nothing is counted
// until it is completed (V32) and a discard never touches XP. Plain private helper of the Home feature (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T042

import SwiftUI

struct StaleSessionPrompt: View {
    let workoutName: String
    let onKeepGoing: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Text("Still working out?").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
            Text("\(workoutName) has been open since yesterday. Keep going, or let it go — nothing is lost either way.").font(.body).foregroundStyle(EmberColors.secondaryText)
            PrimaryButton(title: "Keep going", action: onKeepGoing)
            SecondaryButton(title: "Discard it", action: onDiscard)
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
