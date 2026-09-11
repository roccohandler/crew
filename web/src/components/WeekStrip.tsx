// SPEC: A14 (owner-directed 2026-09-09) · A17.1 / A17.4 · A18.6a / A18.7 (2026-09-10) — the seven-day strip and the
// one ink sentence under it.
//
// Home computed these states all along and rendered none of them (F12), so the user saw "2/4" and one continuous arc
// and could not tell WHICH two days they hit. A14 rendered the marks. A17 added the sentence, because marks alone were
// still unreadable: the owner's report was "I don't know what the colors are for", and the answer is to say so in
// words, in place, rather than in a legend the eye has to travel to and back from.
//
// A18.7 — THE MARKS NOW ARRIVE COMPUTED, from lib/today-state.ts, exactly as ios HomeModel.weekMarks computes them in
// the model. This component derived its own from `projectWeek`'s states, which tested a day's COMPLETION before the
// training-day guard and so emitted "done" for a bonus workout on a non-training day — while the ring, computed
// elsewhere, counted planned days only. One user, two answers, and two different sentences out of the same WeekSummary
// twin. A view that re-derives a fact the model already holds is how twins drift; this one no longer does.
//
// Part III law ④ — a done day is the one place ember belongs here (progress IS the message); every other mark is ink
// or the secondary gray, and the strip is never a control: it reports, it does not navigate. 6.5 — every mark carries
// a SHAPE as well as a colour AND clears the 3:1 non-text ratio (H014).
// Mirrors ios Features/Home/WeekStrip.
import { weekSummary } from "@/lib/engine/week-summary";

const INITIALS = ["M", "T", "W", "T", "F", "S", "S"]; // ISO order, Monday weeks (Appendix A policy)

export function WeekStrip({ marks }: { marks: string[] }) {
  if (marks.length === 0) return null;
  const days = marks.slice(0, INITIALS.length);
  const lines = weekSummary(days);
  return (
    <div className="stack stack--tight">
      {/* E20 — one sentence, not seven stops, and the SAME sentence the eye gets, extended to full day names
          (a screen reader says "Wed" letter by letter). */}
      <div className="weekstrip" role="img" aria-label={lines.spoken}>
        {days.map((mark, index) => (
          <div key={`${INITIALS[index]}-${index}`} className="weekstrip__day">
            <span className="weekstrip__initial" aria-hidden="true">{INITIALS[index]}</span>
            {/* box then dot, exactly as iOS does `mark(state).frame(...)`: the box is always 12 px so every mark shares
                one centre line, and only the dot inside it changes size. */}
            <span className="weekstrip__mark" aria-hidden="true"><span className={`weekstrip__dot weekstrip__dot--${mark}`} /></span>
          </div>
        ))}
      </div>
      {/* A17.1 — ink, never #B84D00 (law ③), never tappable (law ①). This is the sentence the whole screen was
          missing: it names which day was done, which was missed, and when the next workout is. */}
      <p className="muted" aria-hidden="true">{lines.short}</p>
    </div>
  );
}
