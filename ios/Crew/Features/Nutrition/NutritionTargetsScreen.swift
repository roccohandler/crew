// SPEC: nutrition addendum §4 (Settings → Nutrition targets: bodyweight, the three grams, Recalculate — Q1: no goal) · §3 (every
// number is the user's to overwrite; the derivation is offered again only by "Recalculate") · E1's one exception. With no targets yet
// the screen is one number and one button. One ink primary; an error is said in ink — no macro fill, no semantic colour, no ember
// (law ⑥'s exception). R-093: the bodyweight is a number with its unit word beside it, the grams sit in one card, the page link is a
// text button, the page is on the 20 pt gutter. Screens hold ZERO logic (5.6.6): NutritionTargetsModel decides. Twin of web nutrition/targets.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct NutritionTargetsScreen: View {
    @State private var model = NutritionTargetsModel()
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                NutritionTextField(title: "Bodyweight", text: $model.bodyweightText, keyboard: .decimalPad, unit: model.weightUnit, focus: $focused, key: "bodyweight")
                Text("Used for the estimate and nothing else. Only you can see it.").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                if model.hasTargets { GramFields(grams: $model.grams, limit: SpecConstants.macroTargetGramsMax, focus: $focused, prefix: "target"); Whisper(.whyProtein) } // A23
                if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                if let saved = model.savedLine { Text(saved).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary) }
                if model.hasTargets { TextActionButton(title: "Recalculate from bodyweight", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { focused = nil; model.save(manual: false) } } // A28 (f): a text button
                if let source = model.sourceLine, let estimate = model.estimateLine {
                    Text("\(source) \(estimate)").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                }
                if let overage = model.overageLine { Text(overage).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary) }
                MethodLink()
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        // 6.3 · 6.7 (DESIGN.md 4.2) — the one primary is bottom-anchored; ui-reviewer failed it mid-screen (run 35347725730)
        .crewBottomBar {
            if model.hasTargets {
                PrimaryButton(title: "Save targets") { focused = nil; model.save(manual: true) }
            } else {
                PrimaryButton(title: "Estimate my targets") { focused = nil; model.save(manual: false) }
            }
        }
        .navigationTitle("Nutrition targets")
        .navigationBarTitleDisplayMode(.inline)
        // A19.2 — a number pad carries no return key
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .task { await model.open() }
    }
}
