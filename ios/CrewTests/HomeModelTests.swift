// SPEC: T024 (Verify: ios tests + S07 criteria) — the today-state machine: bridge until the first post (1D), workout / rest /
// paused / allDone, Quick Complete hidden once today counts, Resume banner, crew strip nil for solo, the weekly ring.
// Against an in-memory Store, no mocks (C4). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeModelTests: XCTestCase {
    private let userId = "home-user"
    private let tz = TimeZone(identifier: "America/Los_Angeles")!
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")! // Friday — a planned day (Mon/Wed/Fri)

    private func storeWithPlan() throws -> Store {
        let store = Store(inMemory: true)
        let draft = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", access: "fullGym", seed: .shared)
        let workouts = draft.workouts.map { workout in
            LocalWorkoutTemplate(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: workout.exercises.map {
                LocalExerciseTemplate(exerciseId: $0.exerciseId, name: $0.name, pattern: $0.pattern, equipment: $0.equipment, type: $0.type, targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax, targetWeight: nil, holdSeconds: $0.holdSeconds, perSide: $0.perSide ?? false, order: $0.order)
            })
        }
        store.context.insert(LocalPlan(userId: userId, updatedAt: friday, workouts: workouts))
        try store.save()
        return store
    }

    func testBridgeUntilTheFirstPostThenWorkoutState() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertEqual(model.today, .bridge(.workout))
        XCTAssertNil(model.crewStrip)
        XCTAssertEqual(model.streak, 0)
        store.context.insert(LocalPost(clientId: "p1", userId: userId, type: "meal", sessionClientId: nil, caption: "eggs", mealTag: "breakfast", shareToCrew: false, dayKey: "2026-09-03", isPlannedDay: true, workoutCompleted: false, earlierToday: false, createdAt: friday))
        try store.save()
        model.refresh(now: friday)
        XCTAssertEqual(model.today, .workout(name: "Push day", exerciseCount: SpecConstants.beginnerExerciseCount, done: false))
        XCTAssertTrue(model.quickCompleteAvailable)
        XCTAssertEqual(model.ringPlanned, 3)
    }

    func testQuickCompleteCountsTodayAndHidesItself() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        store.context.insert(LocalPost(clientId: "p0", userId: userId, type: "text", sessionClientId: nil, caption: "hi", mealTag: nil, shareToCrew: false, dayKey: "2026-09-03", isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: friday))
        try store.save()
        model.refresh(now: friday)
        let outcome = try XCTUnwrap(model.quickComplete(shareToCrew: false, now: friday))
        XCTAssertEqual(outcome.setsDone, outcome.setsPlanned)
        XCTAssertTrue(outcome.awards.contains(.xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout)))
        XCTAssertEqual(model.today, .allDone)
        XCTAssertFalse(model.quickCompleteAvailable)
        XCTAssertEqual(model.ringDone, 1)
    }

    func testRestDayPausedAndResume() throws {
        let store = try storeWithPlan()
        let saturday = friday.addingTimeInterval(TimeInterval(TimeUnits.secondsPerDay))
        store.context.insert(LocalPost(clientId: "p2", userId: userId, type: "meal", sessionClientId: nil, caption: "x", mealTag: nil, shareToCrew: false, dayKey: "2026-09-04", isPlannedDay: true, workoutCompleted: false, earlierToday: false, createdAt: friday))
        try store.save()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday)
        XCTAssertEqual(model.today, .rest(posted: false))
        store.context.insert(LocalPause(userId: userId, startDay: "2026-09-05", endDay: "2026-09-12", createdAt: saturday))
        try store.save()
        model.refresh(now: saturday)
        XCTAssertEqual(model.today, .paused(until: "2026-09-12"))
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first)
        _ = try SessionActions.startSession(from: workout, userId: userId, timeZone: tz, now: saturday, store: store)
        model.refresh(now: saturday)
        XCTAssertNotNil(model.resumeSession)
    }
}
