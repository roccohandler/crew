// SPEC: S08 → S09 — [Start Workout] creates today's session from the plan's template (the snapshot) and opens it; an open
// session resumes instead (S07 Resume). A1: today's workout is the rotation kind due today (projectWeek), never a weekday slot;
// the snapshot names its kind. A3 / Flow 5: ?bonus=<kind> starts that workout — isPlannedDay only when today is an undone
// training day (then it is simply the planned workout), false on a rest day (+25). Web twin of ios HomeModel.startWorkout. T037
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { sessions } from "@/lib/db";
import type { WorkoutTemplateDoc } from "@/lib/documents";
import { dayKeyFor } from "@/lib/engine/day-key";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";
import { createSession } from "@/lib/sessions";
import { rotationFor } from "@/lib/today-state";
import { openingReps, openingWeight, prefillFacts, type PrefillSet } from "@/lib/engine/set-prefill";

// SPEC: A12 — every strength row opens at the last ACTUAL performance of that exercise (Flow 3's promise, finally used);
// a hold or cardio block still opens at its planned seconds, and an exercise with no history opens at the plan's targets.
// A9: the unit the weight was entered in carries forward with it. Twin of ios SessionActions.startSession.
function snapshotOf(workout: WorkoutTemplateDoc, isPlannedDay: boolean, history: Map<string, PrefillSet[][]>) {
  return {
    name: workout.name,
    kind: workout.kind,
    isPlannedDay,
    exercises: workout.exercises.map((row) => {
      const facts = prefillFacts(history.get(row.exerciseId) ?? []);
      const reps = row.type === "strength" ? openingReps(row.targetReps, facts) : row.targetReps;
      const weight = row.type === "strength" ? openingWeight(row.targetWeight ?? null, facts) : (row.targetWeight ?? null);
      return {
      exerciseId: row.exerciseId, name: row.name, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, holdSeconds: row.holdSeconds ?? null, order: row.order, skipped: false,
      sets: Array.from({ length: row.targetSets }, () => ({ targetReps: row.targetReps, actualReps: reps, weight, holdSeconds: row.holdSeconds ?? null, weightUnit: facts?.weightUnit ?? undefined, isWarmup: false, done: false })),
      };
    }),
  };
}

// SPEC: A12 — one exercise's rows out of the completed history, newest session first; prefillFacts picks from them.
// Only the workout's own exercises are read, and only strength rows, so this is a single bounded query per session start.
async function prefillHistory(userId: ObjectId, workout: WorkoutTemplateDoc): Promise<Map<string, PrefillSet[][]>> {
  const ids = workout.exercises.filter((row) => row.type === "strength").map((row) => row.exerciseId);
  const history = new Map<string, PrefillSet[][]>();
  if (ids.length === 0) return history;
  const completed = await (await sessions())
    .find({ userId, status: "completed" }, { projection: { exercises: 1, completedAt: 1 }, sort: { completedAt: -1 } })
    .toArray();
  for (const id of ids) {
    history.set(id, completed.flatMap((doc) => {
      const row = doc.exercises.find((candidate) => candidate.exerciseId === id && candidate.type === "strength");
      return row === undefined ? [] : [row.sets.map((set) => ({ actualReps: set.actualReps, weight: set.weight, weightUnit: set.weightUnit, done: set.done, isWarmup: set.isWarmup }))];
    }));
  }
  return history;
}

export default async function NewSessionPage({ searchParams }: { searchParams: Promise<{ bonus?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const bonus = (await searchParams).bonus ?? null;
  const open = await (await sessions()).findOne({ userId, status: "inProgress" }, { sort: { startedAt: -1 } });
  if (open !== null) redirect(`/session/${open._id.toHexString()}`);
  const plan = await findPlan(userId);
  if (plan === null) redirect("/home");
  const todayKey = dayKeyFor(new Date(), session.user.timezone);
  const rotation = await rotationFor(userId, plan, todayKey);
  const todayEntry = rotation.week.find((day) => day.dayKey === todayKey) ?? null;
  const plannedToday = todayEntry !== null && todayEntry.state === "planned"; // an undone training day
  const kind = bonus ?? (plannedToday ? todayEntry.kind : null);
  const workout = kind === null ? undefined : plan.workouts.find((candidate) => candidate.kind === kind);
  if (workout === undefined) redirect("/home");
  const created = await createSession(userId, { clientId: crypto.randomUUID(), timezone: session.user.timezone, startedAt: new Date().toISOString(), workoutSnapshot: snapshotOf(workout, plannedToday, await prefillHistory(userId, workout)) });
  redirect(`/session/${created.session._id.toHexString()}`);
}
