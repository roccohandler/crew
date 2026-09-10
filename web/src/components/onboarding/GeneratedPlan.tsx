"use client";
// SPEC: S04 — every exercise shows equipment chip + targets + the mobility block; Swap in 2 taps; 1C — "Your week, built." with the
// one-time swap whisper; the reveal is instant under prefers-reduced-motion · A1 (the reveal shows THIS week's projection —
// "Monday · Push day" — and states the rotation; the workout cards are keyed by kind). Web twin of ios GeneratedPlanScreen + SwapSheet.
import { useState } from "react";
import { WEEKDAY_NAMES } from "@/components/onboarding/DaysQuestion";
import { weekKeyFor } from "@/lib/engine/day-key";
import { setsByReps } from "@/lib/engine/home-lines";
import type { PlanDraft, PlanDraftExercise, PlanDraftWorkout } from "@/lib/engine/plan-generator";
import { projectWeek, type DayProjection } from "@/lib/engine/plan-rotation";
import type { SeedExercise } from "@/generated/seed";

// C5 — the sets×reps phrase reached its third occurrence with A14's Home card, so it lives in one plain function now
export function targetsLabel(row: PlanDraftExercise): string {
  return setsByReps(row.targetSets, row.targetReps, row.targetRepsMax ?? null);
}

// SPEC: A1 — the projection for this week from an empty history: the first planned day gets the cycle's first workout
function projectionLine(day: DayProjection, draft: PlanDraft): string {
  const name = WEEKDAY_NAMES[day.weekday - 1] ?? "";
  if (day.state === "rest") return `${name} · Rest`;
  const workout = draft.workouts.find((candidate) => candidate.kind === day.kind);
  return workout === undefined ? `${name} · —` : `${name} · ${workout.name}`;
}

function WorkoutCard({ workout, onTap }: { workout: PlanDraftWorkout; onTap: (exerciseId: string) => void }) {
  const holds = workout.exercises.filter((row) => row.type === "mobility");
  return (
    <section className="card stack stack--tight" aria-label={workout.name}>
      <h3>{workout.name}</h3>
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

interface Props { draft: PlanDraft; todayKey: string; swapCandidates: (exerciseId: string) => SeedExercise[]; onSwap: (kind: PlanDraftWorkout["kind"], exerciseId: string, replacement: SeedExercise) => void; onAccept: () => void; whisperShown: boolean }

export function GeneratedPlan({ draft, todayKey, swapCandidates, onSwap, onAccept, whisperShown }: Props) {
  const [swapping, setSwapping] = useState<{ kind: PlanDraftWorkout["kind"]; exerciseId: string } | null>(null);
  const cycle = draft.workouts.map((workout) => workout.kind);
  const week = projectWeek({ weekKey: weekKeyFor(todayKey), todayKey, trainingWeekdays: draft.trainingWeekdays, cycle, nextKind: cycle[0] ?? "", completedKindByDay: {} });
  return (
    <div className="stack">
      <h1>Your week, built.</h1>
      {!whisperShown ? <p className="whisper">Tap any exercise to swap it.</p> : null}
      <ul className="card stack stack--tight" style={{ listStyle: "none", margin: 0 }} aria-label="This week">
        {week.map((day) => <li key={day.dayKey} className={day.state === "planned" ? "" : "muted"}>{projectionLine(day, draft)}</li>)}
      </ul>
      <p className="muted">Every workout rotates in, so each gets equal time.</p>
      {draft.workouts.map((workout) => (
        <WorkoutCard key={workout.kind} workout={workout} onTap={(exerciseId) => setSwapping({ kind: workout.kind, exerciseId })} />
      ))}
      {swapping ? (
        <dialog open className="card stack stack--tight" aria-label="Swap">
          <h2>Swap</h2>
          {swapCandidates(swapping.exerciseId).map((candidate) => (
            <button key={candidate.id} type="button" className="card stack stack--tight" onClick={() => { onSwap(swapping.kind, swapping.exerciseId, candidate); setSwapping(null); }}>
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
