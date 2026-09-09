"use client";
// SPEC: Flow 3 set row — tap the row → ✓ at the pre-filled numbers; steppers ±1 reps, ±5 lb / ±2.5 kg; "—" is a complete set
// (weight invisible until invited; bodyweight = no weight chip); plate math on a visible button (6.7: no hover-only affordance).
// Mirrors ios Features/Session/SetRow. Keyboard-complete: every control is a button. Stepper is the one ± pair (reps, weight,
// cardio minutes — the third use, so it is shared from here).
import { useState } from "react";
import type { SetView } from "@/lib/api-client";
import { plateLine } from "@/lib/engine/plate-math";
import { SpecConstants } from "@/generated/spec-constants";

export function Stepper({ label, onStep, ariaLabel }: { label: string; onStep: (direction: number) => void; ariaLabel: string }) {
  return (
    <span className="stepper" role="group" aria-label={ariaLabel}>
      <button type="button" onClick={() => onStep(-1)} aria-label={`Decrease ${ariaLabel}`}>−</button>
      <span>{label}</span>
      <button type="button" onClick={() => onStep(1)} aria-label={`Increase ${ariaLabel}`}>+</button>
    </span>
  );
}

export function SetRow({ exerciseName, equipment, set, index, count, units, ghost, onCheck, onReps, onWeight }: { exerciseName: string; equipment: string; set: SetView; index: number; count: number; units: "lb" | "kg"; ghost: boolean; onCheck: () => void; onReps: (direction: number) => void; onWeight: (direction: number) => void }) {
  const [plates, setPlates] = useState<string | null>(null);
  const weightLabel = set.weight === null ? "—" : `${set.weight} ${units}`;
  const step = units === "lb" ? SpecConstants.weightStepLb : SpecConstants.weightStepKg;
  return (
    <div className={ghost ? "setrow setrow--ghost" : "setrow"}>
      <span className="muted">{set.isWarmup ? "Warm-up" : `Set ${index}`}</span>
      <Stepper label={`${set.actualReps} reps`} onStep={onReps} ariaLabel="reps" />
      {equipment === "bodyweight" ? <span /> : (
        <span className="row">
          <Stepper label={weightLabel} onStep={onWeight} ariaLabel={`weight, step ${step} ${units}`} />
          {equipment === "barbell" && set.weight !== null ? <button type="button" className="button button--text" onClick={() => setPlates(plateLine(set.weight ?? 0, units))}>plates</button> : null}
          {plates ? <span className="whisper">{plates}</span> : null}
        </span>
      )}
      <button type="button" onClick={onCheck} aria-label={`${exerciseName}, ${set.isWarmup ? "warm-up" : `set ${index} of ${count}`}, ${set.actualReps} reps${set.weight === null ? "" : `, ${set.weight} ${units}`}${set.done ? ", done" : ""}`} aria-pressed={set.done} className="toggle">
        {set.done ? "✓" : "○"}
      </button>
    </div>
  );
}
