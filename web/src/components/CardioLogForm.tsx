"use client";
// SPEC: A2 · A3 (owner-directed 2026-09-08) · plan 2.1 "Log cardio" — the standalone log: nine activity tiles (≥ 44 px,
// last-used first), a minutes stepper pre-filled with the last log for that activity or the seed default, an optional distance,
// CTA "Log {activity}". One flow creates the A2 session and completes it: an unplanned workout (+25 per V30/V31) that sustains
// the streak like any post and never advances the rotation; then the normal celebration. Twin: ios CardioLogScreen.swift.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { CardioFields } from "@/components/CardioRow";
import { exercises, type SeedExercise } from "@/generated/seed";
import { createSession, earnedQuery, isApiClientError, patchSession } from "@/lib/api-client";
import { TimeUnits } from "@/lib/time-units";

type Props = { units: "lb" | "kg"; timezone: string; inCrew: boolean; lastActivityId: string | null; lastMinutes: Record<string, number> };

// The nine seeded activities, the last-used one first
function orderedActivities(lastActivityId: string | null): SeedExercise[] {
  const cardio = exercises.filter((exercise) => exercise.type === "cardio");
  const last = cardio.find((exercise) => exercise.id === lastActivityId);
  return last === undefined ? cardio : [last, ...cardio.filter((exercise) => exercise.id !== last.id)];
}

// SPEC: A2 · plan 1.3 — the standalone snapshot: kind "cardio", never a planned day, one cardio exercise with one done set
// (targetReps 0; a done cardio set is a work set, V51); holdSeconds carries the seconds, distanceMeters the optional distance
export function cardioSessionBody(activity: SeedExercise, seconds: number, distanceMeters: number | null, timezone: string) {
  return {
    clientId: crypto.randomUUID(),
    timezone,
    startedAt: new Date().toISOString(),
    workoutSnapshot: {
      name: activity.name,
      kind: "cardio",
      isPlannedDay: false,
      exercises: [{
        exerciseId: activity.id, name: activity.name, equipment: activity.equipment, type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: activity.holdSeconds ?? seconds, order: 0, skipped: false,
        sets: [{ targetReps: 0, actualReps: 0, weight: null, holdSeconds: seconds, distanceMeters, isWarmup: false, done: true }],
      }],
    },
  };
}

export function CardioLogForm({ units, timezone, inCrew, lastActivityId, lastMinutes }: Props) {
  const router = useRouter();
  const activities = orderedActivities(lastActivityId);
  const [activityId, setActivityId] = useState(activities[0]?.id ?? "");
  const [share, setShare] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const activity = activities.find((candidate) => candidate.id === activityId) ?? null;
  const defaultMinutes = activity === null ? 0 : (lastMinutes[activity.id] ?? Math.round((activity.holdSeconds ?? 0) / TimeUnits.secondsPerMinute));
  const submit = async (seconds: number, distanceMeters: number | null) => {
    if (activity === null) return;
    setBusy(true);
    setError(null);
    try {
      const created = await createSession(cardioSessionBody(activity, seconds, distanceMeters, timezone));
      const reply = await patchSession(created.session.id, { timezone, status: "completed", post: { clientId: crypto.randomUUID(), shareToCrew: inCrew && share } });
      router.push(`/session/${created.session.id}/done${earnedQuery(reply.gamification?.newAchievementIds)}`);
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't log that. Try again.");
      setBusy(false);
    }
  };
  return (
    <div className="stack">
      <h1>Log cardio</h1>
      {lastActivityId === null ? <p className="muted">Any length counts. A slow walk is a walk.</p> : null}
      <div className="row row--wrap" role="group" aria-label="Activity">
        {activities.map((candidate) => <button key={candidate.id} type="button" className="chip" aria-pressed={candidate.id === activityId} onClick={() => setActivityId(candidate.id)}>{candidate.name}</button>)}
      </div>
      {activity !== null ? <CardioFields key={activity.id} name={activity.name} defaultMinutes={defaultMinutes} units={units} action={`Log ${activity.name.toLowerCase()}`} disabled={busy} onSubmit={submit} /> : null}
      {inCrew ? <label className="row"><input type="checkbox" checked={share} onChange={(event) => setShare(event.target.checked)} /> Share to crew</label> : null}
      {error ? <p className="danger" role="alert">{error}</p> : null}
    </div>
  );
}
