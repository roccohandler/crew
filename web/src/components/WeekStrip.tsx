// SPEC: A14 (owner-directed 2026-09-09) — the seven-day strip. Home computed the per-day states all along and passed them
// into a ring that never read them (F12), so the user saw "2/4" and one continuous arc and could not tell WHICH two days
// they hit. This renders the states that were already there.
//
// Part III law ④ — a done day is the one place ember belongs here (progress IS the message); everything else is ink or the
// missed gray, and the strip is never a control: it reports, it does not navigate. 6.5 — every mark carries a shape as well
// as a colour, so it reads in grayscale and under every CVD model. Mirrors ios Features/Home/WeekStrip.
import type { DayProjection } from "@/lib/engine/plan-rotation";

const INITIALS = ["M", "T", "W", "T", "F", "S", "S"]; // ISO order, Monday weeks (Appendix A policy)

// A1's projection states map to the four marks: done · today (the open day) · missed (a training day already past) · rest
function markOf(day: DayProjection, todayKey: string): "done" | "today" | "missed" | "rest" {
  if (day.state === "done") return "done";
  if (day.dayKey === todayKey) return "today";
  if (day.state === "open") return "missed"; // a training day that is behind us and holds no completed workout
  return "rest";
}

// E20 — one sentence, not seven stops. A8: a count is stated only when there is one.
function summaryOf(marks: string[]): string {
  const done = marks.filter((mark) => mark === "done").length;
  const missed = marks.filter((mark) => mark === "missed").length;
  if (done === 0 && missed === 0) return "This week: nothing logged yet";
  const workouts = done === 1 ? "1 workout" : `${done} workouts`;
  return missed === 0 ? `This week: ${workouts} done` : `This week: ${workouts} done, ${missed} missed`;
}

export function WeekStrip({ week, todayKey }: { week: DayProjection[]; todayKey: string }) {
  if (week.length === 0) return null;
  const days = week.slice(0, INITIALS.length);
  const marks = days.map((day) => markOf(day, todayKey));
  return (
    <div className="weekstrip" role="img" aria-label={summaryOf(marks)}>
      {days.map((day, index) => (
        <div key={day.dayKey} className="weekstrip__day">
          <span className="weekstrip__initial" aria-hidden="true">{INITIALS[index]}</span>
          <span className={`weekstrip__mark weekstrip__mark--${marks[index]}`} aria-hidden="true" />
        </div>
      ))}
    </div>
  );
}
