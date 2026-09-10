// SPEC: T025 (Verify: ios tests + S09 criteria) — one-tap set logging at pre-fill, ghost row, warm-ups excluded from x/y, holds
// auto-check, out-of-order, skips, completion numbers match the engine (S10), plate math, meal tags. A2 (owner-directed
// 2026-09-08): a cardio block's Done stores minutes as seconds plus an optional bounded distance, and the celebration line reads
// "+ Walk 25 min"; A6: the journal line for the session. A1: the fixture is a rotation plan (trainingWeekdays + ordered
// workouts, no weekday). In-memory Store (C4). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class SessionModelTests: XCTestCase {
    private let userId = "session-user"
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!
    private let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private func template(_ draft: PlanDraftWorkout, extra: [PlanDraftExercise] = []) -> LocalWorkoutTemplate {
        LocalWorkoutTemplate(name: draft.name, kind: draft.kind, order: 0, exercises: (draft.exercises + extra).map {
            LocalExerciseTemplate(exerciseId: $0.exerciseId, name: $0.name, pattern: $0.pattern, equipment: $0.equipment, type: $0.type, targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax, targetWeight: nil, holdSeconds: $0.holdSeconds, perSide: $0.perSide ?? false, order: $0.order)
        })
    }

    private func sessionInStore(withCardio: Bool = false) throws -> (Store, LocalSession) {
        let store = Store(inMemory: true)
        let plan = PlanGenerator.generatePlan(days: [5], experience: "brandNew", access: "fullGym", seed: .shared)
        let draft = plan.workouts[0]
        var extra: [PlanDraftExercise] = []
        if withCardio { extra.append(try XCTUnwrap(PlanGenerator.cardioRow("walk", order: draft.exercises.count, seed: .shared))) }
        let workout = template(draft, extra: extra)
        store.context.insert(LocalPlan(userId: userId, trainingWeekdays: plan.trainingWeekdays, updatedAt: friday, workouts: [workout]))
        try store.save()
        let session = try SessionActions.startSession(from: workout, kind: draft.kind, isPlannedDay: true, userId: userId, timeZone: pacific, now: friday, store: store)
        return (store, session)
    }

    func testCheckSetPreFillsWarmupsExcludedAndCompletionMatchesTheEngine() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "lb")
        let first = model.exercises[0]
        XCTAssertEqual(session.workoutKind, "push") // A1: the snapshot remembers its rotation kind
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

    // SPEC: A2 — Done on a cardio block: holdSeconds = minutes × 60, distance capped, the set done and as planned, part of the +100
    func testCardioBlockDoneStoresMinutesAndDistanceAndReadsInTheSummary() throws {
        let (store, session) = try sessionInStore(withCardio: true)
        let model = SessionModel(session: session, store: store, units: "kg")
        let block = try XCTUnwrap(model.exercises.first { $0.type == "cardio" })
        XCTAssertEqual(block.holdSeconds, SeedCatalog.shared.exercise("walk")?.holdSeconds) // the target comes from the seed
        let set = model.sets(of: block)[0]
        model.finishCardio(set, minutes: 25, distanceMeters: 2250)
        XCTAssertTrue(set.done)
        XCTAssertTrue(set.asPlanned)
        XCTAssertEqual(set.holdSeconds, 25 * TimeUnits.secondsPerMinute)
        XCTAssertEqual(set.distanceMeters, 2250)
        XCTAssertEqual(JournalFacts.cardioMinutes(session), 25)
        XCTAssertEqual(JournalFacts.cardioSuffix(session), " + Walk 25 min") // S10: appended to "x/y sets · n min"
        XCTAssertTrue(model.canComplete) // V51: a done cardio set is a work set
        model.complete(shareToCrew: false)
        let outcome = try XCTUnwrap(model.celebration)
        XCTAssertEqual(outcome.setsDone, 1)
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout) // never extra XP for cardio
        let planned = SpecConstants.beginnerExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax + 1
        XCTAssertEqual(JournalFacts.summaryLine(session, distanceUnit: "km"), "\(session.workoutName) · 1/\(planned) sets · \(JournalFacts.wallClockMinutes(session)) min") // A6
    }

    // SPEC: A2 — the bounds hold: minutes clamp to cardioMinutesMin…Max, a distance never exceeds cardioDistanceMaxMeters
    func testCardioBoundsAreImpossibleToBreak() throws {
        let (store, session) = try sessionInStore(withCardio: true)
        let model = SessionModel(session: session, store: store, units: "lb")
        let block = try XCTUnwrap(model.exercises.first { $0.type == "cardio" })
        let set = model.sets(of: block)[0]
        model.finishCardio(set, minutes: SpecConstants.cardioMinutesMax + 1, distanceMeters: SpecConstants.cardioDistanceMaxMeters + 1)
        XCTAssertEqual(set.holdSeconds, SpecConstants.cardioMinutesMax * TimeUnits.secondsPerMinute)
        XCTAssertEqual(set.distanceMeters, SpecConstants.cardioDistanceMaxMeters)
        model.finishCardio(set, minutes: 0, distanceMeters: nil)
        XCTAssertEqual(set.holdSeconds, SpecConstants.cardioMinutesMin * TimeUnits.secondsPerMinute)
        XCTAssertNil(set.distanceMeters)
    }

    // SPEC: A6 — the server rounds wall-clock minutes; the local line must print the same digit
    func testMinutesRoundLikeTheServer() {
        XCTAssertEqual(JournalFacts.minutes(ofSeconds: 44 * TimeUnits.secondsPerMinute + 29), 44)
        XCTAssertEqual(JournalFacts.minutes(ofSeconds: 44 * TimeUnits.secondsPerMinute + 30), 45)
        XCTAssertEqual(JournalFacts.minutes(ofSeconds: 0), 0)
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
