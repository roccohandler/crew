// SPEC: S07 · A3 (owner-directed 2026-09-08) — the Home card by state. Every non-bridge state carries the what's-next line
// and a way to post a meal. The paused return day reads through dayLabel (never raw ISO). The bridge stays alone (1D) plus
// ONE ink line under the CTA. A8: never a zero as a verdict, sentence case, verb-first CTAs. Server component; twin of ios
// Features/Home/TodayCard.
//
// A17.3 (2026-09-10) — the "Log cardio" / "Bonus workout" pair is GONE from this card, on both platforms. A3 requires *a
// way* to reach each, not a dedicated button each, and the three-slot vector row below is that way at a position that no
// longer moves between states. Before this, rest and all-done offered seven controls reaching three destinations with
// "Post a meal" available three separate ways. They still carry no ink-filled primary once posted, deliberately: on a day
// when nothing is required, a filled primary would manufacture an ask. One primary per view is a ceiling, not a floor.
import Link from "next/link";
import { dayLabel } from "@/lib/engine/day-label";
import type { TodayState } from "@/lib/today-state";

type Props = { today: TodayState; todayKey: string; openSessionId: string | null; nextUpLine: string | null; streak: number };

// SPEC: A3 — "Tomorrow: Pull day · 5 exercises" / "Next workout: Wed · Pull day"; nothing on an undone training day
export function NextUpLine({ line }: { line: string | null }) {
  return line === null ? null : <p className="muted">{line}</p>;
}

// SPEC: A17.1 · A8 · spec:452 — what today is worth, in the line that was already there. "One post keeps it lit" never
// said what "it" was. No new element, no countdown, no notification; at streak 0 it never says "0-day streak".
function stakeLine(posted: boolean, streak: number): string {
  if (posted) return "Today counts.";
  return streak > 0 ? `Post anything today and your ${streak}-day streak holds.` : "One post lights your first flame.";
}

function RestCard({ posted, nextUpLine, streak }: { posted: boolean; nextUpLine: string | null; streak: number }) {
  return (
    <section className="card stack stack--tight">
      <h2>Rest day — recovery is part of the plan.</h2>
      <p className="muted">{stakeLine(posted, streak)}</p>
      {posted ? <NextUpLine line={nextUpLine} /> : <Link className="button button--primary" href="/post">Post a meal</Link>}
      {posted ? <Link className="button button--secondary" href="/post">Post another</Link> : <NextUpLine line={nextUpLine} />}
    </section>
  );
}

export function TodayCard({ today, todayKey, openSessionId, nextUpLine, streak }: Props) {
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
  if (today.kind === "rest") return <RestCard posted={today.posted} nextUpLine={nextUpLine} streak={streak} />;
  if (today.kind === "allDone") {
    return (
      <section className="card stack stack--tight">
        <h2>Done for today.</h2>
        <NextUpLine line={nextUpLine} />
        <Link className="button button--secondary" href="/post">Post a meal</Link>
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
