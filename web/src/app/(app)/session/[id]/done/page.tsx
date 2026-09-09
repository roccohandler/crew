// SPEC: S10 Complete → Post on web — "Counted." then numbers that match the engine exactly (sets from the session, streak + XP
// from the stored server state); PR badge only where weights were logged; the ember shows because progress happened (Part III
// law ④). A2 / plan 2.6: "+ {Activity} {min} min" is appended when a cardio set is done; a standalone cardio log reads its own
// summary line (the same one the server wrote on the post, A6). T037
import { ObjectId } from "mongodb";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { EarnedAchievements, earnedIds } from "@/components/EarnedAchievements";
import { StreakFlame } from "@/components/StreakFlame";
import { sessions } from "@/lib/db";
import type { SessionDoc } from "@/lib/documents";
import { newRecords } from "@/lib/engine/personal-records";
import { sessionSummaryLine } from "@/lib/engine/session-summary-line";
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

// SPEC: A2 — the done cardio blocks: seconds and distance from their done work sets, minutes rounded like the server's summary
function cardioDone(doc: SessionDoc): { name: string; minutes: number; distanceMeters: number | null }[] {
  return doc.exercises.filter((exercise) => exercise.type === "cardio").map((exercise) => {
    const sets = exercise.sets.filter((set) => set.done && !set.isWarmup);
    const seconds = sets.reduce((sum, set) => sum + (set.holdSeconds ?? 0), 0);
    const distanceMeters = sets.some((set) => typeof set.distanceMeters === "number") ? sets.reduce((sum, set) => sum + (set.distanceMeters ?? 0), 0) : null;
    return { name: exercise.name, minutes: Math.round(seconds / TimeUnits.secondsPerMinute), distanceMeters };
  }).filter((block) => block.minutes > 0);
}

// SPEC: S10 · A2 · A6 — "12/12 sets · 44 min" (+ " + Bike 10 min" per done cardio block); a standalone log reads "Walk · 25 min · 2.1 km"
function summaryLine(doc: SessionDoc, setsDone: number, setsPlanned: number, units: string): string {
  const minutes = doc.completedAt ? Math.round((doc.completedAt.getTime() - doc.startedAt.getTime()) / TimeUnits.msPerMinute) : 0;
  const blocks = cardioDone(doc);
  if (doc.workoutKind === "cardio") {
    const block = blocks[0];
    return sessionSummaryLine(doc.workoutName, true, setsDone, setsPlanned, minutes, block?.minutes ?? null, block?.distanceMeters ?? null, units);
  }
  return `${setsDone}/${setsPlanned} sets · ${minutes} min${blocks.map((block) => ` + ${block.name} ${block.minutes} min`).join("")}`;
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
  const records = await personalRecords(userId, doc._id, doc.exercises);
  return (
    <div className="stack center">
      <h1>Counted.</h1>
      <p className="muted">{summaryLine(doc, view.setsDone, view.setsPlanned, session.user.units)}</p>
      <p className="ember-text" style={{ fontSize: "2em", fontWeight: 700 }}>{state?.totalXP ?? 0} XP total</p>
      <StreakFlame streak={state?.currentStreak ?? 0} paused={false} />
      {records.map((line) => <p key={line} className="ember-text">{line}</p>)}
      <EarnedAchievements ids={unlocked} />
      <Link className="button button--primary" href="/home">Done</Link>
    </div>
  );
}
