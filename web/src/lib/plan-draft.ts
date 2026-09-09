// SPEC: A4 (owner-directed 2026-09-08) · Flow 8 — the workout editor's draft mutations, pure and shared by the web plan
// screens (web twin of ios PlanModel's draft edits): swap keeps targets; sets/reps bounded by the Generated constants (G3, the
// reps ceiling); reorder, remove + one-step restore within the exercise list; add strength (targets copied from the workout's
// own rows) and add cardio (A2: one block, after the strength rows); the mobility block always closes the workout. Nothing here
// touches the saved plan — Save does, forward-only.
import type { ExerciseTemplateDoc, WorkoutTemplateDoc } from "@/lib/documents";
import { cardioRow } from "@/lib/engine/plan-generator";
import { TimeUnits } from "@/lib/time-units";
import { equipmentAccess, exercises as seedExercises, planTemplates, type EquipmentAccess, type SeedExercise } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

export type DraftRow = ExerciseTemplateDoc;
export type DraftWorkout = WorkoutTemplateDoc;
export interface DraftPlan { trainingWeekdays: number[]; workouts: DraftWorkout[] }

const seed = { exercises: seedExercises, planTemplates };
const byOrder = (workout: DraftWorkout): DraftRow[] => [...workout.exercises].sort((left, right) => left.order - right.order);
const renumber = (rows: DraftRow[]): DraftRow[] => rows.map((row, order) => ({ ...row, order }));
const clamp = (value: number, min: number, max: number): number => Math.min(max, Math.max(min, value));

// The editable list is everything before the mobility block: strength rows, then a cardio block when one exists
export const editableRows = (workout: DraftWorkout): DraftRow[] => byOrder(workout).filter((row) => row.type !== "mobility");
export const mobilityRows = (workout: DraftWorkout): DraftRow[] => byOrder(workout).filter((row) => row.type === "mobility");
export const strengthCount = (workout: DraftWorkout): number => workout.exercises.filter((row) => row.type === "strength").length;
export const hasCardio = (workout: DraftWorkout): boolean => workout.exercises.some((row) => row.type === "cardio");
// SPEC: Flow 8 — ≤ planMaxExercisesPerDay rows in a workout, the mobility block included
export const isFull = (workout: DraftWorkout): boolean => workout.exercises.length >= SpecConstants.planMaxExercisesPerDay;

function rebuilt(workout: DraftWorkout, editable: DraftRow[]): DraftWorkout {
  return { ...workout, exercises: renumber([...editable, ...mobilityRows(workout)]) };
}

function patchRow(workout: DraftWorkout, order: number, patch: (row: DraftRow) => DraftRow): DraftWorkout {
  return { ...workout, exercises: workout.exercises.map((row) => (row.order === order ? patch(row) : row)) };
}

// The access tier is read off the gear in the workout (the plan carries no answers), like the session swap does
export function accessFor(rows: { equipment: string }[]): EquipmentAccess {
  const gear = new Set(rows.map((row) => row.equipment));
  if (gear.has("barbell") || gear.has("machine") || gear.has("cable")) return "fullGym";
  return gear.has("dumbbell") ? "dumbbells" : "bodyweight";
}

// SPEC: Flow 1 step 4 — a swap keeps the targets (sets × reps, hold seconds); only the exercise identity changes
export function swapRow(workout: DraftWorkout, order: number, replacement: SeedExercise): DraftWorkout {
  return patchRow(workout, order, (row) => ({ ...row, exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment }));
}

// SPEC: Flow 8; G3 — sets move one at a time within 1…planMaxSetsPerExercise
export function adjustSets(workout: DraftWorkout, order: number, direction: number): DraftWorkout {
  return patchRow(workout, order, (row) => ({ ...row, targetSets: clamp(row.targetSets + direction, 1, SpecConstants.planMaxSetsPerExercise) }));
}

// SPEC: Flow 8; planTargetRepsMax — reps move by repsStep within 1…planTargetRepsMax; a G7 range (8–10) moves as a unit
export function adjustReps(workout: DraftWorkout, order: number, direction: number): DraftWorkout {
  return patchRow(workout, order, (row) => {
    const span = row.targetRepsMax === undefined ? 0 : row.targetRepsMax - row.targetReps;
    const reps = clamp(row.targetReps + direction * SpecConstants.repsStep, 1, SpecConstants.planTargetRepsMax - span);
    return row.targetRepsMax === undefined ? { ...row, targetReps: reps } : { ...row, targetReps: reps, targetRepsMax: reps + span };
  });
}

