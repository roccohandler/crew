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
    //
    // A18.7 — EVERY planned day is marked, and the FIRST upcoming one keeps its own mark. A17.4 marked only the next
    // one, so every planned day after it rendered byte-identically to a rest day: on a four-day plan the ring said
    // "of 4" while the strip could account for at most three of them. A18.1 puts the word "workouts" beside the ring,
    // which turns that mismatch into a visible contradiction — so the strip has to be readable AGAINST the ring.
    //
    // A18.6a — PAUSE-AWARE. A planned day inside an active pause window is never `.missed` and never counts toward
    // `planned`: Flow 7 and spec:460 promise "pauses without penalty", and A17.1 turned these grey dots into the
    // English sentence "This week: Mon missed" — printed directly above a card that says the streak is frozen. The
    // day reads exactly as a rest day reads, because under a pause that is what it is.
    //
    // The `trainingWeekdays` guard stays FIRST, before any session is read (A18.7): a bonus workout completed on a
    // non-training day is not a planned-day completion, the ring does not count it, and a strip that marked it could
    // not be read against the ring. The web twin tested the completion first and emitted "done" — one user, two
    // answers, two different summary sentences. This is the rule both engines now follow.
    static func weekMarks(userId: String, plan: LocalPlan?, todayKey: String, pause: LocalPause?, store: Store) throws -> WeekMarks {
        let weekKey = DayKey.weekKey(for: todayKey)
        var done = 0
        var planned = 0
        var days: [DayRingState] = try (0..<TimeUnits.daysPerWeek).map { offset in
            let dayKey = DayKey.addDays(weekKey, offset)
            let isToday = dayKey == todayKey
            let frozen = pause.map { dayKey >= $0.startDay && dayKey < $0.endDay } ?? false
            guard plan?.trainingWeekdays.contains(offset + 1) ?? false, !frozen else { return isToday ? .today : .rest }
            planned += 1
            let completed = try store.sessions(for: userId, dayKey: dayKey).contains { $0.status == "completed" && $0.workoutKind != "cardio" }
            if completed { done += 1; return .done }
            if isToday { return .today }
            return dayKey < todayKey ? .missed : .upcoming
        }
        if let first = days.firstIndex(of: .upcoming) { days[first] = .nextUp }
        return WeekMarks(days: days, done: done, planned: planned)
    }

    // SPEC: A18.9 · A6 — what today actually held, in the sentence the journal already prints. The all-done card was
    // the one state with no filled control and nothing to report, so the day you did everything right was the day the
    // screen looked least finished. Built by the SessionSummaryLine twin, so this adds no copy and no engine rule:
    // one line per completed session, in completion order ("Push day · 12/12 sets · 44 min", "Walk · 25 min · 2.1 km").
    static func todaySummary(userId: String, dayKey: String, distanceUnit: String, store: Store) throws -> [String] {
        try store.sessions(for: userId, dayKey: dayKey)
            .filter { $0.status == "completed" }
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
            .map { JournalFacts.summaryLine($0, distanceUnit: distanceUnit) } // C5: the journal's line, reused, not a second one
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
