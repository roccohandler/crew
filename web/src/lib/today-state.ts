// SPEC: S07 (correct today-state: bridge / workout / rest / paused / done) · 1D (the bridge persists until the first post exists) ·
// Flow 2 (weekly ring 2/4) · A1 (today's workout comes from the rotation projection, never from a weekday slot) · A3 (the
// what's-next line). The server-side twin of ios HomeModel.todayState for the web Home page. T036/T037
import type { ObjectId } from "mongodb";
import { crewMemberships, pauses, posts, sessions } from "@/lib/db";
import type { PlanDoc, WorkoutTemplateDoc } from "@/lib/documents";
import { addDays, dayKeyFor, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { lastRotationKind, nextTrainingDayKey, nextWorkoutKind, projectWeek, workoutKindFromName, type DayProjection } from "@/lib/engine/plan-rotation";
import { strengthLines, tailLine, type HomeExercise, type HomeLine } from "@/lib/engine/home-lines";
import { isStaleSession } from "@/lib/lapsed-user";
import { findPlan } from "@/lib/plans";
import { TimeUnits } from "@/lib/time-units";

export type TodayState =
  | { kind: "bridge"; workoutDay: boolean }
  // A14: the card carries the day's ACTUAL rows and the mobility/cardio tail, built by the HomeLines twin so the two
  // platforms print the same words. The count stays — it just stops being the loudest thing on the card.
  | { kind: "workout"; name: string; workoutKind: string; exerciseCount: number; hasCardio: boolean; lines: HomeLine[]; tail: string | null }
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
  nextUpLine: string | null; // A3: "Tomorrow: Pull day · 5 exercises" / "Next workout: Wed · Pull day"; null on an undone training day
  todayWorkoutKind: string | null; // A1: the rotation kind due today (null on rest, done, paused, no plan)
  week: DayProjection[]; // A1: this week's projection, Mon..Sun
  vectors: VectorSlots; // A14: today's Workout · Cardio · Meals row
}

export interface Rotation { cycle: string[]; nextKind: string | null; week: DayProjection[] }

// SPEC: A14 — today's state for each of the three logging vectors. A measurement or nothing: `null`/false renders as "—",
// never as a zero and never as "0/3" (A8, the same rule that strips the ring off the bridge). Twin of ios VectorSlots.
export interface VectorSlots { workoutDone: boolean; cardioMinutes: number | null; meals: number }

// SPEC: A1 — the pointer is DERIVED from history: the latest completed session whose kind is in the plan's cycle; the week
// projection assigns kinds sequentially from the next one. Shared by Home, the cron reminder and the plan week map.
export async function rotationFor(userId: ObjectId, plan: PlanDoc, todayKey: string): Promise<Rotation> {
  const cycle: string[] = plan.workouts.map((workout) => workout.kind);
  const history = await (await sessions()).find({ userId, status: "completed" }, { projection: { workoutName: 1, workoutKind: 1, completedAt: 1, status: 1, dayKey: 1 } }).sort({ completedAt: -1 }).toArray();
  const nextKind = cycle.length === 0 ? null : nextWorkoutKind(lastRotationKind(history.map((session) => ({ kind: session.workoutKind ?? null, name: session.workoutName, completedAt: session.completedAt?.getTime() ?? null, status: session.status })), cycle), cycle);
  const weekKey = weekKeyFor(todayKey);
  const completedKindByDay: Record<string, string> = {};
  for (const session of history) {
    const kind = session.workoutKind ?? workoutKindFromName(session.workoutName);
    if (kind !== null && cycle.includes(kind) && session.dayKey >= weekKey && completedKindByDay[session.dayKey] === undefined) completedKindByDay[session.dayKey] = kind;
  }
  const week = nextKind === null ? [] : projectWeek({ weekKey, todayKey, trainingWeekdays: plan.trainingWeekdays, cycle, nextKind, completedKindByDay });
  return { cycle, nextKind, week };
}

const strengthCount = (workout: WorkoutTemplateDoc) => workout.exercises.filter((row) => row.type === "strength").length;
const weekdayShort = (dayKey: string) => new Intl.DateTimeFormat("en-US", { weekday: "short", timeZone: "UTC" }).format(new Date(`${dayKey}T00:00:00Z`));

// The kind a training day gets: from this week's projection, or continuing the sequence past this week's planned days
function kindOn(dayKey: string, rotation: Rotation): string | null {
  const entry = rotation.week.find((day) => day.dayKey === dayKey);
  if (entry?.kind) return entry.kind;
  let kind = rotation.nextKind;
  for (let pending = rotation.week.filter((day) => day.state === "planned").length; pending > 0 && kind !== null; pending -= 1) kind = nextWorkoutKind(kind, rotation.cycle);
  return kind;
}

// SPEC: A3 — "Tomorrow: {name} · {n} exercises" when the next training day is tomorrow, else "Next workout: {Wed} · {name}";
// the bridge on a rest-day install reads "Tomorrow: Push day — your first workout." (nothing else competes, 1D)
function whatsNext(todayKey: string, plan: PlanDoc, rotation: Rotation, bridge: boolean): string | null {
  const nextDay = nextTrainingDayKey(todayKey, plan.trainingWeekdays);
  const workout = nextDay === null ? undefined : plan.workouts.find((candidate) => candidate.kind === kindOn(nextDay, rotation));
  if (nextDay === null || workout === undefined) return null;
  const tomorrow = nextDay === addDays(todayKey, 1);
  if (!tomorrow) return `Next workout: ${weekdayShort(nextDay)} · ${workout.name}`;
  if (bridge) return `Tomorrow: ${workout.name} — your first workout.`;
  const count = strengthCount(workout);
  return `Tomorrow: ${workout.name} · ${count} ${count === 1 ? "exercise" : "exercises"}`;
}

