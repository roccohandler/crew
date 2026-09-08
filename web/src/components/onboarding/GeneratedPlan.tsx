"use client";
// SPEC: S04 — every exercise shows equipment chip + targets + the mobility block; Swap in 2 taps; 1C — "Your week, built." with the
// one-time swap whisper; the reveal is instant under prefers-reduced-motion. Web twin of ios GeneratedPlanScreen + SwapSheet.
import { useState } from "react";
import type { PlanDraft, PlanDraftExercise, PlanDraftWorkout } from "@/lib/engine/plan-generator";
import type { SeedExercise } from "@/generated/seed";

const WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

export function targetsLabel(row: PlanDraftExercise): string {
  return row.targetRepsMax !== undefined ? `${row.targetSets}×${row.targetReps}–${row.targetRepsMax}` : `${row.targetSets}×${row.targetReps}`;
}

function DayCard({ workout, onTap }: { workout: PlanDraftWorkout; onTap: (exerciseId: string) => void }) {
  const holds = workout.exercises.filter((row) => row.type === "mobility");
  return (
    <section className="card stack stack--tight" aria-label={`${WEEKDAYS[workout.weekday - 1]} ${workout.name}`}>
      <h3>{WEEKDAYS[workout.weekday - 1]} · {workout.name}</h3>
      {workout.exercises.filter((row) => row.type === "strength").map((row) => (
        <button key={row.exerciseId} type="button" className="row row--between button--text" onClick={() => onTap(row.exerciseId)} aria-label={`${row.name}, ${row.equipment}, ${targetsLabel(row)}. Swap`}>
          <span>{row.name}</span>
          <span className="chip" aria-hidden="true">{row.equipment}</span>
          <span>{targetsLabel(row)}</span>
        </button>
      ))}
      <p className="muted">Mobility · {holds.length} holds: {holds.map((hold) => `${hold.name} ${hold.holdSeconds}s${hold.perSide ? " each" : ""}`).join(" · ")}</p>
    </section>
  );
}

export function GeneratedPlan({ draft, swapCandidates, onSwap, onAccept, whisperShown }: { draft: PlanDraft; swapCandidates: (exerciseId: string) => SeedExercise[]; onSwap: (weekday: number, exerciseId: string, replacement: SeedExercise) => void; onAccept: () => void; whisperShown: boolean }) {
  const [swapping, setSwapping] = useState<{ weekday: number; exerciseId: string } | null>(null);
  return (
    <div className="stack">
      <h1>Your week, built.</h1>
      {!whisperShown ? <p className="whisper">Tap any exercise to swap it.</p> : null}
      {draft.workouts.map((workout) => (
        <DayCard key={workout.weekday} workout={workout} onTap={(exerciseId) => setSwapping({ weekday: workout.weekday, exerciseId })} />
      ))}
      {swapping ? (
        <dialog open className="card stack stack--tight" aria-label="Swap">
          <h2>Swap</h2>
          {swapCandidates(swapping.exerciseId).map((candidate) => (
            <button key={candidate.id} type="button" className="card stack stack--tight" onClick={() => { onSwap(swapping.weekday, swapping.exerciseId, candidate); setSwapping(null); }}>
              <strong>{candidate.name}</strong>
              <span className="muted">{candidate.cueLine}</span>
            </button>
          ))}
          <button type="button" className="button button--text" onClick={() => setSwapping(null)}>Keep it</button>
        </dialog>
      ) : null}
      <button type="button" className="button button--primary" onClick={onAccept}>Looks good</button>
    </div>
  );
}
