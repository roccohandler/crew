// SPEC: Flow 2 (7:00 AM "Push day is ready 💪") · Flow 4 rhythm reminder · 6.6 (every notification names its subject) · A1 (the
// reminder names today's ROTATION workout) · A7 (each kind gated by its toggle, inside the eligibility functions) · T033.
// A Vercel Cron hits this every minute with `Authorization: Bearer $CRON_SECRET` (vercel.json); it evaluates the pure
// eligibility functions per user with a push token and sends through lib/push.ts. Not a user route: no requireUser.
import { crewMemberships, gamificationStates, pushTokens, users } from "@/lib/db";
import { errorResponse, json, unauthorized } from "@/lib/api-error";
import { reminderDue, streakRiskDue } from "@/lib/notification-eligibility";
import { gatherFacts, recordSend } from "@/lib/notification-facts";
import { findPlan } from "@/lib/plans";
import { sendPush } from "@/lib/push";
import { rotationFor } from "@/lib/today-state";
import type { ObjectId } from "mongodb";

function authorized(req: Request): boolean {
  const secret = process.env.CRON_SECRET ?? "";
  return secret.length > 0 && req.headers.get("authorization") === `Bearer ${secret}`;
}

// SPEC: A1 — "Pull day is ready 💪": the workout the rotation puts on today, sized like the Home card ("5 exercises + mobility[ + cardio]")
async function reminderMessage(userId: ObjectId, dayKey: string): Promise<{ title: string; body: string }> {
  const plan = await findPlan(userId);
  const rotation = plan === null ? null : await rotationFor(userId, plan, dayKey);
  const workout = plan?.workouts.find((candidate) => candidate.kind === rotation?.nextKind);
  const exercises = workout?.exercises.filter((row) => row.type === "strength").length ?? 0;
  const cardio = workout?.exercises.some((row) => row.type === "cardio") ? " + cardio" : "";
  return { title: `${workout?.name ?? "Workout"} is ready 💪`, body: `${exercises} exercises + mobility${cardio}` };
}

export async function GET(req: Request) {
  try {
    if (!authorized(req)) throw unauthorized();
    const now = new Date();
    const userIds = await (await pushTokens()).distinct("userId");
    let sent = 0;
    for (const userId of userIds) {
      const user = await (await users()).findOne({ _id: userId });
      if (user === null) continue;
      const state = await (await gamificationStates()).findOne({ userId });
      const facts = await gatherFacts(user, state?.currentStreak ?? 0, now);
      if (reminderDue(facts.reminder)) {
        sent += await sendPush(userId, { kind: "reminder", ...(await reminderMessage(userId, facts.dayKey)) });
        await recordSend(userId, "reminder", facts.dayKey, now);
      }
      if (streakRiskDue(facts.risk)) {
        const inCrew = (await (await crewMemberships()).findOne({ userId })) !== null;
        sent += await sendPush(userId, { kind: "streakRisk", title: `Your ${facts.risk.currentStreak}-day streak`, body: inCrew ? "Nothing posted yet today. A plate counts." : "Nothing posted yet today. A meal photo keeps it alive." });
        await recordSend(userId, "streakRisk", facts.dayKey, now);
      }
    }
    return json({ checked: userIds.length, sent });
  } catch (error) {
    return errorResponse(error);
  }
}
