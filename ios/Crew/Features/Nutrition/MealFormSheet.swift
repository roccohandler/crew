// SPEC: nutrition addendum §4 ("Add a meal": name + P / C / F grams, manual) · §2 · clause ⑤ — a saved meal is a name and three
// whole numbers, and NOTHING else is checked: no food is judged, scored or labelled. The same sheet edits a meal and receives a chain
// item's published numbers (copied, then the user's to change). One ink primary; an error is said in ink.
// Twin of web components/nutrition/MealForm.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct MealFormSheet: View {
    @State var draft: MealDraft
    let model: SavedMealsModel
    let onDone: () -> Void
    @FocusState private var focused: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    NutritionTextField(title: "Name", text: $draft.name, focus: $focused, key: "name")
                    GramFields(grams: $draft.grams, limit: SpecConstants.macroGramsMaxPerEntry, focus: $focused, prefix: "meal")
                    if let error = model.errorLine { Text(error).font(.footnote.weight(.semibold)).foregroundStyle(EmberColors.inkText) }
                }
                .padding(EmberTokens.Spacing.space24)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .crewBottomBar { PrimaryButton(title: "Save meal") { focused = nil; if model.save(draft) { onDone() } } } // 6.3 · 6.7: bottom-anchored
            .navigationTitle(draft.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.errorLine = nil; onDone() } }
                // A19.2 — a number pad carries no return key
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                }
            }
        }
    }
}
