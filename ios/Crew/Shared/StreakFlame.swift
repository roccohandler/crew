// SPEC: 1D — the flame renders UNLIT at 0 ("Your first flame lights today"); Part III law ④ — the ember flame is the
// first orange the user ever sees, on Home. Gray = missed-gray, never red. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct StreakFlame: View {
    let streak: Int
    let paused: Bool

    private var lit: Bool { streak > 0 && !paused }

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            Image(systemName: paused ? "snowflake" : "flame.fill")
                .font(.title)
                .foregroundStyle(lit ? EmberColors.ember : EmberColors.missedGray)
            Text("\(streak)")
                .font(.title.weight(.bold).monospacedDigit())
                .foregroundStyle(lit ? EmberColors.emberText : EmberColors.secondaryText)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(paused ? "Streak paused at \(streak)" : "Streak \(streak)")
    }
}
