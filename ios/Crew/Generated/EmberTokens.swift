// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: A28 — the type scale · 6.4 — spacing scale, the one spring curve, the haptic language (Decision Registry G5/G8 2026-09-04).

import SwiftUI

enum EmberTokens {
    /// A28 (a), (f) — the type scale of design/focus-card-system.md §4. SF Pro throughout (Display above 28 pt, Text below — the system font picks it by size). EVERY NUMERAL is SF Pro Rounded (rounded: true) — set counts, weights, reps, streak, ring, XP, targets, week and workout counts; words are never rounded. Size in points on iOS and px on web. Tracking is a FRACTION of the size (−0.05 = −5%): SwiftUI's .tracking takes points, so a view passes size × tracking; CSS writes it in em. An uppercase role renders its string uppercase and the string itself stays sentence case (VoiceOver reads the string). Scale with Dynamic Type (@ScaledMetric or .custom(_:relativeTo:)).
    enum Typography {
        /// celebration numeral — 96 pt bold, tracking -0.05, rounded
        static let celebrationNumeral = TypeRole(size: 96, weight: .bold, tracking: -0.05, rounded: true, uppercase: false)
        /// hero numeral — reps, weight — 76 pt bold, tracking -0.04, rounded
        static let heroNumeral = TypeRole(size: 76, weight: .bold, tracking: -0.04, rounded: true, uppercase: false)
        /// streak numeral — 54 pt bold, tracking -0.03, rounded
        static let streakNumeral = TypeRole(size: 54, weight: .bold, tracking: -0.03, rounded: true, uppercase: false)
        /// ring numeral and XP numeral — 46 pt bold, tracking -0.02, rounded
        static let ringNumeral = TypeRole(size: 46, weight: .bold, tracking: -0.02, rounded: true, uppercase: false)
        /// screen title — 38 pt heavy, tracking -0.03
        static let screenTitle = TypeRole(size: 38, weight: .heavy, tracking: -0.03, rounded: false, uppercase: false)
        /// screen title on a bare screen (no reward block — no-plan Home's card hero) — 44 pt heavy, tracking -0.035
        static let screenTitleBare = TypeRole(size: 44, weight: .heavy, tracking: -0.035, rounded: false, uppercase: false)
        /// celebration phrase — 30 pt heavy, tracking -0.03
        static let celebrationPhrase = TypeRole(size: 30, weight: .heavy, tracking: -0.03, rounded: false, uppercase: false)
        /// sheet title — 27 pt heavy, tracking -0.03
        static let sheetTitle = TypeRole(size: 27, weight: .heavy, tracking: -0.03, rounded: false, uppercase: false)
        /// exercise title — 24 pt bold, tracking -0.02
        static let exerciseTitle = TypeRole(size: 24, weight: .bold, tracking: -0.02, rounded: false, uppercase: false)
        /// card sub-heading — 20 pt bold, tracking -0.015
        static let cardSubheading = TypeRole(size: 20, weight: .bold, tracking: -0.015, rounded: false, uppercase: false)
        /// unit label beside a hero numeral — 22 pt semibold
        static let heroUnit = TypeRole(size: 22, weight: .semibold, tracking: 0, rounded: false, uppercase: false)
        /// body (the system's Medium half of "Medium / Semibold") — 17 pt medium
        static let body = TypeRole(size: 17, weight: .medium, tracking: 0, rounded: false, uppercase: false)
        /// body (the system's Semibold half of "Medium / Semibold") — 17 pt semibold
        static let bodySemibold = TypeRole(size: 17, weight: .semibold, tracking: 0, rounded: false, uppercase: false)
        /// secondary — 15 pt medium
        static let secondary = TypeRole(size: 15, weight: .medium, tracking: 0, rounded: false, uppercase: false)
        /// caption — 13 pt semibold
        static let caption = TypeRole(size: 13, weight: .semibold, tracking: 0, rounded: false, uppercase: false)
        /// eyebrow (uppercase), +14% — 11 pt bold, tracking 0.14, uppercase
        static let eyebrow = TypeRole(size: 11, weight: .bold, tracking: 0.14, rounded: false, uppercase: true)
        /// eyebrow under the ring and the streak, +12% — 11 pt bold, tracking 0.12, uppercase
        static let eyebrowUnderRing = TypeRole(size: 11, weight: .bold, tracking: 0.12, rounded: false, uppercase: true)
        /// Progress weekday letters, +6% — 11 pt bold, tracking 0.06, uppercase
        static let eyebrowWeekday = TypeRole(size: 11, weight: .bold, tracking: 0.06, rounded: false, uppercase: true)
        /// the primary capsule's label (system §8, Primary button) — 17 pt bold
        static let primaryLabel = TypeRole(size: 17, weight: .bold, tracking: 0, rounded: false, uppercase: false)
        /// a text button's label (system §8, Text button) — 15 pt semibold
        static let textButton = TypeRole(size: 15, weight: .semibold, tracking: 0, rounded: false, uppercase: false)
        /// tab label — the smallest type in the app (nothing below 10 pt) — 10 pt semibold
        static let tabLabel = TypeRole(size: 10, weight: .semibold, tracking: 0, rounded: false, uppercase: false)
    }

