// SPEC: nutrition addendum §4 — "Saved meals & template": a two-way segment [Saved meals | Template]. Saved meals: the list, "Add a
// meal" (name + P / C / F grams, by hand) and "Add from a chain" (chain → item, the chain's own published numbers copied into a meal
// the user may edit). Template: DayTemplateView. Reached from Today's text link. Ink only: no macro fill, no ember, no semantic colour
// (law ⑥'s exception) — an error is said in ink. Screens hold ZERO logic (5.6.6): SavedMealsModel decides.
// Twin of web nutrition/meals + nutrition/template. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum SavedMealsSegment: String, CaseIterable, Identifiable {
    case meals = "Saved meals"
    case template = "Template"

    var id: String { rawValue }
}

struct SavedMealsScreen: View {
    @State private var model = SavedMealsModel()
    @State private var segment = SavedMealsSegment.meals
    @State private var draft: MealDraft?
    @State private var pickingChain = false
    @State private var pickedItem: SeedFastFoodItem? // decided while the chain sheet is up, presented once it is down (the HomeScreen celebration → reminder pattern)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Picker("Saved meals or template", selection: $segment) {
                    ForEach(SavedMealsSegment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                if let error = model.errorLine { Text(error).font(.footnote.weight(.semibold)).foregroundStyle(EmberColors.inkText) }
                switch segment {
                case .meals: mealsList
                case .template: DayTemplateView(model: model)
                }
            }
            .padding(EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Saved meals & template")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refresh() }
        .sheet(item: $draft) { editing in MealFormSheet(draft: editing, model: model) { draft = nil } }
        .sheet(isPresented: $pickingChain, onDismiss: { if let item = pickedItem { pickedItem = nil; draft = model.draft(from: item) } }) {
            ChainPickerSheet(model: model) { item in pickedItem = item; pickingChain = false }
        }
    }

    private var mealsList: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            if model.meals.isEmpty {
                Text("No saved meals yet. Add the ones you eat most, once.").font(.body).foregroundStyle(EmberColors.secondaryText)
            }
            ForEach(model.meals) { meal in
                MealLineRow(line: meal, actions: [
                    MealLineAction(title: "Edit", spoken: "Edit \(meal.name)") { draft = model.draft(editing: meal) },
                    MealLineAction(title: "Delete", spoken: "Delete \(meal.name)") { model.delete(meal) },
                ])
            }
            SecondaryButton(title: "Add a meal") { draft = MealDraft.new() }
            SecondaryButton(title: "Add from a chain") { pickingChain = true }
        }
    }
}
