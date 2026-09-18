// SPEC: A26 (owner-approved 2026-09-18) — every place an exercise row shows its equipment tag (the plan reveal, the plan
// editor's rows and its exercise sheet, the session, the swap lists) draws the tag's SF Symbol beside the word. ONE mapping:
// shared/seed/exercises.json enums.equipmentSymbol → Generated/SeedData.swift → SeedCatalog.equipmentSymbol; no asset, no
// dependency, and a tag the mapping does not know draws the word alone. Ink only (Part III law ①: nothing here is a
// reward, so nothing here is ember) — the symbol takes the word's own secondary ink and is hidden from VoiceOver, which
// already reads the word. S04 (every exercise shows its equipment chip) · Flow 3 (the setup cue line stays where it was).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct EquipmentLabel: View {
    let equipment: String

    static func symbol(for equipment: String) -> String? { SeedCatalog.shared.equipmentSymbol[equipment] }

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space4) {
            if let symbol = Self.symbol(for: equipment) { Image(systemName: symbol).accessibilityHidden(true) }
            Text(equipment.capitalized)
        }
        .font(.caption)
        .foregroundStyle(EmberColors.secondaryText)
    }
}

// The outlined capsule the reveal and the exercise sheet draw around the label. The hairline is a surface seam here, not a
// control's boundary (the chip is not tappable) — it is one of contrast.test.ts's five allow-listed hairlines.
struct EquipmentChip: View {
    let equipment: String

    var body: some View {
        EquipmentLabel(equipment: equipment)
            .padding(.horizontal, EmberTokens.Spacing.space8)
            .padding(.vertical, EmberTokens.Spacing.space4)
            .overlay(Capsule().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
    }
}
