"use client";
// SPEC: nutrition addendum §4 (Today) · 6.9 Screen Density (A25, owner-ratified 2026-09-18 — pass/fail) — what sits under the macro
// lines. "Your template" IS Today's job: one row per slot, ONE tap logs it (✓), the same tap undoes it in place, and a skipped slot is
// simply unlogged — a checklist, never a requirement. Everything else the addendum gives Today is ONE TAP AWAY behind a clear,
// well-sized button, because all of it on one screen ran past two scroll-lengths on a phone (6.9: a second scroll-length of content
// becomes a destination screen — R-077): "Quick add" → /nutrition/quick-add, "Logged today · N" → /nutrition/log (absent with nothing
// logged — A8: an empty day reports nothing), and the text link to Saved meals & template. Ink only: no macro fill, no ember, no
// semantic colour (law ⑥'s exception). The empty state is the template INVITATION. Twin: ios Features/Nutrition/NutritionTodayParts.swift.
import Link from "next/link";
import { Whisper } from "@/components/Whisper";
import { gramsSpoken, gramsText, slotTicks } from "@/lib/engine/macro-day";
import type { MealLogResponse } from "@/lib/nutrition-logs";
import type { TemplateSlotResponse } from "@/lib/nutrition-meals";

export const slotTitle = (slot: TemplateSlotResponse) => (slot.label === "" ? slot.meal.name : `${slot.label} · ${slot.meal.name}`);

export function TemplateRows({ slots, logs, onLog, onUndo }: { slots: TemplateSlotResponse[]; logs: MealLogResponse[]; onLog: (slot: TemplateSlotResponse) => void; onUndo: (clientId: string) => void }) {
  if (slots.length === 0) {
    return (
      <section className="stack stack--tight" aria-label="Your template">
        <h2>Your template</h2>
        <p className="muted">Build your usual day once. After that, one tap logs a meal.</p>
      </section>
    );
  }
  const ticks = slotTicks(slots.map((slot) => slot.savedMealId), logs);
  return (
    <section className="stack stack--tight" aria-label="Your template">
      <h2>Your template</h2>
      <div className="logrows">
        {slots.map((slot, index) => {
          const tick = ticks[index] ?? null;
          return (
            <button key={`${slot.savedMealId}-${index}`} type="button" className="logrow" aria-pressed={tick !== null} aria-label={`${slotTitle(slot)}, ${gramsSpoken(slot.meal)}, ${tick === null ? "not logged" : "logged, tap to undo"}`} onClick={() => (tick === null ? onLog(slot) : onUndo(tick))}>
              <span className="logrow__verb" aria-hidden="true">{tick === null ? "" : "✓ "}{slotTitle(slot)}</span>
              <span className="logrow__status" aria-hidden="true">{gramsText(slot.meal)}</span>
            </button>
          );
        })}
      </div>
      <Whisper id="how.shake" />
    </section>
  );
}

// SPEC: 6.9 — the three ways on from Today, each a labelled control of its own: two outline buttons and the addendum's text link
export function TodayLinks({ logged }: { logged: number }) {
  return (
    <nav className="stack stack--tight" aria-label="More">
      <Link className="button button--secondary" href="/nutrition/quick-add">Quick add</Link>
      {logged > 0 ? <Link className="button button--secondary" href="/nutrition/log">{`Logged today · ${logged}`}</Link> : null}
      <Link className="button button--text" href="/nutrition/meals">Saved meals &amp; template</Link>
    </nav>
  );
}
