// SPEC: Flow 1 step 3 (PPL on your days; Full-Body A/B at ≤2 days; equipment tag + sets×reps; mobility block closing each
// workout) · 5.6.1 generatePlan(days, exp, equip, seed) -> PlanDraft · plan-templates.json. Twin of plan-generator.ts.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct PlanDraftExercise: Codable, Equatable {
    let exerciseId: String
    let name: String
    let pattern: String
    let equipment: String
    let type: String            // strength | mobility
    let targetSets: Int
    let targetReps: Int
    let targetRepsMax: Int?
    let holdSeconds: Int?
    let perSide: Bool?
    let order: Int
}

struct PlanDraftWorkout: Codable, Equatable {
    let weekday: Int            // ISO 1 = Monday … 7 = Sunday
    let name: String
    let kind: String
    let exercises: [PlanDraftExercise]
}

struct PlanDraft: Codable, Equatable {
    let workouts: [PlanDraftWorkout]
}

enum PlanGenerator {
    static func strengthRow(_ id: String, experience: String, order: Int, seed: SeedCatalog) -> PlanDraftExercise? {
        guard let exercise = seed.exercise(id), let targets = seed.planTemplates.targets[experience] else { return nil }
        return PlanDraftExercise(exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "strength", targetSets: targets.sets, targetReps: targets.reps, targetRepsMax: targets.repsMax, holdSeconds: nil, perSide: nil, order: order)
    }

    // Mobility holds are duration-based: one "set", no reps, no weight, ever (Flow 3)
    static func mobilityRow(_ id: String, order: Int, seed: SeedCatalog) -> PlanDraftExercise? {
        guard let exercise = seed.exercise(id) else { return nil }
        return PlanDraftExercise(exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "mobility", targetSets: 1, targetReps: 0, targetRepsMax: nil, holdSeconds: exercise.holdSeconds ?? 0, perSide: exercise.perSide ?? false, order: order)
    }

    static func workout(kind: String, weekday: Int, experience: String, access: String, seed: SeedCatalog) -> PlanDraftWorkout {
        let ids = seed.planTemplates.templates[kind]?[experience]?[access] ?? []
        let strength = ids.enumerated().compactMap { strengthRow($1, experience: experience, order: $0, seed: seed) }
        let holds = (seed.planTemplates.mobilityBlocks[kind] ?? []).enumerated().compactMap { mobilityRow($1, order: strength.count + $0, seed: seed) }
        return PlanDraftWorkout(weekday: weekday, name: seed.planTemplates.workoutNames[kind] ?? kind, kind: kind, exercises: strength + holds)
    }

    // SPEC: Flow 1 step 3 — PPL on the chosen days, Full-Body A/B at ≤ fullBodyMaxTrainingDays; the cycle repeats over the
    // user's sorted days within the week (plan-templates.json gapNotes)
    static func generatePlan(days: Set<Int>, experience: String, access: String, seed: SeedCatalog) -> PlanDraft {
        let split = seed.planTemplates.split
        let sortedDays = days.sorted()
        let cycle = sortedDays.count <= split.fullBodyMaxTrainingDays ? split.fullBodyCycle : split.pplCycle
        let workouts = sortedDays.enumerated().map { index, weekday in
            workout(kind: cycle[index % cycle.count], weekday: weekday, experience: experience, access: access, seed: seed)
        }
        return PlanDraft(workouts: workouts)
    }
}
