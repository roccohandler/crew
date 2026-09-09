// SPEC: Flow 1 step 3 (Push · Pull · Legs; equipment tag + sets×reps; mobility block closing each workout) · A1
// (owner-directed 2026-09-08: a plan is trainingWeekdays plus an ORDERED list of workouts — Push day · Pull day · Leg day
// at every frequency 1–7; Full-Body A/B is no longer generated, the seed keeps its templates for legacy plans) · A2
// (cardio is a third row type, duration-based like a hold) · 5.6.1 generatePlan(days, exp, equip, seed) -> PlanDraft ·
// plan-templates.json. Twin of plan-generator.ts. WRITTEN — UNVERIFIED on a Mac; verified on Linux (ios/Package.swift).

import Foundation

struct PlanDraftExercise: Codable, Equatable {
    let exerciseId: String
    let name: String
    let pattern: String
    let equipment: String
    let type: String            // strength | mobility | cardio
    let targetSets: Int
    let targetReps: Int
    let targetRepsMax: Int?
    let holdSeconds: Int?       // mobility holds and cardio blocks: seconds
    let perSide: Bool?
    let order: Int
}

struct PlanDraftWorkout: Codable, Equatable {
    let name: String
    let kind: String            // push | pull | legs | fullBodyA | fullBodyB | custom
    let exercises: [PlanDraftExercise]   // strength rows, then the mobility block (an added cardio block sits between)
}

// SPEC: A1 — trainingWeekdays (ISO 1 = Monday … 7 = Sunday; sorted, unique) + workouts in rotation order, no weekday
struct PlanDraft: Codable, Equatable {
    let trainingWeekdays: [Int]
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

    // SPEC: A2 — a cardio block is duration-based like a hold: one "set", no reps, holdSeconds = the activity's seed default
    static func cardioRow(_ id: String, order: Int, seed: SeedCatalog) -> PlanDraftExercise? {
        guard let exercise = seed.exercise(id) else { return nil }
        return PlanDraftExercise(exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "cardio", targetSets: 1, targetReps: 0, targetRepsMax: nil, holdSeconds: exercise.holdSeconds ?? 0, perSide: nil, order: order)
    }

    static func workout(kind: String, experience: String, access: String, seed: SeedCatalog) -> PlanDraftWorkout {
        let ids = seed.planTemplates.templates[kind]?[experience]?[access] ?? []
        let strength = ids.enumerated().compactMap { strengthRow($1, experience: experience, order: $0, seed: seed) }
        let holds = (seed.planTemplates.mobilityBlocks[kind] ?? []).enumerated().compactMap { mobilityRow($1, order: strength.count + $0, seed: seed) }
        return PlanDraftWorkout(name: seed.planTemplates.workoutNames[kind] ?? kind, kind: kind, exercises: strength + holds)
    }

    // SPEC: A1 — every generated plan is the pplCycle in stored order (three workouts, at every day count); the days are
    // kept sorted and unique. Which workout lands on which day is the rotation's job (PlanRotation), never the plan's.
    static func generatePlan(days: Set<Int>, experience: String, access: String, seed: SeedCatalog) -> PlanDraft {
        let workouts = seed.planTemplates.split.pplCycle.map { workout(kind: $0, experience: experience, access: access, seed: seed) }
        return PlanDraft(trainingWeekdays: days.sorted(), workouts: workouts)
    }
}
