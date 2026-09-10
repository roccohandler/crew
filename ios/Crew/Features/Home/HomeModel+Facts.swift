// SPEC: A14 / A17 (owner-directed 2026-09-09 and 2026-09-10) — the facts Home REPORTS, as opposed to the state it is
// in: the week's seven marks (with their done/planned counts) and today's three vector slots.
//
// A14: the three primary logging vectors are Workout · Cardio · Meals, and Home has to treat them as peers. Owner-
// directed: "users should log workouts, cardio, and nutrition — those are the three primary vectors". Before this they
// were not close to co-equal (F10): a workout was one tap on the only filled primary, cardio two taps on an outline
// button whose position MOVED between states, and a meal a nav-bar glyph that vanished on the bridge — so logging a
// 45-minute walk changed Home not at all. This is RITUAL equality, not magnitude equality (plan §5): the same slot,
// the same journal row, the same streak weight. It is never a comparison and never a score.
//
// Everything here is STATIC and takes what it needs, because HomeModel's `store` and `userId` are `private let` and a
// Swift extension in another file cannot reach them. That is also why these are testable without a HomeModel at all.
// Split from HomeModel.swift for the C9 200-line cap, the way SettingsModel+Notifications.swift already splits.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

// SPEC: A14 — today's state for each vector. A measurement or nothing: never a zero, never a fraction with a zero on
// top (A8 — the same rule that removes the bridge's "0/3" ring). `nil`/false renders as an invitation to log.
struct VectorSlots: Equatable {
    let workoutDone: Bool
    let cardioMinutes: Int?  // nil = no cardio logged today
    let meals: Int
}

// SPEC: Flow 2 ("weekly ring 2/4") · A17.4 — the week's seven marks and the ring's fraction, from one pass.
struct WeekMarks: Equatable {
    let days: [DayRingState]
    let done: Int
    let planned: Int
}

extension HomeModel {
    // SPEC: A14 — the plan rows Home's card renders, in the shape the HomeLines twin takes
    static func homeExercises(_ workout: LocalWorkoutTemplate) -> [HomeExercise] {
        workout.exercises.map {
            HomeExercise(name: $0.name, type: $0.type, targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax, holdSeconds: $0.holdSeconds, order: $0.order)
        }
    }

    // SPEC: Flow 2 — one mark per ISO weekday from trainingWeekdays (A1); missed = warm gray, never red;
    // A2 — a standalone cardio log never fills a planned slot.
    // A17.4 — the FIRST upcoming training day becomes `.nextUp` and gets its own mark. Before that, `.upcoming` and
    // `.rest` rendered byte-identically, so a plan training Mon/Wed/Sun drew Sunday exactly like Friday while the card
    // said "Next workout: Sun". Only the first: marking every future training day would answer a question nobody asked
    // and put three identical marks where one fact belongs.
    static func weekMarks(userId: String, plan: LocalPlan?, todayKey: String, store: Store) throws -> WeekMarks {
        let weekKey = DayKey.weekKey(for: todayKey)
        var done = 0
        var planned = 0
        var days: [DayRingState] = try (0..<TimeUnits.daysPerWeek).map { offset in
            let dayKey = DayKey.addDays(weekKey, offset)
            guard plan?.trainingWeekdays.contains(offset + 1) ?? false else { return dayKey == todayKey ? .today : .rest }
            planned += 1
            let completed = try store.sessions(for: userId, dayKey: dayKey).contains { $0.status == "completed" && $0.workoutKind != "cardio" }
            if completed { done += 1; return .done }
            if dayKey == todayKey { return .today }
            return dayKey < todayKey ? .missed : .upcoming
        }
        if let first = days.firstIndex(of: .upcoming) { days[first] = .nextUp }
        return WeekMarks(days: days, done: done, planned: planned)
    }

    // SPEC: A14 · A2 — a completed session of kind `cardio` is CARDIO, not a workout; every other completed session is
    // a workout. This is the same split A14 gives the post type, the journal row and the heat map, applied to Home.
    static func slots(userId: String, dayKey: String, store: Store) throws -> VectorSlots {
        let completed = try store.sessions(for: userId, dayKey: dayKey).filter { $0.status == "completed" }
        let cardioSeconds = completed.filter { $0.workoutKind == "cardio" }.flatMap { JournalFacts.doneSets($0, type: "cardio") }.reduce(0) { $0 + ($1.holdSeconds ?? 0) }
        let meals = try store.posts(for: userId, dayKey: dayKey).filter { $0.type == "meal" }.count
        return VectorSlots(
            workoutDone: completed.contains { $0.workoutKind != "cardio" },
            cardioMinutes: cardioSeconds > 0 ? JournalFacts.minutes(ofSeconds: cardioSeconds) : nil,
            meals: meals
        )
    }
}
