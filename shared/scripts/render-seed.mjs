// Renders the three seed JSONs as SeedData.swift (raw JSON bundled for Codable decoding) and seed.ts
// (typed constants). SPEC: Part V 5.2 (SeedData.swift bundles the three seed JSONs · seed.ts) · Part IX seed data ·
// A21.1 (owner-approved 2026-09-17: no equipment tiers; the equipment TAG stays) · A26 (owner-approved 2026-09-18: the
// templates are the owner’s three lists, kind → exercise ids; one SF Symbol per equipment tag, from exercises.json enums)

const swiftHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/seed/*.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.
// SPEC: Part IX seed data — decoded once by Engine/SeedCatalog.swift; never edited by hand.`;

const tsHeader = `// GENERATED FILE — DO NOT EDIT. Source: shared/seed/*.json · Generator: shared/scripts/generate.mjs
// Re-run \`node shared/scripts/generate.mjs\`; \`node shared/scripts/check-drift.mjs\` fails CI when this file drifts.
// SPEC: Part IX seed data — the plan generator and swap finder read these; never edited by hand.`;

function swiftRawString(json) {
  // A raw multi-line string keeps the JSON byte-for-byte; "#"" cannot appear in our JSON.
  return `#"""\n${JSON.stringify(json)}\n"""#`;
}

export function renderSeedDataSwift(seeds) {
  return [
    swiftHeader, "", "import Foundation", "",
    "enum SeedData {",
    "    /// shared/seed/exercises.json",
    `    static let exercisesJSON = ${swiftRawString(seeds.exercises)}`,
    "    /// shared/seed/plan-templates.json",
    `    static let planTemplatesJSON = ${swiftRawString(seeds.planTemplates)}`,
    "    /// shared/seed/achievements.json",
    `    static let achievementsJSON = ${swiftRawString(seeds.achievements)}`,
    "    /// shared/seed/fast-food.json (nutrition addendum §5)",
    `    static let fastFoodJSON = ${swiftRawString({ chains: seeds.fastFood.chains, items: seeds.fastFood.items })}`,
    "}", "",
  ].join("\n");
}

const seedTypes = `export type Pattern = "horizontalPush" | "verticalPush" | "chestIsolation" | "shoulderIsolation" | "triceps" | "horizontalPull" | "verticalPull" | "rearDelt" | "biceps" | "squat" | "hinge" | "lunge" | "calf" | "core" | "mobility" | "cardio";
export type Equipment = "barbell" | "dumbbell" | "machine" | "cable" | "bodyweight";
export type Experience = "brandNew" | "some" | "experienced";
export type WorkoutKind = "push" | "pull" | "legs" | "fullBodyA" | "fullBodyB";
export type TemplateKind = "push" | "pull" | "legs"; // A26: the kinds a plan is generated from; a legacy plan may still carry the other two
export type Region = "push" | "pull" | "legs" | "core" | "mobility" | "cardio";

export interface SeedExercise {
  id: string; name: string; pattern: Pattern; swapGroup: string; equipment: Equipment; level: Experience;
  type: "strength" | "mobility" | "cardio"; cueLine: string; holdSeconds?: number; perSide?: boolean;
}
export interface SeedTargets { sets: number; reps: number; repsMax?: number }
export interface SeedPlanTemplates {
  targets: Record<Experience, SeedTargets>;
  split: { fullBodyMaxTrainingDays: number; pplCycle: TemplateKind[]; fullBodyCycle: WorkoutKind[] };
  workoutNames: Record<WorkoutKind, string>;
  templates: Record<TemplateKind, string[]>; // A26: kind → exercise ids — the same rows at every experience; a row may repeat an exercise
  namedSwaps: Record<string, string[]>; // A26: a template row's exercise id → the swaps the owner named for it (always offered; check-seeds + the SwapFinder tests)
  mobilityBlocks: Record<TemplateKind, string[]>;
}
export interface SeedAchievement { id: string; title: string; line: string; scope: "solo" | "crew"; trigger: string; threshold: number; spec: string }
export interface SeedFastFoodChain { id: string; name: string; icon: string; sourceUrl: string; retrievedOn: string }
export interface SeedFastFoodItem { id: string; chainId: string; name: string; servingLabel: string; proteinG: number; carbsG: number; fatG: number }
export interface SeedFastFood { chains: SeedFastFoodChain[]; items: SeedFastFoodItem[] }`;

export function renderSeedTs(seeds) {
  const { exercises, planTemplates, achievements, fastFood } = seeds;
  return [
    tsHeader, "", seedTypes, "",
    `export const regionOfPattern: Record<Pattern, Region> = ${JSON.stringify(exercises.enums.region, null, 2)};`,
    `// A26: the SF Symbol the PHONE draws beside an equipment tag (R-079: a browser has no SF Symbols, so the web chip stays words)`,
    `export const equipmentSymbol: Record<Equipment, string> = ${JSON.stringify(exercises.enums.equipmentSymbol, null, 2)};`,
    `export const exercises: SeedExercise[] = ${JSON.stringify(exercises.exercises, null, 2)};`,
    `export const planTemplates: SeedPlanTemplates = ${JSON.stringify({ targets: planTemplates.targets, split: planTemplates.split, workoutNames: planTemplates.workoutNames, templates: planTemplates.templates, namedSwaps: planTemplates.namedSwaps, mobilityBlocks: planTemplates.mobilityBlocks }, null, 2)};`,
    `export const achievements: SeedAchievement[] = ${JSON.stringify(achievements.achievements, null, 2)};`,
    `export const fastFood: SeedFastFood = ${JSON.stringify({ chains: fastFood.chains, items: fastFood.items }, null, 2)};`,
    "",
  ].join("\n");
}
