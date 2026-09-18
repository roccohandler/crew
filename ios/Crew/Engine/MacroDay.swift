// SPEC: nutrition addendum §4 (Today: P / C / F and, fourth, Calories — Q2) · §7 · clauses ② ③ · V61–V63. remaining(targets, logs) →
// per line { logged, target, toGo, over }: "N to go" or "N over" are two facts in ink, never a colour and never a verdict (clause ②).
// The calorie line is the three macros in Atwater kilocalories on both sides, so it always agrees with the grams the user set.
// A macro entry is NEVER a game event (clause ③, V63): it pays no XP, moves no streak, fills no shield, earns no achievement.
// Twin of web/src/lib/engine/macro-day.ts — identical names. Pure; Foundation only. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct MealLogFacts: Codable, Equatable {
    let clientId: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

struct MacroLine: Codable, Equatable {
    let logged: Int
    let target: Int
    let toGo: Int
    let over: Int
}

struct MacroRemaining: Codable, Equatable {
    let protein: MacroLine
    let carbs: MacroLine
    let fat: MacroLine
    let calories: MacroLine
}

struct MacroGrams: Codable, Equatable {
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

enum MacroDay {
    static func kcalOf(_ proteinG: Int, _ carbsG: Int, _ fatG: Int) -> Int {
        proteinG * SpecConstants.kcalPerGramProtein + carbsG * SpecConstants.kcalPerGramCarbs + fatG * SpecConstants.kcalPerGramFat
    }

    // SPEC: V61 — to go = target − logged floored at 0; over = the other side of the same subtraction; never both above 0
    static func macroLine(_ logged: Int, _ target: Int) -> MacroLine {
        MacroLine(logged: logged, target: target, toGo: max(0, target - logged), over: max(0, logged - target))
    }

    static func remaining(_ targets: MacroGrams, _ logs: [MealLogFacts]) -> MacroRemaining {
        let proteinG = logs.reduce(0) { $0 + $1.proteinG }
        let carbsG = logs.reduce(0) { $0 + $1.carbsG }
        let fatG = logs.reduce(0) { $0 + $1.fatG }
        return MacroRemaining(
            protein: macroLine(proteinG, targets.proteinG),
            carbs: macroLine(carbsG, targets.carbsG),
            fat: macroLine(fatG, targets.fatG),
            calories: macroLine(kcalOf(proteinG, carbsG, fatG), kcalOf(targets.proteinG, targets.carbsG, targets.fatG))
        )
    }

    // SPEC: V62 · 8.2 ④ — a log is idempotent on its clientId: a template slot tapped twice (or replayed by the queue) logs once
    static func logging(_ entry: MealLogFacts, _ logs: [MealLogFacts]) -> [MealLogFacts] {
        logs.contains { $0.clientId == entry.clientId } ? logs : logs + [entry]
    }

    // SPEC: clause ③ · V63 (load-bearing) — the ONE place a macro entry could become a game event, and it never does
    static func gameEvents(_ logs: [MealLogFacts]) -> [GameEvent] {
        logs.flatMap { _ -> [GameEvent] in [] }
    }
}
