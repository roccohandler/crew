"use client";
// SPEC: A4 · Flow 8 — one workout, Cancel / Save (Save disabled until dirty); rows with one tap target opening the exercise
// sheet; Reorder ↔ Done reveals Move up / Move down; Add exercise · Add cardio (A2); the mobility block closes the workout
// (read-only footer); Remove → "Removed {name} · Undo"; Cancel with a dirty draft asks "Discard changes to {name}?"; Save
// writes the whole plan forward-only and lands on the week map with "Saved · applies from your next {name}". Web twin of
// ios WorkoutEditorScreen.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { cardioMinutes, ExercisePicker, ExerciseSheet, repsLabel } from "@/components/ExerciseSheet";
import { putPlan } from "@/lib/api-client";
import { addCandidates, addCardio, addStrengthRow, adjustMinutes, adjustReps, adjustSets, cardioActivities, editableRows, estimatedMinutes, hasCardio, isFull, mobilityMinutes, mobilityRows, moveRow, removeRow, restoreRow, strengthCount, swapRow, type DraftRow, type DraftWorkout } from "@/lib/plan-draft";
import { SpecConstants } from "@/generated/spec-constants";

interface Props { trainingWeekdays: number[]; workouts: DraftWorkout[]; workout: DraftWorkout }
interface Ui { reorder: boolean; sheet: number | null; picker: "exercise" | "cardio" | null; removed: DraftRow | null; confirm: boolean; error: string | null }
const QUIET: Ui = { reorder: false, sheet: null, picker: null, removed: null, confirm: false, error: null };

const rowTitle = (row: DraftRow): string => (row.type === "cardio" ? `${row.name} · ${cardioMinutes(row)} min` : row.name);
const rowLine = (row: DraftRow): string => (row.type === "cardio" ? "Cardio" : `${row.targetSets} × ${repsLabel(row)} · ${row.equipment}`);

function ExerciseRow({ row, reorder, first, last, onOpen, onMove }: { row: DraftRow; reorder: boolean; first: boolean; last: boolean; onOpen: () => void; onMove: (direction: number) => void }) {
  if (reorder) {
    return (
      <li className="card row row--between row--wrap">
        <span>{rowTitle(row)}</span>
        <span className="row">
          <button type="button" className="button button--text" disabled={first} onClick={() => onMove(-1)} aria-label={`Move ${row.name} up`}>Move up</button>
          <button type="button" className="button button--text" disabled={last} onClick={() => onMove(1)} aria-label={`Move ${row.name} down`}>Move down</button>
        </span>
      </li>
    );
  }
  return (
    <li>
      <button type="button" className="button button--secondary row row--between" onClick={onOpen} aria-label={`${rowTitle(row)}, ${rowLine(row)}`}>
        <span className="stack stack--tight"><strong>{rowTitle(row)}</strong><span className="muted">{rowLine(row)}</span></span>
        <span aria-hidden="true">›</span>
      </button>
    </li>
  );
}

function MobilityFooter({ workout }: { workout: DraftWorkout }) {
  const holds = mobilityRows(workout);
  return (
    <footer className="stack stack--tight">
      <p className="muted">Mobility · {holds.length} holds · ~{mobilityMinutes(workout)} min · closes the workout</p>
      {holds.map((hold) => <p key={hold.order} className="whisper">{hold.name} · {hold.holdSeconds}s{hold.perSide ? " each side" : ""}</p>)}
    </footer>
  );
}

function Dialogs({ draft, ui, setUi, edit }: { draft: DraftWorkout; ui: Ui; setUi: (next: Ui) => void; edit: (next: DraftWorkout, removed?: DraftRow | null) => void }) {
  const rows = editableRows(draft);
  const open = rows.find((row) => row.order === ui.sheet);
  if (ui.confirm) return null;
  if (ui.picker === "exercise") return <ExercisePicker title="Add exercise" candidates={addCandidates(draft)} onPick={(exercise) => { edit(addStrengthRow(draft, exercise)); setUi(QUIET); }} onClose={() => setUi(QUIET)} />;
  if (ui.picker === "cardio") return <ExercisePicker title="Add cardio" candidates={cardioActivities()} onPick={(activity) => { edit(addCardio(draft, activity)); setUi(QUIET); }} onClose={() => setUi(QUIET)} />;
  if (open === undefined) return null;
  return <ExerciseSheet row={open} workoutName={draft.name} rows={rows} onSets={(direction) => edit(adjustSets(draft, open.order, direction))} onReps={(direction) => edit(adjustReps(draft, open.order, direction))} onMinutes={(direction) => edit(adjustMinutes(draft, open.order, direction))} onSwap={(replacement) => edit(swapRow(draft, open.order, replacement))}
    onMove={(direction) => { const next = moveRow(draft, open.order, direction); const moved = editableRows(next).find((row) => row.exerciseId === open.exerciseId); edit(next); setUi({ ...ui, sheet: moved?.order ?? null }); }}
    onRemove={() => { edit(removeRow(draft, open.order), open); setUi({ ...QUIET, removed: open }); }} onClose={() => setUi(QUIET)} />;
}

