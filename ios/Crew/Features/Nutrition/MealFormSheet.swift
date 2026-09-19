// SPEC: nutrition addendum §4 ("Add a meal": name + P / C / F grams, manual) · §2 · clause ⑤ — a saved meal is a name and three
// whole numbers, and NOTHING else is checked: no food is judged, scored or labelled. The same sheet edits a meal and receives a chain
// item's published numbers (copied, then the user's to change). One ink primary; an error is said in ink. A28 (f) · R-093: the
// system's sheet — `card`, the grabber, the title in the content at `sheetTitle` with Cancel beside it, the 20 pt gutter, the name
// with no label stacked over it, the grams in one card. The navigation stack stays for the number pad's Done (A19.2); its bar is
// hidden. Twin of web components/nutrition/MealForm.tsx. WRITTEN — UNVERIFIED (needs Mac).

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
                    HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                        Text(draft.title).typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                        Spacer(minLength: EmberTokens.Spacing.space8)
                        TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { model.errorLine = nil; onDone() }
                    }
                    NutritionTextField(title: "Meal name", text: $draft.name, focus: $focused, key: "name")
                    GramFields(grams: $draft.grams, limit: SpecConstants.macroGramsMaxPerEntry, focus: $focused, prefix: "meal")
                    if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Spacing.space32)
                .padding(.bottom, EmberTokens.Spacing.space16)
            }
            .background(EmberColors.card.ignoresSafeArea())
            .crewBottomBar(surface: EmberColors.card) { PrimaryButton(title: "Save meal") { focused = nil; if model.save(draft) { onDone() } } } // 6.3 · 6.7: bottom-anchored
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                // A19.2 — a number pad carries no return key
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                }
            }
        }
        .tint(EmberColors.ink)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
