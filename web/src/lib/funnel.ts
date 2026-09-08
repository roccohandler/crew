// SPEC: 1C speed targets ("measured, funnel-instrumented": organic hero → Home ≤ 90 s median, invited ≤ 60 s) · 1D (the
// onboarding → first-post gap as its own funnel step) · docs/api.md POST events. Plain functions (C2): a step happening
// BEFORE the account exists is kept in sessionStorage with its own moment, and the whole batch is flushed once the account
// does — POST events keeps the client's `at`, so hero → saved is measurable server-side. Web twin of ios Funnel.
import { logClientEvents } from "@/lib/api-client";

const QUEUE_KEY = "crew.funnel";

interface FunnelStep { name: string; at: string; props?: Record<string, string | number | boolean | null> }

function readQueue(): FunnelStep[] {
  try {
    const raw = window.sessionStorage.getItem(QUEUE_KEY);
    return raw ? (JSON.parse(raw) as FunnelStep[]) : [];
  } catch {
    return [];
  }
}

// Records a step once per browsing session (a re-rendered hero is one hero), stamped now.
export function markFunnelStep(name: string, props?: FunnelStep["props"]): void {
  const queue = readQueue();
  if (queue.some((step) => step.name === name)) return;
  queue.push({ name, at: new Date().toISOString(), ...(props ? { props } : {}) });
  try { window.sessionStorage.setItem(QUEUE_KEY, JSON.stringify(queue)); } catch { /* private mode: the funnel is a measurement, never a blocker */ }
}

// Sends whatever is queued under the now-signed-in account and clears it. A failed flush is dropped, never retried, never
// shown: analytics must not stand in the user's path (Part IV — first-party events, nothing else).
export async function flushFunnel(): Promise<void> {
  const queue = readQueue();
  try { window.sessionStorage.removeItem(QUEUE_KEY); } catch { /* nothing to clear */ }
  if (queue.length === 0) return;
  await logClientEvents(queue).catch(() => undefined);
}
