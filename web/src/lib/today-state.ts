// SPEC: S07 (correct today-state: bridge / workout / rest / paused / done) · 1D (the bridge persists until the first post exists) ·
// Flow 2 (weekly ring 2/4) · A1 (today's workout comes from the rotation projection, never from a weekday slot) · A3 (the
// what's-next line). The server-side twin of ios HomeModel.todayState for the web Home page. T036/T037
import type { ObjectId } from "mongodb";
import { crewMemberships, pauses, posts, sessions } from "@/lib/db";
import type { PlanDoc, WorkoutTemplateDoc } from "@/lib/documents";
import { addDays, dayKeyFor, weekKeyFor } from "@/lib/engine/day-key";
import { lastRotationKind, nextTrainingDayKey, nextWorkoutKind, projectWeek, workoutKindFromName, type DayProjection } from "@/lib/engine/plan-rotation";
import { strengthLines, tailLine, type HomeExercise, type HomeLine } from "@/lib/engine/home-lines";
import { isStaleSession } from "@/lib/lapsed-user";
import { findPlan } from "@/lib/plans";
import { todaySummary, vectorSlots, weekMarks, type VectorSlots } from "@/lib/home-facts";

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
  nextUp: NextUpFacts | null; // A3 / A18.3: null on an undone training day, while paused, and on a workout-day bridge
  todayWorkoutKind: string | null; // A1: the rotation kind due today (null on rest, done, paused, no plan)
  weekMarks: string[]; // A18.6a / A18.7: the seven marks, Mon..Sun — computed HERE, as the iOS twin does, so the pause can be consulted
  todaySummaryLines: string[]; // A18.9: what today held, in the journal's own sentence
  vectors: VectorSlots; // A14: today's Workout · Cardio · Meals row
}

// SPEC: A18.3 — the what's-next fact, split so the block above the card can title it and the bridge card can say it
// as one sentence. Twin of ios Features/Home/NextUpLine.swift NextUpFacts.
export interface NextUpFacts { heading: string; detail: string }

export interface Rotation { cycle: string[]; nextKind: string | null; week: DayProjection[] }

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

// SPEC: A3 · A18.3 — the what's-next fact in TWO halves, because it now renders in two shapes: inside the bridge card
// as one sentence, and on rest / all-done as a titled BLOCK above the card, where repeating the label in the heading
// AND the line would read "NEXT UP / Next workout: Sun · Leg day". One computation, two shapes. Twin of ios NextUp.
export function nextUpFacts(todayKey: string, plan: PlanDoc, rotation: Rotation, bridge: boolean): NextUpFacts | null {
  const nextDay = nextTrainingDayKey(todayKey, plan.trainingWeekdays);
  const workout = nextDay === null ? undefined : plan.workouts.find((candidate) => candidate.kind === kindOn(nextDay, rotation));
  if (nextDay === null || workout === undefined) return null;
  const tomorrow = nextDay === addDays(todayKey, 1);
  if (!tomorrow) return { heading: "Next workout", detail: `${weekdayShort(nextDay)} · ${workout.name}` };
  if (bridge) return { heading: "Tomorrow", detail: `${workout.name} — your first workout.` };
  const count = strengthCount(workout);
  return { heading: "Tomorrow", detail: `${workout.name} · ${count} ${count === 1 ? "exercise" : "exercises"}` };
}

// SPEC: A3 — the one-sentence form the BRIDGE card renders, unchanged byte for byte. Derived from the facts above so
// the two can never say different things.
export const nextUpLineOf = (facts: NextUpFacts | null): string | null => (facts === null ? null : `${facts.heading}: ${facts.detail}`);

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
  // SPEC: Flow 7 · V25 · A18.6d — THE PAUSE GUARD, at the model, mirroring ios HomeModel.swift:85. The rotation
  // projection takes only trainingWeekdays and the cycle and NEVER consults the pause, so on a paused training day
  // this stayed non-nil and every reader of it handed out planned-day controls from a screen that says the streak is
  // frozen: "Quick complete" rendered under "Plan paused", and the Workout row opened /session/new, which re-derived
  // `plannedToday` from the same pause-blind rotation and stamped `isPlannedDay: true` into the snapshot. iOS closed
  // this on the day A17 shipped and the web twin was never given the same line. One assignment at the source makes
  // every present and future reader safe; a guard per call site does not — that is exactly how F14 came back.
  // (XP never leaked: gamification-post.ts returns [] inside a pause window, V20. The defect is the controls offered
  // and the session stamp, which is also why a bonus workout while paused pays ZERO rather than +25.)
  const workout = pause === null && todayEntry?.state === "planned" ? (plan?.workouts.find((candidate) => candidate.kind === todayEntry.kind) ?? null) : null;
  let today: TodayState;
  if (pause !== null) today = { kind: "paused", until: pause.endDay };
  else if (lastPost === null) today = { kind: "bridge", workoutDay: workout !== null };
  else if (todayEntry === null || todayEntry.state === "rest") today = { kind: "rest", posted: todayPosts > 0 };
  else if (workout === null) today = { kind: "allDone" };
  else {
    const rows: HomeExercise[] = workout.exercises.map((row) => ({ name: row.name, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax ?? null, holdSeconds: row.holdSeconds ?? null, order: row.order }));
    today = { kind: "workout", name: workout.name, workoutKind: workout.kind, exerciseCount: strengthCount(workout), hasCardio: workout.exercises.some((row) => row.type === "cardio"), lines: strengthLines(rows), tail: tailLine(rows) };
  }
  const week = await weekMarks(userId, plan?.trainingWeekdays ?? [], todayKey, pause);
  const showsNext = plan !== null && today.kind !== "workout" && today.kind !== "paused" && !(today.kind === "bridge" && today.workoutDay);
  return {
    todayKey, today, ringDone: week.done, ringPlanned: week.planned, weekMarks: week.marks,
    hasPlan: plan !== null, inCrew: membership !== null, openSessionId: open?._id.toHexString() ?? null,
    openSessionStale: open !== null && isStaleSession(open.startedAt, now), openSessionName: open?.workoutName ?? null, lastPostDay: lastPost?.dayKey ?? null,
    quickCompleteAvailable: workout !== null && open === null,
    nextUp: showsNext && plan !== null ? nextUpFacts(todayKey, plan, rotation, today.kind === "bridge") : null,
    todayWorkoutKind: workout?.kind ?? null,
    todaySummaryLines: await todaySummary(userId, todayKey),
    vectors: await vectorSlots(userId, todayKey),
  };
}
