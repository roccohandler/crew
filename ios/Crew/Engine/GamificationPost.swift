// SPEC: README "postCreated" — first post of a day counts it (streak + 1, +25); kind XP; comeback after ≥3 quiet
// non-paused days (V29); perfect week per G6 → +150 + shield (V13, V28); levels G2. Twin of gamification-post.ts.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum GamificationPost {
    struct Flags {
        var comeback = false
        var perfect = false
        var shieldEarned = false
        var shieldConsumed = false
    }

    static func quietDaysBetween(_ fromDayKey: String, _ toDayKey: String, pauses: [Pause]) -> Int {
        var quiet = 0
        var day = DayKey.addDays(fromDayKey, 1)
        while day < toDayKey {
            if !GamificationEngine.isPaused(day, pauses: pauses) { quiet += 1 }
            day = DayKey.addDays(day, 1)
        }
        return quiet
    }

    static func ensureDay(_ state: inout GamificationState, _ dayKey: String) {
        if state.day.key != dayKey { state.day = DayCounters(key: dayKey) }
    }

    static func ensureWeek(_ state: inout GamificationState, _ dayKey: String) {
        let weekKey = DayKey.weekKey(for: dayKey)
        if state.week.key != weekKey { state.week = WeekFacts(key: weekKey) }
    }

    static func snapshot(of state: GamificationState) -> Data {
        var copy = state
        copy.undo = [:]
        copy.earnedAchievementIds = []
        return (try? JSONEncoder.crew.encode(copy)) ?? Data()
    }

    // SPEC: G6 — every day posted AND every planned day workout-completed AND ≥1 planned day; once per week
    static func weekIsPerfect(_ state: GamificationState) -> Bool {
        guard let weekKey = state.week.key, !state.week.awarded else { return false }
        let everyDayPosted = (0..<TimeUnits.daysPerWeek).allSatisfy { state.week.posted.contains(DayKey.addDays(weekKey, $0)) }
        return everyDayPosted && state.week.planned.count >= 1 && state.week.planned.allSatisfy { state.week.plannedDone.contains($0) }
    }

    // Builds the canonical award list (README order) after XP and state changes
    static func finishAwards(_ state: inout GamificationState, xp: [Award], streakBefore: Int, flags: Flags) -> [Award] {
        for award in xp { if case .xp(let amount, _) = award { state.totalXP += amount } }
        var awards = xp
        if state.currentStreak != streakBefore { awards.append(.streakTo(state.currentStreak)) }
        if flags.comeback { state.tallies.comebacks += 1; awards.append(.comeback) }
        if flags.perfect { state.tallies.perfectWeeks += 1; awards.append(.perfectWeek) }
        if flags.shieldEarned { awards.append(.shieldEarned) }
        if flags.shieldConsumed { state.tallies.shieldsConsumed += 1; awards.append(.shieldConsumed) }
        let level = GamificationEngine.levelFor(totalXP: state.totalXP)
        if level > state.level { awards.append(.levelUp(level)) }
        state.level = level
        return awards
    }

    static func applyPostCreated(_ state: inout GamificationState, kind: PostKind, dayKey day: String, isPlannedDay: Bool, workoutCompleted: Bool, pauses: [Pause]) -> [Award] {
        if GamificationEngine.isPaused(day, pauses: pauses) { return [] } // SPEC: V20
        ensureDay(&state, day)
        ensureWeek(&state, day)
        let snapshot = snapshot(of: state)
        let streakBefore = state.currentStreak
        var xp: [Award] = []
        var flags = Flags()
        if state.day.posts == 0 {
            // SPEC: V29 / V39 — the first post after ≥ comebackMissedDaysThreshold quiet days; never the first-ever post
            if let last = state.lastCountedDayKey { flags.comeback = quietDaysBetween(last, day, pauses: pauses) >= SpecConstants.comebackMissedDaysThreshold }
            state.currentStreak += SpecConstants.streakIncrementPerCountedDay   // SPEC: V01, V02, V11
            state.longestStreak = max(state.longestStreak, state.currentStreak)
            state.lastCountedDayKey = day
            xp.append(.xp(SpecConstants.xpFirstPostOfDay, reason: .firstPostOfDay)) // SPEC: V24
        }
        state.day.posts += 1
        if kind == .workout && workoutCompleted {
            // SPEC: V25, V30, V31, E7 — first completed workout on a planned day = +100; every other = +25
            let planned = isPlannedDay && state.day.workouts == 0
            xp.append(planned ? .xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout) : .xp(SpecConstants.xpBonusWorkout, reason: .bonusWorkout))
            state.day.workouts += 1
        }
        if kind == .meal {
            if state.day.meals < SpecConstants.mealXpDailyCap { xp.append(.xp(SpecConstants.xpMealPost, reason: .meal)) } // SPEC: V26
            state.day.meals += 1
        }
        if flags.comeback { xp.append(.xp(SpecConstants.xpComeback, reason: .comeback)) }
        if !state.week.posted.contains(day) { state.week.posted.append(day) }
        if isPlannedDay && !state.week.planned.contains(day) { state.week.planned.append(day) }
        if isPlannedDay && kind == .workout && workoutCompleted && !state.week.plannedDone.contains(day) { state.week.plannedDone.append(day) }
        if weekIsPerfect(state) {
            // SPEC: V13, V14, V28 — +150 always; the shield only below the cap
            state.week.awarded = true
            flags.perfect = true
            xp.append(.xp(SpecConstants.xpPerfectWeek, reason: .perfectWeek))
            if state.shields < SpecConstants.maxShields {
                state.shields += SpecConstants.shieldsEarnedPerPerfectWeek
                flags.shieldEarned = true
            }
        }
        state.undo[day, default: []].append(snapshot)
        return finishAwards(&state, xp: xp, streakBefore: streakBefore, flags: flags)
    }
}
