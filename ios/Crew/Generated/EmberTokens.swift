// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: 6.4 — spacing scale, the one spring curve, the haptic language (Decision Registry G5/G8 2026-09-04).

import SwiftUI

enum EmberTokens {
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
