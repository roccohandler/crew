// SPEC: S11 Nutrition post on web — the browser's native camera input (Part IV honest limits), library via the same input,
// time-smart tag, "same as yesterday" when applicable, text-only, earlier-today, share. A1: isPlannedDay = today is a training
// day (trainingWeekdays), the same fact the server stamps. T037
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { PostComposer } from "@/components/PostComposer";
import { crewMemberships, posts } from "@/lib/db";
import { addDays, dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import { findPlan, isPlannedWeekday } from "@/lib/plans";
import { readSession } from "@/lib/session";

export default async function PostPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const todayKey = dayKeyFor(new Date(), session.user.timezone);
  const yesterday = addDays(todayKey, -1);
  const [meal, membership, plan] = await Promise.all([
    (await posts()).findOne({ userId, dayKey: yesterday, type: "meal", deletedAt: null }, { sort: { createdAt: -1 } }),
    (await crewMemberships()).findOne({ userId }),
    findPlan(userId),
  ]);
  return <PostComposer timezone={session.user.timezone} inCrew={membership !== null} isPlannedDay={isPlannedWeekday(plan, isoWeekday(todayKey))} yesterday={meal ? { caption: meal.caption, mealTag: meal.mealTag } : null} />;
}
