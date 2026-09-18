// SPEC: A14 (owner-directed 2026-09-09) — the three-vector row facts: a walk fills Cardio and never Workout, a workout
// fills Workout, and an empty day reports nothing rather than a zero (A8). A22: the meal slot left with the plate journal.
// A18.6a / A18.7 / A18.9 — and the other two things Home REPORTS: the week's seven marks (pause-aware, every planned
// day marked, the training-day guard before any session is read) and what today actually held.
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
        XCTAssertEqual(slots, VectorSlots(workoutDone: false, cardioMinutes: nil))
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

    // SPEC: A20.10 (2026-09-11) — CARDIO DONE INSIDE A WORKOUT COUNTS ON THE CARDIO ROW.
    //
    // The test above is named "…AndItsCardioBlockCountsAsCardio" and never tested that: its second session is a
    // SEPARATE `kind: "cardio"` log, so the name promised the rule and the body exercised a different one. Under the
    // shipped `workoutKind == "cardio"` filter this case returned nil — Home's Cardio row read "nothing logged today"
    // for a user who had just done twenty minutes of it, while ProgressModel (which counts cardio sets from every
    // session) reported the minutes on the next tab. One device, one day, two answers.
    //
    // `workoutDone` stays true and is the point of the split: the session is still a workout, so the week strip and the
    // ring are untouched (A2 — only a standalone cardio log fails to fill a planned slot).
    func testACardioBlockInsideAWorkoutFillsTheCardioRow() throws {
        let store = Store(inMemory: true)
        try session(store, id: "w2", kind: "push", cardioSeconds: 1200) // a push day carrying a 20-minute cardio block
        let slots = try HomeModel.slots(userId: userId, dayKey: dayKey, store: store)
        XCTAssertTrue(slots.workoutDone, "a push day is still a workout")
        XCTAssertEqual(slots.cardioMinutes, 20, "A20.10 — the Cardio row said nothing logged while Progress reported the minutes")
    }

    // ---------------------------------------------------------------------------------------------------------
    // A18.7 — the week's marks. These are the twin of web/src/lib/home-facts.ts weekMarks; the two engines disagreed
    // about a bonus workout on a non-training day until A18.7 put the trainingWeekdays guard first on both.
    // ---------------------------------------------------------------------------------------------------------

    private func plan(_ store: Store, days: [Int]) throws -> LocalPlan {
        let workout = LocalWorkoutTemplate(name: "Push day", kind: "push", order: 0, exercises: [])
        let plan = LocalPlan(userId: userId, trainingWeekdays: days, updatedAt: friday, workouts: [workout])
        store.context.insert(plan)
        try store.save()
        return plan
    }

    // The fixture week is Mon 2026-08-31 … Sun 2026-09-06; "today" is Friday 2026-09-04.
    func testEveryPlannedDayIsMarkedAndOnlyTheFirstUpcomingOneIsNextUp() throws {
        let store = Store(inMemory: true)
        let saved = try plan(store, days: [1, 3, 5, 7]) // Mon · Wed · Fri · Sun, with Friday as today
        let marks = try HomeModel.weekMarks(userId: userId, plan: saved, todayKey: dayKey, pause: nil, store: store)
        XCTAssertEqual(marks.days, [.missed, .rest, .missed, .rest, .today, .rest, .nextUp])
        XCTAssertEqual(marks.planned, 4)
        XCTAssertEqual(marks.done, 0)
        // A18.7's point: every day the ring counts carries a mark, so the strip can be read against the fraction
        XCTAssertEqual(marks.days.filter { $0 != .rest }.count, marks.planned)
    }

    // A18.7 — the training-day guard comes BEFORE any session is read. A bonus workout on a non-training day is not a
    // planned-day completion: the ring counts planned days only, so a strip that marked it could not be read against
    // the ring. The web twin emitted "done" here, which is how one user got two different summary sentences.
    func testABonusOnANonTrainingDayIsNotAPlannedCompletion() throws {
        let store = Store(inMemory: true)
        let saved = try plan(store, days: [1]) // Monday only; the session below is on Friday
        try session(store, id: "bonus", kind: "push", cardioSeconds: nil)
        let marks = try HomeModel.weekMarks(userId: userId, plan: saved, todayKey: dayKey, pause: nil, store: store)
        XCTAssertEqual(marks.days[4], .today) // Friday: today, not done
        XCTAssertEqual(marks.done, 0)
        XCTAssertEqual(marks.planned, 1)
    }

    // A18.6a — Flow 7 and spec:460 promise "pauses without penalty", and A17.1 turned these marks into the English
    // sentence "This week: Mon missed" — printed directly above a card saying the streak is frozen.
    func testAPausedWeekReportsNoMissesAndCountsNoPlannedDays() throws {
        let store = Store(inMemory: true)
        let saved = try plan(store, days: [1, 2, 3, 4, 5, 6, 7])
        let pause = LocalPause(userId: userId, startDay: "2026-08-31", endDay: "2026-09-07", createdAt: friday)
        store.context.insert(pause)
        try store.save()
        let marks = try HomeModel.weekMarks(userId: userId, plan: saved, todayKey: dayKey, pause: pause, store: store)
        XCTAssertFalse(marks.days.contains(.missed))
        XCTAssertEqual(marks.planned, 0) // a frozen day leaves the denominator, it does not fail inside it
        XCTAssertEqual(marks.days[4], .today)
    }

    // A18.9 — the all-done card reports the day in the journal's own sentence, so this asserts the SAME line
    // JournalFacts prints rather than a second one built for Home.
    func testTodaySummaryIsTheJournalsOwnLine() throws {
        let store = Store(inMemory: true)
        try session(store, id: "c1", kind: "cardio", cardioSeconds: 1500)
        let lines = try HomeModel.todaySummary(userId: userId, dayKey: dayKey, distanceUnit: "mi", store: store)
        XCTAssertEqual(lines, ["Walk · 25 min"])
    }

    func testTodaySummaryIsEmptyOnADayWithNothingCompleted() throws {
        let store = Store(inMemory: true)
        XCTAssertEqual(try HomeModel.todaySummary(userId: userId, dayKey: dayKey, distanceUnit: "mi", store: store), [])
    }
}
