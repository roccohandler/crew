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

struct SlotLog: Equatable {
    let clientId: String
    let savedMealId: String?
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

    // SPEC: §4 — the words on a line, identical on both platforms: "95 / 145 g" and then "50 to go" or "10 over" — two facts in
    // ordinary ink (clause ②). Exactly on target prints no second fact: the amounts already say it, and a zero is never a verdict (A8; R-075).
    static func amountText(_ line: MacroLine, unit: String) -> String {
        "\(line.logged) / \(line.target) \(unit)"
    }

    static func restText(_ line: MacroLine) -> String? {
        if line.over > 0 { return "\(line.over) over" }
        return line.toGo > 0 ? "\(line.toGo) to go" : nil
    }

    // SPEC: clause ② ("an overage is a measurement stated in ordinary ink on its own line, NAMING TOMORROW IN THE SAME BREATH") — one
    // sentence under the four lines whenever any of them is over: the next horizon, as a fact. Never a colour, never an alert, never a
    // verb aimed at the user (no coaching copy, A21.5); nil while nothing is over, so a day on or under target says nothing (R-075).
    static func horizonText(_ day: MacroRemaining) -> String? {
        let anyOver = [day.protein, day.carbs, day.fat, day.calories].contains { $0.over > 0 }
        return anyOver ? "Tomorrow starts from your full targets." : nil
    }

    // SPEC: 6.5 · E20 — the ONE sentence VoiceOver reads for a line, the same on both platforms: "Protein: 95 / 145 g, 50 to go"
    static func spokenLine(_ name: String, _ line: MacroLine, unit: String) -> String {
        guard let rest = restText(line) else { return "\(name): \(amountText(line, unit: unit))" }
        return "\(name): \(amountText(line, unit: unit)), \(rest)"
    }

    // SPEC: §4 · §7.4 encoder ⑤ — the bar's fill as a whole percent of its track. The target marker sits at macroBarTargetPercent,
    // so a fill past the hairline IS the overage, shown as length; the colour never changes. No target → an empty track, or a full one.
    static func barPercent(_ line: MacroLine) -> Int {
        if line.target == 0 { return line.logged > 0 ? SpecConstants.macroPercentScale : 0 }
        return min(SpecConstants.macroPercentScale, (line.logged * SpecConstants.macroBarTargetPercent) / line.target)
    }

    // SPEC: §4 · §7.4 encoders ① ② — a meal's three numbers in the fixed order, each with its letter; and the sentence VoiceOver reads
    static func gramsText(_ grams: MacroGrams) -> String {
        "P \(grams.proteinG) · C \(grams.carbsG) · F \(grams.fatG)"
    }

    static func gramsSpoken(_ grams: MacroGrams) -> String {
        "\(grams.proteinG) grams protein, \(grams.carbsG) grams carbs, \(grams.fatG) grams fat"
    }

    // SPEC: §4 "Your template" — one tap logs a slot (✓), undo in place. Which of today's logs ticks which slot: a meal's logs fill
    // that meal's slots in order, so the same meal in two slots ticks one at a time; a quick add, or a log whose meal is gone, ticks none.
    static func slotTicks(_ slotMealIds: [String], logs: [SlotLog]) -> [String?] {
        var used = Set<String>()
        return slotMealIds.map { mealId in
            guard let match = logs.first(where: { $0.savedMealId == mealId && !used.contains($0.clientId) }) else { return nil }
            used.insert(match.clientId)
            return match.clientId
        }
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
