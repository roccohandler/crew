// SPEC: S11 Nutrition post on web — the browser's native camera input (Part IV honest limits), library via the same input,
// time-smart tag, "same as yesterday" when applicable, text-only, earlier-today, share. T037
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { PostComposer } from "@/components/PostComposer";
import { crewMemberships, posts } from "@/lib/db";
import { addDays, dayKeyFor } from "@/lib/engine/day-key";
import { readSession } from "@/lib/session";

export default async function PostPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const yesterday = addDays(dayKeyFor(new Date(), session.user.timezone), -1);
  const meal = await (await posts()).findOne({ userId, dayKey: yesterday, type: "meal", deletedAt: null }, { sort: { createdAt: -1 } });
  const inCrew = (await (await crewMemberships()).findOne({ userId })) !== null;
  return <PostComposer timezone={session.user.timezone} inCrew={inCrew} yesterday={meal ? { caption: meal.caption, mealTag: meal.mealTag } : null} />;
}
