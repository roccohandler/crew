// SPEC: T020 · 8.3 plan generator property test: every days × experience × equipment combo yields a valid plan (limits
// respected, mobility block present) · A1 (owner-directed 2026-09-08): every combination yields exactly the pplCycle's
// kinds once, in order, at every day count — Full-Body A/B is never generated. Twin of web/tests/engine/plan-generator.test.ts.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class PlanGeneratorTests: XCTestCase {
    private let seed = SeedCatalog.shared
    private let experiences = ["brandNew", "some", "experienced"]
    private let accesses = ["fullGym", "dumbbells", "bodyweight"]
    private var countFor: [String: Int] { ["brandNew": SpecConstants.beginnerExerciseCount, "some": SpecConstants.someExperienceExerciseCount, "experienced": SpecConstants.experiencedExerciseCount] }

    private func daySubsets() -> [Set<Int>] {
        (1..<(1 << 7)).map { mask in Set((1...7).filter { mask & (1 << ($0 - 1)) != 0 }) }
    }

    func testEveryCombinationIsAValidPPLPlan() {
        let subsets = daySubsets()
        XCTAssertEqual(subsets.count, 127)
        for experience in experiences {
            for access in accesses {
                for days in subsets {
                    let plan = PlanGenerator.generatePlan(days: days, experience: experience, access: access, seed: seed)
                    XCTAssertEqual(plan.trainingWeekdays, days.sorted())
                    XCTAssertEqual(plan.workouts.map(\.kind), seed.planTemplates.split.pplCycle)
                    XCTAssertEqual(plan.workouts.map(\.kind), ["push", "pull", "legs"])
                    XCTAssertEqual(plan.workouts.map(\.name), ["Push day", "Pull day", "Leg day"])
                    for workout in plan.workouts {
                        let strength = workout.exercises.filter { $0.type == "strength" }
                        let holds = workout.exercises.filter { $0.type == "mobility" }
                        XCTAssertEqual(strength.count, countFor[experience], "\(experience) \(access) \(days)")
                        XCTAssertLessThanOrEqual(workout.exercises.count, SpecConstants.planMaxExercisesPerDay)
                        XCTAssertTrue((SpecConstants.mobilityHoldsMin...SpecConstants.mobilityHoldsMax).contains(holds.count))
                        let seconds = holds.reduce(0) { $0 + ($1.holdSeconds ?? 0) * (($1.perSide ?? false) ? 2 : 1) }
                        XCTAssertTrue((SpecConstants.mobilityMinutesMin * 60...SpecConstants.mobilityMinutesMax * 60).contains(seconds))
                        for row in workout.exercises {
                            XCTAssertLessThanOrEqual(row.name.count, SpecConstants.exerciseNameMaxChars)
                            XCTAssertLessThanOrEqual(row.targetSets, SpecConstants.planMaxSetsPerExercise)
                            XCTAssertTrue(seed.equipmentAccess[access]!.contains(row.equipment))
                        }
                        XCTAssertEqual(workout.exercises.map(\.order), Array(0..<workout.exercises.count))
                        XCTAssertFalse(workout.exercises.contains { $0.type == "cardio" }) // cardio blocks are added by the editor, never generated
                    }
                }
            }
        }
    }

    func testDaysStaySortedAndFullBodyIsNeverGenerated() {
        XCTAssertEqual(PlanGenerator.generatePlan(days: [5, 1, 3], experience: "brandNew", access: "fullGym", seed: seed).trainingWeekdays, [1, 3, 5])
        for days in [[7], [2, 4]] as [Set<Int>] {
            let plan = PlanGenerator.generatePlan(days: days, experience: "some", access: "bodyweight", seed: seed)
            XCTAssertEqual(plan.trainingWeekdays, days.sorted())
            XCTAssertEqual(plan.workouts.map(\.kind), ["push", "pull", "legs"])
        }
    }

    func testTargetsFollowFlowOneAndG7() {
        let brandNew = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", access: "fullGym", seed: seed).workouts[0]
        XCTAssertTrue(brandNew.exercises.filter { $0.type == "strength" }.allSatisfy { $0.targetSets == 3 && $0.targetReps == 10 })
        let some = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "some", access: "dumbbells", seed: seed).workouts[0]
        XCTAssertTrue(some.exercises.filter { $0.type == "strength" }.allSatisfy { $0.targetReps == 8 && $0.targetRepsMax == 10 })
        let experienced = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "experienced", access: "fullGym", seed: seed)
        XCTAssertTrue(experienced.workouts.contains { $0.exercises.contains { $0.equipment == "barbell" } })
    }

    func testACardioRowIsDurationBased() {
        let walk = PlanGenerator.cardioRow("walk", order: 4, seed: seed)
        XCTAssertEqual(walk, PlanDraftExercise(exerciseId: "walk", name: "Walk", pattern: "cardio", equipment: "bodyweight", type: "cardio", targetSets: 1, targetReps: 0, targetRepsMax: nil, holdSeconds: 1200, perSide: nil, order: 4))
        XCTAssertEqual(seed.exercises.filter { $0.type == "cardio" }.map(\.id), ["walk", "run", "bike", "swim", "row", "elliptical", "stairs", "hike", "other-cardio"])
        XCTAssertNil(PlanGenerator.cardioRow("no-such-activity", order: 0, seed: seed))
    }
}
