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
  // A14 — the identity line now OUTRANKS the count line (it was a whisper while the SIZE of the workout was the heading),
  // and the card lists the day's actual work. Read-only rows: the card still has exactly one action (6.1 · §1B · S07).
  return (
    <section className="card stack">
      <div className="stack stack--tight">
        <h2>{today.name.toUpperCase()}</h2>
        <p className="whisper">{today.exerciseCount} {today.exerciseCount === 1 ? "exercise" : "exercises"} + mobility{today.hasCardio ? " + cardio" : ""}</p>
      </div>
      <ul className="worklist">
        {today.lines.map((line) => (
          <li key={line.name} className="worklist__row"><span>{line.name}</span><span className="worklist__detail">{line.detail}</span></li>
        ))}
        {today.tail === null ? null : <li className="worklist__tail">{today.tail}</li>}
      </ul>
      <Link className="button button--primary" href={openSessionId ? `/session/${openSessionId}` : "/session/new"}>{openSessionId ? "Resume workout" : "Start workout"}</Link>
      <NextUpLine line={nextUpLine} />
    </section>
  );
}