// SPEC: A2 — a cardio block's minutes move by cardioMinutesStep within cardioMinutesMin…cardioMinutesMax (stored as seconds)
export function adjustMinutes(workout: DraftWorkout, order: number, direction: number): DraftWorkout {
  return patchRow(workout, order, (row) => {
    const minutes = clamp(Math.round((row.holdSeconds ?? 0) / TimeUnits.secondsPerMinute) + direction * SpecConstants.cardioMinutesStep, SpecConstants.cardioMinutesMin, SpecConstants.cardioMinutesMax);
    return { ...row, holdSeconds: minutes * TimeUnits.secondsPerMinute };
  });
}

// SPEC: A4 — Move up / Move down are one slot within the exercise list; the mobility block never moves
export function moveRow(workout: DraftWorkout, order: number, direction: number): DraftWorkout {
  const rows = editableRows(workout);
  const from = rows.findIndex((row) => row.order === order);
  const to = from + direction;
  const moving = rows[from];
  const displaced = rows[to];
  if (moving === undefined || displaced === undefined) return workout;
  return rebuilt(workout, rows.map((row, index) => (index === from ? displaced : index === to ? moving : row)));
}

export function removeRow(workout: DraftWorkout, order: number): DraftWorkout {
  return rebuilt(workout, editableRows(workout).filter((row) => row.order !== order));
}

// SPEC: A4 — the one-step Undo puts a removed row back at its old index
export function restoreRow(workout: DraftWorkout, removed: DraftRow): DraftWorkout {
  const rows = editableRows(workout);
  const index = Math.min(removed.order, rows.length);
  return rebuilt(workout, [...rows.slice(0, index), removed, ...rows.slice(index)]);
}

// SPEC: Flow 8 add — a new strength row takes the workout's own targets (the answers are not stored; the rows carry them)
export function addStrengthRow(workout: DraftWorkout, exercise: SeedExercise): DraftWorkout {
  const model = workout.exercises.find((row) => row.type === "strength");
  const defaults = planTemplates.targets.brandNew;
  const row: DraftRow = { exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "strength", targetSets: model?.targetSets ?? defaults.sets, targetReps: model?.targetReps ?? defaults.reps, order: 0 };
  if (model?.targetRepsMax !== undefined) row.targetRepsMax = model.targetRepsMax;
  const rows = editableRows(workout);
  const strength = rows.filter((candidate) => candidate.type === "strength");
  return rebuilt(workout, [...strength, row, ...rows.filter((candidate) => candidate.type !== "strength")]);
}

// SPEC: A2 — one cardio block per workout, after the strength rows, before the mobility block
export function addCardio(workout: DraftWorkout, exercise: SeedExercise): DraftWorkout {
  const rows = editableRows(workout).filter((row) => row.type !== "cardio");
  return rebuilt(workout, [...rows, cardioRow(seed, exercise.id, rows.length)]);
}

// Every strength exercise the workout's gear tier allows, not already in the workout, by name
export function addCandidates(workout: DraftWorkout): SeedExercise[] {
  const allowed = new Set<string>(equipmentAccess[accessFor(workout.exercises)]);
  const present = new Set(workout.exercises.map((row) => row.exerciseId));
  return seedExercises.filter((exercise) => exercise.type === "strength" && allowed.has(exercise.equipment) && !present.has(exercise.id)).sort((left, right) => left.name.localeCompare(right.name));
}

// SPEC: A2 — the nine seeded activities
export const cardioActivities = (): SeedExercise[] => seedExercises.filter((exercise) => exercise.type === "cardio");

const holdSeconds = (row: DraftRow): number => (row.holdSeconds ?? 0) * (row.perSide ? SpecConstants.perSideHoldRepeats : 1);

// SPEC: A4 header "~{min} min" — strength sets × the default rest + hold seconds + cardio seconds, in whole minutes
export function estimatedMinutes(workout: DraftWorkout): number {
  const seconds = workout.exercises.reduce((total, row) => total + (row.type === "strength" ? row.targetSets * SpecConstants.restTimerDefaultSeconds : holdSeconds(row)), 0);
  // SPEC: A4 — the estimate rounds to planEstimateRoundingMinutes (twin: WorkoutDraft.estimatedMinutes)
  const step = SpecConstants.planEstimateRoundingMinutes;
  return Math.round(seconds / (TimeUnits.secondsPerMinute * step)) * step;
}

export function mobilityMinutes(workout: DraftWorkout): number {
  return Math.round(mobilityRows(workout).reduce((total, row) => total + holdSeconds(row), 0) / TimeUnits.secondsPerMinute);
}

// SPEC: A1 · A4 — training days are editable without a rebuild; the rotation is untouched (sorted, unique)
export function setTrainingWeekdays(plan: DraftPlan, weekdays: number[]): DraftPlan {
  return { trainingWeekdays: [...new Set(weekdays)].sort((left, right) => left - right), workouts: plan.workouts };
}
