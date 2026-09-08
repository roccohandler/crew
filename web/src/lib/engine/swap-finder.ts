// SPEC: Flow 1 step 4 (Tap → Swap → 3–5 alternatives that do the same job; no questions asked) · 5.6.1 swapCandidates
// (same pattern, ≤5, never incumbent) · 8.3 (candidates share pattern + equipment) · exercises.json swapRule (tiers
// swapGroup → pattern → region, widening only while fewer than swapCandidatesMin exist; same-or-lower level ranked first).
// Twin: ios/Crew/Engine/SwapFinder.swift. Pure.
import type { EquipmentAccess, Experience, SeedExercise } from "@/generated/seed";
import { equipmentAccess, regionOfPattern } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const LEVEL_RANK: Record<Experience, number> = { brandNew: 0, some: 1, experienced: 2 };

function rankForUser(experience: Experience) {
  return (left: SeedExercise, right: SeedExercise): number => {
    const leftFits = LEVEL_RANK[left.level] <= LEVEL_RANK[experience] ? 0 : 1;
    const rightFits = LEVEL_RANK[right.level] <= LEVEL_RANK[experience] ? 0 : 1;
    if (leftFits !== rightFits) return leftFits - rightFits;
    return LEVEL_RANK[left.level] - LEVEL_RANK[right.level] || left.name.localeCompare(right.name);
  };
}

export function swapCandidates(incumbent: SeedExercise, access: EquipmentAccess, experience: Experience, exercises: SeedExercise[]): SeedExercise[] {
  const available = new Set(equipmentAccess[access]);
  const usable = exercises.filter((candidate) => candidate.id !== incumbent.id && candidate.type === incumbent.type && available.has(candidate.equipment));
  const tiers = [
    (candidate: SeedExercise) => candidate.swapGroup === incumbent.swapGroup,
    (candidate: SeedExercise) => candidate.pattern === incumbent.pattern,
    (candidate: SeedExercise) => regionOfPattern[candidate.pattern] === regionOfPattern[incumbent.pattern],
  ];
  let found: SeedExercise[] = [];
  for (const tier of tiers) {
    found = usable.filter(tier);
    if (found.length >= SpecConstants.swapCandidatesMin) break;
  }
  return found.sort(rankForUser(experience)).slice(0, SpecConstants.swapCandidatesMax);
}
