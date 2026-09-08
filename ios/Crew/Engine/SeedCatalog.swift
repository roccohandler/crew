// SPEC: Part IX seed data · 5.2 Generated/SeedData.swift (bundles the three seed JSONs) — decoded once here into the
// plain values the engines take as a parameter (5.6.1 seed: SeedCatalog). WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct SeedExercise: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let pattern: String
    let swapGroup: String
    let equipment: String
    let level: String
    let type: String
    let cueLine: String
    let holdSeconds: Int?
    let perSide: Bool?
}

struct SeedTargets: Codable, Equatable {
    let sets: Int
    let reps: Int
    let repsMax: Int?
}

struct SeedSplit: Codable, Equatable {
    let fullBodyMaxTrainingDays: Int
    let pplCycle: [String]
    let fullBodyCycle: [String]
}

struct SeedPlanTemplates: Codable, Equatable {
    let targets: [String: SeedTargets]
    let split: SeedSplit
    let workoutNames: [String: String]
    let templates: [String: [String: [String: [String]]]]   // kind → experience → access → exercise ids
    let mobilityBlocks: [String: [String]]
}

struct SeedAchievement: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let line: String
    let scope: String
    let trigger: String
    let threshold: Int
}

struct SeedCatalog {
    let exercises: [SeedExercise]
    let planTemplates: SeedPlanTemplates
    let achievements: [SeedAchievement]
    let equipmentAccess: [String: [String]]
    let regionOfPattern: [String: String]

    private struct ExercisesFile: Codable {
        struct Enums: Codable {
            let equipmentAccess: [String: [String]]
            let region: [String: String]
        }
        let enums: Enums
        let exercises: [SeedExercise]
    }

    private struct AchievementsFile: Codable {
        let achievements: [SeedAchievement]
    }

    static let shared: SeedCatalog = {
        do { return try SeedCatalog.decodeBundled() } catch { fatalError("seed data failed to decode: \(error)") }
    }()

    static func decodeBundled() throws -> SeedCatalog {
        let decoder = JSONDecoder()
        let exercisesFile = try decoder.decode(ExercisesFile.self, from: Data(SeedData.exercisesJSON.utf8))
        let templates = try decoder.decode(SeedPlanTemplates.self, from: Data(SeedData.planTemplatesJSON.utf8))
        let achievementsFile = try decoder.decode(AchievementsFile.self, from: Data(SeedData.achievementsJSON.utf8))
        return SeedCatalog(exercises: exercisesFile.exercises, planTemplates: templates, achievements: achievementsFile.achievements, equipmentAccess: exercisesFile.enums.equipmentAccess, regionOfPattern: exercisesFile.enums.region)
    }

    func exercise(_ id: String) -> SeedExercise? {
        exercises.first { $0.id == id }
    }
}
