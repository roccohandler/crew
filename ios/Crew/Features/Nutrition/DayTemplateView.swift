// SPEC: nutrition addendum §4 (Template: up to dayTemplateMaxSlots slots — add from saved meals, reorder, remove) · §2 — the template
// is an ordered CHECKLIST of saved meals, never a requirement: nothing counts a skipped slot and nothing scores a day. Every change
// replaces the whole ordered list through the queue (SavedMealsModel). Reorder is two visible buttons, never a drag alone (6.3). The
// optional label ("Breakfast") is the user's own word. Ink only. R-093: the slots are one card of rows (the add form was the only
// card, above the content the screen exists for), and the add form's field has no stacked label. Twin of web
// components/nutrition/TemplateView.tsx.
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
                Text("A template is built from saved meals. Add one first.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            } else if model.slots.isEmpty {
                Text("Your usual day, in order. One tap on Today logs each slot.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            }
            if !model.slots.isEmpty {
                FocusCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(model.slots.enumerated()), id: \.element.id) { index, slot in
                            if index > 0 { cardSeam() }
                            MealLineRow(line: slot.meal, title: slot.title, actions: [
                                MealLineAction(title: "Up", spoken: "Move \(slot.meal.name) up") { model.moveSlot(slot, by: -1) },
                                MealLineAction(title: "Down", spoken: "Move \(slot.meal.name) down") { model.moveSlot(slot, by: 1) },
                                MealLineAction(title: "Remove", spoken: "Remove \(slot.meal.name) from the template") { model.removeSlot(slot) },
                            ])
                        }
                    }
                }
            }
            if !model.slots.isEmpty { Whisper(.whyFreeDinner) } // A23: the first daily template
            if model.canAddSlot { addSlot }
        }
    }

    private var chosenMeal: MealLine? { model.meals.first(where: { $0.id == mealId }) ?? model.meals.first }

    private var addSlot: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Text("Add a slot").typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Picker("Saved meal", selection: $mealId) {
                    ForEach(model.meals) { Text($0.name).tag($0.id) }
                }
                .tint(EmberColors.ink)
                .labelsHidden() // the menu's own value is its label; the platform's label column indented it past the card's edge
                NutritionTextField(title: "A label, like Breakfast (optional)", text: $label, focus: $focused, key: "slotLabel")
                TextActionButton(title: "Add to template", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { // A28 (f): a text button
                    focused = nil
                    if let meal = chosenMeal { model.addSlot(meal: meal, label: label); label = "" }
                }
            }
        }
        .onAppear { if mealId.isEmpty { mealId = model.meals.first?.id ?? "" } }
    }
}
