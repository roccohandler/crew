// GENERATED FILE — DO NOT EDIT. Source: shared/design-tokens.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: 6.4 — spacing scale, the one spring curve, the haptic language (Decision Registry G5/G8 2026-09-04).

import SwiftUI

enum EmberTokens {
    /// Decision Registry G5 (2026-09-04) — 4 / 8 / 12 / 16 / 24 / 32, nothing off-scale (points on iOS, px on web)
    enum Spacing {
        static let space4: CGFloat = 4
        static let space8: CGFloat = 8
        static let space12: CGFloat = 12
        static let space16: CGFloat = 16
        static let space24: CGFloat = 24
        static let space32: CGFloat = 32
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
