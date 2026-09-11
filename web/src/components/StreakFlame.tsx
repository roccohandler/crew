// SPEC: 1D (unlit at 0) · Part III law ④ (the ember flame is progress, never chrome). Mirrors ios Shared/StreakFlame.
//
// A18 / J024 — the accessible name was on a bare <div>. ARIA prohibits naming a generic element, which is the exact
// defect H007 fixed for the crew strip (and which the Home page documents in writing); WeeklyRing.tsx already did it
// correctly with role="img". The count was not aria-hidden either, so a screen reader could get a bare "1" where iOS
// speaks "Streak 1". Both halves are now inside one labelled img, so the visible glyph and numeral are one stop.
export function StreakFlame({ streak, paused }: { streak: number; paused: boolean }) {
  const lit = streak > 0 && !paused;
  return (
    <div className="flame" role="img" aria-label={paused ? `Streak paused at ${streak}` : `Streak ${streak}`}>
      <span className={lit ? "flame__icon flame__icon--lit" : "flame__icon"} aria-hidden="true">{paused ? "🧊" : "🔥"}</span>
      <span className={lit ? "flame__count ember-text" : "flame__count muted"} aria-hidden="true">{streak}</span>
    </div>
  );
}
