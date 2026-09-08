// SPEC: Flow 2 ("weekly ring 2/4") · Part III law ④ (ember fill, tint track). Mirrors ios Shared/WeeklyRing. Inline SVG, no library.
import { Geometry } from "@/lib/geometry";

const CENTER = Geometry.svgViewBox * Geometry.half;
const CIRCUMFERENCE = Geometry.tau * Geometry.ringRadius;

export function WeeklyRing({ done, planned }: { done: number; planned: number }) {
  const fraction = planned === 0 ? 0 : done / planned;
  return (
    <svg className="ring" viewBox={`0 0 ${Geometry.svgViewBox} ${Geometry.svgViewBox}`} role="img" aria-label={`${done} of ${planned} workouts done this week`}>
      <circle cx={CENTER} cy={CENTER} r={Geometry.ringRadius} fill="none" stroke="var(--ember-ember-tint)" strokeWidth={Geometry.ringStroke} />
      <circle cx={CENTER} cy={CENTER} r={Geometry.ringRadius} fill="none" stroke="var(--ember-ember)" strokeWidth={Geometry.ringStroke} strokeLinecap="round" strokeDasharray={CIRCUMFERENCE} strokeDashoffset={CIRCUMFERENCE * (1 - fraction)} transform={`rotate(${Geometry.quarterTurnDegrees} ${CENTER} ${CENTER})`} />
      <text x="50%" y="50%" dominantBaseline="middle" textAnchor="middle" className="ring__label">{done}/{planned}</text>
    </svg>
  );
}
