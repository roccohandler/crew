// SPEC: T025 (Verify: ios tests + S09 criteria) as amended by A28 (c), (d) — one set per screen at pre-fill, warm-ups excluded from
// x/y, holds as checks (no countdown), out-of-order, skips, completion numbers match the engine (S10), plate math. A2 (owner-directed
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
        // Mon · Wed · Fri, never a ONE-day plan: complete() stamps the REAL today, and under A22 G1 (a) a one-day plan whose one workout is
        // done IS a perfect week (+150 and a shield) — so with `days: [5]` these tests read 275 instead of 125 on every Friday after 3 AM
        // Pacific and passed on the other six days (master run 35336154762, Friday 2026-09-18; the CelebrationPostTests lesson, a34e4a1)
        let plan = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", seed: .shared)
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
        XCTAssertEqual(model.facts.setsPlanned, SpecConstants.templatePushExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax)
        model.addWarmup(to: first)
        XCTAssertEqual(model.facts.setsPlanned, SpecConstants.templatePushExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax) // warm-ups never count
        let firstWork = model.sets(of: first).first { !$0.isWarmup }!
        XCTAssertTrue(model.displayedSet(of: first)?.isWarmup ?? false) // A28 (d): the warm-up opens the exercise, one set per screen
        model.logSet(firstWork, in: first)
        XCTAssertTrue(firstWork.done)
        XCTAssertTrue(firstWork.asPlanned)
        model.selectedSetOrder = firstWork.order // the ledger row, picked to correct it
        XCTAssertTrue(model.displayedSet(of: first) === firstWork)
        model.adjustReps(firstWork, by: -3)
        XCTAssertEqual(firstWork.actualReps, SpecConstants.templateTargetReps - 3)
        XCTAssertFalse(firstWork.asPlanned) // V33: done, below target — a correction re-judges the set
        XCTAssertTrue(model.canComplete)
        model.complete()
        let outcome = try XCTUnwrap(model.celebration)
        XCTAssertEqual(outcome.setsDone, 1)
        XCTAssertTrue(outcome.awards.contains(.xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout)))
        XCTAssertTrue(outcome.awards.contains(.streakTo(1)))
        try SessionActions.post(outcome, shareToCrew: false, store: store) // A21.9: the tap posts and counts the day
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout)
    }

    func testCompletionNeedsAtLeastOneWorkSetAndSkipsAreNeutral() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "kg")
        model.complete()
        XCTAssertNil(model.celebration)
        XCTAssertNotNil(model.completeError)
        model.skip(model.exercises[0])
        XCTAssertTrue(model.exercises[0].skipped)
        XCTAssertEqual(model.focusIndex, 1) // out-of-order: focus moves on
        let hold = model.exercises.first { $0.type == "mobility" }!
        model.toggleHold(hold) // A28 (c): a hold is a check, never a countdown
        XCTAssertTrue(model.sets(of: hold)[0].done)
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
        model.complete()
        let outcome = try XCTUnwrap(model.celebration)
        XCTAssertEqual(outcome.setsDone, 1)
        try SessionActions.post(outcome, shareToCrew: false, store: store) // A21.9: the tap posts and counts the day
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout) // never extra XP for cardio
        let planned = SpecConstants.templatePushExerciseCount * SpecConstants.beginnerTargetSets + SpecConstants.mobilityHoldsMax + 1
        XCTAssertEqual(JournalFacts.summaryLine(session, distanceUnit: "km"), "\(session.workoutName) · 1 of \(planned) sets") // A6 · A28 (c): no minutes
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

    // SPEC: A26 · E7 — "Update my plan" changes ONE plan row: Pull repeats the rope curl, so the session row's order picks which;
    // a plan edited since (no curl left at that order) falls back to the first curl; an exercise the plan lacks changes nothing
    func testUpdateMyPlanNamesOneRowOfARepeatedExercise() {
        let pull = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", seed: .shared).workouts[1].exercises
        XCTAssertEqual(SessionSwap.planRowToSwap(pull, exerciseId: "cable-rope-curl", order: 3), 3)
        XCTAssertEqual(SessionSwap.planRowToSwap(pull, exerciseId: "cable-rope-curl", order: 2), 1)
        XCTAssertNil(SessionSwap.planRowToSwap(pull, exerciseId: "barbell-row", order: 2))
    }

    func testPlateMath() { // A22: the meal-tag half left with the plate journal (MealTag is gone)
        XCTAssertEqual(PlateMath.plateLine(totalWeight: 190, units: "lb"), "45 + 25 + 2.5 per side")
        XCTAssertEqual(PlateMath.plateLine(totalWeight: 45, units: "lb"), "just the bar")
    }

    // SPEC: A28 (d) — one set per screen: Log set walks the exercise's sets in order, the last one hands the screen to the next
    // exercise, and after the strength work the holds' checklist takes it; "Mark all done" ticks every hold and leaves nothing open
    func testLogSetWalksTheWorkoutOneSetAtATime() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "lb")
        let first = try XCTUnwrap(model.focused)
        XCTAssertEqual(model.countLine, "0 of \(model.facts.setsPlanned) sets")
        for number in 1...model.workSets(of: first).count {
            let set = try XCTUnwrap(model.displayedSet(of: first))
            XCTAssertEqual(model.setNumber(set, in: first), number)
            model.logSet(set, in: first)
        }
        XCTAssertEqual(model.focusIndex, 1) // the exercise is done: the next one takes the screen
        for exercise in model.exercises where exercise.type == "strength" { for set in model.sets(of: exercise) where !set.done { model.logSet(set, in: exercise) } }
        XCTAssertTrue(model.isOnChecklist) // A28 (f): the holds are the last screen
        XCTAssertFalse(model.nothingOpen)
        model.markAllHolds()
        XCTAssertTrue(model.nothingOpen)
        XCTAssertEqual(model.facts.setsDone, model.facts.setsPlanned)
    }

    // SPEC: A28 (f) — the value button's keypad: a typed weight is clamped and snapped to a loadable step; a typed count is clamped
    func testTypedNumbersAreClampedAndSnapped() throws {
        let (store, session) = try sessionInStore()
        let model = SessionModel(session: session, store: store, units: "lb")
        let set = try XCTUnwrap(model.displayedSet(of: try XCTUnwrap(model.focused)))
        model.setWeight(set, to: 152)
        XCTAssertEqual(set.weight, 150)
        XCTAssertEqual(set.weightUnit, "lb")
        model.setWeight(set, to: Double(SpecConstants.setWeightMax + 1))
        XCTAssertEqual(set.weight, Double(SpecConstants.setWeightMax))
        model.setReps(set, to: -4)
        XCTAssertEqual(set.actualReps, 0)
        model.setReps(set, to: SpecConstants.planTargetRepsMax + 1)
        XCTAssertEqual(set.actualReps, SpecConstants.planTargetRepsMax)
    }
}
