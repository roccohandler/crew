// SPEC: A16.c · nutrition addendum §6 · A22 G3 (owner-approved 2026-09-18: an under-18 account has NO nutrition surface) · V65.
// availability(birthYear, currentYear): at nutritionAdultAgeYears or older → available; no birth year on the account (a Sign in
// with Apple account, or one made before the year was stored) → askBirthYear, once, when Nutrition is opened — never at launch;
// younger → absent: no row, no copy, no upsell, no "unlock at 18". The same year arithmetic requireSignupGates uses.
// Twin of web/src/lib/engine/nutrition-gate.ts — identical names. Pure; Foundation only. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum NutritionAvailability: String, Codable, Equatable {
    case available, askBirthYear, absent
}

enum NutritionGate {
    static func availability(_ birthYear: Int?, _ currentYear: Int) -> NutritionAvailability {
        guard let birthYear else { return .askBirthYear }
        return currentYear - birthYear >= SpecConstants.nutritionAdultAgeYears ? .available : .absent
    }
}
