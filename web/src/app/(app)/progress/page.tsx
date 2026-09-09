// SPEC: S15 Progress on web — layer 3 only for weight-logged exercises; heat-map day-tap opens that day's workout + plates;
// meals/week; empty states invite. 6.7: Progress may widen to ~960 px. A1: planned = trainingWeekdays. A2: cardio and
// mobility minutes are facts, never targets. A6: ring captions and the day card read as words, never raw ISO. T040 (web half)
import { ObjectId } from "mongodb";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { HeatMap } from "@/components/HeatMap";
import { WeeklyRing } from "@/components/WeeklyRing";
import { postLine, summaryFromSession } from "@/app/(app)/journal/rows";
import { posts, sessions } from "@/lib/db";
import { weekKeyFor } from "@/lib/engine/day-key";
import { dayLabel, weekHeader } from "@/lib/engine/day-label";
import { findPlan } from "@/lib/plans";
import { progressFacts, type WeekRecord } from "@/lib/progress-facts";
import { readSession } from "@/lib/session";

// SPEC: A6 — the tapped day: its heading is the readable label; every line is the same summary the journal shows
async function DayDetail({ userId, dayKey, todayKey, timeZone, units }: { userId: ObjectId; dayKey: string; todayKey: string; timeZone: string; units: string }) {
  const [daySessions, dayPosts] = await Promise.all([(await sessions()).find({ userId, dayKey, status: "completed" }).toArray(), (await posts()).find({ userId, dayKey, deletedAt: null }).toArray()]);
  return (
    <section className="card stack stack--tight" aria-live="polite">
      <h2><time dateTime={dayKey}>{dayLabel(dayKey, todayKey)}</time></h2>
      {daySessions.map((session) => <p key={session._id.toHexString()}>{summaryFromSession(session, units)}</p>)}
      {dayPosts.filter((post) => post.type !== "workout").map((post) => <p key={post._id.toHexString()}>{post.photoKey ? <img className="photo" src={`/api/v1/photos/${post.photoKey}`} alt={post.caption || "Your plate"} /> : null}{postLine(post, timeZone, null, dayKey === todayKey)}{post.caption ? ` — ${post.caption}` : ""}</p>)}
      {daySessions.length === 0 && dayPosts.length === 0 ? <p className="muted">{"Nothing that day. Tomorrow's a fresh one."}</p> : null}
    </section>
  );
}

// SPEC: A2 — "Cardio {n} min · Mobility {m} min this week"; nothing when both are 0 (a zero is never a verdict, A8)
function MinutesLine({ week }: { week: WeekRecord | undefined }) {
  if (!week || (week.cardioMinutes === 0 && week.mobilityMinutes === 0)) return null;
  return <p className="muted">Cardio {week.cardioMinutes} min · Mobility {week.mobilityMinutes} min this week</p>;
}

export default async function ProgressPage({ searchParams }: { searchParams: Promise<{ day?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const plan = await findPlan(userId);
  const facts = await progressFacts(userId, session.user.timezone, plan?.trainingWeekdays ?? []);
  const { day } = await searchParams;
  if (facts.totals.posts === 0) return <EmptyState title="Your first post starts the story" line="Every workout and every plate lands here." ctaTitle="Post something" href="/post" />;
  const thisWeek = weekKeyFor(facts.todayKey);
  const latest = facts.weeks[facts.weeks.length - 1];
  return (
    <div className="stack app-column--progress">
      <h1>Progress</h1>
      <Link className="button button--text" href="/journal">Journal — every post, forever</Link>
      <section className="stack stack--tight"><h2>Did I show up?</h2><HeatMap days={facts.days} selected={day ?? null} todayKey={facts.todayKey} /></section>
      {day ? <DayDetail userId={userId} dayKey={day} todayKey={facts.todayKey} timeZone={session.user.timezone} units={session.user.units} /> : null}
      <div className="row row--wrap" aria-label="Weekly rings">{facts.weeks.map((week) => <div key={week.weekKey} className="stack center" style={{ gap: 0 }}><WeeklyRing done={week.done} planned={week.planned} /><span className="whisper">{weekHeader(week.weekKey, thisWeek)}</span></div>)}</div>
      <p className="muted">Streak {facts.totals.currentStreak} · longest {facts.totals.longestStreak} · {facts.totals.workouts} workouts · {facts.totals.posts} posts · {latest?.meals ?? 0} meals this week</p>
      <section className="stack stack--tight">
        <h2>How much work?</h2>
        <p className="muted">Sets per week: {facts.weeks.map((week) => week.sets).join(" · ")}</p>
        <p className="muted">Push {facts.balance.push} · Pull {facts.balance.pull} · Legs {facts.balance.legs}{facts.balance.fullBody ? ` · Full body ${facts.balance.fullBody}` : ""}</p>
        <MinutesLine week={latest} />
      </section>
      {facts.strength.length > 0 ? <section className="stack stack--tight"><h2>Am I stronger?</h2>{facts.strength.map((trend) => <p key={trend.exerciseId}>{trend.name}: {trend.points.map((point) => point.best).join(" → ")} {session.user.units}{trend.points.length > 1 && (trend.points[trend.points.length - 1]?.best ?? 0) > Math.max(...trend.points.slice(0, -1).map((point) => point.best)) ? " 🎉" : ""}</p>)}</section> : null}
      <Link className="button button--secondary" href="/post">Post something</Link>
    </div>
  );
}
