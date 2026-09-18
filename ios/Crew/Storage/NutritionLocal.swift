// SPEC: nutrition addendum §2 (RATIFIED 2026-09-18) · E6 — the phone's READS of its own nutrition rows, as typed fetches the three
// nutrition models share (plain functions, no repository layer — C2), plus the one question the pull asks of the queue. Everything is
// scoped to one userId. Nothing here is ever called from the crew, a post, the gamification state or an achievement counter
// (clauses ③ ④): the only callers are Features/Nutrition, Home's "Log macros" row (a COUNT) and Settings' delete. The writes are
// NutritionActions.swift; the pull is NutritionHydrate.swift. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@MainActor
enum NutritionLocal {
    static let opKinds: [OpKind] = [.putNutritionTargets, .upsertSavedMeal, .deleteSavedMeal, .putDayTemplate, .createMealLog, .deleteMealLog]

    static func targets(for userId: String, store: Store) throws -> LocalNutritionTargets? {
        var descriptor = FetchDescriptor<LocalNutritionTargets>(predicate: #Predicate { $0.userId == userId })
        descriptor.fetchLimit = 1
        return try store.context.fetch(descriptor).first
    }

    // Oldest first — the order they were saved in, the same order the server lists them
    static func meals(for userId: String, store: Store) throws -> [LocalSavedMeal] {
        try store.context.fetch(FetchDescriptor<LocalSavedMeal>(predicate: #Predicate { $0.userId == userId }, sortBy: [SortDescriptor(\.createdAt)]))
    }

    static func meal(clientId: String, store: Store) throws -> LocalSavedMeal? {
        var descriptor = FetchDescriptor<LocalSavedMeal>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        return try store.context.fetch(descriptor).first
    }

    static func template(for userId: String, store: Store) throws -> LocalDayTemplate? {
        var descriptor = FetchDescriptor<LocalDayTemplate>(predicate: #Predicate { $0.userId == userId })
        descriptor.fetchLimit = 1
        return try store.context.fetch(descriptor).first
    }

    // SPEC: §2 — "deleting the meal removes the slot": a slot whose meal is no longer on the phone is simply not there
    static func slots(for userId: String, store: Store) throws -> [TemplateSlotFacts] {
        guard let template = try template(for: userId, store: store) else { return [] }
        let stored = (try? JSONDecoder.crew.decode([TemplateSlotFacts].self, from: template.slotsJSON)) ?? []
        let known = Set(try meals(for: userId, store: store).map(\.clientId))
        return stored.filter { known.contains($0.savedMealId) }
    }

    static func logs(for userId: String, dayKey: String, store: Store) throws -> [LocalMealLog] {
        try store.context.fetch(FetchDescriptor<LocalMealLog>(predicate: #Predicate { $0.userId == userId && $0.dayKey == dayKey }, sortBy: [SortDescriptor(\.createdAt)]))
    }

    static func log(clientId: String, store: Store) throws -> LocalMealLog? {
        var descriptor = FetchDescriptor<LocalMealLog>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        return try store.context.fetch(descriptor).first
    }

    // SPEC: A22 G4 · addendum Q3 — Home's "Log macros" row reports a COUNT of today's entries or nothing (A8) — never grams, never a verdict
    static func loggedCount(for userId: String, dayKey: String, store: Store) throws -> Int? {
        let count = try store.context.fetchCount(FetchDescriptor<LocalMealLog>(predicate: #Predicate { $0.userId == userId && $0.dayKey == dayKey }))
        return count > 0 ? count : nil
    }

    // A nutrition op still in the queue (pending, in flight or held) means the phone is AHEAD of the server: the pull waits (NutritionHydrate)
    static func queuedOps(store: Store) throws -> [OpRecord] {
        let kinds = opKinds.map(\.rawValue)
        return try store.context.fetch(FetchDescriptor<OpRecord>(predicate: #Predicate { kinds.contains($0.kind) }))
    }

    // SPEC: §4 "Delete my nutrition data" · V64 — after the server confirmed the cascade: all four kinds of row leave the phone, the
    // bodyweight with the targets, and any nutrition op still queued goes too so nothing deleted can be sent back
    static func wipe(userId: String, store: Store) throws {
        if let targets = try targets(for: userId, store: store) { store.context.delete(targets) }
        if let template = try template(for: userId, store: store) { store.context.delete(template) }
        for meal in try meals(for: userId, store: store) { store.context.delete(meal) }
        for log in try store.context.fetch(FetchDescriptor<LocalMealLog>(predicate: #Predicate { $0.userId == userId })) { store.context.delete(log) }
        for record in try queuedOps(store: store) { store.context.delete(record) }
        try store.save()
    }
}
