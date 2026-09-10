// SPEC: A9 — the conversion twin. Every assertion here has an identical assertion in
// ios/CrewTests/WeightUnitsTests.swift: the two engines must print the same digit (8.1).
import { describe, expect, it } from "vitest";
import { displayScale, normalizedForCompare, weightIn, type WeightUnit } from "@/lib/engine/weight-units";
import { SpecConstants } from "@/generated/spec-constants";

describe("weightIn", () => {
  it("leaves a weight untouched when the unit does not change", () => {
    // the number the user typed is never re-rounded by a no-op conversion
    expect(weightIn(137.5, "lb", "lb")).toBe(137.5);
    expect(weightIn(102.3, "kg", "kg")).toBe(102.3);
  });

  it("converts pounds to kilograms and snaps to the quarter", () => {
    expect(weightIn(225, "lb", "kg")).toBe(102); // 102.0582 -> 102.00
    expect(weightIn(135, "lb", "kg")).toBe(61.25); // 61.2350 -> 61.25
    expect(weightIn(45, "lb", "kg")).toBe(20.5); // 20.4116 -> 20.50
  });

  it("converts kilograms to pounds and snaps to the half", () => {
    expect(weightIn(100, "kg", "lb")).toBe(220.5); // 220.4623 -> 220.5
    expect(weightIn(20, "kg", "lb")).toBe(44); // 44.0925 -> 44.0
    expect(weightIn(60, "kg", "lb")).toBe(132.5); // 132.2774 -> 132.5
  });

  it("round-trips within one display increment", () => {
    // the snap is lossy by design; what must hold is that a value never drifts away over a round trip
    for (const lb of [45, 95, 135, 185, 225, 315, 405]) {
      const back = weightIn(weightIn(lb, "lb", "kg"), "kg", "lb");
      expect(Math.abs(back - lb)).toBeLessThanOrEqual(1 / SpecConstants.weightDisplayScaleLb);
    }
  });

  it("handles the boundaries without a special case", () => {
    expect(weightIn(0, "lb", "kg")).toBe(0);
    expect(weightIn(SpecConstants.setWeightMax, "lb", "kg")).toBe(453.5); // 453.59237 -> 453.50
  });

  it("names the loadable increment of each unit", () => {
    expect(displayScale("lb")).toBe(SpecConstants.weightDisplayScaleLb);
    expect(displayScale("kg")).toBe(SpecConstants.weightDisplayScaleKg);
  });
});

describe("normalizedForCompare", () => {
  it("puts both units on the kilogram scale", () => {
    expect(normalizedForCompare(100, "kg")).toBe(100);
    expect(normalizedForCompare(225, "lb")).toBeCloseTo(102.05828325, 6);
  });

  it("does not snap, so a real record is never hidden", () => {
    // 225 lb and 226 lb both snap to 102.5 kg for display; compared, they must still differ
    const a = normalizedForCompare(225, "lb");
    const b = normalizedForCompare(226, "lb");
    expect(b).toBeGreaterThan(a);
  });

  it("orders a heavier lb lift above a lighter kg lift", () => {
    // the defect this closes: before A9 a unit switch fired a false "new best" in one direction
    const lb225 = normalizedForCompare(225, "lb");
    const kg100 = normalizedForCompare(100, "kg");
    expect(lb225).toBeGreaterThan(kg100);
  });

  it("is monotonic within a unit", () => {
    const units: WeightUnit[] = ["lb", "kg"];
    for (const unit of units) {
      expect(normalizedForCompare(50, unit)).toBeLessThan(normalizedForCompare(51, unit));
    }
  });
});
