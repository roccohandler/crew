// SPEC: S07 · A3 (owner-directed 2026-09-08) — the Home card by state. Every non-bridge state carries the what's-next line, a
// way to post a meal, Log cardio and (rest / all-done) Bonus workout — the next rotation workout, +25 (Flow 5). The paused
// return day reads through dayLabel (never raw ISO). The bridge stays alone (1D) plus ONE ink line under the CTA. A8: never a
// zero as a verdict, sentence case, verb-first CTAs. Server component; twin of ios Features/Home/TodayCard.
import Link from "next/link";
import { dayLabel } from "@/lib/engine/day-label";
import type { TodayState } from "@/lib/today-state";

type Props = { today: TodayState; todayKey: string; openSessionId: string | null; nextUpLine: string | null; bonusKind: string | null };

// SPEC: A3 — "Tomorrow: Pull day · 5 exercises" / "Next workout: Wed · Pull day"; nothing on an undone training day
export function NextUpLine({ line }: { line: string | null }) {
  return line === null ? null : <p className="muted">{line}</p>;
}

// SPEC: A3 — the secondaries: a meal post (when the state names one), Log cardio, Bonus workout (rest / all-done only)
function Secondaries({ post, bonusKind }: { post: string | null; bonusKind: string | null }) {
  return (
    <div className="row row--wrap">
      {post !== null ? <Link className="button button--secondary" href="/post">{post}</Link> : null}
      <Link className="button button--secondary" href="/log-cardio">Log cardio</Link>
      {bonusKind !== null ? <Link className="button button--secondary" href={`/session/new?bonus=${bonusKind}`}>Bonus workout</Link> : null}
    </div>
  );
}

function RestCard({ posted, nextUpLine, bonusKind }: { posted: boolean; nextUpLine: string | null; bonusKind: string | null }) {
  return (
    <section className="card stack stack--tight">
      <h2>Rest day — recovery is part of the plan.</h2>
      <p className="muted">{posted ? "Today counts." : "One post keeps it lit."}</p>
      {posted ? <NextUpLine line={nextUpLine} /> : <Link className="button button--primary" href="/post">Post a meal</Link>}
      <Secondaries post={posted ? "Post another" : null} bonusKind={bonusKind} />
      {posted ? null : <NextUpLine line={nextUpLine} />}
    </section>
  );
}

export function TodayCard({ today, todayKey, openSessionId, nextUpLine, bonusKind }: Props) {
  if (today.kind === "bridge") {
    return (
      <div className="stack">
        <p className="muted">Your first flame lights today.</p>
        <Link className="button button--primary" href={today.workoutDay ? "/session/new" : "/post"}>{today.workoutDay ? "Start your first workout" : "Start your streak — post a meal"}</Link>
        <NextUpLine line={nextUpLine} />
      </div>
    );
  }
  if (today.kind === "paused") return <section className="card stack stack--tight"><h2>Plan paused</h2><p className="muted">Your streak is frozen until {dayLabel(today.until, todayKey)}. Reminders are off.</p></section>;
  if (today.kind === "rest") return <RestCard posted={today.posted} nextUpLine={nextUpLine} bonusKind={bonusKind} />;
  if (today.kind === "allDone") {
    return (
      <section className="card stack stack--tight">
        <h2>Done for today.</h2>
        <NextUpLine line={nextUpLine} />
        <Secondaries post="Post a meal" bonusKind={bonusKind} />
      </section>
    );
  }
  return (
    <section className="card stack stack--tight">
      <p className="whisper">{today.name.toUpperCase()}</p>
      <h2>{today.exerciseCount} {today.exerciseCount === 1 ? "exercise" : "exercises"} + mobility{today.hasCardio ? " + cardio" : ""}</h2>
      <Link className="button button--primary" href={openSessionId ? `/session/${openSessionId}` : "/session/new"}>{openSessionId ? "Resume workout" : "Start workout"}</Link>
      <NextUpLine line={nextUpLine} />
    </section>
  );
}
