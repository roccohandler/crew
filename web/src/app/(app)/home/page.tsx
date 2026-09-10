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
import { VectorRow } from "@/components/VectorRow";
import { WeeklyRing } from "@/components/WeeklyRing";
import { WeekStrip } from "@/components/WeekStrip";
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

// SPEC: A14 — one group: the flame, the ring and the week strip belong together, separated from what follows by the section
// gap rather than by the same 16 px that separated everything from everything (F09).
function WeekHeader({ facts, streak, isBridge }: { facts: HomeFacts; streak: number; isBridge: boolean }) {
  return (
    <div className="stack stack--tight">
      <div className="row row--between">
        <StreakFlame streak={streak} paused={facts.today.kind === "paused"} />
        {/* W043 — the ring is gone from the BRIDGE: there it read "0/3", which is a competing prompt on the one screen §1D
            says must have none, an ember element that is not a reward (law ④), and a zero used as a verdict (A8). */}
        {facts.ringPlanned > 0 && !isBridge ? <WeeklyRing done={facts.ringDone} planned={facts.ringPlanned} /> : null}
      </div>
      {!isBridge ? <WeekStrip week={facts.week} todayKey={facts.todayKey} /> : null}
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
    <div className="stack stack--page">
      <div className="row row--between">
        <h1>Today</h1>
        {!isBridge ? <Link className="button button--text" href="/post" aria-label="Post a meal"><span aria-hidden="true">📷</span></Link> : null}
      </div>
      <EarnedAchievements ids={unlocked} />
      {facts.openSessionId && facts.openSessionStale ? <StaleSessionPrompt id={facts.openSessionId} workoutName={facts.openSessionName ?? "Your workout"} timezone={session.user.timezone} /> : null}
      {facts.openSessionId && !facts.openSessionStale && facts.today.kind !== "workout" ? <Link className="button button--secondary" href={`/session/${facts.openSessionId}`}>Resume workout</Link> : null}
      <WeekHeader facts={facts} streak={state?.currentStreak ?? 0} isBridge={isBridge} />
      <TodayCard today={facts.today} todayKey={facts.todayKey} openSessionId={facts.openSessionId} nextUpLine={facts.nextUpLine} bonusKind={bonusKind} />
      {facts.quickCompleteAvailable && !isBridge && facts.todayWorkoutKind !== null ? <QuickCompleteButton kind={facts.todayWorkoutKind} /> : null}
      {/* A14 — the three vectors as peers, bottom-anchored into the thumb zone (6.7). The standalone "Log cardio" button
          that used to sit here on a workout day IS the Cardio slot now, at a position that no longer moves between states. */}
      {!isBridge ? (
        <div className="stack stack--tight stack--bottom">
          <VectorRow slots={facts.vectors} workoutHref={facts.todayWorkoutKind === null ? "/plan" : facts.openSessionId ? `/session/${facts.openSessionId}` : "/session/new"} />
          {facts.inCrew ? <CrewToday userId={userId} todayKey={facts.todayKey} /> : null}
        </div>
      ) : null}
    </div>
  );
}
