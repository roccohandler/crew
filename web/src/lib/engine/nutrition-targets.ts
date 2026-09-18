// SPEC: nutrition addendum §3 (RATIFIED 2026-09-18; Q1: maintenance only — there is no goal) · A16 (protein first, the fat floor) ·
// V57–V60, V64. deriveTargets(bodyweight, unit) → energy, protein, fat, carbs: an ESTIMATE the user may overwrite, never a
// prescription. Integer arithmetic end to end (the distanceDecimalScale precedent): a bodyweight is TENTHS of its unit, kilograms
// are carried as hundredths, every factor is a named constant, and grams round half-up to macroGramsRoundTo — so Swift and
// TypeScript print the same digit. Twin: ios/Crew/Engine/NutritionTargets.swift — identical names. Pure.
import { SpecConstants } from "@/generated/spec-constants";
import type { WeightUnit } from "@/lib/engine/weight-units";

export interface MacroTargets {
  energyKcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  carbsOverageKcal: number; // > 0 only when protein and fat alone exceed the energy: carbs floor at 0 and the overage is STATED (V60)
}

// SPEC: §2 · E1 — the one object that holds the bodyweight: there is no bodyweight apart from the targets (V64)
export interface TargetsFacts {
  bodyweightTenths: number;
  unit: WeightUnit;
  proteinG: number;
  carbsG: number;
  fatG: number;
  source: "derived" | "manual";
}

// SPEC: §3 rounding — the nearest multiple of `step` to numerator / denominator, half up, integers only
export function roundToStep(numerator: number, denominator: number, step: number): number {
  const unit = denominator * step;
  const whole = Math.floor(numerator / unit);
  const remainder = numerator - whole * unit;
  return (remainder + remainder >= unit ? whole + 1 : whole) * step;
}

// SPEC: A9 · §3 — a bodyweight in tenths of its unit → hundredths of a kilogram (the exact international pound, half-up)
export function kilogramHundredths(bodyweightTenths: number, unit: WeightUnit): number {
  const hundredths = (bodyweightTenths * SpecConstants.bodyweightKilogramScale) / SpecConstants.bodyweightEntryScale;
  if (unit === "kg") return hundredths;
  return roundToStep(hundredths * SpecConstants.kilogramsPerPoundScaled, SpecConstants.weightConversionScale, 1);
}

// SPEC: §3 carbs — what the energy leaves after protein and fat, floored at 0; a floor hit is a measurement on its own line (V60)
export function carbs(energyKcal: number, proteinG: number, fatG: number): { carbsG: number; carbsOverageKcal: number } {
  const left = energyKcal - proteinG * SpecConstants.kcalPerGramProtein - fatG * SpecConstants.kcalPerGramFat;
  if (left <= 0) return { carbsG: 0, carbsOverageKcal: Math.max(0, -left) };
  return { carbsG: roundToStep(left, SpecConstants.kcalPerGramCarbs, SpecConstants.macroGramsRoundTo), carbsOverageKcal: 0 };
}

// SPEC: §3 — energy = kg × kcalPerKgMaintenance · protein = kg × 1.8 · fat = max(20 % of energy, 0.5 g/kg) · carbs = the rest.
// R-074: the energy rounds to energyKcalRoundTo, so 80 kg and 176 lb derive the same four lines (V58) and an estimate never reads
// as a measurement; with the ratified factors the fat floor is a guard that never binds (0.73 g/kg from energy > 0.5 g/kg) — V59.
export function deriveTargets(bodyweightTenths: number, unit: WeightUnit): MacroTargets {
  const kg = kilogramHundredths(bodyweightTenths, unit);
  const perKgScale = SpecConstants.bodyweightKilogramScale * SpecConstants.macroFactorScale;
  const energyKcal = roundToStep(kg * SpecConstants.kcalPerKgMaintenance, SpecConstants.bodyweightKilogramScale, SpecConstants.energyKcalRoundTo);
  const proteinG = roundToStep(kg * SpecConstants.proteinGramsPerKgScaled, perKgScale, SpecConstants.macroGramsRoundTo);
  const fatFromEnergy = roundToStep(energyKcal * SpecConstants.fatFloorPercentOfEnergy, SpecConstants.macroPercentScale * SpecConstants.kcalPerGramFat, SpecConstants.macroGramsRoundTo);
  const fatFloor = roundToStep(kg * SpecConstants.fatFloorGramsPerKgScaled, perKgScale, SpecConstants.macroGramsRoundTo);
  const fatG = Math.max(fatFromEnergy, fatFloor);
  return { energyKcal, proteinG, fatG, ...carbs(energyKcal, proteinG, fatG) };
}

// SPEC: §2 · E1 · V64 — the bodyweight is read OUT OF the targets; delete the targets and no bodyweight is left anywhere
export function bodyweightOf(facts: TargetsFacts | null): { bodyweightTenths: number; unit: WeightUnit } | null {
  return facts === null ? null : { bodyweightTenths: facts.bodyweightTenths, unit: facts.unit };
}
