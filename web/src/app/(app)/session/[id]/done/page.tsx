// SPEC: S10 Complete → Post on web — numbers match the engine exactly (sets from the session, streak + XP from the stored
// server state); PR badge only where weights were logged; the ember shows because progress happened (Part III law ④). T037
import { ObjectId } from "mongodb";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { EarnedAchievements, earnedIds } from "@/components/EarnedAchievements";
import { StreakFlame } from "@/components/StreakFlame";
import { sessions } from "@/lib/db";
import { newRecords } from "@/lib/engine/personal-records";
import { storedState } from "@/lib/gamification-store";
import { readSession } from "@/lib/session";
import { sessionResponse } from "@/lib/sessions";
import { TimeUnits } from "@/lib/time-units";

// Flow 3 PR celebration through the engine rule (never logged weight → politely does not exist, Flow 9)
async function personalRecords(userId: ObjectId, sessionId: ObjectId, current: { exerciseId: string; name: string; sets: { done: boolean; isWarmup: boolean; weight: number | null }[] }[]): Promise<string[]> {
  const earlier = await (await sessions()).find({ userId, status: "completed", _id: { $ne: sessionId } }).toArray();
  const history = earlier.map((doc) => ({ completedAt: (doc.completedAt ?? new Date(0)).toISOString(), exercises: doc.exercises }));
  return newRecords(current, history).map((name) => `${name}: new best 🎉`);
}

export default async function DonePage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ earned?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const { id } = await params;
  const unlocked = earnedIds((await searchParams).earned);
  const userId = new ObjectId(session.user.id);
  const doc = ObjectId.isValid(id) ? await (await sessions()).findOne({ _id: new ObjectId(id), userId }) : null;
  if (doc === null) notFound();
  const view = sessionResponse(doc);
  const state = await storedState(session.user.id);
  const minutes = doc.completedAt ? Math.round((doc.completedAt.getTime() - doc.startedAt.getTime()) / TimeUnits.msPerMinute) : 0;
  const records = await personalRecords(userId, doc._id, doc.exercises);
  return (
    <div className="stack center">
      <p className="muted">{view.setsDone}/{view.setsPlanned} sets · {minutes} min</p>
      <p className="ember-text" style={{ fontSize: "2em", fontWeight: 700 }}>{state?.totalXP ?? 0} XP total</p>
      <StreakFlame streak={state?.currentStreak ?? 0} paused={false} />
      {records.map((line) => <p key={line} className="ember-text">{line}</p>)}
      <EarnedAchievements ids={unlocked} />
      <Link className="button button--primary" href="/home">Done</Link>
    </div>
  );
}
