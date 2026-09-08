// SPEC: S15 Progress on web — layer 3 only for weight-logged exercises; heat-map day-tap opens that day's workout + plates;
// meals/week; empty states invite. 6.7: Progress may widen to ~960 px. T040 (web half)
import { ObjectId } from "mongodb";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { HeatMap } from "@/components/HeatMap";
import { WeeklyRing } from "@/components/WeeklyRing";
import { posts, sessions } from "@/lib/db";
import { findPlan } from "@/lib/plans";
import { progressFacts } from "@/lib/progress-facts";
import { readSession } from "@/lib/session";

async function DayDetail({ userId, dayKey }: { userId: ObjectId; dayKey: string }) {
  const [daySessions, dayPosts] = await Promise.all([(await sessions()).find({ userId, dayKey, status: "completed" }).toArray(), (await posts()).find({ userId, dayKey, deletedAt: null }).toArray()]);
  return (
    <section className="card stack stack--tight" aria-live="polite">
      <h2>{dayKey}</h2>
      {daySessions.map((session) => <p key={session._id.toHexString()}>{session.workoutName} · {session.exercises.flatMap((exercise) => exercise.sets).filter((set) => set.done && !set.isWarmup).length} sets</p>)}
      {dayPosts.filter((post) => post.type !== "workout").map((post) => <p key={post._id.toHexString()}>{post.photoKey ? <img className="photo" src={`/api/v1/photos/${post.photoKey}`} alt="" /> : null}{post.caption}</p>)}
      {daySessions.length === 0 && dayPosts.length === 0 ? <p className="muted">{"Nothing that day. Tomorrow's a fresh one."}</p> : null}
    </section>
  );
}

export default async function ProgressPage({ searchParams }: { searchParams: Promise<{ day?: string }> }) {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const plan = await findPlan(userId);
  const facts = await progressFacts(userId, session.user.timezone, plan?.workouts.map((workout) => workout.weekday) ?? []);
  const { day } = await searchParams;
  if (facts.totals.posts === 0) return <EmptyState title="Your first post starts the story" line="Every workout and every plate lands here." ctaTitle="Post something" href="/post" />;
  return (
    <div className="stack app-column--progress">
      <h1>Progress</h1>
      <Link className="button button--text" href="/journal">Journal — every post, forever</Link>
      <section className="stack stack--tight"><h2>Did I show up?</h2><HeatMap days={facts.days} selected={day ?? null} /></section>
      {day ? <DayDetail userId={userId} dayKey={day} /> : null}
      <div className="row" aria-label="Weekly rings">{facts.weeks.map((week) => <div key={week.weekKey} className="stack center" style={{ gap: 0 }}><WeeklyRing done={week.done} planned={week.planned} /><span className="whisper">{week.weekKey.slice("YYYY-".length)}</span></div>)}</div>
      <p className="muted">Streak {facts.totals.currentStreak} · longest {facts.totals.longestStreak} · {facts.totals.workouts} workouts · {facts.totals.posts} posts · {facts.weeks[facts.weeks.length - 1]?.meals ?? 0} meals this week</p>
      <section className="stack stack--tight"><h2>How much work?</h2><p className="muted">Sets per week: {facts.weeks.map((week) => week.sets).join(" · ")}</p><p className="muted">Push {facts.balance.push} · Pull {facts.balance.pull} · Legs {facts.balance.legs}{facts.balance.fullBody ? ` · Full body ${facts.balance.fullBody}` : ""}</p></section>
      {facts.strength.length > 0 ? <section className="stack stack--tight"><h2>Am I stronger?</h2>{facts.strength.map((trend) => <p key={trend.exerciseId}>{trend.name}: {trend.points.map((point) => point.best).join(" → ")} {session.user.units}{trend.points.length > 1 && (trend.points[trend.points.length - 1]?.best ?? 0) > Math.max(...trend.points.slice(0, -1).map((point) => point.best)) ? " 🎉" : ""}</p>)}</section> : null}
      <Link className="button button--secondary" href="/post">Post something</Link>
    </div>
  );
}
