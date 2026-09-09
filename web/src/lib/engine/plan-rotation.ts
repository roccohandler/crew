// SPEC: A1 (owner-directed 2026-09-08) — workouts rotate in the plan's stored order (Push → Pull → Legs for generated
// plans); the next workout is the one after the LAST COMPLETED rotation workout; only a completed workout advances the
// pointer — never a missed day, a pause, or a plan edit; the pointer is DERIVED from history, never stored; a session
// whose kind is outside the cycle (a standalone cardio log, A2) never advances it. Balance is automatic: over any 3k
// completed workouts each kind occurs k times. Twin: ios/Crew/Engine/PlanRotation.swift — identical names. Pure.
import { addDays, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";

export interface RotationSession {
  kind: string | null; // null on legacy sessions, which carry only a name
  name: string;
  completedAt: number | null; // ms since the epoch
  status: string; // inProgress | completed | discarded
}

export interface DayProjection {
  dayKey: string;
  weekday: number; // ISO 1 = Monday … 7 = Sunday
  state: "done" | "planned" | "open" | "rest";
  kind: string | null;
}

export interface WeekProjectionInput {
  weekKey: string;
  todayKey: string;
  trainingWeekdays: number[];
  cycle: string[];
  nextKind: string;
  completedKindByDay: Record<string, string>;
}

// SPEC: A1 — cycle[(i + 1) % n]; cycle[0] when nothing rotation-worthy has been completed or the last kind left the plan
export function nextWorkoutKind(lastCompletedKind: string | null, cycle: string[]): string {
  const index = lastCompletedKind === null ? -1 : cycle.indexOf(lastCompletedKind);
  if (index < 0) return cycle[0] ?? "";
  return cycle[(index + 1) % cycle.length] ?? "";
}

// SPEC: A1 — legacy sessions carry only a name: "Push day" → push, "Pull day" → pull, "Leg day" → legs,
// "Full body A" → fullBodyA, "Full body B" → fullBodyB, anything else → null
export function workoutKindFromName(name: string): string | null {
  const lower = name.trim().toLowerCase();
  if (lower.startsWith("push")) return "push";
  if (lower.startsWith("pull")) return "pull";
  if (lower.startsWith("leg")) return "legs";
  if (lower.startsWith("full body a")) return "fullBodyA";
  if (lower.startsWith("full body b")) return "fullBodyB";
  return null;
}

function rotationKindOf(session: RotationSession, cycle: string[]): string | null {
  const kind = session.kind ?? workoutKindFromName(session.name);
  return kind !== null && cycle.includes(kind) ? kind : null;
}

// SPEC: A1 — the latest COMPLETED session whose kind (or name-inferred kind) is in the cycle; a miss, a pause and a plan
// edit leave no completed session behind, so none of them can move the pointer
export function lastRotationKind(sessions: RotationSession[], cycle: string[]): string | null {
  let latest: { completedAt: number; kind: string } | null = null;
  for (const session of sessions) {
    if (session.status !== "completed" || session.completedAt === null) continue;
    const kind = rotationKindOf(session, cycle);
    if (kind === null) continue;
    if (latest === null || session.completedAt > latest.completedAt) latest = { completedAt: session.completedAt, kind };
  }
  return latest?.kind ?? null;
}

// SPEC: A1 — 7 entries Mon..Sun: done (a completed rotation session that day, kind from completedKindByDay) · rest
// (weekday ∉ trainingWeekdays) · open (a past training day with nothing completed — no word, no red) · planned
// (today and future training days; kinds run on from nextKind, one step per planned day)
export function projectWeek(input: WeekProjectionInput): DayProjection[] {
  const monday = weekKeyFor(input.weekKey);
  let pointer = input.nextKind;
  const week: DayProjection[] = [];
  for (let offset = 0; offset < TimeUnits.daysPerWeek; offset += 1) {
    const dayKey = addDays(monday, offset);
    const weekday = isoWeekday(dayKey);
    const done = input.completedKindByDay[dayKey];
    if (done !== undefined) week.push({ dayKey, weekday, state: "done", kind: done });
    else if (!input.trainingWeekdays.includes(weekday)) week.push({ dayKey, weekday, state: "rest", kind: null });
    else if (dayKey < input.todayKey) week.push({ dayKey, weekday, state: "open", kind: null });
    else {
      week.push({ dayKey, weekday, state: "planned", kind: pointer });
      pointer = nextWorkoutKind(pointer, input.cycle);
    }
  }
  return week;
}

// SPEC: A1 · A3 (the what's-next line) — the next planned day strictly after a day; null when the plan has no training days
export function nextTrainingDayKey(afterDayKey: string, trainingWeekdays: number[]): string | null {
  for (let offset = 1; offset <= TimeUnits.daysPerWeek; offset += 1) {
    const candidate = addDays(afterDayKey, offset);
    if (trainingWeekdays.includes(isoWeekday(candidate))) return candidate;
  }
  return null;
}
