"use client";
// SPEC: nutrition addendum §4 ("Quick add": three gram steppers and Add · today's log with the visible Delete, 6.3) · 6.9 Screen
// Density (A25) — the two DESTINATIONS behind Today's buttons (R-077): each is one job on its own screen. Quick add carries the one
// filled primary (Add) and returns to Today, where the lines have moved; the log lists today's entries, each with its own Delete, and
// nothing is recomputed when one goes — a log was never counted (clause ③). Three gram amounts and nothing else: no food is named and
// no food is judged (clause ⑤). Ink only; an error is ink. Twin: ios Features/Nutrition/QuickAddScreen.swift + NutritionLogScreen.swift.
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { GramFields } from "@/components/nutrition/GramField";
import { isApiClientError } from "@/lib/api-client";
import { createMealLog, deleteMealLog } from "@/lib/api-client-nutrition";
import { gramsSpoken, gramsText } from "@/lib/engine/macro-day";
import type { MealLogResponse } from "@/lib/nutrition-logs";
import { SpecConstants } from "@/generated/spec-constants";

const QUICK_ADD_NAME = "Quick add";

export function QuickAddForm({ timezone }: { timezone: string }) {
  const router = useRouter();
  const [grams, setGrams] = useState({ proteinG: 0, carbsG: 0, fatG: 0 });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const nothing = grams.proteinG + grams.carbsG + grams.fatG === 0;
  const add = async () => {
    setBusy(true);
    setError(null);
    try {
      await createMealLog({ clientId: crypto.randomUUID(), timezone, name: QUICK_ADD_NAME, ...grams, quickAdd: true });
      router.push("/nutrition");
      router.refresh();
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't add that. Try again.");
      setBusy(false);
    }
  };
  return (
    <div className="stack">
      <GramFields value={grams} max={SpecConstants.macroGramsMaxPerEntry} onChange={setGrams} />
      {error ? <p className="notice" role="alert">{error}</p> : null}
      <button type="button" className="button button--primary" disabled={busy || nothing} onClick={() => void add()}>Add</button>
      <Link className="button button--text" href="/nutrition">Back to Today</Link>
    </div>
  );
}

export function DayLogList({ initialLogs }: { initialLogs: MealLogResponse[] }) {
  const [logs, setLogs] = useState(initialLogs);
  const [error, setError] = useState<string | null>(null);
  const remove = async (log: MealLogResponse) => {
    setError(null);
    setLogs((current) => current.filter((kept) => kept.clientId !== log.clientId));
    try {
      await deleteMealLog(log.clientId);
    } catch (caught) {
      setLogs((current) => (current.some((kept) => kept.clientId === log.clientId) ? current : [...current, log]));
      setError(isApiClientError(caught) ? caught.message : "Couldn't delete that. Try again.");
    }
  };
  return (
    <div className="stack">
      {error ? <p className="notice" role="alert">{error}</p> : null}
      {logs.length === 0 ? <p className="muted">Nothing logged yet today.</p> : null}
      <ul className="worklist">
        {logs.map((log) => (
          <li key={log.clientId} className="mealrow">
            <span>{log.name}<span className="worklist__detail"> · {gramsText(log)}</span></span>
            <button type="button" className="button button--text" aria-label={`Delete ${log.name}, ${gramsSpoken(log)}`} onClick={() => void remove(log)}>Delete</button>
          </li>
        ))}
      </ul>
      <Link className="button button--text" href="/nutrition">Back to Today</Link>
    </div>
  );
}
