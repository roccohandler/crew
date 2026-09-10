// SPEC: A14 (owner-directed 2026-09-09) — the three primary logging vectors are Workout · Cardio · Meals, and Home has to
// treat them as peers. Owner-directed: "users should log workouts, cardio, and nutrition — those are the three primary
// vectors". Before this they were not close to co-equal (F10): a workout was one tap on the only filled primary, cardio two
// taps on an outline button whose position MOVED between states, and a meal a nav-bar glyph that vanished on the bridge —
// so logging a 45-minute walk changed Home not at all.
//
// This is RITUAL equality, not magnitude equality (plan §5): the same slot, the same journal row, the same streak weight.
// It is never a comparison and never a score — Flow 4 forbids the app from grading, and nothing here ranks the three.
//
// Split from HomeModel.swift for the C9 200-line cap, the way SettingsModel+Notifications.swift already splits.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

// SPEC: A14 — today's state for each vector. A measurement or nothing: never a zero, never a fraction with a zero on top
// (A8 — the same rule that removes the bridge's "0/3" ring). `nil`/false renders as "—", which says nothing at all.
struct VectorSlots: Equatable {
    let workoutDone: Bool
    let cardioMinutes: Int?  // nil = no cardio logged today
    let meals: Int
}

extension HomeModel {
    // SPEC: A14 — the plan rows Home's card renders, in the shape the HomeLines twin takes
    static func homeExercises(_ workout: LocalWorkoutTemplate) -> [HomeExercise] {
        workout.exercises.map {
            HomeExercise(name: $0.name, type: $0.type, targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax, holdSeconds: $0.holdSeconds, order: $0.order)
        }
    }

    // SPEC: A14 · A2 — a completed session of kind `cardio` is CARDIO, not a workout; every other completed session is a
    // workout. This is the same split A14 gives the post type, the journal row and the heat map, applied to Home.
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
