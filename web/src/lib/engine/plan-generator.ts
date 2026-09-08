// SPEC: Flow 1 step 3 (questions → full Push·Pull·Legs on your days; Full-Body A/B at ≤2 days; every exercise with
// equipment tag + sets×reps; a short MOBILITY BLOCK closing each workout) · 5.6.1 generatePlan(days, exp, equip, seed)
// → PlanDraft · shared/seed/plan-templates.json (targets, split, templates, mobility blocks; gapNotes for the P-P-L cycle
// and experienced targets). Twin: ios/Crew/Engine/PlanGenerator.swift. Pure; the seed is a parameter.
import type { EquipmentAccess, Experience, SeedExercise, SeedPlanTemplates, WorkoutKind } from "@/generated/seed";

export interface SeedCatalog {
  exercises: SeedExercise[];
  planTemplates: SeedPlanTemplates;
}

export interface PlanDraftExercise {
  exerciseId: string;
  name: string;
  pattern: string;
  equipment: string;
  type: "strength" | "mobility";
  targetSets: number;
  targetReps: number;
  targetRepsMax?: number;
  holdSeconds?: number;
  perSide?: boolean;
  order: number;
}

export interface PlanDraftWorkout {
  weekday: number; // ISO 1 = Monday … 7 = Sunday
  name: string;
  kind: WorkoutKind;
  exercises: PlanDraftExercise[]; // strength rows, then the mobility block
}

export interface PlanDraft {
  workouts: PlanDraftWorkout[];
}

function exerciseById(seed: SeedCatalog, id: string): SeedExercise {
  const exercise = seed.exercises.find((candidate) => candidate.id === id);
  if (exercise === undefined) throw new Error(`plan template names an unknown exercise: ${id}`);
  return exercise;
}

function strengthRow(seed: SeedCatalog, id: string, experience: Experience, order: number): PlanDraftExercise {
  const exercise = exerciseById(seed, id);
  const targets = seed.planTemplates.targets[experience];
  const row: PlanDraftExercise = { exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "strength", targetSets: targets.sets, targetReps: targets.reps, order };
  if (targets.repsMax !== undefined) row.targetRepsMax = targets.repsMax;
  return row;
}

// Mobility holds are duration-based: one "set", no reps, no weight, ever (Flow 3)
function mobilityRow(seed: SeedCatalog, id: string, order: number): PlanDraftExercise {
  const exercise = exerciseById(seed, id);
  return { exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "mobility", targetSets: 1, targetReps: 0, holdSeconds: exercise.holdSeconds ?? 0, perSide: exercise.perSide ?? false, order };
}

export function workoutFor(kind: WorkoutKind, weekday: number, experience: Experience, access: EquipmentAccess, seed: SeedCatalog): PlanDraftWorkout {
  const templates = seed.planTemplates;
  const ids = templates.templates[kind][experience][access];
  const exercises = ids.map((id, index) => strengthRow(seed, id, experience, index));
  const holds = templates.mobilityBlocks[kind].map((id, index) => mobilityRow(seed, id, exercises.length + index));
  return { weekday, name: templates.workoutNames[kind], kind, exercises: [...exercises, ...holds] };
}

// SPEC: Flow 1 step 3 — PPL on the chosen days, Full-Body A/B at ≤ fullBodyMaxTrainingDays; the cycle repeats over the
// user's sorted days within the week (plan-templates.json gapNotes)
export function generatePlan(days: number[], experience: Experience, access: EquipmentAccess, seed: SeedCatalog): PlanDraft {
  const split = seed.planTemplates.split;
  const sortedDays = [...new Set(days)].sort((left, right) => left - right);
  const cycle = sortedDays.length <= split.fullBodyMaxTrainingDays ? split.fullBodyCycle : split.pplCycle;
  const workouts = sortedDays.map((weekday, index) => workoutFor(cycle[index % cycle.length] as WorkoutKind, weekday, experience, access, seed));
  return { workouts };
}
