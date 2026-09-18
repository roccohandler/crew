// SPEC: README "postCreated" — A22 G1 (a) (owner-approved 2026-09-18): a day COUNTS (streak + 1) only when a completed workout lands
// on a planned training day — or on any day under an all-rest plan (plannedWeekdays == []); a rest day neither requires nor breaks;
// a bonus or cardio day pays its XP and leaves the streak unchanged (V70, the repeal of V30). The first post of a day still pays
// +xpFirstPostOfDay whatever it is (V25, V70). Comeback: the first COUNTED day after ≥ comebackMissedDaysThreshold missed planned
// days (V82, R-069). Perfect week: every planned weekday of the Mon–Sun week carries a completed workout (V73–V76) — the "every day
// posted" clause is gone with the plate journal. Levels G2. Meals/text: fixture-only branches (their vectors are retired).
// Twin of gamification-post.ts. WRITTEN — UNVERIFIED (needs Mac).

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

    // GAP: A22 G1 (a) names no comeback rule — the most conservative reading (R-069): a "missed day" is a non-paused PLANNED day between
    // two counted days (a rest day is never missed; an all-rest plan misses nothing). A fixture without plannedWeekdays (pre-A22) counts
    // every non-paused day, as it always did. The crew's comeback BANNER keeps quietDaysBetween — silence in the stream (V37–V39).
    static func missedDaysBetween(_ fromDayKey: String, _ toDayKey: String, pauses: [Pause], plannedWeekdays: [Int]?) -> Int {
        var missed = 0
        var day = DayKey.addDays(fromDayKey, 1)
        while day < toDayKey {
            let planned = plannedWeekdays?.contains(DayKey.isoWeekday(day)) ?? true
            if planned && !GamificationEngine.isPaused(day, pauses: pauses) { missed += 1 }
            day = DayKey.addDays(day, 1)
        }
        return missed
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

    // SPEC: A22 G1 (a) — what counts a day: a completed workout on a planned day; under an all-rest plan, any completed workout;
    // a fixture without plannedWeekdays (pre-A22) counts a planned completed workout and nothing else
    static func countsTheDay(kind: PostKind, isPlannedDay: Bool, workoutCompleted: Bool, plannedWeekdays: [Int]?) -> Bool {
        guard kind == .workout, workoutCompleted else { return false }
        guard let plannedWeekdays else { return isPlannedDay }
        return isPlannedDay || plannedWeekdays.isEmpty
    }

    // SPEC: G6 as amended by A22 G1 (a) — every planned weekday of this Mon–Sun week carries a completed workout; ≥ 1 planned day;
    // once per week. Without a plan on the event there is nothing to judge, so no week is perfect.
    static func weekIsPerfect(_ state: GamificationState, plannedWeekdays: [Int]?) -> Bool {
        guard let weekKey = state.week.key, !state.week.awarded, let plannedWeekdays, !plannedWeekdays.isEmpty else { return false }
        return plannedWeekdays.allSatisfy { weekday in state.week.plannedDone.contains(DayKey.addDays(weekKey, weekday - 1)) }
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

    static func applyPostCreated(_ state: inout GamificationState, kind: PostKind, dayKey day: String, isPlannedDay: Bool, workoutCompleted: Bool, plannedWeekdays: [Int]?, pauses: [Pause]) -> [Award] {
        if GamificationEngine.isPaused(day, pauses: pauses) { return [] } // SPEC: V20 → V79
        ensureDay(&state, day)
        ensureWeek(&state, day)
        let snapshot = snapshot(of: state)
        let streakBefore = state.currentStreak
        var xp: [Award] = []
        var flags = Flags()
        if state.day.posts == 0 { xp.append(.xp(SpecConstants.xpFirstPostOfDay, reason: .firstPostOfDay)) } // SPEC: V25, V70
        state.day.posts += 1
        if countsTheDay(kind: kind, isPlannedDay: isPlannedDay, workoutCompleted: workoutCompleted, plannedWeekdays: plannedWeekdays) && state.lastCountedDayKey != day {
            // SPEC: V82 — the first counted day after ≥ comebackMissedDaysThreshold missed planned days (R-069); never the first-ever
            if let last = state.lastCountedDayKey { flags.comeback = missedDaysBetween(last, day, pauses: pauses, plannedWeekdays: plannedWeekdays) >= SpecConstants.comebackMissedDaysThreshold }
            state.currentStreak += SpecConstants.streakIncrementPerCountedDay   // SPEC: V02, V67, V72
            state.longestStreak = max(state.longestStreak, state.currentStreak)
            state.lastCountedDayKey = day
        }
        if kind == .workout && workoutCompleted {
            // SPEC: V25, V70, V71, E7 — first completed workout on a planned day = +100; every other = +25
            let planned = isPlannedDay && state.day.workouts == 0
            xp.append(planned ? .xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout) : .xp(SpecConstants.xpBonusWorkout, reason: .bonusWorkout))
            state.day.workouts += 1
        }
        if kind == .meal {
            if state.day.meals < SpecConstants.mealXpDailyCap { xp.append(.xp(SpecConstants.xpMealPost, reason: .meal)) } // fixture-only since A22
            state.day.meals += 1
        }
        if flags.comeback { xp.append(.xp(SpecConstants.xpComeback, reason: .comeback)) }
        if !state.week.posted.contains(day) { state.week.posted.append(day) }
        if isPlannedDay && !state.week.planned.contains(day) { state.week.planned.append(day) }
        if isPlannedDay && kind == .workout && workoutCompleted && !state.week.plannedDone.contains(day) { state.week.plannedDone.append(day) }
        if weekIsPerfect(state, plannedWeekdays: plannedWeekdays) {
            // SPEC: V73, V74 — +150 always; the shield only below the cap
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