export async function homeFacts(userId: ObjectId, timezone: string, now: Date = new Date()): Promise<HomeFacts> {
  const todayKey = dayKeyFor(now, timezone);
  const [plan, todayPosts, lastPost, pause, membership, open] = await Promise.all([
    findPlan(userId),
    (await posts()).countDocuments({ userId, dayKey: todayKey, deletedAt: null }),
    (await posts()).findOne({ userId, deletedAt: null }, { sort: { dayKey: -1 }, projection: { dayKey: 1 } }),
    (await pauses()).findOne({ userId, startDay: { $lte: todayKey }, endDay: { $gt: todayKey } }),
    (await crewMemberships()).findOne({ userId }),
    (await sessions()).findOne({ userId, status: "inProgress" }, { sort: { startedAt: -1 } }),
  ]);
  const rotation: Rotation = plan === null ? { cycle: [], nextKind: null, week: [] } : await rotationFor(userId, plan, todayKey);
  const todayEntry = rotation.week.find((day) => day.dayKey === todayKey) ?? null;
  const workout = todayEntry?.state === "planned" ? (plan?.workouts.find((candidate) => candidate.kind === todayEntry.kind) ?? null) : null;
  let today: TodayState;
  if (pause !== null) today = { kind: "paused", until: pause.endDay };
  else if (lastPost === null) today = { kind: "bridge", workoutDay: workout !== null };
  else if (todayEntry === null || todayEntry.state === "rest") today = { kind: "rest", posted: todayPosts > 0 };
  else if (workout === null) today = { kind: "allDone" };
  else {
    const rows: HomeExercise[] = workout.exercises.map((row) => ({ name: row.name, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax ?? null, holdSeconds: row.holdSeconds ?? null, order: row.order }));
    today = { kind: "workout", name: workout.name, workoutKind: workout.kind, exerciseCount: strengthCount(workout), hasCardio: workout.exercises.some((row) => row.type === "cardio"), lines: strengthLines(rows), tail: tailLine(rows) };
  }
  const ring = await weeklyRing(userId, plan?.trainingWeekdays ?? [], todayKey);
  const showsNext = plan !== null && today.kind !== "workout" && today.kind !== "paused" && !(today.kind === "bridge" && today.workoutDay);
  return {
    todayKey, today, ...ring, hasPlan: plan !== null, inCrew: membership !== null, openSessionId: open?._id.toHexString() ?? null,
    openSessionStale: open !== null && isStaleSession(open.startedAt, now), openSessionName: open?.workoutName ?? null, lastPostDay: lastPost?.dayKey ?? null,
    quickCompleteAvailable: workout !== null && open === null,
    nextUpLine: showsNext && plan !== null ? whatsNext(todayKey, plan, rotation, today.kind === "bridge") : null,
    todayWorkoutKind: workout?.kind ?? null, week: rotation.week,
    vectors: await vectorSlots(userId, todayKey),
  };
}

// SPEC: A14 — today per vector, the server twin of ios HomeModel.slots. A completed session of kind `cardio` is CARDIO,
// not a workout: the same split A14 gives the post type, the journal row and the heat map. Ritual equality, never a score.
async function vectorSlots(userId: ObjectId, todayKey: string): Promise<VectorSlots> {
  const [completed, mealCount] = await Promise.all([
    (await sessions()).find({ userId, status: "completed", dayKey: todayKey }, { projection: { workoutKind: 1, exercises: 1 } }).toArray(),
    (await posts()).countDocuments({ userId, dayKey: todayKey, type: "meal", deletedAt: null }),
  ]);
  const cardioSeconds = completed
    .filter((session) => session.workoutKind === "cardio")
    .flatMap((session) => session.exercises.filter((row) => row.type === "cardio").flatMap((row) => row.sets))
    .filter((set) => set.done && !set.isWarmup)
    .reduce((total, set) => total + (set.holdSeconds ?? 0), 0);
  return {
    workoutDone: completed.some((session) => session.workoutKind !== "cardio"),
    cardioMinutes: cardioSeconds > 0 ? Math.round(cardioSeconds / TimeUnits.secondsPerMinute) : null,
    meals: mealCount,
  };
}

// SPEC: Flow 2 — done/planned this week; a standalone cardio log (A2) never fills a planned slot
async function weeklyRing(userId: ObjectId, plannedWeekdays: number[], todayKey: string): Promise<{ ringDone: number; ringPlanned: number }> {
  const weekKey = weekKeyFor(todayKey);
  const days = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(weekKey, offset));
  const completed = await (await sessions()).find({ userId, status: "completed", dayKey: { $in: days }, workoutKind: { $ne: "cardio" } }, { projection: { dayKey: 1 } }).toArray();
  const doneDays = new Set(completed.map((session) => session.dayKey));
  const planned = days.filter((day) => plannedWeekdays.includes(isoWeekday(day)));
  return { ringDone: planned.filter((day) => doneDays.has(day)).length, ringPlanned: planned.length };
}
