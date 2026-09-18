// SPEC: R-074 (3) — the bodyweight bound is a TYPO bound (30–300 kg), checked in kilograms whichever unit was typed, by the form and
// by the validator with the same arithmetic. Twin of ios/CrewTests/NutritionTargetsTests.swift. (V57–V60, V64 pin the derivation.)
import { describe, expect, it } from "vitest";
import { bodyweightInBounds, bodyweightTenthsFrom } from "@/lib/engine/nutrition-targets";

describe("bodyweightTenthsFrom", () => {
  it("reads what a person types, with a point or a comma, to one decimal", () => {
    expect(bodyweightTenthsFrom("176", "lb")).toBe(1760);
    expect(bodyweightTenthsFrom(" 80.5 ", "kg")).toBe(805);
    expect(bodyweightTenthsFrom("80,5", "kg")).toBe(805);
    expect(bodyweightTenthsFrom("80.25", "kg")).toBe(803); // half-up to tenths
  });

  it("refuses what is not a number, and what is not a bodyweight", () => {
    expect(bodyweightTenthsFrom("", "kg")).toBeNull();
    expect(bodyweightTenthsFrom("eighty", "kg")).toBeNull();
    expect(bodyweightTenthsFrom("-80", "kg")).toBeNull();
    expect(bodyweightTenthsFrom("8", "kg")).toBeNull(); // a typo, not a judgement
    expect(bodyweightTenthsFrom("1760", "lb")).toBeNull();
  });
});

describe("bodyweightInBounds", () => {
  it("holds the two kilogram bounds exactly", () => {
    expect(bodyweightInBounds(300, "kg")).toBe(true); // 30.0 kg
    expect(bodyweightInBounds(299, "kg")).toBe(false); // 29.9 kg
    expect(bodyweightInBounds(3000, "kg")).toBe(true); // 300.0 kg
    expect(bodyweightInBounds(3001, "kg")).toBe(false); // 300.1 kg
  });

  it("checks pounds in kilograms", () => {
    expect(bodyweightInBounds(661, "lb")).toBe(false); // 66.1 lb = 29.98 kg
    expect(bodyweightInBounds(662, "lb")).toBe(true); // 66.2 lb = 30.03 kg
    expect(bodyweightInBounds(6613, "lb")).toBe(true); // 661.3 lb = 299.96 kg
    expect(bodyweightInBounds(6615, "lb")).toBe(false); // 661.5 lb = 300.05 kg
  });
});
