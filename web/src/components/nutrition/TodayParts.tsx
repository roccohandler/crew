"use client";
// SPEC: nutrition addendum §4 (Today) — the three blocks under the macro lines. "Your template": one row per slot, ONE tap logs it
// (✓), the same tap undoes it in place, and a skipped slot is simply unlogged — a checklist, never a requirement. "Quick add": three
// gram steppers and Add. Then today's log, every row with its visible Delete (6.3). Ink only: no macro fill, no ember, no semantic
// colour (law ⑥'s exception). The empty state is the template INVITATION. Twin: ios Features/Nutrition/NutritionTodayParts.swift.
import Link from "next/link";
import { useState } from "react";
import { GramFields } from "@/components/nutrition/GramField";
import { gramsSpoken, gramsText, slotTicks } from "@/lib/engine/macro-day";
import type { MealLogResponse } from "@/lib/nutrition-logs";
import type { TemplateSlotResponse } from "@/lib/nutrition-meals";
import { SpecConstants } from "@/generated/spec-constants";

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
    </section>
  );
}

export function QuickAdd({ onAdd }: { onAdd: (grams: { proteinG: number; carbsG: number; fatG: number }) => void }) {
  const empty = { proteinG: 0, carbsG: 0, fatG: 0 };
  const [grams, setGrams] = useState(empty);
  const nothing = grams.proteinG + grams.carbsG + grams.fatG === 0;
  return (
    <section className="stack stack--tight" aria-label="Quick add">
      <h2>Quick add</h2>
      <GramFields value={grams} max={SpecConstants.macroGramsMaxPerEntry} onChange={setGrams} />
      <button type="button" className="button button--secondary" disabled={nothing} onClick={() => { onAdd(grams); setGrams(empty); }}>Add</button>
    </section>
  );
}

export function LogList({ logs, onDelete }: { logs: MealLogResponse[]; onDelete: (clientId: string) => void }) {
  if (logs.length === 0) return null;
  return (
    <section className="stack stack--tight" aria-label="Logged today">
      <h2>Logged today</h2>
      <ul className="worklist">
        {logs.map((log) => (
          <li key={log.clientId} className="mealrow">
            <span>{log.name}<span className="worklist__detail"> · {gramsText(log)}</span></span>
            <button type="button" className="button button--text" aria-label={`Delete ${log.name}, ${gramsSpoken(log)}`} onClick={() => onDelete(log.clientId)}>Delete</button>
          </li>
        ))}
      </ul>
    </section>
  );
}

export function MealsLink() {
  return <Link className="button button--text" href="/nutrition/meals">Saved meals &amp; template</Link>;
}
