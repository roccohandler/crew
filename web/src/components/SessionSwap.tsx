"use client";
// SPEC: E7 — mid-workout Swap asks [Just today] [Update my plan]; Flow 1 step 4 swap-don't-interrogate (3–5 alternatives that do
// the same job, two taps). "Just today" rewrites this session's snapshot only (running sessions are snapshots, E7); "Update my
// plan" also replaces the exercise in the plan's workout of this session's KIND (A1: workouts rotate, so a kind — never a
// weekday — names the workout), forward-only (Flow 8). A21.1 (owner-approved 2026-09-17): no equipment tier is read off the
// session's gear — the whole gym catalog is the pool. Web twin of ios SessionSwap.
import { useState } from "react";
import { getPlan, putPlan, type SessionExerciseView } from "@/lib/api-client";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { exercises as seedExercises, type SeedExercise } from "@/generated/seed";

export type SwapScope = "today" | "plan";

export function swappedExercise(current: SessionExerciseView, replacement: SeedExercise): SessionExerciseView {
  return { ...current, exerciseId: replacement.id, name: replacement.name, equipment: replacement.equipment };
}

// SPEC: Flow 8 · A1 — the plan's workout of this session's kind gets the same replacement; the other workouts and the training
// days are untouched (the PUT always carries trainingWeekdays + the ordered workouts). A26: a workout may repeat an exercise, so ONE
// plan row changes — the one at the session row's order when it still holds that exercise, else the first row that does.
export function planRowToSwap(rows: { exerciseId: string; order: number }[], exerciseId: string, order: number): number | null {
  const matches = rows.filter((row) => row.exerciseId === exerciseId);
  return (matches.find((row) => row.order === order) ?? matches[0])?.order ?? null;
}

export async function updatePlanWithSwap(kind: string | null, exerciseId: string, order: number, replacement: SeedExercise): Promise<void> {
  const plan = await getPlan();
  const workouts = plan.workouts.map((workout) => {
    if (workout.kind !== kind) return workout;
    const target = planRowToSwap(workout.exercises, exerciseId, order);
    return { ...workout, exercises: workout.exercises.map((row) => (row.order === target ? { ...row, exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment } : row)) };
  });
  await putPlan({ trainingWeekdays: plan.trainingWeekdays, workouts });
}

export function SessionSwap({ exercise, onPick, onClose }: { exercise: SessionExerciseView; onPick: (replacement: SeedExercise, scope: SwapScope) => void; onClose: () => void }) {
  const [chosen, setChosen] = useState<SeedExercise | null>(null);
  const incumbent = seedExercises.find((candidate) => candidate.id === exercise.exerciseId);
  const candidates = incumbent ? swapCandidates(incumbent, "experienced", seedExercises) : [];
  return (
    <dialog open className="card stack stack--tight" aria-label="Swap">
      {chosen === null ? <h2>Swap {exercise.name}</h2> : <h2>{chosen.name} — for how long?</h2>}
      {chosen === null ? candidates.map((candidate) => (
        <button key={candidate.id} type="button" className="card stack stack--tight" onClick={() => setChosen(candidate)}>
          <strong>{candidate.name}</strong>
          <span className="muted">{candidate.cueLine}</span>
        </button>
      )) : (
        <div className="row row--wrap">
          <button type="button" className="button button--primary" onClick={() => onPick(chosen, "today")}>Just today</button>
          <button type="button" className="button button--secondary" onClick={() => onPick(chosen, "plan")}>Update my plan</button>
        </div>
      )}
      {candidates.length === 0 ? <p className="muted">Nothing else does this job. Keep it or skip it.</p> : null}
      <button type="button" className="button button--text" onClick={onClose}>Keep it</button>
    </dialog>
  );
}
