// SPEC: docs/api.md plans — one plan per user (Part IX UNIQUE), PUT replaces the whole plan forward-only (Flow 8: history
// never rewrites — sessions keep their snapshots), shapes mirror PlanDTO in ApiPlans.swift. A1: a plan is trainingWeekdays plus
// an ORDERED list of workouts (the rotation cycle); a document written before A1 is normalised on read. A27 (a) (owner-ruled
// 2026-09-18): the plan keeps its training-days HISTORY — a change of days is appended, in effect from the dayKey it was saved,
// never edited and never deleted; a plan from before A27 gains one entry, in effect from its creation dayKey.
import { ObjectId } from "mongodb";
import { plans, users } from "@/lib/db";
import type { PlanDoc, WorkoutTemplateDoc } from "@/lib/documents";
import { dayKeyFor } from "@/lib/engine/day-key";
import { appendTrainingDays, isPlannedOn, type TrainingDaysEntry } from "@/lib/engine/training-days";
import { serverDayKey } from "@/lib/server-clock";
import type { PutPlanInput } from "@/lib/validate-plans";

export interface PlanResponse {
  trainingWeekdays: number[];
  trainingDaysHistory: TrainingDaysEntry[];
  workouts: PlanDoc["workouts"];
  updatedAt: string;
}

export function planResponse(doc: PlanDoc): PlanResponse {
  return { trainingWeekdays: doc.trainingWeekdays, trainingDaysHistory: doc.trainingDaysHistory, workouts: doc.workouts, updatedAt: doc.updatedAt.toISOString() };
}

// What the collection may still hold: a pre-A1 document carried one workout per weekday and no trainingWeekdays; a pre-A27 one
// carries no history
type StoredPlan = Omit<PlanDoc, "trainingWeekdays" | "trainingDaysHistory" | "workouts"> & { trainingWeekdays?: number[]; trainingDaysHistory?: TrainingDaysEntry[]; workouts: (WorkoutTemplateDoc & { weekday?: number })[] };

function uniqueSorted(weekdays: number[]): number[] {
  return [...new Set(weekdays)].sort((left, right) => left - right);
}

// SPEC: A1 — a legacy plan becomes trainingWeekdays = its workouts' weekdays, workouts deduped by kind in first-seen order,
// weekday dropped; nothing of it is written until the next PUT
function normaliseRotation(stored: StoredPlan): { trainingWeekdays: number[]; workouts: WorkoutTemplateDoc[] } {
  if (Array.isArray(stored.trainingWeekdays)) return { trainingWeekdays: stored.trainingWeekdays, workouts: stored.workouts };
  const seen = new Set<string>();
  const workouts: WorkoutTemplateDoc[] = [];
  for (const workout of stored.workouts) {
    if (seen.has(workout.kind)) continue;
    seen.add(workout.kind);
    workouts.push({ kind: workout.kind, name: workout.name, exercises: workout.exercises });
  }
  return { trainingWeekdays: uniqueSorted(stored.workouts.map((workout) => workout.weekday ?? 0).filter((weekday) => weekday > 0)), workouts };
}

async function timezoneOf(userId: ObjectId): Promise<string> {
  return (await (await users()).findOne({ _id: userId }, { projection: { timezone: 1 } }))?.timezone ?? "UTC";
}

// SPEC: A27 (a) — THE MIGRATION: a plan without a history gains ONE entry, its days in effect from the plan's creation dayKey (the
// document's _id timestamp, in the user's zone). Written once, and only while the history is still missing, so it can never land on
// top of an appended entry.
async function historyOf(stored: StoredPlan, trainingWeekdays: number[]): Promise<TrainingDaysEntry[]> {
  if (Array.isArray(stored.trainingDaysHistory) && stored.trainingDaysHistory.length > 0) return stored.trainingDaysHistory;
  const history = [{ from: dayKeyFor(stored._id.getTimestamp(), await timezoneOf(stored.userId)), weekdays: trainingWeekdays }];
  await (await plans()).updateOne({ _id: stored._id, "trainingDaysHistory.0": { $exists: false } }, { $set: { trainingDaysHistory: history } });
  return history;
}

export async function findPlan(userId: ObjectId): Promise<PlanDoc | null> {
  const stored = (await (await plans()).findOne({ userId })) as StoredPlan | null;
  if (stored === null) return null;
  const { trainingWeekdays, workouts } = normaliseRotation(stored);
  return { _id: stored._id, userId: stored.userId, trainingWeekdays, workouts, updatedAt: stored.updatedAt, trainingDaysHistory: await historyOf(stored, trainingWeekdays) };
}

// SPEC: A1 — workouts are stored in the order given (that order IS the rotation); training days sorted and unique. A27 (a): a change
// of days is PUSHED onto the history (never an edit), in effect from the day it was saved — the client's savedAt when it lies inside
// E15's window (a queued edit keeps its own day; server-clock.ts), else now — and never from before the last entry
export async function replacePlan(userId: ObjectId, input: PutPlanInput, timezone?: string, now: Date = new Date()): Promise<PlanDoc> {
  const workouts = input.workouts.map((workout) => ({ ...workout, exercises: [...workout.exercises].sort((left, right) => left.order - right.order) }));
  const trainingWeekdays = uniqueSorted(input.trainingWeekdays);
  const history = (await findPlan(userId))?.trainingDaysHistory ?? []; // a pre-A27 plan is migrated first, so its own days lead
  const savedDayKey = serverDayKey(input.savedAt === undefined ? undefined : new Date(input.savedAt), timezone ?? (await timezoneOf(userId)), now);
  const entry = appendTrainingDays(history, trainingWeekdays, savedDayKey)[history.length]; // undefined: the same days, nothing to add
  const appended = entry === undefined ? {} : { $push: { trainingDaysHistory: entry } };
  await (await plans()).updateOne({ userId }, { $set: { trainingWeekdays, workouts, updatedAt: now }, ...appended, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  const doc = await findPlan(userId);
  if (doc === null) throw new Error("plan vanished after upsert");
  return doc;
}

// SPEC: A27 (a) — was this day planned? The entry in effect ON that dayKey answers; the reminder and the streak nudge read it
// (A22 G1 (a): a rest day asks nothing)
export function isPlannedDayOf(plan: PlanDoc | null, dayKey: string): boolean {
  return plan !== null && isPlannedOn(plan.trainingDaysHistory, dayKey);
}
