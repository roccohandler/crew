// SPEC: nutrition addendum §4 (Template: up to dayTemplateMaxSlots slots — add from saved meals, reorder, remove) · §2 — the template
// is an ordered CHECKLIST of saved meals, never a requirement: nothing counts a skipped slot and nothing scores a day. Every change
// replaces the whole ordered list through the queue (SavedMealsModel). Reorder is two visible buttons, never a drag alone (6.3). The
// optional label ("Breakfast") is the user's own word. Ink only. Twin of web components/nutrition/TemplateView.tsx.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct DayTemplateView: View {
    let model: SavedMealsModel
    @State private var mealId = ""
    @State private var label = ""
    @FocusState private var focused: String?

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            if model.meals.isEmpty {
                Text("A template is built from saved meals. Add one first.").font(.body).foregroundStyle(EmberColors.secondaryText)
            } else if model.slots.isEmpty {
                Text("Your usual day, in order. One tap on Today logs each slot.").font(.body).foregroundStyle(EmberColors.secondaryText)
            }
            ForEach(model.slots) { slot in
                MealLineRow(line: slot.meal, title: slot.title, actions: [
                    MealLineAction(title: "Up", spoken: "Move \(slot.meal.name) up") { model.moveSlot(slot, by: -1) },
                    MealLineAction(title: "Down", spoken: "Move \(slot.meal.name) down") { model.moveSlot(slot, by: 1) },
                    MealLineAction(title: "Remove", spoken: "Remove \(slot.meal.name) from the template") { model.removeSlot(slot) },
                ])
            }
            if !model.slots.isEmpty { Whisper(.whyFreeDinner) } // A23: the first daily template
            if model.canAddSlot { addSlot }
        }
    }

    private var chosenMeal: MealLine? { model.meals.first(where: { $0.id == mealId }) ?? model.meals.first }

    private var addSlot: some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Text("Add a slot").font(.headline).foregroundStyle(EmberColors.inkText)
                Picker("Saved meal", selection: $mealId) {
                    ForEach(model.meals) { Text($0.name).tag($0.id) }
                }
                .tint(EmberColors.inkText)
                NutritionTextField(title: "Label (optional)", text: $label, focus: $focused, key: "slotLabel")
                SecondaryButton(title: "Add to template") {
                    focused = nil
                    if let meal = chosenMeal { model.addSlot(meal: meal, label: label); label = "" }
                }
            }
        }
        .onAppear { if mealId.isEmpty { mealId = model.meals.first?.id ?? "" } }
    }
}
