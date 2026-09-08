// SPEC: T025 (Verify: ios tests + S09 criteria) — one-tap set logging at pre-fill, ghost row, warm-ups excluded from x/y, holds
// auto-check, out-of-order, skips, completion numbers match the engine (S10), plate math, meal tags. In-memory Store (C4).
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class SessionModelTests: XCTestCase {
    private let userId = "session-user"
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!

    private func sessionInStore() throws -> (Store, LocalSession) {
        let store = Store(inMemory: true)
        let draft = PlanGenerator.generatePlan(days: [5], experience: "brandNew", access: "fullGym", seed: .shared).workouts[0]
        let template = LocalWorkoutTemplate(weekday: draft.weekday, name: draft.name, kind: draft.kind, exercises: draft.exercises.map {
            LocalExerciseTemplate(exerciseId: $0.exerciseId, name: $0.name, pattern: $0.pattern, equipment: $0.equipment, type: $0.type, targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax, targetWeight: nil, holdSeconds: $0.holdSeconds, perSide: $0.perSide ?? false, order: $0.order)
        })
        store.context.insert(LocalPlan(userId: userId, updatedAt: friday, workouts: [template]))
        try store.save()
        let session = try SessionActions.startSession(from: template, userId: userId, timeZone: TimeZone(identifier: "America/Los_Angeles")!, now: friday, store: store)
        return (store, session)
    }

    func testCheckSetPreFillsWarmupsExcludedAndCompletionMatchesTheEngine() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "lb")
        let first = model.exercises[0]
        XCTAssertEqual(model.facts.setsPlanned, SpecConstants.beginnerExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax)
        model.addWarmup(to: first)
        XCTAssertEqual(model.facts.setsPlanned, SpecConstants.beginnerExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax) // warm-ups never count
        let firstWork = model.sets(of: first).first { !$0.isWarmup }!
        model.checkSet(firstWork, in: first)
        XCTAssertTrue(firstWork.done)
        XCTAssertTrue(firstWork.asPlanned)
        XCTAssertTrue(model.restTimer.isRunning)
        model.adjustReps(firstWork, by: -3)
        XCTAssertEqual(firstWork.actualReps, SpecConstants.beginnerTargetReps - 3)
        model.checkSet(firstWork, in: first)
        model.checkSet(firstWork, in: first)
        XCTAssertFalse(firstWork.asPlanned) // V33: done, below target
        XCTAssertTrue(model.canComplete)
        model.complete(shareToCrew: false)
        let outcome = try XCTUnwrap(model.celebration)
        XCTAssertEqual(outcome.setsDone, 1)
        XCTAssertTrue(outcome.awards.contains(.xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout)))
        XCTAssertTrue(outcome.awards.contains(.streakTo(1)))
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout)
    }

    func testCompletionNeedsAtLeastOneWorkSetAndSkipsAreNeutral() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "kg")
        model.complete(shareToCrew: false)
        XCTAssertNil(model.celebration)
        XCTAssertNotNil(model.completeError)
        model.skip(model.exercises[0])
        XCTAssertTrue(model.exercises[0].skipped)
        XCTAssertEqual(model.focusIndex, 1) // out-of-order: focus moves on
        let hold = model.exercises.first { $0.type == "mobility" }!
        model.finishHold(model.sets(of: hold)[0])
        XCTAssertTrue(model.canComplete) // a hold counts as a set (Flow 2 "18/18")
        model.adjustWeight(model.sets(of: model.exercises[1])[0], by: 1)
        XCTAssertEqual(model.sets(of: model.exercises[1])[0].weight, SpecConstants.weightStepKg)
    }

    func testPlateMathAndMealTags() {
        XCTAssertEqual(PlateMath.plateLine(totalWeight: 190, units: "lb"), "45 + 25 + 2.5 per side")
        XCTAssertEqual(PlateMath.plateLine(totalWeight: 45, units: "lb"), "just the bar")
        XCTAssertEqual(MealTag.tagFor(minuteOfDay: 7 * 60), .breakfast)
        XCTAssertEqual(MealTag.tagFor(minuteOfDay: 12 * 60 + 30), .lunch)
        XCTAssertEqual(MealTag.tagFor(minuteOfDay: 19 * 60), .dinner)
        XCTAssertEqual(MealTag.tagFor(minuteOfDay: 2 * 60), .snack)
    }
}
