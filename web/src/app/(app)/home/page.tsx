// SPEC: S07 Home on web — the bridge until the first post (1D), today-state, streak flame, weekly ring, crew strip absent for solo;
// ≤ 3 taps to fast-log (Quick complete). A3 (owner-directed 2026-09-08): a camera button (Post a meal) on every non-bridge state,
// the what's-next line, Log cardio, Bonus workout. Server-rendered from the same facts the API exposes. T036/T037
import { ObjectId } from "mongodb";
import Link from "next/link";
import { redirect } from "next/navigation";
import { DraftFlusher } from "@/components/DraftFlusher";
import { EarnedAchievements, earnedIds } from "@/components/EarnedAchievements";
import { QuickCompleteButton } from "@/components/QuickCompleteButton";
import { StaleSessionPrompt } from "@/components/StaleSessionPrompt";
import { WelcomeBack } from "@/components/WelcomeBack";
import { StreakFlame } from "@/components/StreakFlame";
import { WeeklyRing } from "@/components/WeeklyRing";
import { memberDots } from "@/lib/crew-stream";
import { crewMemberships, crews } from "@/lib/db";
import { storedState } from "@/lib/gamification-store";
import { shouldShowWelcomeBack } from "@/lib/lapsed-user";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";
import { homeFacts, rotationFor, type HomeFacts } from "@/lib/today-state";
import { TodayCard } from "@/app/(app)/home/TodayCard";

// SPEC: A3 · Flow 5 — Bonus workout starts the NEXT rotation workout (+25, never expected); the pointer is derived from
// history (A1), so it is read from the same rotation Home used, and only where the card offers the button (rest / all-done)
async function bonusKindFor(userId: ObjectId, facts: HomeFacts): Promise<string | null> {
  if (facts.today.kind !== "rest" && facts.today.kind !== "allDone") return null;
  const plan = await findPlan(userId);
  return plan === null ? null : (await rotationFor(userId, plan, facts.todayKey)).nextKind;
}

async function CrewToday({ userId, todayKey }: { userId: ObjectId; todayKey: string }) {
  const membership = await (await crewMemberships()).findOne({ userId });
  const crew = membership ? await (await crews()).findOne({ _id: membership.crewId }) : null;
  if (crew === null) return null;
  const members = await memberDots(crew._id, crew.captainId, todayKey);
  return (
    <div className="members" aria-label="Crew today">
      {members.map((member) => <div key={member.id} className="member"><span className="avatar" aria-hidden="true">{member.displayName.slice(0, 1)}<span className={member.postedToday ? "avatar__dot avatar__dot--posted" : "avatar__dot"} /></span><span className="whisper">{member.paused ? "⏸" : member.streak}</span></div>)}
    </div>
  );
}

export default async function HomePage({ searchParams }: { searchParams: Promise<{ earned?: string }> }) {
  const session = await readSession();
  const unlocked = earnedIds((await searchParams).earned);
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const facts = await homeFacts(userId, session.user.timezone);
  if (!facts.hasPlan) return <main className="stack"><DraftFlusher /><h1>Build your week</h1><p className="muted">Three questions and your plan is ready.</p><Link className="button button--primary" href="/onboarding">Build my week</Link></main>;
  const state = await storedState(session.user.id);
  if (shouldShowWelcomeBack(facts.lastPostDay, session.user.welcomeBackAckDay, facts.todayKey)) return <WelcomeBack todayKey={facts.todayKey} longestStreak={state?.longestStreak ?? 0} />; // E4 / S18
  const bonusKind = await bonusKindFor(userId, facts);
  const isBridge = facts.today.kind === "bridge";
  return (
    <div className="stack">
      <div className="row row--between">
        <h1>Today</h1>
        {!isBridge ? <Link className="button button--text" href="/post" aria-label="Post a meal"><span aria-hidden="true">📷</span></Link> : null}
      </div>
      <EarnedAchievements ids={unlocked} />
      {facts.openSessionId && facts.openSessionStale ? <StaleSessionPrompt id={facts.openSessionId} workoutName={facts.openSessionName ?? "Your workout"} timezone={session.user.timezone} /> : null}
      {facts.openSessionId && !facts.openSessionStale && facts.today.kind !== "workout" ? <Link className="button button--secondary" href={`/session/${facts.openSessionId}`}>Resume workout</Link> : null}
      <div className="row row--between">
        <StreakFlame streak={state?.currentStreak ?? 0} paused={facts.today.kind === "paused"} />
        {facts.ringPlanned > 0 ? <WeeklyRing done={facts.ringDone} planned={facts.ringPlanned} /> : null}
      </div>
      <TodayCard today={facts.today} todayKey={facts.todayKey} openSessionId={facts.openSessionId} nextUpLine={facts.nextUpLine} bonusKind={bonusKind} />
      {facts.quickCompleteAvailable && !isBridge && facts.todayWorkoutKind !== null ? <QuickCompleteButton kind={facts.todayWorkoutKind} /> : null}
      {facts.today.kind === "workout" ? <Link className="button button--secondary" href="/log-cardio">Log cardio</Link> : null}
      {facts.inCrew && !isBridge ? <CrewToday userId={userId} todayKey={facts.todayKey} /> : null}
    </div>
  );
}
