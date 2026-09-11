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
import { VectorRow } from "@/components/VectorRow";
import { memberDots } from "@/lib/crew-stream";
import { crewMemberships, crews } from "@/lib/db";
import { storedState } from "@/lib/gamification-store";
import { shouldShowWelcomeBack } from "@/lib/lapsed-user";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";
import { SpecConstants } from "@/generated/spec-constants";
import { homeFacts, nextUpLineOf, rotationFor, type HomeFacts } from "@/lib/today-state";
import { TodayCard } from "@/app/(app)/home/TodayCard";
import { NextUpBlock, WeekHeader } from "@/app/(app)/home/HomeHeader";

// SPEC: A3 · Flow 5 — Bonus workout starts the NEXT rotation workout; the pointer is derived from history (A1), so it
// is read from the same rotation Home used.
//
// J023 (A18) — PAUSED is in this list now. It was rest and allDone only, so on a paused day `todayWorkoutKind` was
// null, no bonus kind existed, and the Workout row fell through to "/plan" — a destination this file's own comment
// below already calls wrong ("answers a question the user did not ask and leaves the screen entirely"), while iOS
// opened the bonus sheet. Note what a paused bonus actually pays: ZERO, not +25 — V20 expects [] for a workout
// completed inside a pause window, and gamification-post.ts implements it. It is allowed, it simply earns nothing,
// which is what "pauses without penalty" means in both directions.
async function bonusKindFor(userId: ObjectId, facts: HomeFacts): Promise<string | null> {
  if (facts.today.kind !== "rest" && facts.today.kind !== "allDone" && facts.today.kind !== "paused") return null;
  const plan = await findPlan(userId);
  return plan === null ? null : (await rotationFor(userId, plan, facts.todayKey)).nextKind;
}

