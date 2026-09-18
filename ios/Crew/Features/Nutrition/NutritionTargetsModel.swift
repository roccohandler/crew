// SPEC: nutrition addendum §3–§4 (Settings → Nutrition targets: the bodyweight, the three grams, Recalculate — Q1: there is no
// goal) · E1's ONE exception (the bodyweight, in the account's weight unit, shown to nobody) · V60 (a carbs floor is a measurement on
// its own line, never a warning) · 5.6.2 — NutritionTargetsModel — state: bodyweightText · grams · hasTargets · sourceLine ·
// estimateLine · overageLine · savedLine · errorLine; actions: refresh · save(manual:) — manual keeps the three grams as typed
// (source manual), otherwise they are derived again from the bodyweight ("Recalculate", and the first-run estimate). Every number is
// the engine twin's, so the web form prints the same digits. Twin of web components/nutrition/TargetsForm.tsx.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

@Observable
@MainActor
final class NutritionTargetsModel {
    var bodyweightText = ""
    var grams = MacroGrams(proteinG: 0, carbsG: 0, fatG: 0)
    var hasTargets = false
    var sourceLine: String?
    var estimateLine: String?
    var overageLine: String?
    var savedLine: String?
    var errorLine: String?
    let weightUnit: String

    private let store: Store
    private let userId: String
    private let queue: SyncQueue?

    init(store: Store = .shared, userId: String? = nil, weightUnit: String? = nil, queue: SyncQueue? = nil) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.weightUnit = weightUnit ?? AuthStore.shared.weightUnit
        self.queue = queue
    }

    // The Store first, then the server's copy (a reinstalled phone, or targets set on the web) — unless the user has already started
    // typing, in which case what is on screen stays theirs
    func open(now: Date = Date()) async {
        refresh()
        let shownText = bodyweightText
        let shownGrams = grams
        guard await NutritionHydrate.pull(userId: userId, dayKey: DayKey.dayKey(for: now, tz: .current), store: store) else { return }
        if bodyweightText == shownText, grams == shownGrams { refresh() }
    }

    func refresh() {
        guard let stored = try? NutritionLocal.targets(for: userId, store: store) else {
            hasTargets = false
            sourceLine = nil
            estimateLine = nil
            overageLine = nil
            return
        }
        // A9 — the form speaks the account's CURRENT unit: a bodyweight typed in pounds reads in kilograms after the switch
        let typed = Double(stored.bodyweightTenths) / Double(SpecConstants.bodyweightEntryScale)
        let shown = WeightUnits.weightIn(typed, from: stored.unit, to: weightUnit)
        bodyweightText = shown.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(shown))" : "\(shown)"
        grams = MacroGrams(proteinG: stored.proteinG, carbsG: stored.carbsG, fatG: stored.fatG)
        hasTargets = true
        sourceLine = stored.source == "derived" ? "Estimated from your bodyweight." : "Set by you."
        let estimate = NutritionTargets.deriveTargets(stored.bodyweightTenths, stored.unit)
        estimateLine = "The estimate at this bodyweight: \(estimate.energyKcal) kcal · P \(estimate.proteinG) · C \(estimate.carbsG) · F \(estimate.fatG)."
        overageLine = estimate.carbsOverageKcal > 0 ? "Protein and fat alone come to \(estimate.carbsOverageKcal) kcal more than the energy estimate, so carbs sit at 0." : nil
    }

    // `manual` true keeps the grams on screen (source manual); false derives them again from the bodyweight — "Recalculate"
    func save(manual: Bool, now: Date = Date()) {
        savedLine = nil
        guard let tenths = NutritionTargets.bodyweightTenthsFrom(bodyweightText, weightUnit) else {
            errorLine = NutritionTodayModel.bodyweightHint(weightUnit)
            return
        }
        let capped = MacroGrams(proteinG: min(grams.proteinG, SpecConstants.macroTargetGramsMax), carbsG: min(grams.carbsG, SpecConstants.macroTargetGramsMax), fatG: min(grams.fatG, SpecConstants.macroTargetGramsMax))
        do {
            try NutritionActions.setTargets(bodyweightTenths: tenths, unit: weightUnit, manual: manual ? capped : nil, userId: userId, now: now, store: store, queue: queue)
            errorLine = nil
            savedLine = "Saved."
        } catch {
            errorLine = AppError.storage("nutrition").userLine
        }
        refresh()
    }
}
