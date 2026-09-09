"use client";
// SPEC: A4 — the exercise sheet: every gesture has a button. Sets / Reps (or Minutes for a cardio block, A2) on 44 px
// steppers bounded by the Generated constants, Swap exercise (3–5 candidates that do the same job, Flow 1 step 4), Move up /
// Move down, Remove from {workout} (no "Are you sure?" — the editor offers Undo). The picker is shared by swap, add exercise
// and add cardio. Web twin of ios ExerciseSheet + SwapSheet, as a <dialog>.
import { useState } from "react";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { accessFor, type DraftRow } from "@/lib/plan-draft";
import { TimeUnits } from "@/lib/time-units";
import { exercises as seedExercises, type SeedExercise } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

export function ExercisePicker({ title, candidates, onPick, onClose }: { title: string; candidates: SeedExercise[]; onPick: (exercise: SeedExercise) => void; onClose: () => void }) {
  return (
    <dialog open className="card stack stack--tight" aria-label={title}>
      <h2>{title}</h2>
      {candidates.map((candidate) => (
        <button key={candidate.id} type="button" className="card stack stack--tight" onClick={() => onPick(candidate)}>
          <strong>{candidate.name}</strong>
          <span className="muted">{candidate.cueLine}</span>
        </button>
      ))}
      {candidates.length === 0 ? <p className="muted">Nothing else does this job with your gear.</p> : null}
      <button type="button" className="button button--text" onClick={onClose}>Keep it</button>
    </dialog>
  );
}

function Stepper({ name, value, atMin, atMax, onStep }: { name: string; value: string; atMin: boolean; atMax: boolean; onStep: (direction: number) => void }) {
  return (
    <div className="row row--between">
      <span>{name}</span>
      <span className="stepper" role="group" aria-label={name}>
        <button type="button" onClick={() => onStep(-1)} disabled={atMin} aria-label={`Decrease ${name}`}>−</button>
        <span aria-live="polite">{value}</span>
        <button type="button" onClick={() => onStep(1)} disabled={atMax} aria-label={`Increase ${name}`}>+</button>
      </span>
    </div>
  );
}

export const repsLabel = (row: DraftRow): string => (row.targetRepsMax === undefined ? `${row.targetReps}` : `${row.targetReps}–${row.targetRepsMax}`);
export const cardioMinutes = (row: DraftRow): number => Math.round((row.holdSeconds ?? 0) / TimeUnits.secondsPerMinute);

interface SheetProps {
  row: DraftRow;
  workoutName: string;
  rows: DraftRow[]; // the editable list, for the access tier and the move bounds
  onSets: (direction: number) => void;
  onReps: (direction: number) => void;
  onMinutes: (direction: number) => void;
  onSwap: (replacement: SeedExercise) => void;
  onMove: (direction: number) => void;
  onRemove: () => void;
  onClose: () => void;
}

// SPEC: G3 / planTargetRepsMax / A2 — the segment at a bound renders disabled rather than erroring
function Targets({ row, onSets, onReps, onMinutes }: Pick<SheetProps, "row" | "onSets" | "onReps" | "onMinutes">) {
  if (row.type === "cardio") {
    const minutes = cardioMinutes(row);
    return <Stepper name="Minutes" value={`${minutes} min`} atMin={minutes <= SpecConstants.cardioMinutesMin} atMax={minutes >= SpecConstants.cardioMinutesMax} onStep={onMinutes} />;
  }
  const repsTop = row.targetRepsMax ?? row.targetReps;
  return (
    <>
      <Stepper name="Sets" value={`${row.targetSets}`} atMin={row.targetSets <= 1} atMax={row.targetSets >= SpecConstants.planMaxSetsPerExercise} onStep={onSets} />
      <Stepper name="Reps" value={repsLabel(row)} atMin={row.targetReps <= 1} atMax={repsTop >= SpecConstants.planTargetRepsMax} onStep={onReps} />
    </>
  );
}

export function ExerciseSheet({ row, workoutName, rows, onSets, onReps, onMinutes, onSwap, onMove, onRemove, onClose }: SheetProps) {
  const [swapping, setSwapping] = useState(false);
  const incumbent = seedExercises.find((candidate) => candidate.id === row.exerciseId);
  const index = rows.findIndex((candidate) => candidate.order === row.order);
  if (swapping) {
    const candidates = incumbent === undefined ? [] : swapCandidates(incumbent, accessFor(rows), "experienced", seedExercises);
    return <ExercisePicker title={`Swap ${row.name}`} candidates={candidates} onPick={(replacement) => { onSwap(replacement); setSwapping(false); }} onClose={() => setSwapping(false)} />;
  }
  return (
    <dialog open className="card stack" aria-label={row.name}>
      <div className="row row--between">
        <h2>{row.name}</h2>
        <span className="chip" aria-hidden="true">{row.equipment}</span>
      </div>
      {incumbent ? <p className="muted">{incumbent.cueLine}</p> : null}
      <Targets row={row} onSets={onSets} onReps={onReps} onMinutes={onMinutes} />
      <button type="button" className="button button--secondary" onClick={() => setSwapping(true)}>Swap exercise</button>
      <div className="row">
        <button type="button" className="button button--secondary" disabled={index <= 0} onClick={() => onMove(-1)}>Move up</button>
        <button type="button" className="button button--secondary" disabled={index < 0 || index >= rows.length - 1} onClick={() => onMove(1)}>Move down</button>
      </div>
      <button type="button" className="button button--text" onClick={onRemove}>Remove from {workoutName}</button>
      <button type="button" className="button button--primary" onClick={onClose}>Done</button>
    </dialog>
  );
}
