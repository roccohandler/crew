// SPEC: nutrition addendum §4 (Saved meals & template) · §2 · §5 · 5.6.2 — SavedMealsModel — state: meals · slots · chains · errorLine;
// actions: refresh · save(draft) (create or edit; a chain item's numbers are COPIED) · delete(meal) (its slots go with it) · addSlot ·
// moveSlot · removeSlot (each PUTs the whole ordered list through the queue). A meal is a name and three whole numbers and NOTHING
// else is checked (clause ⑤): no food is judged, scored or labelled. The template is a checklist, never a requirement: nothing here
// counts a skipped slot. 5.6.6: the screens hold zero logic. Twin of web SavedMealsView.tsx + TemplateView.tsx.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

// What the meal form edits: a new meal (id nil), an existing one, or a chain item's published numbers on their way to becoming one
struct MealDraft: Equatable, Identifiable {
    var id: String?
    var title: String
    var name: String
    var grams: MacroGrams
    var seed: SavedMealSeedDTO?

    static func new() -> MealDraft { MealDraft(id: nil, title: "Add a meal", name: "", grams: MacroGrams(proteinG: 0, carbsG: 0, fatG: 0), seed: nil) }
}

@Observable
@MainActor
final class SavedMealsModel {
    var meals: [MealLine] = []
    var slots: [SlotLine] = []
    var errorLine: String?
    let chains: [SeedFastFoodChain]

    private let store: Store
    private let userId: String
    private let queue: SyncQueue?
    private let seed: SeedCatalog

    init(store: Store = .shared, userId: String? = nil, seed: SeedCatalog = .shared, queue: SyncQueue? = nil) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.seed = seed
        self.queue = queue
        self.chains = seed.fastFood.chains
    }

    var canAddSlot: Bool { !meals.isEmpty && slots.count < SpecConstants.dayTemplateMaxSlots }

    func refresh() {
        do {
            let stored = try NutritionLocal.meals(for: userId, store: store)
            meals = stored.map { MealLine(id: $0.clientId, name: $0.name, grams: MacroGrams(proteinG: $0.proteinG, carbsG: $0.carbsG, fatG: $0.fatG)) }
            slots = try NutritionLocal.slots(for: userId, store: store).enumerated().compactMap { index, slot -> SlotLine? in
                guard let meal = meals.first(where: { $0.id == slot.savedMealId }) else { return nil }
                return SlotLine(id: index, title: slot.label.isEmpty ? meal.name : "\(slot.label) · \(meal.name)", meal: meal, tickedLogId: nil)
            }
        } catch {
            errorLine = AppError.storage("nutrition").userLine
        }
    }

    // SPEC: §5 — a chain's items in the file's own alphabetical order: a sort is not a ranking
    func items(of chain: SeedFastFoodChain) -> [SeedFastFoodItem] {
        seed.fastFood.items.filter { $0.chainId == chain.id }
    }

    // The chain item's published numbers, copied into a draft the user may edit before saving (the name is cut to the cap)
    func draft(from item: SeedFastFoodItem) -> MealDraft {
        MealDraft(id: nil, title: "Add from a chain", name: String(item.name.prefix(SpecConstants.savedMealNameMaxChars)), grams: MacroGrams(proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG), seed: SavedMealSeedDTO(chainId: item.chainId, itemId: item.id))
    }

    func draft(editing meal: MealLine) -> MealDraft {
        MealDraft(id: meal.id, title: "Edit meal", name: meal.name, grams: meal.grams, seed: nil)
    }

    // Returns true when the meal was saved — the sheet closes then
    func save(_ draft: MealDraft) -> Bool {
        let name = String(draft.name.trimmingCharacters(in: .whitespaces).prefix(SpecConstants.savedMealNameMaxChars))
        guard !name.isEmpty else { errorLine = "Give it a name, like Oats and whey."; return false }
        guard draft.id != nil || meals.count < SpecConstants.savedMealsMax else { errorLine = "You can keep \(SpecConstants.savedMealsMax) saved meals. Delete one to add another."; return false }
        return write { _ = try NutritionActions.saveMeal(clientId: draft.id, name: name, grams: draft.grams, seed: draft.seed, userId: userId, store: store, queue: queue) }
    }

    func delete(_ meal: MealLine) {
        _ = write { try NutritionActions.deleteMeal(clientId: meal.id, userId: userId, store: store, queue: queue) }
    }

    func addSlot(meal: MealLine, label: String) {
        let facts = currentSlots() + [TemplateSlotFacts(savedMealId: meal.id, label: String(label.trimmingCharacters(in: .whitespaces).prefix(SpecConstants.dayTemplateSlotLabelMaxChars)))]
        _ = write { try NutritionActions.putTemplate(facts, userId: userId, store: store, queue: queue) }
    }

    // Swap a slot with its neighbour; out of range → unchanged
    func moveSlot(_ slot: SlotLine, by direction: Int) {
        var facts = currentSlots()
        let target = slot.id + direction
        guard facts.indices.contains(slot.id), facts.indices.contains(target) else { return }
        facts.swapAt(slot.id, target)
        _ = write { try NutritionActions.putTemplate(facts, userId: userId, store: store, queue: queue) }
    }

    func removeSlot(_ slot: SlotLine) {
        var facts = currentSlots()
        guard facts.indices.contains(slot.id) else { return }
        facts.remove(at: slot.id)
        _ = write { try NutritionActions.putTemplate(facts, userId: userId, store: store, queue: queue) }
    }

    private func currentSlots() -> [TemplateSlotFacts] {
        (try? NutritionLocal.slots(for: userId, store: store)) ?? []
    }

    // One local write, then the lists re-read the Store; a failed write says so in ink
    private func write(_ work: () throws -> Void) -> Bool {
        var saved = true
        do {
            try work()
            errorLine = nil
        } catch {
            errorLine = AppError.storage("nutrition").userLine
            saved = false
        }
        refresh()
        return saved
    }
}
