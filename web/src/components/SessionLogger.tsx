"use client";
// SPEC: S09 — one-tap set logging at pre-fill, ghost row, warm-ups excluded from x/y, holds, cardio rows (A2), rest timer,
// out-of-order (any exercise opens), neutral skips, Complete always visible (sticky), every tap saves (PATCH). Web twin of ios
// SessionModel + SessionScreen.
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { CardioRow } from "@/components/CardioRow";
import { HoldRow } from "@/components/HoldRow";
import { RestTimer } from "@/components/RestTimer";
import { accessFor, SessionSwap, swappedExercise, updatePlanWithSwap, type SwapScope } from "@/components/SessionSwap";
import { SetRow } from "@/components/SetRow";
import { exercises as seedExercises, type SeedExercise } from "@/generated/seed";
import { earnedQuery, patchSession, type SessionExerciseView, type SessionSummary } from "@/lib/api-client";
import { asPlanned, completionFacts } from "@/lib/engine/completion";
import { workoutKindFromName } from "@/lib/engine/plan-rotation";
import { SpecConstants } from "@/generated/spec-constants";

type Props = { initial: SessionSummary; units: "lb" | "kg"; timezone: string; lastTime: Record<string, string>; inCrew: boolean };
type SetUpdate = (index: number, next: SessionExerciseView["sets"][number]) => void;

// One set line by exercise type: a hold counts down (Flow 3), a cardio block takes minutes + distance (A2), a strength set is the tap row
function SetLine({ exercise, set, index, units, onSet }: { exercise: SessionExerciseView; set: SessionExerciseView["sets"][number]; index: number; units: "lb" | "kg"; onSet: SetUpdate }) {
  if (exercise.type === "mobility") return <HoldRow name={exercise.name} seconds={set.holdSeconds ?? 0} perSide={seedExercises.find((candidate) => candidate.id === exercise.exerciseId)?.perSide ?? false} done={set.done} onFinished={() => onSet(index, { ...set, done: true, asPlanned: true })} />;
  if (exercise.type === "cardio") return <CardioRow name={exercise.name} seconds={set.holdSeconds ?? exercise.holdSeconds ?? 0} distanceMeters={set.distanceMeters ?? null} units={units} done={set.done} onDone={(seconds, distanceMeters) => onSet(index, { ...set, holdSeconds: seconds, distanceMeters, done: true, asPlanned: true })} />;
  const firstOpen = exercise.sets.findIndex((candidate) => !candidate.done && !candidate.isWarmup);
  const workCount = exercise.sets.filter((candidate) => !candidate.isWarmup).length;
  return <SetRow exerciseName={exercise.name} equipment={exercise.equipment} set={set} index={exercise.sets.slice(0, index + 1).filter((candidate) => !candidate.isWarmup).length} count={workCount} units={units} ghost={firstOpen >= 0 && index > firstOpen}
    onCheck={() => onSet(index, { ...set, done: !set.done, asPlanned: asPlanned({ ...set, done: !set.done }) })}
    onReps={(direction) => onSet(index, { ...set, actualReps: Math.max(0, set.actualReps + direction * SpecConstants.repsStep) })}
    onWeight={(direction) => onSet(index, { ...set, weight: Math.max(0, (set.weight ?? 0) + direction * (units === "lb" ? SpecConstants.weightStepLb : SpecConstants.weightStepKg)) })} />;
}

function ExerciseCard({ exercise, open, units, lastTime, onOpen, onSkip, onSwap, onSet }: { exercise: SessionExerciseView; open: boolean; units: "lb" | "kg"; lastTime?: string; onOpen: () => void; onSkip: () => void; onSwap: () => void; onSet: SetUpdate }) {
  return (
    <section className="card stack stack--tight">
      <div className="row row--between">
        <h3 className={exercise.skipped ? "missed" : ""}>{exercise.name}</h3>
        <span className="chip" aria-hidden="true">{exercise.equipment}</span>
        {exercise.type === "strength" && !exercise.skipped ? <button type="button" className="button button--text" onClick={onSwap} aria-label={`Swap ${exercise.name}`}>Swap</button> : null}
        <button type="button" className="button button--text" onClick={onSkip}>{exercise.skipped ? "Unskip" : "Skip"}</button>
      </div>
      {lastTime ? <p className="whisper">{lastTime}</p> : null}
      {!open && !exercise.skipped ? <button type="button" className="button button--text" onClick={onOpen}>Open</button> : null}
      {open && !exercise.skipped ? exercise.sets.map((set, index) => <SetLine key={index} exercise={exercise} set={set} index={index} units={units} onSet={onSet} />) : null}
    </section>
  );
}

