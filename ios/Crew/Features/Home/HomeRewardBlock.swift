// SPEC: A28 (b), (d) — Home's reward block (mockups 03–06): the weekly ring beside the flame and its ink streak numeral, over the
// one card. ABSENT on the first day and with no plan (HomeScreen decides), where a zero would read as a verdict. The flame is
// accent while the streak is alive, inkMuted at zero, and off-season a snowflake in inkSecondary while the ring stays accent
// (those workouts happened). Replaces A14's header group: the week strip left Home — the ring IS the week (system §11).
//
// Rules carried, not changed: A18.1 names each numeral where it sits (the eyebrows "DAY STREAK" / "OFF-SEASON" and the ring's
// "OF N"); A8 / A18.1 — nothing captions a streak of zero; A18.2 — the ring renders only once the week holds a completed planned
// workout (GAP 3 in A28: the conservative reading keeps that gate and the planned-workout count until the owner rules); A17.1 /
// H020 — the shield fact stays on Home as one quiet line (GAP 3's third question). Screens hold zero logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct HomeRewardBlock: View {
    let streak: Int
    let shields: Int
    let ringDone: Int
    let ringPlanned: Int
    let isPaused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var flameSize: CGFloat = EmberTokens.Focus.flameGlyph

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space12) {
            HStack(alignment: .center, spacing: EmberTokens.Focus.rewardGap) {
                if Self.showsRing(ringDone: ringDone, ringPlanned: ringPlanned) { FocusRing(done: ringDone, planned: ringPlanned) }
                streakGroup
            }
            .frame(maxWidth: .infinity)
            if !isPaused, streak > 0 { Whisper(.whyStreak) } // A23: the first lit flame
            if !isPaused, shields > 0 { // GAP: A28 GAP 3, R-084 (1) — A17.1 / H020 kept: the shield fact stays one quiet line
                Text(shields == 1 ? "1 shield ready — one missed day won't break the streak." : "\(shields) shields ready — a missed day won't break the streak.")
                    .typeRole(EmberTokens.Typography.caption)
                    .foregroundStyle(EmberColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps, it never widens the column
            }
        }
    }

    private var streakGroup: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            HStack(alignment: .center, spacing: EmberTokens.Focus.space6) {
                Image(systemName: isPaused ? "snowflake" : "flame.fill")
                    .font(.system(size: flameSize, weight: .semibold))
                    .foregroundStyle(flameColor)
                Text("\(streak)")
                    .typeRole(EmberTokens.Typography.streakNumeral)
                    .foregroundStyle(isPaused ? EmberColors.inkSecondary : EmberColors.ink) // mockup 06 sets the frozen count in slate
                    .contentTransition(.numericText())
            }
            if let caption {
                Text(caption).typeRole(EmberTokens.Typography.eyebrowUnderRing).foregroundStyle(EmberColors.inkSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isPaused ? "Off-season, streak \(streak)" : "Streak \(streak)")
    }

    // SPEC: A28 (b) — the flame's three states; accent is the glyph alone, never the numeral
    private var flameColor: Color {
        if isPaused { return EmberColors.inkSecondary }
        return Self.flameIsAccent(streak: streak, isPaused: isPaused) ? EmberColors.accent : EmberColors.inkMuted
    }

    static func flameIsAccent(streak: Int, isPaused: Bool) -> Bool { !isPaused && streak > 0 }

    // SPEC: A28 (b) — the accent budget as a count: the ring's stroke and the flame glyph (two), off-season the ring alone (one), and
    // none where the block is absent (the first day, no plan). HomeRewardBlockTests pins it state by state.
    static func accentMarks(streak: Int, ringDone: Int, ringPlanned: Int, isPaused: Bool) -> Int {
        (showsRing(ringDone: ringDone, ringPlanned: ringPlanned) ? 1 : 0) + (flameIsAccent(streak: streak, isPaused: isPaused) ? 1 : 0)
    }

    // A8 / A18.1 — the eyebrow's STRING stays sentence case; its type role renders it uppercase (R-083 (7))
    private var caption: String? {
        if isPaused { return "Off-season" }
        return streak > 0 ? "Day streak" : nil
    }

    // GAP: A28 GAP 3, R-084 (1) — A18.2 kept: the ring is the reward, so it appears once the week holds one; A28 (b) keeps it off-season
    static func showsRing(ringDone: Int, ringPlanned: Int) -> Bool { ringPlanned > 0 && ringDone > 0 }
}
