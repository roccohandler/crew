"use client";
// SPEC: Flow 8 — small edits (swap / adjust sets·reps / reorder / add / remove, undo always); big = Rebuild (the questions again);
// input limits ≤ 15 exercises/day, ≤ 20 sets are the guardrails; everything applies forward. Web twin of ios PlanScreen (T014-S14).
import Link from "next/link";
import { useState } from "react";
import { putPlan } from "@/lib/api-client";
import type { WorkoutTemplateDoc } from "@/lib/documents";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { exercises, type EquipmentAccess } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

type Workout = WorkoutTemplateDoc;
type Row = Workout["exercises"][number];
const WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function accessFor(workout: Workout): EquipmentAccess {
  const gear = new Set(workout.exercises.map((row) => row.equipment));
  if (gear.has("barbell") || gear.has("machine") || gear.has("cable")) return "fullGym";
  return gear.has("dumbbell") ? "dumbbells" : "bodyweight";
}

function ExerciseEditor({ row, onChange, onRemove, onMove, onSwap }: { row: Row; onChange: (row: Row) => void; onRemove: () => void; onMove: (direction: number) => void; onSwap: () => void }) {
  return (
    <div className="stack stack--tight">
      <div className="row row--between"><button type="button" className="button button--text" onClick={onSwap}>{row.name}</button><span className="chip" aria-hidden="true">{row.equipment}</span></div>
      {row.type === "strength" ? (
        <div className="row row--wrap">
          <label className="field field--short"><span>Sets</span><input type="number" min={1} max={SpecConstants.planMaxSetsPerExercise} value={row.targetSets} onChange={(event) => onChange({ ...row, targetSets: Math.min(SpecConstants.planMaxSetsPerExercise, Math.max(1, Number(event.target.value))) })} /></label>
          <label className="field field--short"><span>Reps</span><input type="number" min={1} value={row.targetReps} onChange={(event) => onChange({ ...row, targetReps: Math.max(1, Number(event.target.value)) })} /></label>
          <button type="button" className="button button--text" onClick={() => onMove(-1)} aria-label={`Move ${row.name} up`}>↑</button>
          <button type="button" className="button button--text" onClick={() => onMove(1)} aria-label={`Move ${row.name} down`}>↓</button>
          <button type="button" className="button button--text" onClick={onRemove} aria-label={`Remove ${row.name}`}>Remove</button>
        </div>
      ) : <p className="whisper">Mobility · {row.holdSeconds}s{row.perSide ? " each" : ""}</p>}
    </div>
  );
}

export function PlanEditor({ initial }: { initial: { workouts: Workout[] } }) {
  const [workouts, setWorkouts] = useState(initial.workouts);
  const [previous, setPrevious] = useState<Workout[] | null>(null);
  const [swapping, setSwapping] = useState<{ weekday: number; row: Row } | null>(null);
  const [saved, setSaved] = useState<string | null>(null);

  const edit = (next: Workout[]) => { setPrevious(workouts); setWorkouts(next); setSaved(null); };
  const updateDay = (weekday: number, update: (workout: Workout) => Workout) => edit(workouts.map((workout) => (workout.weekday === weekday ? update(workout) : workout)));
  const reorder = (workout: Workout, from: number, direction: number): Workout => {
    const rows = [...workout.exercises].sort((left, right) => left.order - right.order);
    const to = from + direction;
    if (to < 0 || to >= rows.length) return workout;
    [rows[from], rows[to]] = [rows[to]!, rows[from]!];
    return { ...workout, exercises: rows.map((row, order) => ({ ...row, order })) };
  };
  const save = async () => { await putPlan({ workouts }); setSaved("Saved. Changes apply from your next workout on — history never rewrites."); };

  return (
    <div className="stack">
      <h1>Plan</h1>
      <p className="muted">Everything applies forward. History never rewrites.</p>
      {workouts.sort((left, right) => left.weekday - right.weekday).map((workout) => (
        <section key={workout.weekday} className="card stack stack--tight">
          <h2>{WEEKDAYS[workout.weekday - 1]} · {workout.name}</h2>
          {[...workout.exercises].sort((left, right) => left.order - right.order).map((row, index) => (
            <ExerciseEditor key={`${row.exerciseId}-${row.order}`} row={row} onChange={(next) => updateDay(workout.weekday, (day) => ({ ...day, exercises: day.exercises.map((candidate) => (candidate.order === row.order ? next : candidate)) }))} onRemove={() => updateDay(workout.weekday, (day) => ({ ...day, exercises: day.exercises.filter((candidate) => candidate.order !== row.order).map((candidate, order) => ({ ...candidate, order })) }))} onMove={(direction) => updateDay(workout.weekday, (day) => reorder(day, index, direction))} onSwap={() => setSwapping({ weekday: workout.weekday, row })} />
          ))}
          {workout.exercises.length < SpecConstants.planMaxExercisesPerDay ? <button type="button" className="button button--text" onClick={() => setSwapping({ weekday: workout.weekday, row: { ...workout.exercises[0]!, order: workout.exercises.length, exerciseId: "__add__" } })}>+ Add exercise</button> : null}
        </section>
      ))}
      {swapping ? <dialog open className="card stack stack--tight" aria-label="Swap"><h2>{swapping.row.exerciseId === "__add__" ? "Add" : "Swap"}</h2>{swapCandidates(exercises.find((candidate) => candidate.id === (swapping.row.exerciseId === "__add__" ? workouts.find((workout) => workout.weekday === swapping.weekday)?.exercises[0]?.exerciseId : swapping.row.exerciseId)) ?? exercises[0]!, accessFor(workouts.find((workout) => workout.weekday === swapping.weekday)!), "experienced", exercises).map((candidate) => <button key={candidate.id} type="button" className="card stack stack--tight" onClick={() => { const next: Row = { ...swapping.row, exerciseId: candidate.id, name: candidate.name, pattern: candidate.pattern, equipment: candidate.equipment }; updateDay(swapping.weekday, (day) => ({ ...day, exercises: swapping.row.exerciseId === "__add__" ? [...day.exercises, next] : day.exercises.map((row) => (row.order === swapping.row.order ? next : row)) })); setSwapping(null); }}><strong>{candidate.name}</strong><span className="muted">{candidate.cueLine}</span></button>)}<button type="button" className="button button--text" onClick={() => setSwapping(null)}>Keep it</button></dialog> : null}
      <div className="row">
        <button type="button" className="button button--primary" onClick={save}>Save plan</button>
        {previous ? <button type="button" className="button button--secondary" onClick={() => { setWorkouts(previous); setPrevious(null); }}>Undo</button> : null}
      </div>
      {saved ? <p className="muted" role="status">{saved}</p> : null}
      <Link className="button button--secondary" href="/onboarding">Rebuild my week</Link>
    </div>
  );
}
