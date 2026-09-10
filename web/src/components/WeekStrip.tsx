// SPEC: A14 (owner-directed 2026-09-09) · A17.1 / A17.4 (2026-09-10) — the seven-day strip and the one ink sentence
// under it.
//
// Home computed these states all along and rendered none of them (F12), so the user saw "2/4" and one continuous arc
// and could not tell WHICH two days they hit. A14 rendered the marks. A17 adds the sentence, because marks alone were
// still unreadable: the owner's report was "I don't know what the colors are for", and the answer is to say so in
// words, in place, rather than in a legend the eye has to travel to and back from.
//
// Part III law ④ — a done day is the one place ember belongs here (progress IS the message); every other mark is ink
// or the secondary gray, and the strip is never a control: it reports, it does not navigate. 6.5 — every mark carries
// a SHAPE as well as a colour AND clears the 3:1 non-text ratio (H014); the A14 pass answered only the first of those.
// Mirrors ios Features/Home/WeekStrip.
import type { DayProjection } from "@/lib/engine/plan-rotation";
import { weekSummary } from "@/lib/engine/week-summary";

const INITIALS = ["M", "T", "W", "T", "F", "S", "S"]; // ISO order, Monday weeks (Appendix A policy)

// A1's projection states map to the marks: done · today (the open day) · missed (a training day already past and not
// done) · upcoming (a planned day still to come) · rest. The state strings are the WeekSummary twin's contract.
function markOf(day: DayProjection, todayKey: string): string {
  if (day.state === "done") return "done";
  if (day.dayKey === todayKey) return "today";
  if (day.state === "open") return "missed";
  if (day.state === "planned") return "upcoming";
  return "rest";
}

export function WeekStrip({ week, todayKey }: { week: DayProjection[]; todayKey: string }) {
  if (week.length === 0) return null;
  const days = week.slice(0, INITIALS.length);
  const marks = days.map((day) => markOf(day, todayKey));
  // A17.4 — only the FIRST upcoming training day is marked. Marking every future one would answer a question nobody
  // asked and put three identical marks where one fact belongs. Twin of HomeModel.weekMarks's firstIndex(of: .upcoming).
  const next = marks.indexOf("upcoming");
  if (next >= 0) marks[next] = "nextUp";
  const lines = weekSummary(marks);
  return (
    <div className="stack stack--tight">
      {/* E20 — one sentence, not seven stops, and now the SAME sentence the eye gets, extended to full day names
          (a screen reader says "Wed" letter by letter). */}
      <div className="weekstrip" role="img" aria-label={lines.spoken}>
        {days.map((day, index) => (
          <div key={day.dayKey} className="weekstrip__day">
            <span className="weekstrip__initial" aria-hidden="true">{INITIALS[index]}</span>
            {/* box then dot, exactly as iOS does `mark(state).frame(...)`: the box is always 12 px so every mark shares
                one centre line, and only the dot inside it changes size. */}
            <span className="weekstrip__mark" aria-hidden="true"><span className={`weekstrip__dot weekstrip__dot--${marks[index]}`} /></span>
          </div>
        ))}
      </div>
      {/* A17.1 — ink, never #B84D00 (law ③), never tappable (law ①). This is the sentence the whole screen was
          missing: it names which day was done, which was missed, and when the next workout is. */}
      <p className="muted" aria-hidden="true">{lines.short}</p>
    </div>
  );
}
