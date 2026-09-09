// SPEC: Flow 1 step 3 (questions → Push · Pull · Legs; every exercise with equipment tag + sets×reps; a short MOBILITY
// BLOCK closing each workout) · A1 (owner-directed 2026-09-08: a plan is trainingWeekdays plus an ORDERED list of
// workouts — Push day · Pull day · Leg day at every frequency 1–7; Full-Body A/B is no longer generated, the seed keeps
// its templates for legacy plans) · A2 (cardio is a third row type, duration-based like a hold) · 5.6.1
// generatePlan(days, exp, equip, seed) → PlanDraft · shared/seed/plan-templates.json (targets, split, templates,
// mobility blocks). Twin: ios/Crew/Engine/PlanGenerator.swift. Pure; the seed is a parameter.
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
  type: "strength" | "mobility" | "cardio";
  targetSets: number;
  targetReps: number;
  targetRepsMax?: number;
  holdSeconds?: number; // mobility holds and cardio blocks: seconds
  perSide?: boolean;
  order: number;
}

export interface PlanDraftWorkout {
  name: string;
  kind: WorkoutKind;
  exercises: PlanDraftExercise[]; // strength rows, then the mobility block (an added cardio block sits between)
}

// SPEC: A1 — trainingWeekdays (ISO 1 = Monday … 7 = Sunday; sorted, unique) + workouts in rotation order, no weekday
export interface PlanDraft {
  trainingWeekdays: number[];
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

// SPEC: A2 — a cardio block is duration-based like a hold: one "set", no reps, holdSeconds = the activity's seed default
export function cardioRow(seed: SeedCatalog, id: string, order: number): PlanDraftExercise {
  const exercise = exerciseById(seed, id);
  return { exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: exercise.holdSeconds ?? 0, order };
}

export function workoutFor(kind: WorkoutKind, experience: Experience, access: EquipmentAccess, seed: SeedCatalog): PlanDraftWorkout {
  const templates = seed.planTemplates;
  const ids = templates.templates[kind][experience][access];
  const exercises = ids.map((id, index) => strengthRow(seed, id, experience, index));
  const holds = templates.mobilityBlocks[kind].map((id, index) => mobilityRow(seed, id, exercises.length + index));
  return { name: templates.workoutNames[kind], kind, exercises: [...exercises, ...holds] };
}

// SPEC: A1 — every generated plan is the pplCycle in stored order (three workouts, at every day count); the days are
// kept sorted and unique. Which workout lands on which day is the rotation's job (plan-rotation.ts), never the plan's.
export function generatePlan(days: number[], experience: Experience, access: EquipmentAccess, seed: SeedCatalog): PlanDraft {
  const trainingWeekdays = [...new Set(days)].sort((left, right) => left - right);
  const workouts = seed.planTemplates.split.pplCycle.map((kind) => workoutFor(kind, experience, access, seed));
  return { trainingWeekdays, workouts };
}
