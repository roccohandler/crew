// SPEC: A16.c · nutrition addendum §6 · A22 G3 (owner-approved 2026-09-18: an under-18 account has NO nutrition surface) · V65.
// availability(birthYear, currentYear): at nutritionAdultAgeYears or older → available; no birth year on the account (a Sign in
// with Apple account, or one made before the year was stored) → askBirthYear, once, when Nutrition is opened — never at launch;
// younger → absent: no row, no copy, no upsell, no "unlock at 18". The same year arithmetic requireSignupGates uses.
// Twin: ios/Crew/Engine/NutritionGate.swift — identical names. Pure.
import { SpecConstants } from "@/generated/spec-constants";

export type NutritionAvailability = "available" | "askBirthYear" | "absent";

export function availability(birthYear: number | null, currentYear: number): NutritionAvailability {
  if (birthYear === null) return "askBirthYear";
  return currentYear - birthYear >= SpecConstants.nutritionAdultAgeYears ? "available" : "absent";
}
