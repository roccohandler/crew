// SPEC: Flow 9 layer 1 — the heat map; tap a day → that day's workout + plates; Part III law ④ (ember fills = progress; a missed
// day is neutral, never red). Mirrors ios HeatMapView. Keyboard-complete: every day is a link.
import Link from "next/link";
import type { DayCell } from "@/lib/progress-facts";

export function HeatMap({ days, selected }: { days: DayCell[]; selected: string | null }) {
  return (
    <div className="heatmap" role="list" aria-label="Days">
      {days.map((day) => (
        <Link key={day.dayKey} role="listitem" href={`/progress?day=${day.dayKey}`} className={day.workout ? "heatmap__day heatmap__day--workout" : day.posted ? "heatmap__day heatmap__day--posted" : "heatmap__day"} aria-label={`${day.dayKey}${day.workout ? ", workout" : day.posted ? ", posted" : ""}`} aria-current={selected === day.dayKey ? "date" : undefined} />
      ))}
    </div>
  );
}
