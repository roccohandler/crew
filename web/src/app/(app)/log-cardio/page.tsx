// SPEC: A2 · A3 (owner-directed 2026-09-08) · plan 2.1 — /log-cardio: the standalone cardio log on web. Units and crew come
// from the session; "last-used first" and the pre-filled minutes come from the user's own completed cardio logs (the server is
// the memory — nothing is stored in the browser). The one h1 lives in the form.
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { CardioLogForm } from "@/components/CardioLogForm";
import { crewMemberships, sessions } from "@/lib/db";
import { readSession } from "@/lib/session";
import { TimeUnits } from "@/lib/time-units";

// SPEC: plan 2.1 — the latest completed cardio log names the last-used activity; per activity, the latest logged minutes
async function lastLogs(userId: ObjectId): Promise<{ lastActivityId: string | null; lastMinutes: Record<string, number> }> {
  const logs = await (await sessions()).find({ userId, status: "completed", workoutKind: "cardio" }, { projection: { exercises: 1 }, sort: { completedAt: -1 } }).toArray();
  const lastMinutes: Record<string, number> = {};
  for (const log of logs) {
    for (const exercise of log.exercises) {
      const seconds = exercise.sets.filter((set) => set.done).reduce((sum, set) => sum + (set.holdSeconds ?? 0), 0);
      if (seconds > 0 && lastMinutes[exercise.exerciseId] === undefined) lastMinutes[exercise.exerciseId] = Math.round(seconds / TimeUnits.secondsPerMinute);
    }
  }
  return { lastActivityId: logs[0]?.exercises[0]?.exerciseId ?? null, lastMinutes };
}

export default async function LogCardioPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const [membership, last] = await Promise.all([(await crewMemberships()).findOne({ userId }), lastLogs(userId)]);
  return <CardioLogForm units={session.user.units} timezone={session.user.timezone} inCrew={membership !== null} lastActivityId={last.lastActivityId} lastMinutes={last.lastMinutes} />;
}
