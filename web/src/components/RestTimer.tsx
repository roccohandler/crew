"use client";
// SPEC: Flow 3 rest timer · G9 (default 90 s, per-workout adjustable, off-able) — a quiet inline countdown that starts when a
// set is checked; no sound on web (haptics-only feedback is an iPhone law, the web has neither). Twin of ios RestTimerView.
import { useEffect, useState } from "react";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

function clock(seconds: number): string {
  const minutes = Math.floor(seconds / TimeUnits.secondsPerMinute);
  const rest = seconds % TimeUnits.secondsPerMinute;
  return `${minutes}:${String(rest).padStart("00".length, "0")}`;
}

// `startToken` counts checked sets: every new value (re)starts the countdown. The end moment is state written from a
// scheduled callback (never during render or synchronously inside the effect); the display derives from the ticking `now`.
export function RestTimer({ startToken }: { startToken: number }) {
  const [length, setLength] = useState<number>(SpecConstants.restTimerDefaultSeconds);
  const [enabled, setEnabled] = useState(true);
  const [endsAt, setEndsAt] = useState<number | null>(null);
  const [now, setNow] = useState<number>(0);

  useEffect(() => {
    if (startToken === 0 || !enabled) return;
    const arm = window.setTimeout(() => {
      const started = Date.now();
      setNow(started);
      setEndsAt(started + length * TimeUnits.msPerSecond);
    }, 0);
    return () => window.clearTimeout(arm);
  }, [startToken, enabled, length]);

  useEffect(() => {
    if (endsAt === null) return;
    const ticker = window.setInterval(() => setNow(Date.now()), TimeUnits.msPerSecond);
    return () => window.clearInterval(ticker);
  }, [endsAt]);

  const remaining = endsAt === null ? 0 : Math.max(0, Math.ceil((endsAt - now) / TimeUnits.msPerSecond));
  const running = remaining > 0;
  const step = SpecConstants.restTimerAdjustStepSeconds;
  return (
    <div className="row row--wrap" role="group" aria-label="Rest timer">
      {running ? <span className="muted" aria-live="polite">rest {clock(remaining)}</span> : null}
      {running ? <button type="button" className="button button--text" onClick={() => setEndsAt(null)}>Skip rest</button> : null}
      {!running ? <button type="button" className="button button--text" onClick={() => setEnabled(!enabled)} aria-pressed={enabled}>{enabled ? `Rest ${clock(length)}` : "Rest timer off"}</button> : null}
      {!running && enabled ? <span className="stepper" role="group" aria-label="rest length"><button type="button" onClick={() => setLength(Math.max(step, length - step))} aria-label="Shorter rest">−</button><button type="button" onClick={() => setLength(length + step)} aria-label="Longer rest">+</button></span> : null}
    </div>
  );
}
