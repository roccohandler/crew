// SPEC: T020 · 8.3 plan generator property test: every days × experience combo yields a valid plan (limits respected,
// mobility block present) · A21.1 (owner-approved 2026-09-17): the equipment axis is gone — every user trains in a full gym,
// so a row's equipment is any of the five tags · A1 (owner-directed 2026-09-08): every combination yields exactly the
// pplCycle's kinds once, in order, at every day count — Full-Body A/B is never generated · A26 (owner-approved 2026-09-18,
// canonical templates): the rows are the owner's own Push, Pull and Legs at EVERY experience; experience changes the sets only.
// Twin of web/tests/engine/plan-generator.test.ts. Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class PlanGeneratorTests: XCTestCase {
    private let seed = SeedCatalog.shared
    private let experiences = ["brandNew", "some", "experienced"]
    private let equipmentTags: Set<String> = ["barbell", "dumbbell", "machine", "cable", "bodyweight"]
    private var countFor: [String: Int] { ["push": SpecConstants.templatePushExerciseCount, "pull": SpecConstants.templatePullExerciseCount, "legs": SpecConstants.templateLegsExerciseCount] }
    private var setsFor: [String: Int] { ["brandNew": SpecConstants.beginnerTargetSets, "some": SpecConstants.someExperienceTargetSets, "experienced": SpecConstants.experiencedTargetSets] }

    private func daySubsets() -> [Set<Int>] {
        (1..<(1 << 7)).map { mask in Set((1...7).filter { mask & (1 << ($0 - 1)) != 0 }) }
    }

    func testEveryCombinationIsAValidPPLPlan() {
        let subsets = daySubsets()
        XCTAssertEqual(subsets.count, 127)
        for experience in experiences {
            for days in subsets {
                let plan = PlanGenerator.generatePlan(days: days, experience: experience, seed: seed)
                XCTAssertEqual(plan.trainingWeekdays, days.sorted())
                XCTAssertEqual(plan.workouts.map(\.kind), seed.planTemplates.split.pplCycle)
                XCTAssertEqual(plan.workouts.map(\.kind), ["push", "pull", "legs"])
                XCTAssertEqual(plan.workouts.map(\.name), ["Push day", "Pull day", "Leg day"])
                for workout in plan.workouts {
                    let strength = workout.exercises.filter { $0.type == "strength" }
                    let holds = workout.exercises.filter { $0.type == "mobility" }
                    XCTAssertEqual(strength.count, countFor[workout.kind], "\(experience) \(days)")
                    for row in strength { // A26: sets by experience × 8, no range
                        XCTAssertEqual(row.targetSets, setsFor[experience])
                        XCTAssertEqual(row.targetReps, SpecConstants.templateTargetReps)
                        XCTAssertNil(row.targetRepsMax)
                    }
                    XCTAssertLessThanOrEqual(workout.exercises.count, SpecConstants.planMaxExercisesPerDay)
                    XCTAssertTrue((SpecConstants.mobilityHoldsMin...SpecConstants.mobilityHoldsMax).contains(holds.count))
                    let seconds = holds.reduce(0) { $0 + ($1.holdSeconds ?? 0) * (($1.perSide ?? false) ? 2 : 1) }
                    XCTAssertTrue((SpecConstants.mobilityMinutesMin * 60...SpecConstants.mobilityMinutesMax * 60).contains(seconds))
                    for row in workout.exercises {
                        XCTAssertLessThanOrEqual(row.name.count, SpecConstants.exerciseNameMaxChars)
                        XCTAssertLessThanOrEqual(row.targetSets, SpecConstants.planMaxSetsPerExercise)
                        XCTAssertTrue(equipmentTags.contains(row.equipment)) // A21.1: the tag stays; the tier is gone
                    }
                    XCTAssertEqual(workout.exercises.map(\.order), Array(0..<workout.exercises.count))
                    XCTAssertFalse(workout.exercises.contains { $0.type == "cardio" }) // cardio blocks are added by the editor, never generated
                }
            }
        }
    }

    func testDaysStaySortedAndFullBodyIsNeverGenerated() {
        XCTAssertEqual(PlanGenerator.generatePlan(days: [5, 1, 3], experience: "brandNew", seed: seed).trainingWeekdays, [1, 3, 5])
        for days in [[7], [2, 4]] as [Set<Int>] {
            let plan = PlanGenerator.generatePlan(days: days, experience: "some", seed: seed)
            XCTAssertEqual(plan.trainingWeekdays, days.sorted())
            XCTAssertEqual(plan.workouts.map(\.kind), ["push", "pull", "legs"])
        }
    }

    func testTheRowsAreTheOwnersCanonicalTemplatesAtEveryExperience() {
        let canonical = [
            ["barbell-bench-press", "cable-rope-triceps-extension", "machine-incline-press", "cable-triceps-pushdown", "machine-decline-press"],
            ["lat-pulldown", "cable-rope-curl", "machine-row", "cable-rope-curl", "cable-face-pull", "cable-rope-curl"],
            ["machine-standing-calf-raise", "leg-press", "leg-extension", "seated-leg-curl", "dumbbell-walking-lunge"],
        ]
        var firstRows: [String] = []
        for experience in experiences {
            let plan = PlanGenerator.generatePlan(days: [1, 3, 5], experience: experience, seed: seed)
            let strengthIds = plan.workouts.map { workout in workout.exercises.filter { $0.type == "strength" }.map(\.exerciseId) }
            XCTAssertEqual(strengthIds, canonical, experience)
            let first = plan.workouts[0].exercises[0]
            XCTAssertEqual(first.name, "Barbell Bench Press")
            firstRows.append("\(first.targetSets)×\(first.targetReps)")
        }
        XCTAssertEqual(firstRows, ["3×8", "4×8", "5×8"])
    }

    // A26: Pull carries the rope curl three times — one row per slot, each with its own order; no row opens on a barbell
    func testARepeatedExerciseKeepsOneRowPerSlot() {
        let pull = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "some", seed: seed).workouts[1]
        XCTAssertEqual(pull.exercises.filter { $0.exerciseId == "cable-rope-curl" }.map(\.order), [1, 3, 5])
        XCTAssertFalse(pull.exercises.contains { $0.equipment == "barbell" })
    }

    func testACardioRowIsDurationBased() {
        let walk = PlanGenerator.cardioRow("walk", order: 4, seed: seed)
        XCTAssertEqual(walk, PlanDraftExercise(exerciseId: "walk", name: "Walk", pattern: "cardio", equipment: "bodyweight", type: "cardio", targetSets: 1, targetReps: 0, targetRepsMax: nil, holdSeconds: 1200, perSide: nil, order: 4))
        XCTAssertEqual(seed.exercises.filter { $0.type == "cardio" }.map(\.id), ["walk", "run", "bike", "swim", "row", "elliptical", "stairs", "hike", "other-cardio"])
        XCTAssertNil(PlanGenerator.cardioRow("no-such-activity", order: 0, seed: seed))
    }
}
