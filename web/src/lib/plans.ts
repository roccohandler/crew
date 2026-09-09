// SPEC: docs/api.md plans — one plan per user (Part IX UNIQUE), PUT replaces the whole plan forward-only (Flow 8: history
// never rewrites — sessions keep their snapshots), shapes mirror PlanDTO in ApiPlans.swift. A1: a plan is trainingWeekdays plus
// an ORDERED list of workouts (the rotation cycle); a document written before A1 is normalised on read.
import { ObjectId } from "mongodb";
import { plans } from "@/lib/db";
import type { PlanDoc, WorkoutTemplateDoc } from "@/lib/documents";
import type { PutPlanInput } from "@/lib/validate-plans";

export interface PlanResponse {
  trainingWeekdays: number[];
  workouts: PlanDoc["workouts"];
  updatedAt: string;
}

export function planResponse(doc: PlanDoc): PlanResponse {
  return { trainingWeekdays: doc.trainingWeekdays, workouts: doc.workouts, updatedAt: doc.updatedAt.toISOString() };
}

// What the collection may still hold: a pre-A1 document carried one workout per weekday and no trainingWeekdays
type StoredPlan = Omit<PlanDoc, "trainingWeekdays" | "workouts"> & { trainingWeekdays?: number[]; workouts: (WorkoutTemplateDoc & { weekday?: number })[] };

function uniqueSorted(weekdays: number[]): number[] {
  return [...new Set(weekdays)].sort((left, right) => left - right);
}

// SPEC: A1 — a legacy plan becomes trainingWeekdays = its workouts' weekdays, workouts deduped by kind in first-seen order,
// weekday dropped; nothing is written until the next PUT
function normalisePlan(stored: StoredPlan): PlanDoc {
  if (Array.isArray(stored.trainingWeekdays)) return stored as PlanDoc;
  const seen = new Set<string>();
  const workouts: WorkoutTemplateDoc[] = [];
  for (const workout of stored.workouts) {
    if (seen.has(workout.kind)) continue;
    seen.add(workout.kind);
    workouts.push({ kind: workout.kind, name: workout.name, exercises: workout.exercises });
  }
  const trainingWeekdays = uniqueSorted(stored.workouts.map((workout) => workout.weekday ?? 0).filter((weekday) => weekday > 0));
  return { _id: stored._id, userId: stored.userId, trainingWeekdays, workouts, updatedAt: stored.updatedAt };
}

export async function findPlan(userId: ObjectId): Promise<PlanDoc | null> {
  const stored = (await (await plans()).findOne({ userId })) as StoredPlan | null;
  return stored === null ? null : normalisePlan(stored);
}

// SPEC: A1 — workouts are stored in the order given (that order IS the rotation); training days sorted and unique
export async function replacePlan(userId: ObjectId, input: PutPlanInput, now: Date = new Date()): Promise<PlanDoc> {
  const workouts = input.workouts.map((workout) => ({ ...workout, exercises: [...workout.exercises].sort((left, right) => left.order - right.order) }));
  const trainingWeekdays = uniqueSorted(input.trainingWeekdays);
  await (await plans()).updateOne({ userId }, { $set: { trainingWeekdays, workouts, updatedAt: now }, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  const doc = await findPlan(userId);
  if (doc === null) throw new Error("plan vanished after upsert");
  return doc;
}

// SPEC: A1 — is this ISO weekday a training day? (rest day = not in trainingWeekdays); meal posts stamp isPlannedDay from it
export function isPlannedWeekday(plan: PlanDoc | null, weekday: number): boolean {
  return plan?.trainingWeekdays.includes(weekday) ?? false;
}
