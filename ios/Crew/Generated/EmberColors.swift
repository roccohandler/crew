// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: A28 (a) — the Focus Card colour table: nothing in the UI uses a colour that is not on it. Ink acts; orange is a point.

import SwiftUI
import UIKit

enum EmberColors {
    /// Every page background — Varsity cream / Midnight navy · light #F7F1E4 · dark #0E1A2E
    static let canvas = emberColor(light: 0xF7F1E4, dark: 0x0E1A2E)
    /// Cards and the sheet surface — one step off the canvas (1.10:1 light, 1.21:1 dark); light lifts it with the card shadow, dark with tone alone · light #FFFCF6 · dark #1B2A42
    static let card = emberColor(light: 0xFFFCF6, dark: 0x1B2A42)
    /// NAVY ink — all text and structure, every icon and glyph, every text button, the stepper's plus and minus, the completed check, completed progress segments, heat-map done-days, day marks, the streak and ring numerals, the selected tab, and the primary capsule's fill (it inverts with the mode). 13.29 / 14.61 light and 15.05 / 12.46 dark on canvas / card · light #142744 · dark #F2EEE6
    static let ink = emberColor(light: 0x142744, dark: 0xF2EEE6)
    /// Secondary text, eyebrows, quiet fact rows, the off-season snowflake. 5.84 / 6.42 light and 7.03 / 5.82 dark on canvas / card · light #4E5E78 · dark #95A6BE
    static let inkSecondary = emberColor(light: 0x4E5E78, dark: 0x95A6BE)
    /// Muted marks — the unlit flame at zero; carries NO text below 24 pt (3.32 / 3.64 light, 3.98 / 3.29 dark on canvas / card: a graphical object, never small text) · light #7E8496 · dark #687A93
    static let inkMuted = emberColor(light: 0x7E8496, dark: 0x687A93)
    /// The seam between two rows inside a card — a boundary between surfaces, never a control's boundary · light #EFE8D9 · dark #26364E
    static let hairlineOnCard = emberColor(light: 0xEFE8D9, dark: 0x26364E)
    /// A seam drawn on the canvas (the tab bar's top rule) — a boundary between surfaces, never a control's boundary · light #E6DCC8 · dark #223049
    static let hairlineOnCanvas = emberColor(light: 0xE6DCC8, dark: 0x223049)
    /// The stepper's 1.5 pt ring. ~1.6:1 by design (§6): a control drawn with it is identified by its ink glyph, which clears 3:1 — it is never a control's only mark (R-083) · light #D3C7AE · dark #33475F
    static let controlBorder = emberColor(light: 0xD3C7AE, dark: 0x33475F)
    /// Segmented workout bar — a pending set · light #E0D6C0 · dark #27384F
    static let segmentEmpty = emberColor(light: 0xE0D6C0, dark: 0x27384F)
    /// Segmented workout bar — the current exercise's segments (also 8 pt tall against 6 pt, so height carries the state too) · light #A89C84 · dark #5A6E88
    static let segmentCurrent = emberColor(light: 0xA89C84, dark: 0x5A6E88)
    /// A row button's chevron — decoration; the row's name identifies the control · light #A89C84 · dark #5A6E88
    static let chevron = emberColor(light: 0xA89C84, dark: 0x5A6E88)
    /// The weekly ring's track — a neutral in both modes, never a tint of the accent (a wash over a 140 pt circle is a field) · light #E0D6C0 · dark #27384F
    static let ringTrack = emberColor(light: 0xE0D6C0, dark: 0x27384F)
    /// Heat map — a day with no workout (done-days are ink) · light #E4E3E1 · dark #27384F
    static let heatEmpty = emberColor(light: 0xE4E3E1, dark: 0x27384F)
    /// The tab bar's surface · light #FBF7EE · dark #12203A
    static let tabBar = emberColor(light: 0xFBF7EE, dark: 0x12203A)
    /// ORANGE IS A POINT, NOT A FIELD — exactly three places: the flame glyph (fill), the weekly ring's progress arc (stroke), the celebration's XP numeral and its unit (text). Never a background, never on a control, never behind text, never an area larger than a fingertip. One hue (27.0° / 26.9°): the dark value is the light one lifted for its ground, not a second colour — do not re-pick either. 3.15 / 3.46 light and 7.40 / 6.13 dark on canvas / card · light #DE6400 · dark #FF8A2B
    static let accent = emberColor(light: 0xDE6400, dark: 0xFF8A2B)
    /// The label on an ink fill (the primary capsule): cream on navy in light, navy on cream in dark — 14.61 / 15.05 · light #FFFCF6 · dark #0E1A2E
    static let onInk = emberColor(light: 0xFFFCF6, dark: 0x0E1A2E)
    /// Red — only inside a destructive confirm sheet, in both modes, and nowhere else. 5.88 / 6.09 on its sheet · light #BC2A1C · dark #FF8575
    static let destructive = emberColor(light: 0xBC2A1C, dark: 0xFF8575)
    /// The scrim behind a sheet — rgba(20,39,68,0.34) light, rgba(4,9,17,0.58) dark · light #142744 at 0.34 · dark #040911 at 0.58
    static let sheetScrim = emberColor(light: 0x142744, dark: 0x040911, lightOpacity: 0.34, darkOpacity: 0.58)