async function CrewToday({ userId, todayKey }: { userId: ObjectId; todayKey: string }) {
  const membership = await (await crewMemberships()).findOne({ userId });
  const crew = membership ? await (await crews()).findOne({ _id: membership.crewId }) : null;
  if (crew === null) return null;
  const members = await memberDots(crew._id, crew.captainId, todayKey);
  // A17.1 / H033 — a crew of ONE has a snapshot whose members are [you], so Home was showing the user their own face
  // back to them, unlabelled, and calling it a crew. The Crew tab has always known better (the same crewMinMembers
  // predicate). True solo was already correct (no crew → null), so Flow 10 was satisfied; this is the crew-of-one
  // state A5 governs. Twin of HomeModel.crewStripFromSnapshot.
  if (members.length < SpecConstants.crewMinMembers) return null;
  return (
    // A17.1 / H034 — the strip was a bare avatar with an unexplained dot and numeral. Ink caption, never a link: the
    // Crew tab is where a member opens (law ①).
    // H007 — the initial AND the dot were both aria-hidden, so a screen-reader user heard a bare "1" and posted-vs-not
    // was announced nowhere. `aria-label` also sat on a bare <div>, which ARIA prohibits and browsers widely ignore.
    // A real list with a labelled listitem carries the same sentence CrewStrip.swift:28 speaks on iOS.
    <div className="stack stack--tight">
      <p className="muted">Your crew</p>
      <ul className="members" aria-label="Crew today">
        {members.map((member) => (
          <li key={member.id} className="member" aria-label={`${member.displayName}, streak ${member.streak}, ${member.paused ? "paused" : member.postedToday ? "posted today" : "not yet today"}`}>
            <span className="avatar" aria-hidden="true">{member.displayName.slice(0, 1)}<span className={member.postedToday ? "avatar__dot avatar__dot--posted" : "avatar__dot"} /></span>
            <span className="whisper" aria-hidden="true">{member.paused ? "⏸" : member.streak}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

// SPEC: A17.4 / S07 — the heading NAMES THE STATE, so the page says what today is before anything else is read. It was
// the constant "Today" while the tab said "Home". The BRIDGE keeps "Today": §1D says that screen carries one CTA and
// nothing else, and a state name there would be the first thing a brand-new user reads about a day they have not started.
function title(today: HomeFacts["today"]): string {
  if (today.kind === "workout") return today.name;
  if (today.kind === "rest") return "Rest day";
  if (today.kind === "paused") return "Plan paused";
  if (today.kind === "allDone") return "Done for today";
  return "Today";
}

// SPEC: A17.2 / H019 — everything from the card down is ONE bottom-anchored group, so the slack lands as a section
// break under the header rather than as a hole between the card and the vector row. Twin of the iOS Spacer moving
// above TodayCard: the day's ink-filled primary is now in the thumb zone on every state.
function BottomGroup({ facts, streak, bonusKind, userId, isBridge }: { facts: HomeFacts; streak: number; bonusKind: string | null; userId: ObjectId; isBridge: boolean }) {
  // H008 — the twin divergence. iOS opens the BonusWorkoutSheet on a rest day; web went to "/plan", which answers a
  // question the user did not ask and leaves the screen entirely. Both offer the bonus workout now; "/plan" survives
  // only as the last resort when the plan has no next kind to offer.
  const workoutHref = facts.todayWorkoutKind !== null
    ? (facts.openSessionId ? `/session/${facts.openSessionId}` : "/session/new")
    : bonusKind !== null ? `/session/new?bonus=${bonusKind}` : "/plan";
  return (
    <div className="stack stack--sections stack--bottom">
      <TodayCard today={facts.today} todayKey={facts.todayKey} openSessionId={facts.openSessionId} bridgeLine={nextUpLineOf(facts.nextUp)} streak={streak} todaySummaryLines={facts.todaySummaryLines} />
      {facts.quickCompleteAvailable && !isBridge && facts.todayWorkoutKind !== null ? <QuickCompleteButton kind={facts.todayWorkoutKind} /> : null}
      {/* A14 — the three vectors as peers; every standalone duplicate that used to sit here or in the card is gone
          (A17.3). A17.1 / H034 — sectionGap, not the 8 px "within one group" stack: the layout used to assert the
          crew avatar was a fourth vector slot. */}
      {!isBridge ? (
        <div className="stack stack--sections">
          <VectorRow slots={facts.vectors} workoutHref={workoutHref} />
          {facts.inCrew ? <CrewToday userId={userId} todayKey={facts.todayKey} /> : null}
        </div>
      ) : null}
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
        <h1>{title(facts.today)}</h1>
        {/* A3 gave every non-bridge state a camera. A18.10 NARROWS it: not on a state whose CARD already offers a meal
            CTA. On the rest day the owner photographed, posting was reachable three ways at three weights — an
            unlabelled glyph, a filled card primary and a slot — and Apple's own navigation guidance names that
            redundancy as a cause of confusion. Twin of ios HomeScreen.showsCameraButton. */}
        {!isBridge && facts.today.kind !== "rest" ? <Link className="button button--text" href="/post" aria-label="Post a meal"><span aria-hidden="true">📷</span></Link> : null}
      </div>
      <EarnedAchievements ids={unlocked} />
      {facts.openSessionId && facts.openSessionStale ? <StaleSessionPrompt id={facts.openSessionId} workoutName={facts.openSessionName ?? "Your workout"} timezone={session.user.timezone} /> : null}
      {/* A18.8 — NOT on the bridge. The bridge lasts until the first POST and starting a workout is not a post, so an
          abandoned first workout put this banner beside the bridge's own single CTA — two prompts on the one screen
          §1D says carries none, and a CI test asserted both at once. The bridge's own button resumes instead. */}
      {facts.openSessionId && !facts.openSessionStale && facts.today.kind !== "workout" && !isBridge ? <Link className="button button--secondary" href={`/session/${facts.openSessionId}`}>Resume workout</Link> : null}
      <WeekHeader facts={facts} streak={state?.currentStreak ?? 0} shields={state?.shields ?? 0} isBridge={isBridge} />
      <NextUpBlock facts={facts} />
      <BottomGroup facts={facts} streak={state?.currentStreak ?? 0} bonusKind={bonusKind} userId={userId} isBridge={isBridge} />
    </div>
  );
}
