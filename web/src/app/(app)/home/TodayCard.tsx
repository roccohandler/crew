// SPEC: S07 · A3 (owner-directed 2026-09-08) — the Home card by state. The paused return day reads through dayLabel
// (never raw ISO). The bridge stays alone (1D) plus ONE ink line under the CTA. A8: never a zero as a verdict,
// sentence case, verb-first CTAs. Server component; twin of ios Features/Home/TodayCard.
//
// A17.3 (2026-09-10) — the "Log cardio" / "Bonus workout" pair is GONE from this card on both platforms. A3 requires
// *a way* to reach each, not a dedicated button each, and the log rows below are that way at a position that no longer
// moves between states.
//
// A18 (2026-09-10): A18.9 the all-done card REPORTS THE DAY (the stored post summary — the journal's own sentence) and carries
// no control; A18.6c the paused card gains "End the pause now", the string Settings already uses (6.6); A18.8 the bridge ABSORBS
// an open session instead of a second Resume banner appearing beside its one CTA (§1D); A18.3 the what's-next line has left this
// card on rest and all-done — it is the block above it now.
//
// A22 G1 (a) (owner-approved 2026-09-18) — A REST DAY ASKS NOTHING. The rest card's premise line (A18.4: "Rest days count too —
// post anything…") is deleted with the daily requirement it explained; the card carries no control and no stake. The plate
// journal is gone, so the bridge's rest-day CTA ("Start your streak — post a meal") went with it (R-070 below).
import Link from "next/link";
import { dayLabel } from "@/lib/engine/day-label";
import type { TodayState } from "@/lib/today-state";
import { EndPauseButton } from "@/components/EndPauseButton";

type Props = {
  today: TodayState;
  todayKey: string;
  openSessionId: string | null;
  bridgeLine: string | null; // A3 / §1D: the bridge's one line, and only the bridge's
  bonusHref: string | null; // A22: the rest-day bridge's one control — the next rotation workout as a bonus (A3), when the plan has one
  todaySummaryLines: string[];
};

// Each state is its own small component, the way iOS branches inside one `switch` on TodayState: the dispatcher below
// stays readable, and no branch can quietly grow past the size where a reader stops checking the others.

// A18.8 — one CTA, and it takes the open session with it. The bridge lasts until the first POST and starting a workout
// is not a post, so an abandoned first workout used to put a Resume banner beside this button (§1D: nothing competes).
// GAP: A22 G1 (a) — 1D's rest-day bridge lost its subject (the meal). The most conservative in-spec reading keeps §1D's ONE
// control and gives it the bonus workout A3 already offers on every rest day; the copy stops promising a flame a rest day
// cannot light (a bonus workout pays XP and leaves the streak, V70). R-070.
function BridgeCard({ workoutDay, openSessionId, bridgeLine, bonusHref }: { workoutDay: boolean; openSessionId: string | null; bridgeLine: string | null; bonusHref: string | null }) {
  const resuming = openSessionId !== null;
  const href = resuming ? `/session/${openSessionId}` : workoutDay ? "/session/new" : bonusHref;
  const label = resuming ? "Resume your first workout" : workoutDay ? "Start your first workout" : "Start a bonus workout";
  return (
    <div className="stack">
      <p className="muted">{workoutDay || resuming ? "Your first flame lights today." : "Your plan rests today. Your first flame lights on your first planned workout."}</p>
      {href === null ? null : <Link className="button button--primary" href={href}>{label}</Link>}
      {bridgeLine === null ? null : <p className="muted">{bridgeLine}</p>}
    </div>
  );
}

// A18.6c — Flow 7 gave this state zero controls, which left a paused user reading a return date with no route off it
// that any word on the screen named. The wording is the one Settings already uses (6.6: one action, one string).
function PausedCard({ until, todayKey }: { until: string; todayKey: string }) {
  return (
    <section className="card stack stack--tight">
      <h2>Plan paused</h2>
      <p className="muted">Your streak is frozen until {dayLabel(until, todayKey)}. Reminders are off.</p>
      <EndPauseButton />
    </section>
  );
}

// SPEC: Flow 5 · A22 G1 (a) — "a rest day asks nothing": no control, no stake, no premise. The block above names the next workout.
function RestCard() {
  return (
    <section className="card stack stack--tight">
      <h2>Rest day — recovery is part of the plan.</h2>
      <p className="muted">Nothing to do here. A rest day asks nothing of your streak.</p>
    </section>
  );
}

// A18.9 — the day, reported. These are the summaries the server STORED on each post at completion, so this card, the
// journal and Progress print one sentence and cannot drift. No button: the day is closed.
function AllDoneCard({ todaySummaryLines }: { todaySummaryLines: string[] }) {
  return (
    <section className="card stack stack--tight">
      <h2>Done for today.</h2>
      {todaySummaryLines.map((line) => <p key={line} className="muted">{line}</p>)}
    </section>
  );
}

// A14 — the identity line now OUTRANKS the count line (it was a whisper while the SIZE of the workout was the heading),
// and the card lists the day's actual work. Read-only rows: the card still has exactly one action (6.1 · §1B · S07).
function WorkoutCard({ today, openSessionId }: { today: Extract<TodayState, { kind: "workout" }>; openSessionId: string | null }) {
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
    </section>
  );
}

export function TodayCard({ today, todayKey, openSessionId, bridgeLine, bonusHref, todaySummaryLines }: Props) {
  if (today.kind === "bridge") return <BridgeCard workoutDay={today.workoutDay} openSessionId={openSessionId} bridgeLine={bridgeLine} bonusHref={bonusHref} />;
  if (today.kind === "paused") return <PausedCard until={today.until} todayKey={todayKey} />;
  if (today.kind === "rest") return <RestCard />;
  if (today.kind === "allDone") return <AllDoneCard todaySummaryLines={todaySummaryLines} />;
  return <WorkoutCard today={today} openSessionId={openSessionId} />;
}
