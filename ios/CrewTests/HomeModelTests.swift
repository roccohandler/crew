// SPEC: T024 (Verify: ios tests + S07 criteria) — the today-state machine: bridge until the first post (1D), workout / rest /
// paused / allDone, Quick Complete hidden once today counts, Resume banner, crew strip nil for solo, the weekly ring.
// A1 (owner-directed 2026-09-08): today's workout is the rotation's next kind, a completion advances it, a cardio log
// (A2) never does. A3: the what's-next line and the bonus list. Against an in-memory Store, no mocks (C4).
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeModelTests: XCTestCase {
    private let userId = "home-user"
    private let tz = TimeZone(identifier: "America/Los_Angeles")!
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")! // Friday — a training day (Mon/Wed/Fri)
    private var saturday: Date { friday.addingTimeInterval(TimeInterval(TimeUnits.secondsPerDay)) }
    private var sunday: Date { friday.addingTimeInterval(TimeInterval(2 * TimeUnits.secondsPerDay)) }
    private var monday: Date { friday.addingTimeInterval(TimeInterval(3 * TimeUnits.secondsPerDay)) }

    // A1: every generated plan is Push day → Pull day → Leg day in stored order, at any frequency
    private func storeWithPlan() throws -> Store {
        let store = Store(inMemory: true)
        let draft = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", access: "fullGym", seed: .shared)
        try PlanLocal.replace(draft, userId: userId, updatedAt: friday, store: store)
        return store
    }

    private func post(_ store: Store, id: String, dayKey: String) throws {
        store.context.insert(LocalPost(clientId: id, userId: userId, type: "meal", sessionClientId: nil, caption: "eggs", mealTag: "breakfast", shareToCrew: false, dayKey: dayKey, isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: friday))
        try store.save()
    }

    func testBridgeUntilTheFirstPostThenWorkoutState() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertEqual(model.today, .bridge(.workout))
        XCTAssertNil(model.nextUpLine) // a workout-day bridge carries nothing but its CTA (1D)
        XCTAssertNil(model.crewStrip)
        XCTAssertEqual(model.streak, 0)
        try post(store, id: "p1", dayKey: "2026-09-03")
        model.refresh(now: friday)
        // Nothing completed yet, so the rotation starts at the cycle's first workout whatever the weekday (A1)
        XCTAssertEqual(model.today, .workout(name: "Push day", exerciseCount: SpecConstants.beginnerExerciseCount, hasCardio: false))
        XCTAssertNil(model.nextUpLine) // an undone training day says nothing about tomorrow (A3)
        XCTAssertTrue(model.quickCompleteAvailable)
        XCTAssertEqual(model.ringPlanned, 3)
        XCTAssertEqual(model.bonusWorkouts.map(\.kind), ["push", "pull", "legs"])
    }

    func testQuickCompleteCountsTodayHidesItselfAndAdvancesTheRotation() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        try post(store, id: "p0", dayKey: "2026-09-03")
        model.refresh(now: friday)
        let outcome = try XCTUnwrap(model.quickComplete(shareToCrew: false, now: friday))
        XCTAssertEqual(outcome.setsDone, outcome.setsPlanned)
        XCTAssertTrue(outcome.awards.contains(.xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout)))
        XCTAssertEqual(model.today, .allDone)
        XCTAssertFalse(model.quickCompleteAvailable)
        XCTAssertEqual(model.ringDone, 1)
        XCTAssertEqual(model.nextUpLine, "Next workout: Mon · Pull day") // A3: the day after a done day is not tomorrow
        XCTAssertEqual(model.bonusWorkouts.map(\.kind), ["pull", "legs", "push"]) // next up first
        model.refresh(now: monday)
        XCTAssertEqual(model.today, .workout(name: "Pull day", exerciseCount: SpecConstants.beginnerExerciseCount, hasCardio: false))
    }

    func testRestDayLinesPausedAndResume() throws {
        let store = try storeWithPlan()
        try post(store, id: "p2", dayKey: "2026-09-04")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday)
        XCTAssertEqual(model.today, .rest(posted: false))
        XCTAssertEqual(model.nextUpLine, "Next workout: Mon · Push day")
        try post(store, id: "p3", dayKey: "2026-09-06")
        model.refresh(now: sunday)
        XCTAssertEqual(model.today, .rest(posted: true))
        XCTAssertEqual(model.nextUpLine, "Tomorrow: Push day · \(SpecConstants.beginnerExerciseCount) exercises")
        store.context.insert(LocalPause(userId: userId, startDay: "2026-09-05", endDay: "2026-09-12", createdAt: saturday))
        try store.save()
        model.refresh(now: saturday)
        XCTAssertEqual(model.today, .paused(until: "Sat Sep 12")) // A3: a DayLabel, never raw ISO
        XCTAssertNil(model.nextUpLine)
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first)
        _ = try SessionActions.startSession(from: workout, kind: workout.kind, isPlannedDay: false, userId: userId, timeZone: tz, now: saturday, store: store)
        model.refresh(now: saturday)
        XCTAssertNotNil(model.resumeSession)
    }

    // A3 + 1D: a rest-day install gets one line under its CTA; the wording changes when the first workout is tomorrow
    func testRestDayBridgeCarriesTheFirstWorkoutLine() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday)
        XCTAssertEqual(model.today, .bridge(.rest))
        XCTAssertEqual(model.nextUpLine, "Next workout: Mon · Push day")
        model.refresh(now: sunday)
        XCTAssertEqual(model.nextUpLine, "Tomorrow: Push day — your first workout.")
    }

    // A2: a standalone cardio log is outside the cycle — the training day stays planned, the ring slot stays open
    func testCardioLogNeverCompletesTheTrainingDayNorAdvancesTheRotation() throws {
        let store = try storeWithPlan()
        try post(store, id: "p4", dayKey: "2026-09-03")
        let log = LocalSession(clientId: "cardio-1", userId: userId, dayKey: "2026-09-04", status: "completed", workoutName: "Walk", workoutKind: "cardio", isPlannedDay: false, startedAt: friday, timezone: tz.identifier, exercises: [])
        log.completedAt = friday
        store.context.insert(log)
        try store.save()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertEqual(model.today, .workout(name: "Push day", exerciseCount: SpecConstants.beginnerExerciseCount, hasCardio: false))
        XCTAssertTrue(model.quickCompleteAvailable)
        XCTAssertEqual(model.ringDone, 0)
        XCTAssertEqual(model.bonusWorkouts.first?.kind, "push")
    }

    // A3: a bonus on a rest day is unplanned (+25, never expected); on an undone training day it is simply the planned workout
    func testBonusWorkoutIsPlannedOnlyOnAnUndoneTrainingDay() throws {
        let store = try storeWithPlan()
        try post(store, id: "p5", dayKey: "2026-09-04")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday)
        let legs = try XCTUnwrap(model.bonusWorkouts.first { $0.kind == "legs" })
        let restDaySession = try XCTUnwrap(model.startBonus(legs, now: saturday))
        XCTAssertFalse(restDaySession.isPlannedDay)
        XCTAssertEqual(restDaySession.workoutKind, "legs")
        XCTAssertEqual(model.resumeSession?.clientId, restDaySession.clientId)
        let fresh = try storeWithPlan()
        try post(fresh, id: "p6", dayKey: "2026-09-03")
        let trainingDay = HomeModel(store: fresh, userId: userId, timeZone: tz)
        trainingDay.refresh(now: friday)
        let planned = try XCTUnwrap(trainingDay.startWorkout(now: friday))
        XCTAssertTrue(planned.isPlannedDay)
        XCTAssertEqual(planned.workoutKind, "push")
    }
}
