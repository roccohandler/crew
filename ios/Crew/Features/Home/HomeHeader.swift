// SPEC: A14 · A17.1 · A18.1 · A18.2 · A18.6b — Home's header group: the flame, the weekly ring, the week strip, the
// shield line, and the two captions that name the numbers.
//
// A18.1 — EVERY NUMERAL IS NAMED WHERE IT SITS. A17.1 diagnosed this exactly ("the flame, the ring, the week strip and
// the crew avatar each build a complete English sentence and render it ONLY to VoiceOver, so a sighted user gets a
// glyph, two bare numerals and seven dots") and then gave copy to the strip and the crew avatar only. THE TWO BARE
// NUMERALS WERE THE FLAME AND THE RING. On the screen the owner photographed they both read "1" while counting
// different things — consecutive days with any post, and workouts done this ISO week — so the natural reading, "my 1
// is 1 of 3", is wrong. A17.1's three hard limits are carried verbatim: secondaryText ink and never #B84D00 (law ③),
// never tappable (law ①), bridge-gated.
//
// The captions live HERE rather than inside StreakFlame and WeeklyRing because ProgressScreen renders the same ring
// under its own week caption; a caption baked into the component would double up there.
//
// Split from HomeScreen.swift for the C9 200-line cap, the way HomeModel+Facts.swift already splits HomeModel.
// Screens hold ZERO logic (5.6.6): every value here is read off the model. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct HomeHeader: View {
    let streak: Int
    let shields: Int
    let ringDone: Int
    let ringPlanned: Int
    let week: [DayRingState]
    let isBridge: Bool
    let isPaused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            HStack(alignment: .top, spacing: EmberTokens.Spacing.space16) {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                    StreakFlame(streak: streak, paused: isPaused)
                    if !isBridge, let caption = streakCaption {
                        Text(caption).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    }
                }
                Spacer()
                // W043 — the ring is gone from the BRIDGE. There it read "0/3": a competing prompt on the one screen
                // §1D says must have none, an ember element that is not a reward (law ④), and a zero used as a verdict
                // (A8) — three rules at once, on a user's first ever screen.
                // A18.2 — and gone on every MONDAY too, for the same three reasons, which nobody checked: `ringDone`
                // resets each ISO week, so the shipped gate (`ringPlanned > 0, !isBridge`) printed "0/3" one day in
                // seven for every user, for the life of the app. It is the reward layer; it appears when there is a
                // reward. A18.6b — and never while the plan is frozen, where a fraction states a penalty the card denies.
                if showsRing {
                    VStack(alignment: .trailing, spacing: EmberTokens.Spacing.space4) {
                        WeeklyRing(done: ringDone, planned: ringPlanned)
                        Text("workouts this week").font(.caption).foregroundStyle(EmberColors.secondaryText)
                    }
                }
            }
            if !isBridge, !week.isEmpty { WeekStrip(days: week) } // A14: the states HomeModel already computed (F12)
            // A17.1 / H020 — the shield, which HomeModel has computed since day one and iOS rendered nowhere. A user
            // holding two shields and a user holding none saw an identical screen and an identical "One post keeps it
            // lit." Stated as reassurance, never as a countdown (spec:452). A8: rendered only above zero, so a
            // shieldless user is never told they have none.
            if !isBridge, shields > 0 {
                Text(shields == 1 ? "1 shield ready — one missed day won't break the streak." : "\(shields) shields ready — a missed day won't break the streak.")
                    .font(.caption).foregroundStyle(EmberColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps, it never widens the column
            }
        }
    }

    // A18.1 — A8 branch: nothing at a streak of zero, so the word "streak" never appears beside a 0 used as a verdict
    // (the same rule that takes the ring off the bridge and off Monday).
    private var streakCaption: String? {
        if isPaused { return "streak paused" }
        return streak > 0 ? "day streak" : nil
    }

    // A18.2 / A18.6b — the ring is the reward layer (law ④), so it renders only when there is a reward to show.
    private var showsRing: Bool { ringPlanned > 0 && ringDone > 0 && !isBridge && !isPaused }
}
