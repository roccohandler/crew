// SPEC: docs/api.md GET/PUT plans — one plan per user; PUT replaces forward-only; limits rejected by the schema (400) · T023
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { findPlan, planResponse, replacePlan } from "@/lib/plans";
import { putPlanSchema } from "@/lib/validate-plans";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const plan = await findPlan(new ObjectId(userId));
    if (plan === null) throw notFound("Plan");
    return json(planResponse(plan));
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PUT(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = putPlanSchema.parse(await req.json());
    const plan = await replacePlan(new ObjectId(userId), body);
    await logEvent(userId, "plan_saved", { workouts: plan.workouts.length });
    return json(planResponse(plan));
  } catch (error) {
    return errorResponse(error);
  }
}
