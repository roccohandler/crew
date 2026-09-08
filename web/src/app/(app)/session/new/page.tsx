// SPEC: S08 → S09 — [Start Workout] creates today's session from the plan's template (the snapshot) and opens it; an open
// session resumes instead (S07 Resume). Web twin of ios HomeModel.startWorkout. T037
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { sessions } from "@/lib/db";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";
import { createSession } from "@/lib/sessions";

export default async function NewSessionPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const open = await (await sessions()).findOne({ userId, status: "inProgress" }, { sort: { startedAt: -1 } });
  if (open !== null) redirect(`/session/${open._id.toHexString()}`);
  const plan = await findPlan(userId);
  const todayKey = dayKeyFor(new Date(), session.user.timezone);
  const workout = plan?.workouts.find((candidate) => candidate.weekday === isoWeekday(todayKey));
  if (!workout) redirect("/home");
  const created = await createSession(userId, {
    clientId: crypto.randomUUID(),
    timezone: session.user.timezone,
    startedAt: new Date().toISOString(),
    workoutSnapshot: {
      name: workout.name,
      weekday: workout.weekday,
      isPlannedDay: true,
      exercises: workout.exercises.map((row) => ({
        exerciseId: row.exerciseId, name: row.name, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, holdSeconds: row.holdSeconds ?? null, order: row.order, skipped: false,
        sets: Array.from({ length: row.targetSets }, () => ({ targetReps: row.targetReps, actualReps: row.targetReps, weight: row.targetWeight ?? null, holdSeconds: row.holdSeconds ?? null, isWarmup: false, done: false })),
      })),
    },
  });
  redirect(`/session/${created.session._id.toHexString()}`);
}
