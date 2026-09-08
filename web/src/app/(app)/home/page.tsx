// SPEC: S07 Home on web — the bridge until the first post (1D), today-state, streak flame, weekly ring, crew strip absent for solo;
// ≤ 3 taps to fast-log (Quick complete). Server-rendered from the same facts the API exposes. T036/T037
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
import { readSession } from "@/lib/session";
import { homeFacts, type TodayState } from "@/lib/today-state";

function TodayCard({ today, openSessionId }: { today: TodayState; openSessionId: string | null }) {
  if (today.kind === "bridge") return <div className="stack"><p className="muted">Your first flame lights today.</p><Link className="button button--primary" href={today.workoutDay ? "/session/new" : "/post"}>{today.workoutDay ? "Start your first workout" : "Start your streak — post a meal"}</Link></div>;
  if (today.kind === "paused") return <section className="card stack stack--tight"><h2>Plan paused</h2><p className="muted">Your streak is frozen until {today.until}. Reminders are off.</p></section>;
  if (today.kind === "rest") return <section className="card stack stack--tight"><h2>Rest day — recovery is part of the plan.</h2><p className="muted">{today.posted ? "Today's posted. Streak safe." : "Post something today and the streak stays safe."}</p>{!today.posted ? <Link className="button button--secondary" href="/post">Post a meal</Link> : null}</section>;
  if (today.kind === "allDone") return <section className="card stack stack--tight"><h2>Done for today.</h2><p className="muted">Post a plate whenever. Bonus workouts are always welcome.</p></section>;
  return <section className="card stack stack--tight"><p className="whisper">{today.name.toUpperCase()}</p><h2>{today.exerciseCount} {today.exerciseCount === 1 ? "exercise" : "exercises"} + mobility</h2><Link className="button button--primary" href={openSessionId ? `/session/${openSessionId}` : "/session/new"}>{openSessionId ? "Resume workout" : "Start workout"}</Link></section>;
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
  const membership = facts.inCrew ? await (await crewMemberships()).findOne({ userId }) : null;
  const crew = membership ? await (await crews()).findOne({ _id: membership.crewId }) : null;
  const members = crew ? await memberDots(crew._id, crew.captainId, facts.todayKey) : null;
  const isBridge = facts.today.kind === "bridge";
  return (
    <div className="stack">
      <h1>Today</h1>
      <EarnedAchievements ids={unlocked} />
      {facts.openSessionId && facts.openSessionStale ? <StaleSessionPrompt id={facts.openSessionId} workoutName={facts.openSessionName ?? "Your workout"} timezone={session.user.timezone} /> : null}
      {facts.openSessionId && !facts.openSessionStale && facts.today.kind !== "workout" ? <Link className="button button--secondary" href={`/session/${facts.openSessionId}`}>Resume workout</Link> : null}
      <div className="row row--between">
        <StreakFlame streak={state?.currentStreak ?? 0} paused={facts.today.kind === "paused"} />
        {facts.ringPlanned > 0 ? <WeeklyRing done={facts.ringDone} planned={facts.ringPlanned} /> : null}
      </div>
      <TodayCard today={facts.today} openSessionId={facts.openSessionId} />
      {facts.quickCompleteAvailable && !isBridge ? <QuickCompleteButton /> : null}
      {members && !isBridge ? <div className="members" aria-label="Crew today">{members.map((member) => <div key={member.id} className="member"><span className="avatar" aria-hidden="true">{member.displayName.slice(0, 1)}<span className={member.postedToday ? "avatar__dot avatar__dot--posted" : "avatar__dot"} /></span><span className="whisper">{member.paused ? "⏸" : member.streak}</span></div>)}</div> : null}
      {!isBridge ? <Link className="button button--secondary" href="/post">Post a meal</Link> : null}
    </div>
  );
}
