// SPEC: nutrition addendum §4 (Today) · §6 (the 18+ gate; the birth year asked once, here) · 5.6.2 — NutritionTodayModel — state:
// availability · targets (nil = the first-run state) · remaining (the four lines) · slots (with their ticks) · logs · errorLine;
// actions: open (Store first, then the pull) · refresh · estimate(bodyweightText) · tapSlot (one tap logs, the same tap undoes) ·
// quickAdd · deleteLog · saveBirthYear. Everything the screen prints is decided HERE (5.6.6: a screen holds zero logic) and every
// number on it comes from the engine twins (NutritionTargets, MacroDay), so the web page prints the same digits. A macro entry is
// never a game event (clause ③): this model has no access to XP, the streak or a shield, and creates no post (clause ④).
// Twin of web NutritionToday.tsx + nutrition/page.tsx. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

// A saved meal or a log as a screen prints it; `id` is the row's clientId
struct MealLine: Equatable, Identifiable {
    let id: String
    let name: String
    let grams: MacroGrams
}

struct SlotLine: Equatable, Identifiable {
    let id: Int                  // the slot's position — the same meal may sit in two slots
    let title: String            // "Breakfast · Oats and whey", or the meal's name alone
    let meal: MealLine
    let tickedLogId: String?     // today's log that ticks this slot (MacroDay.slotTicks); nil = not logged
}

@Observable
@MainActor
final class NutritionTodayModel {
    var availability: NutritionAvailability
    var targets: MacroGrams?
    var remaining: MacroRemaining?
    var slots: [SlotLine] = []
    var logs: [MealLine] = []
    var errorLine: String?
    var isSaving = false
    let weightUnit: String

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let queue: SyncQueue?

    init(store: Store = .shared, userId: String? = nil, availability: NutritionAvailability? = nil, weightUnit: String? = nil, timeZone: TimeZone = .current, queue: SyncQueue? = nil) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.availability = availability ?? AuthStore.shared.nutrition
        self.weightUnit = weightUnit ?? AuthStore.shared.weightUnit
        self.timeZone = timeZone
        self.queue = queue
    }

    // The Store first (the screen is right at once, offline or not), then the server's copy when the phone is not ahead of it
    func open(now: Date = Date()) async {
        refresh(now: now)
        guard availability == .available else { return }
        if await NutritionHydrate.pull(userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), store: store) { refresh(now: now) }
    }

    func refresh(now: Date = Date()) {
        do {
            let dayKey = DayKey.dayKey(for: now, tz: timeZone)
            let stored = try NutritionLocal.targets(for: userId, store: store)
            let dayLogs = try NutritionLocal.logs(for: userId, dayKey: dayKey, store: store)
            let meals = try NutritionLocal.meals(for: userId, store: store)
            let slotFacts = try NutritionLocal.slots(for: userId, store: store)
            let ticks = MacroDay.slotTicks(slotFacts.map(\.savedMealId), logs: dayLogs.map { SlotLog(clientId: $0.clientId, savedMealId: $0.savedMealId) })
            targets = stored.map { MacroGrams(proteinG: $0.proteinG, carbsG: $0.carbsG, fatG: $0.fatG) }
            remaining = targets.map { MacroDay.remaining($0, dayLogs.map { MealLogFacts(clientId: $0.clientId, proteinG: $0.proteinG, carbsG: $0.carbsG, fatG: $0.fatG) }) }
            logs = dayLogs.map { MealLine(id: $0.clientId, name: $0.name, grams: MacroGrams(proteinG: $0.proteinG, carbsG: $0.carbsG, fatG: $0.fatG)) }
            slots = slotFacts.enumerated().compactMap { index, slot -> SlotLine? in
                guard let meal = meals.first(where: { $0.clientId == slot.savedMealId }) else { return nil }
                let line = MealLine(id: meal.clientId, name: meal.name, grams: MacroGrams(proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG))
                return SlotLine(id: index, title: slot.label.isEmpty ? meal.name : "\(slot.label) · \(meal.name)", meal: line, tickedLogId: ticks[index])
            }
        } catch {
            errorLine = AppError.storage("nutrition").userLine
        }
    }

    // SPEC: §3 — the first-run state: one number in the account's weight unit → the estimate (the engine twin derives it; R-074 (3))
    func estimate(bodyweightText: String, now: Date = Date()) {
        guard let tenths = NutritionTargets.bodyweightTenthsFrom(bodyweightText, weightUnit) else {
            errorLine = NutritionTodayModel.bodyweightHint(weightUnit)
            return
        }
        write(now: now) { try NutritionActions.setTargets(bodyweightTenths: tenths, unit: weightUnit, manual: nil, userId: userId, now: now, store: store, queue: queue) }
    }

    // The one sentence a bodyweight the parser refused gets, with an example in the account's own unit (shared with the targets screen)
    static func bodyweightHint(_ unit: String) -> String {
        let example = unit == "kg" ? "80" : "176"
        return "Type your bodyweight in \(unit), like \(example)."
    }

    // SPEC: §4 "Your template" — one tap logs the slot (✓); the same tap undoes it in place; a skipped slot is simply unlogged
    func tapSlot(_ slot: SlotLine, now: Date = Date()) {
        write(now: now) {
            if let logId = slot.tickedLogId { return try NutritionActions.deleteLog(clientId: logId, now: now, store: store, queue: queue) }
            guard let meal = try NutritionLocal.meal(clientId: slot.meal.id, store: store) else { return }
            _ = try NutritionActions.logMeal(meal, userId: userId, timeZone: timeZone, now: now, store: store, queue: queue)
        }
    }

    func quickAdd(_ grams: MacroGrams, now: Date = Date()) {
        guard grams.proteinG + grams.carbsG + grams.fatG > 0 else { return }
        write(now: now) { _ = try NutritionActions.quickAdd(grams, userId: userId, timeZone: timeZone, now: now, store: store, queue: queue) }
    }

    func deleteLog(_ id: String, now: Date = Date()) {
        write(now: now) { try NutritionActions.deleteLog(clientId: id, now: now, store: store, queue: queue) }
    }

    // SPEC: A16.c · §6 — the birth year, asked ONCE when Nutrition is first opened on an account without one; network-only (it is
    // the server that judges it, behind the 13+ floor). Under 18 the surface simply does not exist afterwards — no copy about it.
    func saveBirthYear(_ text: String) async {
        guard let year = Int(text), year >= SpecConstants.birthYearMin, year <= Calendar.current.component(.year, from: Date()) else {
            errorLine = "Four digits, like 1994."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let user = try await Api.shared.updateMe(UpdateMeRequestDTO(birthYear: year))
            AuthStore.shared.updateCurrentUser(user)
            availability = AuthStore.shared.nutrition
            errorLine = nil
            await open()
        } catch let error as AppError {
            errorLine = error.userLine
        } catch {
            errorLine = AppError.invalidResponse.userLine
        }
    }

    // One local write, then the screen re-reads the Store; a failed write says so in ink
    private func write(now: Date, _ work: () throws -> Void) {
        do {
            try work()
            errorLine = nil
        } catch {
            errorLine = AppError.storage("nutrition").userLine
        }
        refresh(now: now)
    }
}
