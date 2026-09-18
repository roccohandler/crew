// SPEC: nutrition addendum §3 (RATIFIED 2026-09-18; Q1: maintenance only — there is no goal) · A16 (protein first, the fat floor) ·
// V57–V60, V64. deriveTargets(bodyweight, unit) → energy, protein, fat, carbs: an ESTIMATE the user may overwrite, never a
// prescription. Integer arithmetic end to end (the distanceDecimalScale precedent): a bodyweight is TENTHS of its unit, kilograms
// are carried as hundredths, every factor is a named constant, and grams round half-up to macroGramsRoundTo — so Swift and
// TypeScript print the same digit. Twin of web/src/lib/engine/nutrition-targets.ts — identical names. Pure; Foundation only.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct MacroTargets: Codable, Equatable {
    let energyKcal: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let carbsOverageKcal: Int   // > 0 only when protein and fat alone exceed the energy: carbs floor at 0 and the overage is STATED (V60)
}

// SPEC: §2 · E1 — the one object that holds the bodyweight: there is no bodyweight apart from the targets (V64)
struct TargetsFacts: Codable, Equatable {
    let bodyweightTenths: Int
    let unit: String            // "lb" | "kg" — the account's weightUnit at entry (A9)
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let source: String          // "derived" | "manual"
}

struct BodyweightFacts: Codable, Equatable {
    let bodyweightTenths: Int
    let unit: String
}

struct CarbsResult: Codable, Equatable {
    let carbsG: Int
    let carbsOverageKcal: Int
}

enum NutritionTargets {
    // SPEC: §3 rounding — the nearest multiple of `step` to numerator / denominator, half up, integers only
    static func roundToStep(_ numerator: Int, _ denominator: Int, _ step: Int) -> Int {
        let unit = denominator * step
        let whole = numerator / unit
        let remainder = numerator - whole * unit
        return (remainder + remainder >= unit ? whole + 1 : whole) * step
    }

    // SPEC: A9 · §3 — a bodyweight in tenths of its unit → hundredths of a kilogram (the exact international pound, half-up)
    static func kilogramHundredths(_ bodyweightTenths: Int, _ unit: String) -> Int {
        let hundredths = bodyweightTenths * SpecConstants.bodyweightKilogramScale / SpecConstants.bodyweightEntryScale
        if unit == "kg" { return hundredths }
        return roundToStep(hundredths * SpecConstants.kilogramsPerPoundScaled, SpecConstants.weightConversionScale, 1)
    }

    // SPEC: §3 carbs — what the energy leaves after protein and fat, floored at 0; a floor hit is a measurement on its own line (V60)
    static func carbs(_ energyKcal: Int, _ proteinG: Int, _ fatG: Int) -> CarbsResult {
        let left = energyKcal - proteinG * SpecConstants.kcalPerGramProtein - fatG * SpecConstants.kcalPerGramFat
        if left <= 0 { return CarbsResult(carbsG: 0, carbsOverageKcal: max(0, -left)) }
        return CarbsResult(carbsG: roundToStep(left, SpecConstants.kcalPerGramCarbs, SpecConstants.macroGramsRoundTo), carbsOverageKcal: 0)
    }

    // SPEC: §3 — energy = kg × kcalPerKgMaintenance · protein = kg × 1.8 · fat = max(20 % of energy, 0.5 g/kg) · carbs = the rest.
    // R-074: the energy rounds to energyKcalRoundTo, so 80 kg and 176 lb derive the same four lines (V58) and an estimate never
    // reads as a measurement; with the ratified factors the fat floor is a guard that never binds (0.73 g/kg > 0.5 g/kg) — V59.
    static func deriveTargets(_ bodyweightTenths: Int, _ unit: String) -> MacroTargets {
        let kg = kilogramHundredths(bodyweightTenths, unit)
        let perKgScale = SpecConstants.bodyweightKilogramScale * SpecConstants.macroFactorScale
        let energyKcal = roundToStep(kg * SpecConstants.kcalPerKgMaintenance, SpecConstants.bodyweightKilogramScale, SpecConstants.energyKcalRoundTo)
        let proteinG = roundToStep(kg * SpecConstants.proteinGramsPerKgScaled, perKgScale, SpecConstants.macroGramsRoundTo)
        let fatFromEnergy = roundToStep(energyKcal * SpecConstants.fatFloorPercentOfEnergy, SpecConstants.macroPercentScale * SpecConstants.kcalPerGramFat, SpecConstants.macroGramsRoundTo)
        let fatFloor = roundToStep(kg * SpecConstants.fatFloorGramsPerKgScaled, perKgScale, SpecConstants.macroGramsRoundTo)
        let fatG = max(fatFromEnergy, fatFloor)
        let rest = carbs(energyKcal, proteinG, fatG)
        return MacroTargets(energyKcal: energyKcal, proteinG: proteinG, carbsG: rest.carbsG, fatG: fatG, carbsOverageKcal: rest.carbsOverageKcal)
    }

    // SPEC: §2 · E1 · V64 — the bodyweight is read OUT OF the targets; delete the targets and no bodyweight is left anywhere
    static func bodyweightOf(_ facts: TargetsFacts?) -> BodyweightFacts? {
        facts.map { BodyweightFacts(bodyweightTenths: $0.bodyweightTenths, unit: $0.unit) }
    }
}
