// SPEC: nutrition addendum §4 ("Quick add": three gram steppers and Add · today's log with the visible Delete, 6.3) · 6.9 Screen
// Density (A25, owner-ratified 2026-09-18 — pass/fail; R-077) — the two DESTINATIONS behind Today's buttons: each is one job on its
// own screen, one tap from Today. Quick add carries the one filled primary (Add) and returns to Today, where the lines have moved;
// the log lists today's entries, each with its own Delete, and nothing is recomputed when one goes — a log was never counted
// (clause ③). Three gram amounts and nothing else: no food is named and no food is judged (clause ⑤). Ink only; an error is ink.
// Screens hold ZERO logic (5.6.6): NutritionTodayModel — the same instance Today holds — decides.
// Twin of web nutrition/quick-add + nutrition/log (components/nutrition/DayLogViews.tsx). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct QuickAddScreen: View {
    let model: NutritionTodayModel
    let onAdded: () -> Void
    @State private var grams = MacroGrams(proteinG: 0, carbsG: 0, fatG: 0)
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                GramFields(grams: $grams, limit: SpecConstants.macroGramsMaxPerEntry, focus: $focused, prefix: "quick")
                if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
            }
            .padding(EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        // 6.3 · 6.7 (DESIGN.md 4.2) — the primary is bottom-anchored in the thumb zone; ui-reviewer failed it mid-screen (run 35347725730)
        .crewBottomBar {
            PrimaryButton(title: "Add") {
                focused = nil
                model.quickAdd(grams)
                onAdded()
            }
            .disabled(isEmpty)
        }
        .navigationTitle("Quick add")
        .navigationBarTitleDisplayMode(.inline)
        // A19.2 — a number pad carries no return key
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
    }

    private var isEmpty: Bool { grams.proteinG + grams.carbsG + grams.fatG == 0 }
}

struct NutritionLogScreen: View {
    let model: NutritionTodayModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                if model.logs.isEmpty { Text("Nothing logged yet today.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary) }
                if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                ForEach(model.logs) { log in
                    MealLineRow(line: log, actions: [MealLineAction(title: "Delete", spoken: "Delete \(log.name)") { model.deleteLog(log.id) }])
                }
            }
            .padding(EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Logged today")
        .navigationBarTitleDisplayMode(.inline)
    }
}
