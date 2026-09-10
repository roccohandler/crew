// SPEC: A14 (owner-directed 2026-09-09) — the Home card's rows and the three-vector row. Twin of
// web/tests/engine/home-lines.test.ts: the same cases, the same expected strings, so the two platforms cannot drift.
// WRITTEN — UNVERIFIED (needs Mac) for the Store half; HomeLines itself is pure and runs on Linux.

import XCTest
@testable import Crew

final class HomeLinesTests: XCTestCase {
    private func exercise(_ name: String, type: String = "strength", sets: Int = 3, reps: Int = 8, repsMax: Int? = nil, seconds: Int? = nil, order: Int = 0) -> HomeExercise {
        HomeExercise(name: name, type: type, targetSets: sets, targetReps: reps, targetRepsMax: repsMax, holdSeconds: seconds, order: order)
    }

    func testSetsByRepsReadsAsAFixedCountOrARange() {
        XCTAssertEqual(HomeLines.setsByReps(targetSets: 3, targetReps: 8, targetRepsMax: nil), "3×8")
        XCTAssertEqual(HomeLines.setsByReps(targetSets: 3, targetReps: 8, targetRepsMax: 10), "3×8–10")
        XCTAssertEqual(HomeLines.setsByReps(targetSets: 1, targetReps: 15, targetRepsMax: nil), "1×15")
    }

    // A range whose ends are equal is not a range — it would read "3×8–8", which is noise
    func testARangeWithEqualEndsCollapses() {
        XCTAssertEqual(HomeLines.setsByReps(targetSets: 4, targetReps: 12, targetRepsMax: 12), "4×12")
    }

    func testStrengthLinesKeepPlanOrderAndDropEverythingElse() {
        let rows = [
            exercise("Cable Fly", order: 2),
            exercise("Pigeon", type: "mobility", order: 5),
            exercise("Bench Press", order: 0),
            exercise("Walk", type: "cardio", seconds: 1200, order: 6),
            exercise("Incline DB Press", reps: 8, repsMax: 10, order: 1),
        ]
        XCTAssertEqual(HomeLines.strengthLines(rows), [
            HomeLine(name: "Bench Press", detail: "3×8"),
            HomeLine(name: "Incline DB Press", detail: "3×8–10"),
            HomeLine(name: "Cable Fly", detail: "3×8"),
        ])
    }

    // A8 — a pure-lifting day says nothing rather than saying "0 holds"
    func testTailLineIsAbsentWhenThereIsNothingToTail() {
        XCTAssertNil(HomeLines.tailLine([exercise("Bench Press")]))
        XCTAssertNil(HomeLines.tailLine([]))
    }

    func testTailLineNamesMobilityThenCardio() {
        let holds = [exercise("Pigeon", type: "mobility", seconds: 30), exercise("Couch", type: "mobility", seconds: 30)]
        XCTAssertEqual(HomeLines.tailLine(holds), "+ mobility · 2 holds")
        XCTAssertEqual(HomeLines.tailLine([exercise("Pigeon", type: "mobility", seconds: 30)]), "+ mobility · 1 hold")
        XCTAssertEqual(HomeLines.tailLine(holds + [exercise("Walk", type: "cardio", seconds: 1200)]), "+ mobility · 2 holds · cardio · 20 min")
    }

    // A2 — cardio seconds round exactly the way the server and JournalFacts round (90 s → 2 min, not 1)
    func testCardioMinutesRoundHalfUpLikeEverythingElse() {
        XCTAssertEqual(HomeLines.tailLine([exercise("Row", type: "cardio", seconds: 90)]), "+ cardio · 2 min")
        XCTAssertEqual(HomeLines.tailLine([exercise("Row", type: "cardio", seconds: 89)]), "+ cardio · 1 min")
    }

    // A14 — a mobility block with no seconds still counts as a hold: the tail names WHAT is there, not how long
    func testAHoldWithoutSecondsStillCounts() {
        XCTAssertEqual(HomeLines.tailLine([exercise("Pigeon", type: "mobility", seconds: nil)]), "+ mobility · 1 hold")
    }
}
