// SPEC: docs/api.md plans — one plan per user (Part IX UNIQUE), PUT replaces the whole plan forward-only (Flow 8: history
// never rewrites — sessions keep their snapshots), shapes mirror PlanDTO in ApiPlans.swift.
import { ObjectId } from "mongodb";
import { plans } from "@/lib/db";
import type { PlanDoc } from "@/lib/documents";
import type { PutPlanInput } from "@/lib/validate-plans";

export interface PlanResponse {
  workouts: PlanDoc["workouts"];
  updatedAt: string;
}

export function planResponse(doc: PlanDoc): PlanResponse {
  return { workouts: doc.workouts, updatedAt: doc.updatedAt.toISOString() };
}

export async function findPlan(userId: ObjectId): Promise<PlanDoc | null> {
  return (await plans()).findOne({ userId });
}

export async function replacePlan(userId: ObjectId, input: PutPlanInput, now: Date = new Date()): Promise<PlanDoc> {
  const workouts = input.workouts
    .map((workout) => ({ ...workout, exercises: [...workout.exercises].sort((left, right) => left.order - right.order) }))
    .sort((left, right) => left.weekday - right.weekday);
  await (await plans()).updateOne({ userId }, { $set: { workouts, updatedAt: now }, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  const doc = await findPlan(userId);
  if (doc === null) throw new Error("plan vanished after upsert");
  return doc;
}

// Is this ISO weekday a planned training day? (rest day = no workout for that weekday)
export function isPlannedWeekday(plan: PlanDoc | null, weekday: number): boolean {
  return plan?.workouts.some((workout) => workout.weekday === weekday) ?? false;
}
