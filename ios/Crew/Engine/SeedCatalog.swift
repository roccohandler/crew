// SPEC: Part IX seed data · 5.2 Generated/SeedData.swift (bundles the three seed JSONs) — decoded once here into the
// plain values the engines take as a parameter (5.6.1 seed: SeedCatalog). A21.1 (owner-approved 2026-09-17): every user
// has full commercial gym access, so there is no equipment-access map and the per-exercise equipment TAG is the only
// equipment fact. A26 (owner-approved 2026-09-18): the templates are the owner's three lists (kind → exercise ids), the
// swaps the owner named ride along for the tests, and every equipment tag has ONE SF Symbol — the single mapping every
// chip reads. WRITTEN — UNVERIFIED (needs Mac).

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
    let templates: [String: [String]]             // A26: kind → exercise ids — the same rows at every experience; a row may repeat
    let namedSwaps: [String: [String]]            // A26: a template row's exercise id → the swaps the owner named (always offered)
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

// SPEC: nutrition addendum §5 — the curated fast-food seed: a chain's NAME and a neutral glyph (never a logo, never a food photo),
// an item's name, serving label and three gram amounts as the chain itself published them. No rating, no rank: the order is the
// file's alphabetical sort. Twin of SeedFastFoodChain / SeedFastFoodItem in web/src/generated/seed.ts.
struct SeedFastFoodChain: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let icon: String           // an SF Symbol from the fixed neutral set (check-seeds)
    let sourceUrl: String
    let retrievedOn: String
}

struct SeedFastFoodItem: Codable, Equatable, Identifiable {
    let id: String
    let chainId: String
    let name: String
    let servingLabel: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

struct SeedFastFood: Codable, Equatable {
    let chains: [SeedFastFoodChain]
    let items: [SeedFastFoodItem]
}

struct SeedCatalog {
    let exercises: [SeedExercise]
    let planTemplates: SeedPlanTemplates
    let achievements: [SeedAchievement]
    let regionOfPattern: [String: String]
    let equipmentSymbol: [String: String]         // A26: equipment tag → SF Symbol (exercises.json enums.equipmentSymbol)
    let fastFood: SeedFastFood

    private struct ExercisesFile: Codable {
        struct Enums: Codable {
            let region: [String: String]
            let equipmentSymbol: [String: String]
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
        let fastFood = try decoder.decode(SeedFastFood.self, from: Data(SeedData.fastFoodJSON.utf8))
        return SeedCatalog(exercises: exercisesFile.exercises, planTemplates: templates, achievements: achievementsFile.achievements, regionOfPattern: exercisesFile.enums.region, equipmentSymbol: exercisesFile.enums.equipmentSymbol, fastFood: fastFood)
    }

    func exercise(_ id: String) -> SeedExercise? {
        exercises.first { $0.id == id }
    }
}
