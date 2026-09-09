// SPEC: A1 (owner-directed 2026-09-08) rotation rules — 4 days → 12 completions → 4/4/4; misses never advance; 1 day →
// Push then Pull three weeks later; 7 days → PPLPPLP / PLPPLPP; a cardio session never advances; legacy names infer; a
// plan without the last kind cycles its own kinds. Twin of web/tests/engine/plan-rotation.test.ts: identical cases.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class PlanRotationTests: XCTestCase {
    private let ppl = ["push", "pull", "legs"]
    private let epoch = Date(timeIntervalSince1970: 0)

    private func completed(_ kind: String?, at order: Int, name: String = "") -> RotationSession {
        RotationSession(kind: kind, name: name, completedAt: epoch.addingTimeInterval(TimeInterval(order)), status: "completed")
    }

    private func completeNext(_ sessions: inout [RotationSession], cycle: [String]) -> String {
        let next = PlanRotation.nextWorkoutKind(lastCompletedKind: PlanRotation.lastRotationKind(sessions: sessions, cycle: cycle), cycle: cycle)
        sessions.append(completed(next, at: sessions.count + 1))
        return next
    }

    func testFourDaysTwelveCompletionsBalanceFourFourFour() {
        var sessions: [RotationSession] = []
        var done: [String] = []
        for _ in 0..<12 { done.append(completeNext(&sessions, cycle: ppl)) }
        XCTAssertEqual(Array(done.prefix(3)), ppl)
        XCTAssertEqual(done.filter { $0 == "push" }.count, 4)
        XCTAssertEqual(done.filter { $0 == "pull" }.count, 4)
        XCTAssertEqual(done.filter { $0 == "legs" }.count, 4)
    }

    func testMissesInProgressAndDiscardedNeverAdvance() {
        let sessions = [
            completed("push", at: 1),
            RotationSession(kind: "pull", name: "Pull day", completedAt: nil, status: "inProgress"),
            RotationSession(kind: "pull", name: "Pull day", completedAt: epoch.addingTimeInterval(2), status: "discarded"),
        ]
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: sessions, cycle: ppl), "push")
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: "push", cycle: ppl), "pull")
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: "legs", cycle: ppl), "push")
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: nil, cycle: ppl), "push")
        XCTAssertNil(PlanRotation.lastRotationKind(sessions: [], cycle: ppl))
    }

    func testTheLatestCompletionWinsRegardlessOfListOrder() {
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: [completed("legs", at: 3), completed("push", at: 1), completed("pull", at: 2)], cycle: ppl), "legs")
    }

    func testACardioSessionNeverAdvances() {
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: [completed("push", at: 1), completed("cardio", at: 2, name: "Walk")], cycle: ppl), "push")
    }

    func testLegacyNamesInferAndAStoredKindIsNeverOverridden() {
        XCTAssertEqual(PlanRotation.workoutKindFromName("Push day"), "push")
        XCTAssertEqual(PlanRotation.workoutKindFromName("Pull day"), "pull")
        XCTAssertEqual(PlanRotation.workoutKindFromName("Leg day"), "legs")
        XCTAssertEqual(PlanRotation.workoutKindFromName("Full body A"), "fullBodyA")
        XCTAssertEqual(PlanRotation.workoutKindFromName("Full body B"), "fullBodyB")
        XCTAssertNil(PlanRotation.workoutKindFromName("Walk"))
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: [completed(nil, at: 1, name: "Leg day")], cycle: ppl), "legs")
        XCTAssertNil(PlanRotation.lastRotationKind(sessions: [completed("custom", at: 1, name: "Push day")], cycle: ppl))
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: [completed(nil, at: 1, name: "Full body B")], cycle: ["fullBodyA", "fullBodyB"]), "fullBodyB")
    }

    func testAPlanWithoutTheLastCompletedKindCyclesItsOwnKinds() {
        let cycle = ["custom", "push"]
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: "legs", cycle: cycle), "custom")
        XCTAssertNil(PlanRotation.lastRotationKind(sessions: [completed("legs", at: 1)], cycle: cycle))
        XCTAssertEqual(PlanRotation.lastRotationKind(sessions: [completed("legs", at: 2), completed("custom", at: 1)], cycle: cycle), "custom")
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: "custom", cycle: cycle), "push")
        XCTAssertEqual(PlanRotation.nextWorkoutKind(lastCompletedKind: "push", cycle: cycle), "custom")
    }

    func testOneDayPushThenPullThreeWeeksLater() {
        let week1 = PlanRotation.projectWeek(weekKey: "2026-09-07", todayKey: "2026-09-07", trainingWeekdays: [1], cycle: ppl, nextKind: "push", completedKindByDay: [:])
        XCTAssertEqual(week1.map(\.state), [.planned, .rest, .rest, .rest, .rest, .rest, .rest])
        XCTAssertEqual(week1[0].kind, "push")
        let after = PlanRotation.nextWorkoutKind(lastCompletedKind: PlanRotation.lastRotationKind(sessions: [completed("push", at: 1)], cycle: ppl), cycle: ppl)
        let week4 = PlanRotation.projectWeek(weekKey: "2026-09-28", todayKey: "2026-09-28", trainingWeekdays: [1], cycle: ppl, nextKind: after, completedKindByDay: [:])
        XCTAssertEqual(week4[0].kind, "pull")
        let week2 = PlanRotation.projectWeek(weekKey: "2026-09-14", todayKey: "2026-09-28", trainingWeekdays: [1], cycle: ppl, nextKind: after, completedKindByDay: [:])
        XCTAssertEqual(week2[0].state, .open) // a missed Monday: no word, no kind, no red
        XCTAssertNil(week2[0].kind)
    }

    func testSevenDaysProjectPPLPPLPThenPLPPLPP() {
        let all = Array(1...TimeUnits.daysPerWeek)
        let week1 = PlanRotation.projectWeek(weekKey: "2026-09-07", todayKey: "2026-09-07", trainingWeekdays: all, cycle: ppl, nextKind: "push", completedKindByDay: [:])
        XCTAssertEqual(week1.map { $0.kind ?? "" }, ["push", "pull", "legs", "push", "pull", "legs", "push"])
        var sessions: [RotationSession] = []
        for _ in 0..<TimeUnits.daysPerWeek { _ = completeNext(&sessions, cycle: ppl) }
        let next = PlanRotation.nextWorkoutKind(lastCompletedKind: PlanRotation.lastRotationKind(sessions: sessions, cycle: ppl), cycle: ppl)
        let week2 = PlanRotation.projectWeek(weekKey: "2026-09-14", todayKey: "2026-09-14", trainingWeekdays: all, cycle: ppl, nextKind: next, completedKindByDay: [:])
        XCTAssertEqual(week2.map { $0.kind ?? "" }, ["pull", "legs", "push", "pull", "legs", "push", "pull"])
    }

    func testProjectWeekStatesAndNextTrainingDay() {
        let week = PlanRotation.projectWeek(weekKey: "2026-09-09", todayKey: "2026-09-09", trainingWeekdays: [1, 3, 5], cycle: ppl, nextKind: "pull", completedKindByDay: ["2026-09-07": "push"])
        XCTAssertEqual(week.map(\.dayKey), ["2026-09-07", "2026-09-08", "2026-09-09", "2026-09-10", "2026-09-11", "2026-09-12", "2026-09-13"])
        XCTAssertEqual(week.map(\.weekday), Array(1...TimeUnits.daysPerWeek))
        XCTAssertEqual(week.map(\.state), [.done, .rest, .planned, .rest, .planned, .rest, .rest])
        XCTAssertEqual(week.map(\.kind), ["push", nil, "pull", nil, "legs", nil, nil])
        let missed = PlanRotation.projectWeek(weekKey: "2026-09-07", todayKey: "2026-09-10", trainingWeekdays: [1, 3, 5], cycle: ppl, nextKind: "push", completedKindByDay: [:])
        XCTAssertEqual(missed.map(\.state), [.open, .rest, .open, .rest, .planned, .rest, .rest])
        XCTAssertEqual(missed[4].kind, "push")
        XCTAssertEqual(PlanRotation.nextTrainingDayKey(afterDayKey: "2026-09-09", trainingWeekdays: [1, 3, 5]), "2026-09-11")
        XCTAssertEqual(PlanRotation.nextTrainingDayKey(afterDayKey: "2026-09-11", trainingWeekdays: [1, 3, 5]), "2026-09-14")
        XCTAssertEqual(PlanRotation.nextTrainingDayKey(afterDayKey: "2026-09-11", trainingWeekdays: [5]), "2026-09-18")
        XCTAssertNil(PlanRotation.nextTrainingDayKey(afterDayKey: "2026-09-11", trainingWeekdays: []))
    }
}
