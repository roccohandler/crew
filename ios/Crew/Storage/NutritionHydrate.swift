// SPEC: nutrition addendum §2 · E6 · 1C (a reinstalled phone wakes signed in with an empty Store) — the nutrition PULL. The phone is
// the truth it renders from, and the server is the truth two devices agree on: when Nutrition opens (and only then — never at launch,
// §6) the four GETs run and the server's copy REPLACES the phone's, so a meal saved on the web, or everything after a reinstall, is
// there. THE ONE GUARD: while any nutrition op is still queued (pending, in flight or held) the phone is AHEAD of the server and the
// pull does nothing — replacing then would erase a tap the server has not seen (the same reason SyncQueue.reconcile waits for
// undelivered posts, A3). Offline, gated or failing, the pull leaves the phone as it was (E6: offline is not a failure).
// A log and a slot arrive naming their meal by SERVER id; the phone keys meals by clientId, so they are translated here.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@MainActor
enum NutritionHydrate {
    // Returns true when the server's copy was written — the model re-reads the Store then
    @discardableResult
    static func pull(userId: String, dayKey: String, store: Store) async -> Bool {
        guard ((try? NutritionLocal.queuedOps(store: store)) ?? []).isEmpty else { return false }
        guard let targets = try? await Api.shared.nutritionTargets(), let meals = try? await Api.shared.savedMeals(),
              let template = try? await Api.shared.dayTemplate(), let logs = try? await Api.shared.mealLogs(dayKey: dayKey) else { return false }
        guard ((try? NutritionLocal.queuedOps(store: store)) ?? []).isEmpty else { return false } // a tap landed while the four GETs were out
        do {
            try write(targets: targets.targets, meals: meals.items, slots: template.slots, logs: logs.items, userId: userId, dayKey: dayKey, store: store)
            return true
        } catch {
            return false
        }
    }

    static func write(targets: NutritionTargetsDTO?, meals: [SavedMealDTO], slots: [TemplateSlotDTO], logs: [MealLogDTO], userId: String, dayKey: String, store: Store, now: Date = Date()) throws {
        if let existing = try NutritionLocal.targets(for: userId, store: store) { store.context.delete(existing) }
        if let existing = try NutritionLocal.template(for: userId, store: store) { store.context.delete(existing) }
        for meal in try NutritionLocal.meals(for: userId, store: store) { store.context.delete(meal) }
        for log in try NutritionLocal.logs(for: userId, dayKey: dayKey, store: store) { store.context.delete(log) }
        try store.save() // the old rows leave first: the new ones reuse their unique keys
        if let targets {
            let tenths = Int((targets.bodyweight * Double(SpecConstants.bodyweightEntryScale)).rounded())
            store.context.insert(LocalNutritionTargets(userId: userId, bodyweightTenths: tenths, unit: targets.unit, proteinG: targets.proteinG, carbsG: targets.carbsG, fatG: targets.fatG, source: targets.source, updatedAt: targets.updatedAt))
        }
        var clientIdByServerId: [String: String] = [:]
        for meal in meals {
            clientIdByServerId[meal.id] = meal.clientId
            let local = LocalSavedMeal(clientId: meal.clientId, userId: userId, name: meal.name, proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG, seedChainId: meal.source.chainId, seedItemId: meal.source.itemId, createdAt: meal.createdAt)
            local.serverId = meal.id
            store.context.insert(local)
        }
        let slotFacts = slots.map { TemplateSlotFacts(savedMealId: $0.meal.clientId, label: $0.label) }
        store.context.insert(LocalDayTemplate(userId: userId, slotsJSON: try JSONEncoder.crew.encode(slotFacts), updatedAt: now))
        for log in logs {
            let mealClientId = log.savedMealId.flatMap { clientIdByServerId[$0] } // a meal deleted since keeps its log and ticks no slot
            store.context.insert(LocalMealLog(clientId: log.clientId, userId: userId, dayKey: log.dayKey, savedMealId: mealClientId, name: log.name, proteinG: log.proteinG, carbsG: log.carbsG, fatG: log.fatG, quickAdd: log.quickAdd, createdAt: log.createdAt))
        }
        try store.save()
    }
}
