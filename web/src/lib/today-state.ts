// SPEC: S07 (correct today-state: bridge / workout / rest / paused / done) · 1D (the bridge persists until the first post exists) ·
// Flow 2 (weekly ring 2/4). The server-side twin of ios HomeModel.todayState for the web Home page. T036/T037
import type { ObjectId } from "mongodb";
import { crewMemberships, pauses, posts, sessions } from "@/lib/db";
import { addDays, dayKeyFor, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { isStaleSession } from "@/lib/lapsed-user";
import { findPlan } from "@/lib/plans";
import { TimeUnits } from "@/lib/time-units";

export type TodayState =
  | { kind: "bridge"; workoutDay: boolean }
  | { kind: "workout"; name: string; exerciseCount: number; weekday: number }
  | { kind: "rest"; posted: boolean }
  | { kind: "paused"; until: string }
  | { kind: "allDone" };

export interface HomeFacts {
  todayKey: string;
  today: TodayState;
  ringDone: number;
  ringPlanned: number;
  hasPlan: boolean;
  inCrew: boolean;
  openSessionId: string | null;
  openSessionStale: boolean; // S01: in progress for more than a day
  openSessionName: string | null;
  lastPostDay: string | null; // E4: the last activity of any kind
  quickCompleteAvailable: boolean;
}

export async function homeFacts(userId: ObjectId, timezone: string, now: Date = new Date()): Promise<HomeFacts> {
  const todayKey = dayKeyFor(now, timezone);
  const weekday = isoWeekday(todayKey);
  const [plan, todaySessions, todayPosts, lastPost, pause, membership, open] = await Promise.all([
    findPlan(userId),
    (await sessions()).find({ userId, dayKey: todayKey, status: "completed" }).toArray(),
    (await posts()).countDocuments({ userId, dayKey: todayKey, deletedAt: null }),
    (await posts()).findOne({ userId, deletedAt: null }, { sort: { dayKey: -1 }, projection: { dayKey: 1 } }),
    (await pauses()).findOne({ userId, startDay: { $lte: todayKey }, endDay: { $gt: todayKey } }),
    (await crewMemberships()).findOne({ userId }),
    (await sessions()).findOne({ userId, status: "inProgress" }, { sort: { startedAt: -1 } }),
  ]);
  const workout = plan?.workouts.find((candidate) => candidate.weekday === weekday) ?? null;
  const doneToday = todaySessions.length > 0;
  let today: TodayState;
  if (pause !== null) today = { kind: "paused", until: pause.endDay };
  else if (lastPost === null) today = { kind: "bridge", workoutDay: workout !== null };
  else if (workout === null) today = { kind: "rest", posted: todayPosts > 0 };
  else if (doneToday) today = { kind: "allDone" };
  else today = { kind: "workout", name: workout.name, exerciseCount: workout.exercises.filter((row) => row.type === "strength").length, weekday };
  const ring = await weeklyRing(userId, plan?.workouts.map((candidate) => candidate.weekday) ?? [], todayKey);
  return {
    todayKey, today, ...ring, hasPlan: plan !== null, inCrew: membership !== null, openSessionId: open?._id.toHexString() ?? null,
    openSessionStale: open !== null && isStaleSession(open.startedAt, now), openSessionName: open?.workoutName ?? null, lastPostDay: lastPost?.dayKey ?? null,
    quickCompleteAvailable: workout !== null && !doneToday && open === null,
  };
}

async function weeklyRing(userId: ObjectId, plannedWeekdays: number[], todayKey: string): Promise<{ ringDone: number; ringPlanned: number }> {
  const weekKey = weekKeyFor(todayKey);
  const days = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(weekKey, offset));
  const completed = await (await sessions()).find({ userId, status: "completed", dayKey: { $in: days } }, { projection: { dayKey: 1 } }).toArray();
  const doneDays = new Set(completed.map((session) => session.dayKey));
  const planned = days.filter((day) => plannedWeekdays.includes(isoWeekday(day)));
  return { ringDone: planned.filter((day) => doneDays.has(day)).length, ringPlanned: planned.length };
}
