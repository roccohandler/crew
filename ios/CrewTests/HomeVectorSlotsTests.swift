// SPEC: A14 (owner-directed 2026-09-09) — the three-vector row facts: a walk fills Cardio and never Workout, a workout
// fills Workout, meals count meal posts, and an empty day reports nothing rather than a zero (A8).
//
// This file is NOT in ios/Package.swift: it reaches SwiftData through Store, which the Linux engine target does not build
// (that target compiles Engine/, Generated/, TimeUnits and ApiModels only). It runs under Xcode with HomeModelTests.
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeVectorSlotsTests: XCTestCase {
    private let userId = "vector-user"
    private let tz = TimeZone(identifier: "America/Los_Angeles")!
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!
    private let dayKey = "2026-09-04"

    private func session(_ store: Store, id: String, kind: String, cardioSeconds: Int?) throws {
        // `done` and `distanceMeters` are not init parameters — a set log is created open and checked off afterwards
        let sets = cardioSeconds.map { seconds -> [LocalSetLog] in
            let set = LocalSetLog(order: 0, targetReps: 0, actualReps: 0, weight: nil, holdSeconds: seconds, isWarmup: false)
            set.done = true
            return [set]
        } ?? []
        let exercises = cardioSeconds == nil ? [] : [LocalSessionExercise(exerciseId: "walk", name: "Walk", equipment: "none", type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: cardioSeconds, order: 0, sets: sets)]
        let doc = LocalSession(clientId: id, userId: userId, dayKey: dayKey, status: "completed", workoutName: kind == "cardio" ? "Walk" : "Push day", workoutKind: kind, isPlannedDay: kind != "cardio", startedAt: friday, timezone: tz.identifier, exercises: exercises)
        doc.completedAt = friday
        store.context.insert(doc)
        try store.save()
    }

    // A8 — an empty day reports nothing, never a zero and never "0/3"
    func testAnEmptyDayReportsNothingRatherThanZero() throws {
        let store = Store(inMemory: true)
        let slots = try HomeModel.slots(userId: userId, dayKey: dayKey, store: store)
        XCTAssertEqual(slots, VectorSlots(workoutDone: false, cardioMinutes: nil, meals: 0))
    }

    // A14 — the split that is the whole point: a walk fills the Cardio slot and leaves Workout empty. Before A14 the walk
    // wrote a post of type "workout", so every count of workouts silently included it.
    func testACardioLogFillsCardioAndNeverWorkout() throws {
        let store = Store(inMemory: true)
        try session(store, id: "c1", kind: "cardio", cardioSeconds: 1500)
        let slots = try HomeModel.slots(userId: userId, dayKey: dayKey, store: store)
        XCTAssertFalse(slots.workoutDone)
        XCTAssertEqual(slots.cardioMinutes, 25)
    }

    func testAWorkoutFillsWorkoutAndItsCardioBlockCountsAsCardio() throws {
        let store = Store(inMemory: true)
        try session(store, id: "w1", kind: "push", cardioSeconds: nil)
        var slots = try HomeModel.slots(userId: userId, dayKey: dayKey, store: store)
        XCTAssertTrue(slots.workoutDone)
        XCTAssertNil(slots.cardioMinutes) // a push day with no cardio block leaves the slot empty
        try session(store, id: "c2", kind: "cardio", cardioSeconds: 600)
        slots = try HomeModel.slots(userId: userId, dayKey: dayKey, store: store)
        XCTAssertTrue(slots.workoutDone)
        XCTAssertEqual(slots.cardioMinutes, 10) // both vectors, same day, independently
    }

    // Meals count meal posts only — a workout post is not a meal, and the slot is capped by nothing (Flow 4: post freely)
    func testMealsCountMealPostsOnly() throws {
        let store = Store(inMemory: true)
        for id in ["m1", "m2"] {
            store.context.insert(LocalPost(clientId: id, userId: userId, type: "meal", sessionClientId: nil, caption: "eggs", mealTag: "breakfast", shareToCrew: false, dayKey: dayKey, isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: friday))
        }
        store.context.insert(LocalPost(clientId: "w-post", userId: userId, type: "workout", sessionClientId: nil, caption: "", mealTag: nil, shareToCrew: false, dayKey: dayKey, isPlannedDay: true, workoutCompleted: true, earlierToday: false, createdAt: friday))
        try store.save()
        XCTAssertEqual(try HomeModel.slots(userId: userId, dayKey: dayKey, store: store).meals, 2)
    }
}
