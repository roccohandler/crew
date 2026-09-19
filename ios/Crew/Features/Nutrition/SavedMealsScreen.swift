// SPEC: nutrition addendum §4 — Saved meals: the list, "Add a meal" (name + P / C / F grams, by hand) and "Add from a chain" (chain
// → item, the chain's own published numbers copied into a meal the user may edit); Template: DayTemplateView. A27's screen jobs
// (owner-ratified 2026-09-18) name them as TWO screens with two jobs, and the addendum's two-way segment is not on A28 (f)'s kit, so
// Today opens each from its own row (R-093); this one screen type draws whichever it was opened for. The rows sit in one card on the
// 20 pt gutter. Ink only: no macro fill, no ember, no semantic colour (law ⑥'s exception) — an error is said in ink. Screens hold ZERO
// logic (5.6.6): SavedMealsModel decides. Twin of web nutrition/meals + nutrition/template. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum SavedMealsSegment: String, CaseIterable, Identifiable {
    case meals = "Saved meals"
    case template = "Template"

    var id: String { rawValue }
}

struct SavedMealsScreen: View {
    let segment: SavedMealsSegment
    @State private var model = SavedMealsModel()
    @State private var draft: MealDraft?
    @State private var pickingChain = false
    @State private var pickedItem: SeedFastFoodItem? // decided while the chain sheet is up, presented once it is down (the HomeScreen celebration → reminder pattern)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                switch segment {
                case .meals: mealsList
                case .template: DayTemplateView(model: model)
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(segment.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refresh() }
        .sheet(item: $draft) { editing in MealFormSheet(draft: editing, model: model) { draft = nil } }
        .sheet(isPresented: $pickingChain, onDismiss: { if let item = pickedItem { pickedItem = nil; draft = model.draft(from: item) } }) {
            ChainPickerSheet(model: model) { item in pickedItem = item; pickingChain = false }
        }
    }

    private var mealsList: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            if model.meals.isEmpty {
                Text("No saved meals yet. Add the ones you eat most, once.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            } else {
                FocusCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(model.meals.enumerated()), id: \.element.id) { index, meal in
                            if index > 0 { cardSeam() }
                            MealLineRow(line: meal, actions: [
                                MealLineAction(title: "Edit", spoken: "Edit \(meal.name)") { draft = model.draft(editing: meal) },
                                MealLineAction(title: "Delete", spoken: "Delete \(meal.name)") { model.delete(meal) },
                            ])
                        }
                    }
                }
            }
            // A28 (f): the two ways in are text buttons (the outline button is not on the list), on the gutter's edge
            TextActionButton(title: "Add a meal", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { draft = MealDraft.new() }
            TextActionButton(title: "Add from a chain", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { pickingChain = true }
        }
    }
}