    /// One row of the type scale. `tracking` is a fraction of the size: SwiftUI's .tracking takes points, so a view passes
    /// size × tracking. `rounded` = SF Pro Rounded (every numeral); `uppercase` = the string renders uppercase.
    struct TypeRole {
        let size: CGFloat
        let weight: Font.Weight
        let tracking: CGFloat
        let rounded: Bool
        let uppercase: Bool
    }

    /// Decision Registry G5 (2026-09-04) — 4 / 8 / 12 / 16 / 24 / 32, nothing off-scale (points on iOS, px on web). A14 (2026-09-09) adds two ROLE aliases onto that same scale so macro and micro rhythm can diverge without a new number: sectionGap (24) is the gap BETWEEN groups, rowGap (8) the gap WITHIN one — a uniform 16 pt everywhere is why Home read as empty rather than composed.
    enum Spacing {
        static let space4: CGFloat = 4
        static let space8: CGFloat = 8
        static let space12: CGFloat = 12
        static let space16: CGFloat = 16
        static let space24: CGFloat = 24
        static let space32: CGFloat = 32
        static let sectionGap: CGFloat = 24
        static let rowGap: CGFloat = 8
    }

    /// GAP (agent, 2026-09-04): component sizes the spec never states, named once so no layout number is typed inline (C7 spirit); points on iOS, px on web
    enum Size {
        static let avatar: CGFloat = 40
        static let avatarLarge: CGFloat = 96
        static let ringDiameter: CGFloat = 64
        static let ringStartAngleDegrees: CGFloat = -90
        static let skeletonRow: CGFloat = 64
        static let skeletonHero: CGFloat = 128
        static let cornerRadius: CGFloat = 16
        static let hairline: CGFloat = 1
    }

    /// GAP (agent, 2026-09-04): the one opacity used for a disabled control; named so no literal is typed inline
    enum Opacity {
        static let disabled: Double = 0.5
    }

    /// 6.4 — one spring curve app-wide, defined once; values = Decision Registry G5 (2026-09-04)
    enum Motion {
        static let springResponse: Double = 0.35
        static let springDampingFraction: Double = 0.8
    }

    /// Flow 3 + 6.4 — the fixed haptic language; Shared/Haptics.swift plays exactly these.
    enum Haptic: String, CaseIterable {
        /// set done — SPEC: Flow 3 haptic language; 6.4
        case tick
        /// exercise done — SPEC: Flow 3 haptic language; 6.4
        case double
        /// workout complete — SPEC: Flow 3 haptic language; 6.4
        case thump
        /// reaction received — SPEC: 6.4; Decision Registry G8 (2026-09-04)
        case softTap
    }
}
