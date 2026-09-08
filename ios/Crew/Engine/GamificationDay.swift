// SPEC: README "postUndone" (V34 same-day atomic reversal; V35 achievements survive; V43 rolled-over day = deletion) ·
// "dayRolledOver" (V04 reset, V15/V16 shields, V19–V21 pause) · "reactionGiven" (V27). Twin of gamification-day.ts.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum GamificationDay {
    static func applyPostUndone(_ state: inout GamificationState, dayKey: String) -> [Award] {
        if let judged = state.judgedThroughDayKey, judged >= dayKey { return [] } // SPEC: V43, E3
        guard var stack = state.undo[dayKey], let snapshot = stack.popLast() else { return [] }
        let streakBefore = state.currentStreak
        guard let restored = try? JSONDecoder.crew.decode(GamificationState.self, from: snapshot) else { return [] }
        let achievements = state.earnedAchievementIds
        var undo = state.undo
        undo[dayKey] = stack
        state = restored                        // SPEC: V34 — XP, streak, longest, lastCountedDayKey, week facts revert together
        state.earnedAchievementIds = achievements // SPEC: V35
        state.undo = undo
        return state.currentStreak != streakBefore ? [.streakTo(state.currentStreak)] : []
    }

    static func applyDayRolledOver(_ state: inout GamificationState, dayKey: String, hadRequirement: Bool, pauses: [Pause]) -> [Award] {
        state.judgedThroughDayKey = dayKey
        if !hadRequirement || state.lastCountedDayKey == dayKey || GamificationEngine.isPaused(dayKey, pauses: pauses) { return [] }
        if state.shields > 0 {
            state.shields -= 1                   // SPEC: V15, V16 — a shield absorbs the miss; the streak stands
            state.tallies.shieldsConsumed += 1
            return [.shieldConsumed]
        }
        if state.currentStreak > 0 {
            state.currentStreak = SpecConstants.streakAfterUnshieldedMiss   // SPEC: V04 — stated once, in gray
            return [.streakTo(state.currentStreak)]
        }
        return []
    }

    static func applyReactionGiven(_ state: inout GamificationState, dayKey: String, pauses: [Pause]) -> [Award] {
        if GamificationEngine.isPaused(dayKey, pauses: pauses) { return [] }
        if state.day.key != dayKey { state.day = DayCounters(key: dayKey) }
        state.day.reactions += 1
        if state.day.reactions > SpecConstants.reactionXpDailyCap { return [] }   // SPEC: V27
        return GamificationPost.finishAwards(&state, xp: [.xp(SpecConstants.xpReaction, reason: .reaction)], streakBefore: state.currentStreak, flags: GamificationPost.Flags())
    }
}
