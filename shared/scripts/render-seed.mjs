// Renders the three seed JSONs as SeedData.swift (raw JSON bundled for Codable decoding) and seed.ts
// (typed constants). SPEC: Part V 5.2 (SeedData.swift bundles the three seed JSONs · seed.ts) · Part IX seed data

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
    "}", "",
  ].join("\n");
}

const seedTypes = `export type Pattern = "horizontalPush" | "verticalPush" | "chestIsolation" | "shoulderIsolation" | "triceps" | "horizontalPull" | "verticalPull" | "rearDelt" | "biceps" | "squat" | "hinge" | "lunge" | "calf" | "core" | "mobility";
export type Equipment = "barbell" | "dumbbell" | "machine" | "cable" | "bodyweight";
export type EquipmentAccess = "fullGym" | "dumbbells" | "bodyweight";
export type Experience = "brandNew" | "some" | "experienced";
export type WorkoutKind = "push" | "pull" | "legs" | "fullBodyA" | "fullBodyB";
export type Region = "push" | "pull" | "legs" | "core" | "mobility";

export interface SeedExercise {
  id: string; name: string; pattern: Pattern; swapGroup: string; equipment: Equipment; level: Experience;
  type: "strength" | "mobility"; cueLine: string; holdSeconds?: number; perSide?: boolean;
}
export interface SeedTargets { sets: number; reps: number; repsMax?: number }
export interface SeedPlanTemplates {
  targets: Record<Experience, SeedTargets>;
  split: { fullBodyMaxTrainingDays: number; pplCycle: WorkoutKind[]; fullBodyCycle: WorkoutKind[] };
  workoutNames: Record<WorkoutKind, string>;
  templates: Record<WorkoutKind, Record<Experience, Record<EquipmentAccess, string[]>>>;
  mobilityBlocks: Record<WorkoutKind, string[]>;
}
export interface SeedAchievement { id: string; title: string; line: string; scope: "solo" | "crew"; trigger: string; threshold: number; spec: string }`;

export function renderSeedTs(seeds) {
  const { exercises, planTemplates, achievements } = seeds;
  return [
    tsHeader, "", seedTypes, "",
    `export const equipmentAccess: Record<EquipmentAccess, Equipment[]> = ${JSON.stringify(exercises.enums.equipmentAccess, null, 2)};`,
    `export const regionOfPattern: Record<Pattern, Region> = ${JSON.stringify(exercises.enums.region, null, 2)};`,
    `export const exercises: SeedExercise[] = ${JSON.stringify(exercises.exercises, null, 2)};`,
    `export const planTemplates: SeedPlanTemplates = ${JSON.stringify({ targets: planTemplates.targets, split: planTemplates.split, workoutNames: planTemplates.workoutNames, templates: planTemplates.templates, mobilityBlocks: planTemplates.mobilityBlocks }, null, 2)};`,
    `export const achievements: SeedAchievement[] = ${JSON.stringify(achievements.achievements, null, 2)};`,
    "",
  ].join("\n");
}
