// SPEC: nutrition addendum §4 (Settings → Nutrition targets: bodyweight, the three grams, Recalculate — Q1: no goal) · §3 (every
// number is the user's to overwrite; the derivation is offered again only by "Recalculate") · E1's one exception. With no targets yet
// the screen is one number and one button. One ink primary; an error is said in ink — no macro fill, no semantic colour, no ember
// (law ⑥'s exception). Screens hold ZERO logic (5.6.6): NutritionTargetsModel decides. Twin of web nutrition/targets.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct NutritionTargetsScreen: View {
    @State private var model = NutritionTargetsModel()
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                NutritionTextField(title: "Bodyweight (\(model.weightUnit))", text: $model.bodyweightText, keyboard: .decimalPad, focus: $focused, key: "bodyweight")
                Text("Used for the estimate and nothing else. Only you can see it.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                if model.hasTargets { GramFields(grams: $model.grams, limit: SpecConstants.macroTargetGramsMax, focus: $focused, prefix: "target"); Whisper(.whyProtein) } // A23
                if let error = model.errorLine { Text(error).font(.footnote.weight(.semibold)).foregroundStyle(EmberColors.inkText) }
                if let saved = model.savedLine { Text(saved).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                if model.hasTargets { SecondaryButton(title: "Recalculate from bodyweight") { focused = nil; model.save(manual: false) } }
                if let source = model.sourceLine, let estimate = model.estimateLine {
                    Text("\(source) \(estimate)").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                }
                if let overage = model.overageLine { Text(overage).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                NavigationLink("How targets are estimated") { NutritionMethodScreen() }.foregroundStyle(EmberColors.inkText)
            }
            .padding(EmberTokens.Spacing.space16)
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