    // A16's bounded exception to Part III law ⑥ (nutrition surfaces only) — NOT on A28's table and NOT re-picked by it: the design system is silent on nutrition, so these stand unchanged until the Nutrition session rules on them (docs/debt.md 2026-09-19, A28). Dark carbs measures 2.79:1 on A28's dark card; dark is unreachable until the light lock lifts.
    /// Macro identity — protein (pine). Nutrition surfaces ONLY; identity, never status: it never changes with over / under / on target; never beside an ember element (law ⑥'s bounded exception). Solid fill. 8.86:1 on bone. · light #2E4E28 · dark #BDD9B9
    static let macroProtein = emberColor(light: 0x2E4E28, dark: 0xBDD9B9)
    /// Macro identity — carbs (slate). Nutrition surfaces ONLY; identity, never status. Solid fill + ink hairline. 3.32:1 on bone (a graphical object, never text). · light #5A8EB4 · dark #3D7392
    static let macroCarbs = emberColor(light: 0x5A8EB4, dark: 0x3D7392)
    /// Macro identity — fat (mulberry). Nutrition surfaces ONLY; identity, never status. Outline + hairline. 8.84:1 on bone. · light #6C315F · dark #DAADDB
    static let macroFat = emberColor(light: 0x6C315F, dark: 0xDAADDB)
    /// Macro bar track — protein · light #D9DDD4 · dark #42473D
    static let macroProteinTrack = emberColor(light: 0xD9DDD4, dark: 0x42473D)
    /// Macro bar track — carbs · light #E0E7EB · dark #212D33
    static let macroCarbsTrack = emberColor(light: 0xE0E7EB, dark: 0x212D33)
    /// Macro bar track — fat · light #E3D8DD · dark #4A3C46
    static let macroFatTrack = emberColor(light: 0xE3D8DD, dark: 0x4A3C46)

    // A28 (2026-09-19): the names screens still call colours by, each pointing at ONE row of the table above, so the whole app recolors with no screen edit. An alias carries no value of its own. Each goes when the last screen that reads it is redesigned onto the table's own names (docs/debt.md 2026-09-19, A28). Retired outright with A28 because nothing read them: secondaryButtonOutline (the pre-A18.11 hairline outline — an alias with that name would re-arm the trap A18.11 closed) and success (no green for done; a navy success invites misuse).
    /// card edges and dividers — a boundary between two surfaces; 17 of its 21 uses sit on the canvas, where the table's seam is hairlineOnCanvas (1.21:1; 1.33:1 on a card, still a seam and never a control) — the table's `hairlineOnCanvas`
    static let hairline = EmberColors.hairlineOnCanvas
    /// all text and structure — the table's `ink`
    static let inkText = EmberColors.ink
    /// the primary capsule's fill — the table's `ink`
    static let primaryButtonFill = EmberColors.ink
    /// the primary capsule's label — the table's `onInk`
    static let primaryButtonLabel = EmberColors.onInk
    /// an outline control's label — the table's `ink`
    static let secondaryButtonLabel = EmberColors.ink
    /// the boundary of a legacy OUTLINE control — A18.11's 3:1 gate holds (3.32 / 3.64 light, 3.98 / 3.29 dark) until the redesign replaces outline controls with the system's text buttons; controlBorder (~1.6:1) would fail it — the table's `inkMuted`
    static let controlOutline = EmberColors.inkMuted
    /// secondary text — the table's `inkSecondary`
    static let secondaryText = EmberColors.inkSecondary
    /// the unlit flame and missed marks — a miss is a fact, not a verdict; never red — the table's `inkMuted`
    static let missedGray = EmberColors.inkMuted
    /// the reward shapes — A28 (b) leaves only the flame glyph and the ring's arc; heat-map fills, day marks and crew dots still drawn with it turn ink in their screen's redesign — the table's `accent`
    static let ember = EmberColors.accent
    /// orange WORDS retire under A28 (b) (accent measures 3.15:1 on the canvas, below 4.5:1 for small text); the celebration's XP numeral and unit move to accent in the Logger session — the table's `ink`
    static let emberText = EmberColors.ink
    /// tints and ring tracks — A28 (b): no accent wash; the ring track is a neutral — the table's `ringTrack`
    static let emberTint = EmberColors.ringTrack
    /// red — A28 (a) confines it to destructive confirms; the error lines and delete labels still drawn with it move in their screen's redesign — the table's `destructive`
    static let danger = EmberColors.destructive
}

/// One adaptive color from the light and dark values; follows the system appearance (A28 (a): light is the default, dark is
/// supported — while the light lock of A21.10 as amended 2026-09-18 stands, the dark branch is never taken).
private func emberColor(light: UInt32, dark: UInt32, lightOpacity: CGFloat = 1, darkOpacity: CGFloat = 1) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? uiColor(hex: dark, alpha: darkOpacity) : uiColor(hex: light, alpha: lightOpacity)
    })
}

private func uiColor(hex: UInt32, alpha: CGFloat) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}
