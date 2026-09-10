// SPEC: A9 (owner-directed 2026-09-09) — a logged weight is stored in the unit it was ENTERED in, so a preference change
// is cosmetic and never reinterprets history. weightIn(_:from:to:) converts for display and for comparison; it snaps to
// the loadable increment of the target unit (weightDisplayScaleLb halves, weightDisplayScaleKg quarters) with integer
// arithmetic so both engines print the same digit — JS toFixed and Swift rounding disagree on an exact binary half (the
// distanceDecimalScale precedent, A2). normalizedForCompare puts two weights on one scale so PR detection and strength
// trends never fire a false best across a unit change. Twin of web/src/lib/engine/weight-units.ts.

import Foundation

enum WeightUnits {
    // SPEC: A9 — the display scale of a unit: halves for lb, quarters for kg
    static func displayScale(_ unit: String) -> Int {
        unit == "kg" ? SpecConstants.weightDisplayScaleKg : SpecConstants.weightDisplayScaleLb
    }

    // SPEC: A9 — round half-up to a scale, the same way SessionSummaryLine rounds to tenths: .rounded() in Swift,
    // Math.round in TS. Both are half-up for a non-negative value, and a weight is never negative.
    private static func roundToScale(_ value: Double, _ scale: Int) -> Double {
        (value * Double(scale)).rounded() / Double(scale)
    }

    // SPEC: A9 — convert a weight between units and snap to the target unit's loadable increment. Same unit = unchanged:
    // a number the user typed is never re-rounded by a no-op conversion.
    static func weightIn(_ value: Double, from: String, to: String) -> Double {
        guard from != to else { return value }
        let scaled = Double(SpecConstants.kilogramsPerPoundScaled)
        let divisor = Double(SpecConstants.weightConversionScale)
        let converted = from == "lb" ? value * scaled / divisor : value * divisor / scaled
        return roundToScale(converted, displayScale(to))
    }

    // SPEC: A9 — PR detection and strength trends compare on ONE unit. Comparison uses the raw converted value, never the
    // display-snapped one: snapping two nearby weights to the same quarter-kilo would hide a real record.
    static func normalizedForCompare(_ value: Double, unit: String) -> Double {
        guard unit != "kg" else { return value }
        return value * Double(SpecConstants.kilogramsPerPoundScaled) / Double(SpecConstants.weightConversionScale)
    }
}
