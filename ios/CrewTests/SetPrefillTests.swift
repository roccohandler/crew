// SPEC: A12 (owner-directed 2026-09-09) — the prefill twin. Twin of web/tests/engine/set-prefill.test.ts: identical cases,
// so a row opens at the same numbers on both engines (8.1). Runs on the open-source toolchain (ios/Package.swift) and Xcode.

import XCTest
@testable import Crew

final class SetPrefillTests: XCTestCase {
    private func work(_ reps: Int, _ weight: Double?, done: Bool = true) -> PrefillSet {
        PrefillSet(actualReps: reps, weight: weight, weightUnit: nil, done: done, isWarmup: false)
    }

    func testNothingToSayWithNoHistory() {
        XCTAssertNil(SetPrefill.facts(from: []))
    }

    func testTakesTheHeaviestDoneWorkSetOfTheMostRecentSession() {
        let facts = SetPrefill.facts(from: [[work(8, 135), work(6, 155), work(5, 145)]])
        XCTAssertEqual(facts, PrefillFacts(reps: 6, weight: 155, weightUnit: nil))
    }

    func testIgnoresWarmUpsHoweverHeavyTheyLook() {
        let warmup = PrefillSet(actualReps: 12, weight: 225, weightUnit: nil, done: true, isWarmup: true)
        let facts = SetPrefill.facts(from: [[warmup, work(8, 135)]])
        XCTAssertEqual(facts, PrefillFacts(reps: 8, weight: 135, weightUnit: nil))
    }

    func testIgnoresRowsThatWereNeverCompleted() {
        let facts = SetPrefill.facts(from: [[work(8, 135), work(1, 315, done: false)]])
        XCTAssertEqual(facts, PrefillFacts(reps: 8, weight: 135, weightUnit: nil))
    }

    func testFallsThroughASessionWhereTheExerciseWasSkippedEntirely() {
        // newest first: the skipped session has no done rows, so the one before it wins
        let facts = SetPrefill.facts(from: [[work(0, nil, done: false)], [work(10, 95)]])
        XCTAssertEqual(facts, PrefillFacts(reps: 10, weight: 95, weightUnit: nil))
    }

    func testCarriesRepsForwardForABodyweightExercise() {
        XCTAssertEqual(SetPrefill.facts(from: [[work(14, nil)]]), PrefillFacts(reps: 14, weight: nil, weightUnit: nil))
    }

    func testCarriesTheUnitTheWeightWasEnteredIn() {
        let logged = PrefillSet(actualReps: 5, weight: 100, weightUnit: "kg", done: true, isWarmup: false)
        XCTAssertEqual(SetPrefill.facts(from: [[logged]]), PrefillFacts(reps: 5, weight: 100, weightUnit: "kg"))
    }

    func testARowOpensAtThePlansTargetsWithNoHistory() {
        XCTAssertEqual(SetPrefill.openingReps(targetReps: 10, facts: nil), 10)
        XCTAssertNil(SetPrefill.openingWeight(targetWeight: nil, facts: nil))
    }

    func testRealityBeatsTheTargetOnceThereIsHistory() {
        let facts = SetPrefill.facts(from: [[work(6, 185)]])
        XCTAssertEqual(SetPrefill.openingReps(targetReps: 10, facts: facts), 6)
        XCTAssertEqual(SetPrefill.openingWeight(targetWeight: nil, facts: facts), 185)
    }

    func testANilWeightStaysNilSoDashRemainsReachable() {
        let facts = SetPrefill.facts(from: [[work(12, nil)]])
        XCTAssertNil(SetPrefill.openingWeight(targetWeight: nil, facts: facts))
    }
}
