// SPEC: E4 / S18 — the lapsed user (14+ quiet days): one warm screen, "Your record still stands", two choices (Keep my plan ·
// Rebuild), zero guilt, no recap of what was missed. Screens hold ZERO logic (5.6.6): the trigger lives in HomeModel.
// WRITTEN — UNVERIFIED (needs Mac). T042

import SwiftUI

struct WelcomeBackScreen: View {
    let longestStreak: Int
    let onKeep: () -> Void
    let onRebuild: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Spacer()
            Text("Welcome back.").font(.largeTitle.weight(.bold)).foregroundStyle(EmberColors.inkText)
            Text("Your record still stands.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.emberText)
            if longestStreak > 0 {
                Text("Longest streak: \(longestStreak) days. That happened, and it still counts.").font(.body).foregroundStyle(EmberColors.secondaryText)
            }
            Text("Your plan is right where you left it.").font(.body).foregroundStyle(EmberColors.secondaryText)
            Spacer()
            PrimaryButton(title: "Keep my plan", action: onKeep)
            SecondaryButton(title: "Rebuild", action: onRebuild)
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome back")
    }
}
