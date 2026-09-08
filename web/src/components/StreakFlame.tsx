// SPEC: 1D (unlit at 0) · Part III law ④ (the ember flame is progress, never chrome). Mirrors ios Shared/StreakFlame.
export function StreakFlame({ streak, paused }: { streak: number; paused: boolean }) {
  const lit = streak > 0 && !paused;
  return (
    <div className="flame" aria-label={paused ? `Streak paused at ${streak}` : `Streak ${streak}`}>
      <span className={lit ? "flame__icon flame__icon--lit" : "flame__icon"} aria-hidden="true">{paused ? "🧊" : "🔥"}</span>
      <span className={lit ? "flame__count ember-text" : "flame__count muted"}>{streak}</span>
    </div>
  );
}
