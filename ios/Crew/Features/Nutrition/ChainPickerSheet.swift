// SPEC: nutrition addendum §4 ("Add from a chain": chain list → item list) · §5 · clause ① — the curated seed, as published by the
// chains themselves: a chain's NAME as plain text beside a neutral glyph (never a logo, never a mark, never a food photo), an item's
// name, serving label and grams. No rating, no rank, no search and no filter beyond chain → item (§8); the order is the seed's
// alphabetical sort — a sort is not a ranking. Picking an item hands its numbers to the meal form, where they are copied and the
// user's to edit. Ink only. A28 (f) · R-091: the system's sheet — `card`, the title in the content at `sheetTitle` with Cancel beside
// it, rows on the gutter (the platform's navigation-bar title and inset list on the canvas — ui-reviewer, run 35445082374); the
// items page draws its own title row too (a back chevron, the chain, Cancel) with a chevron on every item — R-095. Twin of web components/nutrition/ChainPicker.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct ChainPickerSheet: View {
    let model: SavedMealsModel
    let onPick: (SeedFastFoodItem?) -> Void   // nil = cancelled

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                        Text("Add from a chain").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Spacer(minLength: EmberTokens.Spacing.space8)
                        TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { onPick(nil) }
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(model.chains.enumerated()), id: \.element.id) { index, chain in
                            if index > 0 { cardSeam(inset: 0) }
                            NavigationLink {
                                ChainItemsList(chain: chain, items: model.items(of: chain), onPick: onPick)
                            } label: {
                                HStack(spacing: EmberTokens.Spacing.space12) {
                                    // §5 clause ①: the neutral glyph beside the name, in a fixed column so every name starts on one edge (R-095)
                                    Image(systemName: chain.icon).foregroundStyle(EmberColors.ink).frame(width: EmberTokens.Spacing.space24).accessibilityHidden(true)
                                    Text(chain.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                                    Spacer(minLength: EmberTokens.Spacing.space8)
                                    Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron).accessibilityHidden(true)
                                }
                                .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(chain.name)
                        }
                    }
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Spacing.space32)
                .padding(.bottom, EmberTokens.Spacing.space24)
            }
            .background(EmberColors.card.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
        .tint(EmberColors.ink)
    }
}

struct ChainItemsList: View {
    let chain: SeedFastFoodChain
    let items: [SeedFastFoodItem]
    let onPick: (SeedFastFoodItem?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.body.weight(.semibold)).foregroundStyle(EmberColors.ink)
                            .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back to the chains")
                    Text(chain.name).typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { onPick(nil) }
                }
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { cardSeam(inset: 0) }
                        row(item)
                    }
                }
                Text("Numbers are \(chain.name)'s own published nutrition facts.").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space32)
            .padding(.bottom, EmberTokens.Spacing.space24)
        }
        .background(EmberColors.card.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func row(_ item: SeedFastFoodItem) -> some View {
        let grams = MacroGrams(proteinG: item.proteinG, carbsG: item.carbsG, fatG: item.fatG)
        return Button { onPick(item) } label: {
            HStack(spacing: EmberTokens.Spacing.space8) {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                    Text(item.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    Text(item.servingLabel).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                }
                Spacer(minLength: EmberTokens.Spacing.space8)
                Text(numerals: MacroDay.gramsText(grams)).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).lineLimit(1)
                Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron).accessibilityHidden(true) // a tap saves it as a meal (A27)
            }
            .padding(.vertical, EmberTokens.Spacing.space12)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(item.servingLabel), \(MacroDay.gramsSpoken(grams))")
    }
}
