"use client";
// SPEC: nutrition addendum §4 (RATIFIED 2026-09-18) — Today: four lines (P / C / F and Calories), "Your template", "Quick add",
// today's log, and a text link to Saved meals & template. NO ink-filled primary of its own (Q3: the Home row "Log macros" is the way
// in). Every write is optimistic and rolls back on failure, written out here (C5): the row appears at once, the server's copy
// replaces it, an error takes it away again and says so in ink — never in the semantic red, which does not exist on this surface.
// A log is never a game event (clause ③): nothing here reads or moves XP, the streak or a shield.
// Twin: ios Features/Nutrition/NutritionTodayScreen.swift.
import { useRef, useState } from "react";
import { MacroLines } from "@/components/nutrition/MacroLines";
import { LogList, MealsLink, QuickAdd, TemplateRows } from "@/components/nutrition/TodayParts";
import { createMealLog, deleteMealLog, type MealLogBody } from "@/lib/api-client-nutrition";
import { isApiClientError } from "@/lib/api-client";
import { remaining } from "@/lib/engine/macro-day";
import type { MealLogResponse } from "@/lib/nutrition-logs";
import type { TemplateSlotResponse } from "@/lib/nutrition-meals";

type Props = { targets: { proteinG: number; carbsG: number; fatG: number }; slots: TemplateSlotResponse[]; initialLogs: MealLogResponse[]; todayKey: string; timezone: string };

const QUICK_ADD_NAME = "Quick add";

// SPEC: V62 — a clientId logs once: a row already on screen is never added twice, and the server answers a replay with the same log.
// One tap logs and the SAME tap undoes (§4), so an undo can arrive while its log is still on the way up: the delete waits for that
// create to land (`sending`) — the server cannot delete what it has not seen — and is skipped when the create failed.
function useDayLog(initialLogs: MealLogResponse[], todayKey: string) {
  const [logs, setLogs] = useState(initialLogs);
  const [error, setError] = useState<string | null>(null);
  const sending = useRef(new Map<string, Promise<boolean>>());
  const fail = (caught: unknown, fallback: string) => setError(isApiClientError(caught) ? caught.message : fallback);
  const add = async (body: MealLogBody) => {
    const optimistic: MealLogResponse = { id: body.clientId, clientId: body.clientId, dayKey: todayKey, savedMealId: body.savedMealId ?? null, name: body.name, proteinG: body.proteinG, carbsG: body.carbsG, fatG: body.fatG, quickAdd: body.quickAdd, createdAt: new Date().toISOString() };
    setError(null);
    setLogs((current) => (current.some((log) => log.clientId === body.clientId) ? current : [...current, optimistic]));
    const sent = createMealLog(body).then((reply) => {
      setLogs((current) => current.map((log) => (log.clientId === body.clientId ? reply.log : log)));
      return true;
    }, (caught: unknown) => {
      setLogs((current) => current.filter((log) => log.clientId !== body.clientId));
      fail(caught, "Couldn't log that. Try again.");
      return false;
    });
    sending.current.set(body.clientId, sent);
    await sent;
    sending.current.delete(body.clientId);
  };
  const remove = async (clientId: string) => {
    const removed = logs.find((log) => log.clientId === clientId);
    if (removed === undefined) return;
    setError(null);
    setLogs((current) => current.filter((log) => log.clientId !== clientId));
    try {
      if ((await (sending.current.get(clientId) ?? Promise.resolve(true))) === false) return;
      await deleteMealLog(clientId);
    } catch (caught) {
      setLogs((current) => (current.some((log) => log.clientId === clientId) ? current : [...current, removed]));
      fail(caught, "Couldn't delete that. Try again.");
    }
  };
  return { logs, error, add, remove };
}

export function NutritionToday({ targets, slots, initialLogs, todayKey, timezone }: Props) {
  const { logs, error, add, remove } = useDayLog(initialLogs, todayKey);
  const logSlot = (slot: TemplateSlotResponse) => void add({ clientId: crypto.randomUUID(), timezone, savedMealId: slot.savedMealId, name: slot.meal.name, proteinG: slot.meal.proteinG, carbsG: slot.meal.carbsG, fatG: slot.meal.fatG, quickAdd: false });
  const quickAdd = (grams: { proteinG: number; carbsG: number; fatG: number }) => void add({ clientId: crypto.randomUUID(), timezone, name: QUICK_ADD_NAME, ...grams, quickAdd: true });
  return (
    <div className="stack stack--page">
      <h1>Today</h1>
      <MacroLines remaining={remaining(targets, logs)} />
      {error ? <p className="notice" role="alert">{error}</p> : null}
      <TemplateRows slots={slots} logs={logs} onLog={logSlot} onUndo={(clientId) => void remove(clientId)} />
      <QuickAdd onAdd={quickAdd} />
      <LogList logs={logs} onDelete={(clientId) => void remove(clientId)} />
      <MealsLink />
    </div>
  );
}
