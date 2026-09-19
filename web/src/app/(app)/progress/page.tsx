// SPEC: S15 Progress on web — layer 3 only for weight-logged exercises; heat-map day-tap opens that day's workouts (A22: the plates
// and meals/week left with the plate journal); empty states invite. 6.7: Progress may widen to ~960 px. A1: planned = trainingWeekdays. A2: cardio and
// mobility minutes are facts, never targets. A6: ring captions and the day card read as words, never raw ISO. A19.4 / W6 (2026-09-17):
// the Charts | Journal segment sits at the top (ProgressSegments); the empty state's CTA goes to today (Home), not the composer. T040 (web half)
import { ObjectId } from "mongodb";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { HeatMap } from "@/components/HeatMap";
import { ProgressSegments } from "@/components/ProgressSegments";
import { WeeklyRing } from "@/components/WeeklyRing";
import { summaryFromSession } from "@/app/(app)/journal/rows";
import { posts, sessions } from "@/lib/db";
import { weekKeyFor } from "@/lib/engine/day-key";
import { dayLabel, weekHeader } from "@/lib/engine/day-label";
import { findPlan } from "@/lib/plans";
import { progressFacts, seasonLine, seasonOf, type WeekRecord } from "@/lib/progress-facts";
import { readSession } from "@/lib/session";

// SPEC: A6 — the tapped day: its heading is the readable label; every line is the same summary the journal shows
async function DayDetail({ userId, dayKey, todayKey, distanceUnit }: { userId: ObjectId; dayKey: string; todayKey: string; distanceUnit: string }) {
  const [daySessions, dayPosts] = await Promise.all([(await sessions()).find({ userId, dayKey, status: "completed" }).toArray(), (await posts()).find({ userId, dayKey, deletedAt: null }).toArray()]);
  return (
    <section className="card stack stack--tight" aria-live="polite">
      <h2><time dateTime={dayKey}>{dayLabel(dayKey, todayKey)}</time></h2>
      {daySessions.map((session) => <p key={session._id.toHexString()}>{summaryFromSession(session, distanceUnit)}</p>)}
      {daySessions.length === 0 && dayPosts.length === 0 ? <p className="muted">{"Nothing that day. Tomorrow's a fresh one."}</p> : null}
    </section>
  );
}

// SPEC: A2 as amended by A28 (c) — "Cardio {n} min this week": the minutes the user entered (GAP 4, R-084 (2)); the mobility minutes
// are gone with the hold timer; nothing at 0 (a zero is never a verdict, A8)
function MinutesLine({ week }: { week: WeekRecord | undefined }) {
  if (!week || week.cardioMinutes === 0) return null;
  return <p className="muted">Cardio {week.cardioMinutes} min this week</p>;
}

export default async function ProgressPage({ searchParams }: { searchParams: Promise<{ day?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const plan = await findPlan(userId);
  const facts = await progressFacts(userId, session.user.timezone, plan?.trainingDaysHistory ?? []); // A27 (a): each week judged by the days in effect on it
  const { day } = await searchParams;
  const season = await seasonOf(userId, plan?.trainingDaysHistory ?? [], facts.todayKey); // A28 (e) · R-086: the season line
  if (facts.totals.posts === 0) {
    return (
      <div className="stack app-column--progress">
        <ProgressSegments active="charts" />
        <EmptyState title="Your first post starts the story" line="Every workout you complete lands here." ctaTitle="Go to today" href="/home" />
      </div>
    );
  }
  const thisWeek = weekKeyFor(facts.todayKey);
  const latest = facts.weeks[facts.weeks.length - 1];
  return (
    <div className="stack app-column--progress">
      <h1>Progress</h1>
      {season ? <p className="muted">{seasonLine(season)}</p> : null}
      <ProgressSegments active="charts" />
      <section className="stack stack--tight"><h2>Did I show up?</h2><HeatMap days={facts.days} selected={day ?? null} todayKey={facts.todayKey} /></section>
      {day ? <DayDetail userId={userId} dayKey={day} todayKey={facts.todayKey} distanceUnit={session.user.distanceUnit} /> : null}
      <div className="row row--wrap" aria-label="Weekly rings">{facts.weeks.map((week) => <div key={week.weekKey} className="stack center" style={{ gap: 0 }}><WeeklyRing done={week.done} planned={week.planned} /><span className="whisper">{weekHeader(week.weekKey, thisWeek)}</span></div>)}</div>
      <p className="muted">Streak {facts.totals.currentStreak} · longest {facts.totals.longestStreak} · {facts.totals.workouts} workouts · {facts.totals.posts} posts</p>
      <section className="stack stack--tight">
        <h2>How much work?</h2>
        <p className="muted">Sets per week: {facts.weeks.map((week) => week.sets).join(" · ")}</p>
        <p className="muted">Push {facts.balance.push} · Pull {facts.balance.pull} · Legs {facts.balance.legs}{facts.balance.fullBody ? ` · Full body ${facts.balance.fullBody}` : ""}</p>
        <MinutesLine week={latest} />
      </section>
      {facts.strength.length > 0 ? <section className="stack stack--tight"><h2>Am I stronger?</h2>{facts.strength.map((trend) => <p key={trend.exerciseId}>{trend.name}: {trend.points.map((point) => point.best).join(" → ")} {session.user.weightUnit}{trend.points.length > 1 && (trend.points[trend.points.length - 1]?.best ?? 0) > Math.max(...trend.points.slice(0, -1).map((point) => point.best)) ? " 🎉" : ""}</p>)}</section> : null}
    </div>
  );
}