// E7: "Just today" rewrites the snapshot; "Update my plan" also replaces the exercise in the plan's workout of this kind, forward-only
async function performSwap(exercises: SessionExerciseView[], index: number, replacement: SeedExercise, scope: SwapScope, kind: string | null, save: (next: SessionExerciseView[]) => Promise<void>, onPlanError: () => void): Promise<void> {
  const current = exercises[index];
  if (current === undefined) return;
  await save(exercises.map((exercise, candidate) => (candidate === index ? swappedExercise(exercise, replacement) : exercise)));
  if (scope === "plan") await updatePlanWithSwap(kind, current.exerciseId, replacement).catch(onPlanError);
}

function withSet(exercises: SessionExerciseView[], exerciseIndex: number, setIndex: number, set: SessionExerciseView["sets"][number]): SessionExerciseView[] {
  return exercises.map((exercise, index) => (index === exerciseIndex ? { ...exercise, sets: exercise.sets.map((candidate, candidateIndex) => (candidateIndex === setIndex ? set : candidate)) } : exercise));
}

export function SessionLogger({ initial, units, timezone, lastTime, inCrew }: Props) {
  const router = useRouter();
  const [exercises, setExercises] = useState(initial.exercises);
  const [focus, setFocus] = useState(0);
  const [share, setShare] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [restToken, setRestToken] = useState(0); // G9: every checked set (re)starts the rest countdown
  const [swapping, setSwapping] = useState<number | null>(null); // E7: which exercise is being swapped
  const facts = completionFacts(exercises.flatMap((exercise) => exercise.sets));
  const kind = initial.workoutKind ?? workoutKindFromName(initial.workoutName); // A1: legacy sessions carry only a name
  const lastSave = useRef<Promise<unknown>>(Promise.resolve()); // every tap saves; Complete waits for the last one (no reply races)
  const save = async (next: SessionExerciseView[]) => {
    setExercises(next);
    lastSave.current = patchSession(initial.id, { timezone, exercises: next }).catch(() => setError("Couldn't save that. Check your connection and try again."));
    await lastSave.current;
  };
  const updateSet = (exerciseIndex: number, setIndex: number, set: SessionExerciseView["sets"][number]) => {
    if (set.done && !set.isWarmup) setRestToken((token) => token + 1);
    void save(withSet(exercises, exerciseIndex, setIndex, set));
  };
  const swap = (replacement: SeedExercise, scope: SwapScope) => { if (swapping !== null) { setSwapping(null); void performSwap(exercises, swapping, replacement, scope, kind, save, () => setError("Swapped for today, but the plan didn't save. Try again from Plan.")); } };
  const complete = async () => {
    if (!facts.complete) { setError("Check off at least one set and this counts."); return; }
    await lastSave.current;
    const reply = await patchSession(initial.id, { timezone, exercises, status: "completed", post: { clientId: crypto.randomUUID(), shareToCrew: inCrew && share } });
    router.push(`/session/${initial.id}/done${earnedQuery(reply.gamification?.newAchievementIds)}`);
  };
  return (
    <div className="stack">
      <h1>{initial.workoutName}</h1>
      <p className="muted">{facts.setsDone}/{facts.setsPlanned} sets</p>
      <RestTimer startToken={restToken} />
      {exercises.map((exercise, index) => <ExerciseCard key={exercise.order} exercise={exercise} open={index === focus} units={units} lastTime={lastTime[exercise.exerciseId]} onOpen={() => setFocus(index)} onSwap={() => setSwapping(index)} onSkip={() => void save(exercises.map((candidate, candidateIndex) => (candidateIndex === index ? { ...candidate, skipped: !candidate.skipped } : candidate)))} onSet={(setIndex, set) => updateSet(index, setIndex, set)} />)}
      {swapping !== null && exercises[swapping] ? <SessionSwap exercise={exercises[swapping]} access={accessFor(exercises)} onPick={swap} onClose={() => setSwapping(null)} /> : null}
      {inCrew ? <label className="row"><input type="checkbox" checked={share} onChange={(event) => setShare(event.target.checked)} /> Share to crew</label> : null}
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="button" className="button button--primary" onClick={complete}>Complete workout</button>
    </div>
  );
}
