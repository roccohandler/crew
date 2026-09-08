// SPEC: T020 · 8.3 plan generator property test: every days × experience × equipment combo yields a valid plan (limits
// respected, mobility block present, Full-Body at ≤2 days). Twin of web/tests/engine/plan-generator.test.ts.
// WRITTEN — UNVERIFIED (needs Mac).

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

    func testEveryCombinationIsAValidPlan() {
        let subsets = daySubsets()
        XCTAssertEqual(subsets.count, 127)
        for experience in experiences {
            for access in accesses {
                for days in subsets {
                    let plan = PlanGenerator.generatePlan(days: days, experience: experience, access: access, seed: seed)
                    XCTAssertEqual(plan.workouts.map(\.weekday), days.sorted())
                    let fullBody = days.count <= SpecConstants.fullBodyMaxTrainingDays
                    for workout in plan.workouts {
                        XCTAssertTrue((fullBody ? ["fullBodyA", "fullBodyB"] : ["push", "pull", "legs"]).contains(workout.kind))
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
                    }
                }
            }
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
}
