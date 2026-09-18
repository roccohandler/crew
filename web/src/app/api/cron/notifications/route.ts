// SPEC: Flow 2 (7:00 AM "Push day is ready 💪") · the streak nudge (A22 G1 (a): only a planned day with no completed workout is at
// risk — a rest day asks nothing) · 6.6 (every notification names its subject) · A1 (the
// reminder names today's ROTATION workout) · A7 (each kind gated by its toggle, inside the eligibility functions) · T033.
// A Vercel Cron hits this every minute with `Authorization: Bearer $CRON_SECRET` (vercel.json); it evaluates the pure
// eligibility functions per user with a push token and sends through lib/push.ts. Not a user route: no requireUser.
import { gamificationStates, pushTokens, users } from "@/lib/db";
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

// SPEC: A1 — the workout the rotation puts on today: the subject of both notifications (6.6)
async function todaysWorkout(userId: ObjectId, dayKey: string) {
  const plan = await findPlan(userId);
  const rotation = plan === null ? null : await rotationFor(userId, plan, dayKey);
  return plan?.workouts.find((candidate) => candidate.kind === rotation?.nextKind);
}

// SPEC: A1 — "Pull day is ready 💪": today's rotation workout, sized like the Home card ("5 exercises + mobility[ + cardio]")
async function reminderMessage(userId: ObjectId, dayKey: string): Promise<{ title: string; body: string }> {
  const workout = await todaysWorkout(userId, dayKey);
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
        // SPEC: A22 G1 (a) · 6.6 — the nudge names the open workout; it fires only on a planned day with nothing completed
        const name = (await todaysWorkout(userId, facts.dayKey))?.name ?? "Today's workout";
        sent += await sendPush(userId, { kind: "streakRisk", title: `Your ${facts.risk.currentStreak}-day streak`, body: `${name} is still open. Finish it and the streak holds.` });
        await recordSend(userId, "streakRisk", facts.dayKey, now);
      }
    }
    return json({ checked: userIds.length, sent });
  } catch (error) {
    return errorResponse(error);
  }
}
