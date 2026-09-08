// SPEC: Flow 3 plate math — tap-hold a barbell weight → "45 + 25 + 2.5 per side". Greedy from the heaviest plate; a total
// that the plate set cannot make exactly reports the nearest reachable total below it. Twin: ios/Crew/Engine/PlateMath.swift.
import { SpecConstants } from "@/generated/spec-constants";

export interface PlateBreakdown {
  perSide: number[];
  reachableTotal: number;
  exact: boolean;
}

export function platesPerSide(totalWeight: number, units: "lb" | "kg"): PlateBreakdown {
  const bar = units === "lb" ? SpecConstants.barbellBarWeightLb : SpecConstants.barbellBarWeightKg;
  const plates = units === "lb" ? SpecConstants.plateSetLb : SpecConstants.plateSetKg;
  const perSide: number[] = [];
  let remaining = Math.max(0, totalWeight - bar) / (1 + 1);
  for (const plate of plates) {
    while (remaining + Number.EPSILON >= plate) {
      perSide.push(plate);
      remaining -= plate;
    }
  }
  const loaded = perSide.reduce((sum, plate) => sum + plate, 0);
  const reachableTotal = bar + loaded + loaded;
  return { perSide, reachableTotal, exact: Math.abs(reachableTotal - totalWeight) < Number.EPSILON && totalWeight >= bar };
}

export function plateLine(totalWeight: number, units: "lb" | "kg"): string {
  const breakdown = platesPerSide(totalWeight, units);
  if (breakdown.perSide.length === 0) return "just the bar";
  return `${breakdown.perSide.join(" + ")} per side`;
}