export function WorkoutEditor({ trainingWeekdays, workouts, workout }: Props) {
  const router = useRouter();
  const [draft, setDraft] = useState(workout);
  const [dirty, setDirty] = useState(false);
  const [ui, setUi] = useState<Ui>(QUIET);
  const edit = (next: DraftWorkout, removed: DraftRow | null = null) => { setDraft(next); setDirty(true); setUi({ ...ui, removed, error: null }); };
  const save = async () => {
    try { await putPlan({ trainingWeekdays, workouts: workouts.map((candidate) => (candidate.kind === draft.kind ? draft : candidate)) }); router.push(`/plan?saved=${draft.kind}`); }
    catch { setUi({ ...ui, error: "Couldn't save. Your changes are still here." }); }
  };
  const cancel = () => { if (dirty) setUi({ ...QUIET, confirm: true }); else router.push("/plan"); };
  const rows = editableRows(draft);
  return (
    <div className="stack">
      <div className="row row--between">
        <button type="button" className="button button--text" onClick={cancel}>Cancel</button>
        <h1>{draft.name}</h1>
        <button type="button" className="button button--text" disabled={!dirty} onClick={save}>Save</button>
      </div>
      <p className="muted">{strengthCount(draft)} exercises + mobility · ~{estimatedMinutes(draft)} min</p>
      <div className="row row--between"><h2>Exercises</h2><button type="button" className="button button--text" onClick={() => setUi({ ...QUIET, reorder: !ui.reorder })}>{ui.reorder ? "Done" : "Reorder"}</button></div>
      {rows.length === 0 ? <p className="muted">No exercises yet — add one to build {draft.name}</p> : null}
      <ul className="stack stack--tight" style={{ listStyle: "none", padding: 0, margin: 0 }}>
        {rows.map((row, index) => <ExerciseRow key={`${row.exerciseId}-${row.order}`} row={row} reorder={ui.reorder} first={index === 0} last={index === rows.length - 1} onOpen={() => setUi({ ...QUIET, sheet: row.order })} onMove={(direction) => edit(moveRow(draft, row.order, direction))} />)}
      </ul>
      {ui.removed ? <div className="row row--between" role="status"><span>Removed {ui.removed.name}</span><button type="button" className="button button--text" onClick={() => { edit(restoreRow(draft, ui.removed as DraftRow)); }}>Undo</button></div> : null}
      {isFull(draft) ? <p className="whisper">{draft.name} is full · {SpecConstants.planMaxExercisesPerDay} exercises</p> : <div className="row row--wrap">
        <button type="button" className="button button--secondary" onClick={() => setUi({ ...QUIET, picker: "exercise" })}>Add exercise</button>
        {hasCardio(draft) ? null : <button type="button" className="button button--secondary" onClick={() => setUi({ ...QUIET, picker: "cardio" })}>Add cardio</button>}
      </div>}
      <MobilityFooter workout={draft} />
      {ui.error ? <p className="danger" role="alert">{ui.error}</p> : null}
      <Dialogs draft={draft} ui={ui} setUi={setUi} edit={edit} />
      {ui.confirm ? <dialog open className="card stack" aria-label={`Discard changes to ${draft.name}?`}><h2>Discard changes to {draft.name}?</h2><div className="row row--wrap"><button type="button" className="button button--primary" onClick={() => router.push("/plan")}>Discard changes</button><button type="button" className="button button--secondary" onClick={() => setUi(QUIET)}>Keep editing</button></div></dialog> : null}
    </div>
  );
}
