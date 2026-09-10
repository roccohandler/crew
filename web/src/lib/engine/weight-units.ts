// SPEC: A9 (owner-directed 2026-09-09) — a logged weight is stored in the unit it was ENTERED in, so a preference change
// is cosmetic and never reinterprets history. weightIn(value, from, to) converts for display and for comparison; it snaps
// to the loadable increment of the target unit (weightDisplayScaleLb halves, weightDisplayScaleKg quarters) with integer
// arithmetic so both engines print the same digit — JS toFixed and Swift rounding disagree on an exact binary half (the
// distanceDecimalScale precedent, A2). normalizedForCompare puts two weights on one scale so PR detection and strength
// trends never fire a false best across a unit change. Twin of ios/Crew/Engine/WeightUnits.swift.
import { SpecConstants } from "@/generated/spec-constants";

export type WeightUnit = "lb" | "kg";

// SPEC: A9 — the display scale of a unit: halves for lb, quarters for kg
export function displayScale(unit: WeightUnit): number {
  return unit === "kg" ? SpecConstants.weightDisplayScaleKg : SpecConstants.weightDisplayScaleLb;
}

// SPEC: A9 — round half-up to a scale, the same way distanceText rounds to tenths: Math.round in TS, .rounded() in Swift.
// Both are half-up for a non-negative value, and a weight is never negative.
function roundToScale(value: number, scale: number): number {
  return Math.round(value * scale) / scale;
}

// SPEC: A9 — convert a weight between units and snap to the target unit's loadable increment. Same unit = unchanged:
// a number the user typed is never re-rounded by a no-op conversion.
export function weightIn(value: number, from: WeightUnit, to: WeightUnit): number {
  if (from === to) return value;
  const scaled = SpecConstants.kilogramsPerPoundScaled;
  const divisor = SpecConstants.weightConversionScale;
  const converted = from === "lb" ? (value * scaled) / divisor : (value * divisor) / scaled;
  return roundToScale(converted, displayScale(to));
}

// SPEC: A9 — PR detection and strength trends compare on ONE unit. Comparison uses the raw converted value, never the
// display-snapped one: snapping two nearby weights to the same quarter-kilo would hide a real record.
export function normalizedForCompare(value: number, unit: WeightUnit): number {
  if (unit === "kg") return value;
  return (value * SpecConstants.kilogramsPerPoundScaled) / SpecConstants.weightConversionScale;
}
