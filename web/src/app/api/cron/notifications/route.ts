// SPEC: Flow 2 (7:00 AM "Push day is ready 💪") · Flow 4 rhythm reminder · 6.6 (every notification names its subject) · T033.
// A Vercel Cron hits this every minute with `Authorization: Bearer $CRON_SECRET` (vercel.json); it evaluates the pure
// eligibility functions per user with a push token and sends through lib/push.ts. Not a user route: no requireUser.
import { crewMemberships, gamificationStates, plans, pushTokens, users } from "@/lib/db";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import { errorResponse, json, unauthorized } from "@/lib/api-error";
import { reminderDue, streakRiskDue } from "@/lib/notification-eligibility";
import { gatherFacts, recordSend } from "@/lib/notification-facts";
import { sendPush } from "@/lib/push";

function authorized(req: Request): boolean {
  const secret = process.env.CRON_SECRET ?? "";
  return secret.length > 0 && req.headers.get("authorization") === `Bearer ${secret}`;
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
        const plan = await (await plans()).findOne({ userId });
        const workout = plan?.workouts.find((candidate) => candidate.weekday === isoWeekday(dayKeyFor(now, user.timezone)));
        const exercises = workout?.exercises.filter((row) => row.type === "strength").length ?? 0;
        sent += await sendPush(userId, { kind: "reminder", title: `${workout?.name ?? "Workout"} is ready 💪`, body: `${exercises} exercises + mobility` });
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
