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

// The snapshot: every set pre-filled at its target (weight from the plan when set; a hold or cardio block at its seconds)
function snapshotOf(workout: WorkoutTemplateDoc, isPlannedDay: boolean) {
  return {
    name: workout.name,
    kind: workout.kind,
    isPlannedDay,
    exercises: workout.exercises.map((row) => ({
      exerciseId: row.exerciseId, name: row.name, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, holdSeconds: row.holdSeconds ?? null, order: row.order, skipped: false,
      sets: Array.from({ length: row.targetSets }, () => ({ targetReps: row.targetReps, actualReps: row.targetReps, weight: row.targetWeight ?? null, holdSeconds: row.holdSeconds ?? null, isWarmup: false, done: false })),
    })),
  };
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
  const created = await createSession(userId, { clientId: crypto.randomUUID(), timezone: session.user.timezone, startedAt: new Date().toISOString(), workoutSnapshot: snapshotOf(workout, plannedToday) });
  redirect(`/session/${created.session._id.toHexString()}`);
}
