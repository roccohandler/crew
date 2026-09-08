"use client";
// SPEC: Flow 3 quick complete — trained phone-free? One tap logs the planned workout at its targets; hidden once today counts
// (S07). Creates the session from the plan and completes it in one round trip each.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { createSession, earnedQuery, getPlan, patchSession } from "@/lib/api-client";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import { SpecConstants } from "@/generated/spec-constants";

export function sessionBodyFrom(workout: { name: string; weekday: number; exercises: { exerciseId: string; name: string; equipment: string; type: "strength" | "mobility"; targetSets: number; targetReps: number; holdSeconds?: number; order: number }[] }, timezone: string, allDone: boolean) {
  return {
    clientId: crypto.randomUUID(),
    timezone,
    startedAt: new Date().toISOString(),
    workoutSnapshot: {
      name: workout.name,
      weekday: workout.weekday,
      isPlannedDay: true,
      exercises: workout.exercises.map((row) => ({
        exerciseId: row.exerciseId, name: row.name, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, holdSeconds: row.holdSeconds ?? null, order: row.order, skipped: false,
        sets: Array.from({ length: row.targetSets }, () => ({ targetReps: row.targetReps, actualReps: row.targetReps, weight: null, holdSeconds: row.holdSeconds ?? null, isWarmup: false, done: allDone })),
      })),
    },
  };
}

export function QuickCompleteButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const run = async () => {
    setBusy(true);
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const plan = await getPlan();
    const todayKey = dayKeyFor(new Date(), timezone); // the 3 AM day (E8), the same day Home judged — not the calendar date
    const workout = plan.workouts.find((candidate) => candidate.weekday === isoWeekday(todayKey));
    if (!workout) { setBusy(false); return; }
    const body = sessionBodyFrom(workout, timezone, true);
    const created = await createSession(body);
    const reply = await patchSession(created.session.id, { timezone, status: "completed", exercises: body.workoutSnapshot.exercises, post: { clientId: crypto.randomUUID(), shareToCrew: true } });
    router.push(`/session/${created.session.id}/done${earnedQuery(reply.gamification?.newAchievementIds)}`);
  };
  return <button type="button" className="button button--secondary" onClick={run} disabled={busy}>{busy ? "Logging…" : "Quick complete"}</button>;
}

export const quickCompleteHint = `Logs every set at ${SpecConstants.beginnerTargetReps}×target`; // used by tests to assert the constant flows through
