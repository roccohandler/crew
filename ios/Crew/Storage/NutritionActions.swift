// SPEC: nutrition addendum §2–§4 (RATIFIED 2026-09-18) · 5.3 optimistic write · 5.6.3 (the six nutrition ops) · E6 — the phone's
// WRITES. Every one is the same two steps WRITTEN OUT at its own site (C5: no wrapper): the row changes in the Store first — the
// screen is already right, offline or not — then the op that tells the server joins the queue, in order (8.3: upsertSavedMeal before
// the putDayTemplate or createMealLog that names the meal). Ids are chosen HERE (lowercased UUIDs), so a replayed op is idempotent
// (8.2 ④, V62). A macro entry is NEVER a game event (clause ③, V63): nothing in this file reads, moves or recomputes XP, the streak, a
// shield or an achievement, and nothing here creates a post (clause ④). WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@MainActor
enum NutritionActions {
    static let quickAddName = "Quick add"

    // SPEC: §3 — `manual` nil derives the three grams from the bodyweight with the engine twin (this is also "Recalculate"); grams
    // the user typed are kept as they are (source manual). The payload carries all three grams or none, as the validator requires.
    static func setTargets(bodyweightTenths: Int, unit: String, manual: MacroGrams?, userId: String, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws {
        let derived = NutritionTargets.deriveTargets(bodyweightTenths, unit)
        let grams = manual ?? MacroGrams(proteinG: derived.proteinG, carbsG: derived.carbsG, fatG: derived.fatG)
        let source = manual == nil ? "derived" : "manual"
        if let existing = try NutritionLocal.targets(for: userId, store: store) {
            existing.bodyweightTenths = bodyweightTenths
            existing.unit = unit
            existing.proteinG = grams.proteinG
            existing.carbsG = grams.carbsG
            existing.fatG = grams.fatG
            existing.source = source
            existing.updatedAt = now
        } else {
            store.context.insert(LocalNutritionTargets(userId: userId, bodyweightTenths: bodyweightTenths, unit: unit, proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: grams.fatG, source: source, updatedAt: now))
        }
        try store.save()
        let bodyweight = Double(bodyweightTenths) / Double(SpecConstants.bodyweightEntryScale)
        try (queue ?? .shared).enqueue(.putNutritionTargets, payload: PutTargetsPayload(bodyweight: bodyweight, unit: unit, proteinG: manual?.proteinG, carbsG: manual?.carbsG, fatG: manual?.fatG), now: now)
    }

    // SPEC: §2 — create (clientId nil → a new id) or edit (the same clientId; the server's upsert edits what the first arrival made).
    // A chain item's numbers are COPIED here, so a later seed edit never rewrites what the user saved.
    @discardableResult
    static func saveMeal(clientId: String?, name: String, grams: MacroGrams, seed: SavedMealSeedDTO?, userId: String, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws -> String {
        let id = clientId ?? UUID().uuidString.lowercased()
        if let existing = try NutritionLocal.meal(clientId: id, store: store) {
            existing.name = name
            existing.proteinG = grams.proteinG
            existing.carbsG = grams.carbsG
            existing.fatG = grams.fatG
        } else {
            store.context.insert(LocalSavedMeal(clientId: id, userId: userId, name: name, proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: grams.fatG, seedChainId: seed?.chainId, seedItemId: seed?.itemId, createdAt: now))
        }
        try store.save()
        try (queue ?? .shared).enqueue(.upsertSavedMeal, payload: UpsertSavedMealPayload(clientId: id, name: name, proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: grams.fatG, seed: seed), now: now)
        return id
    }

    // SPEC: §2 — "deleting the meal removes the slot" (the server pulls the slots itself when the op lands); a day already logged keeps
    // its own copy of the name and the grams, so history is untouched
    static func deleteMeal(clientId: String, userId: String, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws {
        guard let meal = try NutritionLocal.meal(clientId: clientId, store: store) else { return }
        let kept = try NutritionLocal.slots(for: userId, store: store).filter { $0.savedMealId != clientId }
        store.context.delete(meal)
        try writeSlots(kept, userId: userId, now: now, store: store)
        try store.save()
        try (queue ?? .shared).enqueue(.deleteSavedMeal, payload: NutritionIdPayload(id: clientId), now: now)
    }

    // SPEC: §4 Template — the whole ordered list is replaced (add, reorder, remove), capped at dayTemplateMaxSlots
    static func putTemplate(_ slots: [TemplateSlotFacts], userId: String, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws {
        let capped = Array(slots.prefix(SpecConstants.dayTemplateMaxSlots))
        try writeSlots(capped, userId: userId, now: now, store: store)
        try store.save()
        try (queue ?? .shared).enqueue(.putDayTemplate, payload: PutTemplatePayload(slots: capped), now: now)
    }

    // SPEC: §4 · V62 — one tap logs a slot: the log COPIES the meal's name and grams, so a later edit of the meal never rewrites the day
    @discardableResult
    static func logMeal(_ meal: LocalSavedMeal, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws -> String {
        let id = UUID().uuidString.lowercased()
        store.context.insert(LocalMealLog(clientId: id, userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), savedMealId: meal.clientId, name: meal.name, proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG, quickAdd: false, createdAt: now))
        try store.save()
        try (queue ?? .shared).enqueue(.createMealLog, payload: CreateMealLogPayload(clientId: id, timezone: timeZone.identifier, savedMealId: meal.clientId, name: meal.name, proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG, quickAdd: false, createdAt: now), now: now)
        return id
    }

    // SPEC: §4 "Quick add" — three gram amounts and nothing else: no food is named, and no food is judged (clause ⑤)
    @discardableResult
    static func quickAdd(_ grams: MacroGrams, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws -> String {
        let id = UUID().uuidString.lowercased()
        store.context.insert(LocalMealLog(clientId: id, userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), savedMealId: nil, name: quickAddName, proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: grams.fatG, quickAdd: true, createdAt: now))
        try store.save()
        try (queue ?? .shared).enqueue(.createMealLog, payload: CreateMealLogPayload(clientId: id, timezone: timeZone.identifier, name: quickAddName, proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: grams.fatG, quickAdd: true, createdAt: now), now: now)
        return id
    }

    // SPEC: §4 — undo in place, and the log list's Delete: the row leaves the day; nothing is recomputed because a log was never counted
    static func deleteLog(clientId: String, now: Date = Date(), store: Store, queue: SyncQueue? = nil) throws {
        guard let log = try NutritionLocal.log(clientId: clientId, store: store) else { return }
        store.context.delete(log)
        try store.save()
        try (queue ?? .shared).enqueue(.deleteMealLog, payload: NutritionIdPayload(id: clientId), now: now)
    }

    private static func writeSlots(_ slots: [TemplateSlotFacts], userId: String, now: Date, store: Store) throws {
        let data = try JSONEncoder.crew.encode(slots)
        if let template = try NutritionLocal.template(for: userId, store: store) {
            template.slotsJSON = data
            template.updatedAt = now
        } else {
            store.context.insert(LocalDayTemplate(userId: userId, slotsJSON: data, updatedAt: now))
        }
    }
}
