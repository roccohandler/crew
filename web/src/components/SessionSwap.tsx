"use client";
// SPEC: E7 — mid-workout Swap asks [Just today] [Update my plan]; Flow 1 step 4 swap-don't-interrogate (3–5 alternatives that do
// the same job, two taps). "Just today" rewrites this session's snapshot only (running sessions are snapshots, E7); "Update my
// plan" also replaces the exercise in the plan's workout for this weekday, forward-only (Flow 8). Web twin of ios SessionSwap.
import { useState } from "react";
import { getPlan, putPlan, type SessionExerciseView } from "@/lib/api-client";
import { isoWeekday } from "@/lib/engine/day-key";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { exercises as seedExercises, type EquipmentAccess, type SeedExercise } from "@/generated/seed";

export type SwapScope = "today" | "plan";

// The access tier is read off the gear in the session (the snapshot carries no answers), like the plan editor does
export function accessFor(rows: { equipment: string }[]): EquipmentAccess {
  const gear = new Set(rows.map((row) => row.equipment));
  if (gear.has("barbell") || gear.has("machine") || gear.has("cable")) return "fullGym";
  return gear.has("dumbbell") ? "dumbbells" : "bodyweight";
}

export function swappedExercise(current: SessionExerciseView, replacement: SeedExercise): SessionExerciseView {
  return { ...current, exerciseId: replacement.id, name: replacement.name, equipment: replacement.equipment };
}

// Flow 8: the plan's workout for this session's weekday gets the same replacement; other days are untouched
export async function updatePlanWithSwap(dayKey: string, exerciseId: string, replacement: SeedExercise): Promise<void> {
  const plan = await getPlan();
  const weekday = isoWeekday(dayKey);
  const workouts = plan.workouts.map((workout) => (workout.weekday === weekday
    ? { ...workout, exercises: workout.exercises.map((row) => (row.exerciseId === exerciseId ? { ...row, exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment } : row)) }
    : workout));
  await putPlan({ workouts });
}

export function SessionSwap({ exercise, access, onPick, onClose }: { exercise: SessionExerciseView; access: EquipmentAccess; onPick: (replacement: SeedExercise, scope: SwapScope) => void; onClose: () => void }) {
  const [chosen, setChosen] = useState<SeedExercise | null>(null);
  const incumbent = seedExercises.find((candidate) => candidate.id === exercise.exerciseId);
  const candidates = incumbent ? swapCandidates(incumbent, access, "experienced", seedExercises) : [];
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
      {candidates.length === 0 ? <p className="muted">Nothing else does this job with your gear. Keep it or skip it.</p> : null}
      <button type="button" className="button button--text" onClick={onClose}>Keep it</button>
    </dialog>
  );
}
