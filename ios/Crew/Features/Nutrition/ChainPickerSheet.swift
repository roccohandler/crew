// SPEC: nutrition addendum §4 ("Add from a chain": chain list → item list) · §5 · clause ① — the curated seed, as published by the
// chains themselves: a chain's NAME as plain text beside a neutral glyph (never a logo, never a mark, never a food photo), an item's
// name, serving label and grams. No rating, no rank, no search and no filter beyond chain → item (§8); the order is the seed's
// alphabetical sort — a sort is not a ranking. Picking an item hands its numbers to the meal form, where they are copied and the
// user's to edit. Ink only. Twin of web components/nutrition/ChainPicker.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct ChainPickerSheet: View {
    let model: SavedMealsModel
    let onPick: (SeedFastFoodItem?) -> Void   // nil = cancelled

    var body: some View {
        NavigationStack {
            List(model.chains) { chain in
                NavigationLink {
                    ChainItemsList(chain: chain, items: model.items(of: chain), onPick: onPick)
                } label: {
                    Label { Text(chain.name).foregroundStyle(EmberColors.ink) } icon: { Image(systemName: chain.icon).foregroundStyle(EmberColors.ink) }
                }
                .listRowBackground(EmberColors.card)
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Add from a chain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onPick(nil) } } }
        }
    }
}

struct ChainItemsList: View {
    let chain: SeedFastFoodChain
    let items: [SeedFastFoodItem]
    let onPick: (SeedFastFoodItem?) -> Void

    var body: some View {
        List {
            Section {
                ForEach(items) { item in
                    Button { onPick(item) } label: {
                        HStack(spacing: EmberTokens.Spacing.space8) {
                            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                                Text(item.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                                Text(item.servingLabel).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                            }
                            Spacer(minLength: EmberTokens.Spacing.space8)
                            Text(numerals: MacroDay.gramsText(MacroGrams(proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG))).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink).lineLimit(1)
                        }
                    }
                    .accessibilityLabel("\(item.name), \(item.servingLabel), \(MacroDay.gramsSpoken(MacroGrams(proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG)))")
                    .listRowBackground(EmberColors.card)
                }
            } footer: {
                Text("Numbers are \(chain.name)'s own published nutrition facts.").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(chain.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
