// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: Part III — the Ember color system. Ink acts, Ember rewards.

import SwiftUI
import UIKit

enum EmberColors {
    /// 70% Canvas — every page background (Bone) · light #FAF8F5 · dark #171412
    static let canvas = emberColor(light: 0xFAF8F5, dark: 0x171412)
    /// 70% Canvas — cards · light #FFFFFF · dark #211D19
    static let card = emberColor(light: 0xFFFFFF, dark: 0x211D19)
    /// 70% Canvas — hairlines · light #E9E4DD · dark #2E2822
    static let hairline = emberColor(light: 0xE9E4DD, dark: 0x2E2822)
    /// 20% Ink — ALL text and structure · light #211D19 · dark #F5F1EB
    static let inkText = emberColor(light: 0x211D19, dark: 0xF5F1EB)
    /// 20% Ink — primary button fill (ink acts; ≈15:1 on canvas) · light #211D19 · dark #F5F1EB
    static let primaryButtonFill = emberColor(light: 0x211D19, dark: 0xF5F1EB)
    /// 20% Ink — primary button label · light #FAF8F5 · dark #171412
    static let primaryButtonLabel = emberColor(light: 0xFAF8F5, dark: 0x171412)
    /// 20% Ink — secondary button = hairline outline · light #E9E4DD · dark #2E2822
    static let secondaryButtonOutline = emberColor(light: 0xE9E4DD, dark: 0x2E2822)
    /// 20% Ink — secondary button = ink label · light #211D19 · dark #F5F1EB
    static let secondaryButtonLabel = emberColor(light: 0x211D19, dark: 0xF5F1EB)
    /// 20% Ink — secondary text · light #6F6860 · dark #A69E94
    static let secondaryText = emberColor(light: 0x6F6860, dark: 0xA69E94)
    /// 20% Ink — missed = warm gray, never red; recedes on dark · light #A8A29A · dark #5E574F
    static let missedGray = emberColor(light: 0xA8A29A, dark: 0x5E574F)
    /// ≤10% Ember — SHAPES only: streak flame, XP count-ups, ring & heat-map fills, PR/comeback/celebration accents; dark lifts, never inverts · light #FF6600 · dark #FF7A1F
    static let ember = emberColor(light: 0xFF6600, dark: 0xFF7A1F)
    /// ≤10% Ember — any orange WORDS (#FF6600 fails WCAG on light; #FF7A1F clears 4.5:1 on dark) · light #B84D00 · dark #FF7A1F
    static let emberText = emberColor(light: 0xB84D00, dark: 0xFF7A1F)
    /// ≤10% Ember — tints & ring tracks · light #FFEFE3 · dark #33241A
    static let emberTint = emberColor(light: 0xFFEFE3, dark: 0x33241A)
    /// Semantic — success (single value in spec; both modes) · light #3E8E5A · dark #3E8E5A
    static let success = emberColor(light: 0x3E8E5A, dark: 0x3E8E5A)
    /// Semantic — danger (berry, never near orange; single value in spec; both modes) · light #D64550 · dark #D64550
    static let danger = emberColor(light: 0xD64550, dark: 0xD64550)
}

/// One adaptive color from the light and dark hex values; follows the system appearance.
private func emberColor(light: UInt32, dark: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? uiColor(hex: dark) : uiColor(hex: light)
    })
}

private func uiColor(hex: UInt32) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}
