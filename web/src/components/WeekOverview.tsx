"use client";
// SPEC: A4 · S14 — the week map: seven rows with zero controls (one link each), done days ✓, open past days "—" (no word, no
// red), rest rows; the rotation stated in copy (forward-only, A1); "Change days" edits trainingWeekdays without a rebuild;
// "Rebuild my week" goes through the questions again. Web twin of ios PlanScreen + WeekRow + DaysSheet.
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { DayToggles, WEEKDAY_NAMES } from "@/components/onboarding/DaysQuestion";
import { putPlan } from "@/lib/api-client";
import { nextWorkoutKind, type DayProjection } from "@/lib/engine/plan-rotation";
import { setTrainingWeekdays, strengthCount, type DraftWorkout } from "@/lib/plan-draft";

interface Props { trainingWeekdays: number[]; workouts: DraftWorkout[]; week: DayProjection[]; cycle: string[]; nextKind: string | null; savedName: string | null }

const dayName = (day: DayProjection): string => WEEKDAY_NAMES[day.weekday - 1] ?? "";

function WeekRow({ day, workouts }: { day: DayProjection; workouts: DraftWorkout[] }) {
  const workout = workouts.find((candidate) => candidate.kind === day.kind);
  if (day.state === "rest") return <li className="card muted">{dayName(day)} · Rest</li>;
  if (day.state === "open" || workout === undefined) return <li className="card muted">{dayName(day)} · —</li>;
  return (
    <li>
      <Link href={`/plan/${workout.kind}`} className="button button--secondary row row--between">
        <span className="stack stack--tight">
          <strong>{dayName(day)} · {day.state === "done" ? "✓ " : ""}{workout.name}</strong>
          <span className="muted">{strengthCount(workout)} exercises + mobility</span>
        </span>
        <span aria-hidden="true">›</span>
      </Link>
    </li>
  );
}

// SPEC: A1 — "Next week starts with {name}" only when the cycle does not divide the training days (the carry-over is visible)
function nextWeekLine({ trainingWeekdays, workouts, week, cycle, nextKind }: Props): string | null {
  if (cycle.length === 0 || nextKind === null || trainingWeekdays.length % cycle.length === 0) return null;
  const lastPlanned = [...week].reverse().find((day) => day.state === "planned");
  const startKind = lastPlanned?.kind ? nextWorkoutKind(lastPlanned.kind, cycle) : nextKind;
  const workout = workouts.find((candidate) => candidate.kind === startKind);
  return workout === undefined ? null : `Next week starts with ${workout.name}`;
}

export function WeekOverview(props: Props) {
  const router = useRouter();
  const [days, setDays] = useState(props.trainingWeekdays);
  const [editingDays, setEditingDays] = useState(false);
  const [status, setStatus] = useState<string | null>(props.savedName === null ? null : `Saved · applies from your next ${props.savedName}`);
  const saveDays = async () => {
    try {
      await putPlan(setTrainingWeekdays(props, days));
      setEditingDays(false);
      setStatus("Saved · your days apply from today");
      router.refresh();
    } catch {
      setStatus("Couldn't save. Your days are still here — try again.");
    }
  };
  const carry = nextWeekLine(props);
  return (
    <div className="stack">
      <h1>Your week</h1>
      <p className="muted">Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.</p>
      {status ? <p className="muted" role="status">{status}</p> : null}
      <ul className="stack stack--tight" style={{ listStyle: "none", padding: 0, margin: 0 }}>
        {props.week.map((day) => <WeekRow key={day.dayKey} day={day} workouts={props.workouts} />)}
      </ul>
      {carry ? <p className="whisper">{carry}</p> : null}
      {editingDays ? (
        <section className="card stack" aria-label="Change days">
          <DayToggles days={days} onToggle={(weekday) => setDays(days.includes(weekday) ? days.filter((day) => day !== weekday) : [...days, weekday])} />
          <div className="row">
            <button type="button" className="button button--primary" disabled={days.length === 0} onClick={saveDays}>Save days</button>
            <button type="button" className="button button--text" onClick={() => { setDays(props.trainingWeekdays); setEditingDays(false); }}>Cancel</button>
          </div>
        </section>
      ) : <button type="button" className="button button--secondary" onClick={() => setEditingDays(true)}>Change days</button>}
      <Link className="button button--secondary" href="/onboarding">Rebuild my week</Link>
    </div>
  );
}
