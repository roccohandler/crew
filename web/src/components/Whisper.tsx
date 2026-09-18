"use client";
// SPEC: A23 (Appendix A 2026-09-18, the education layer) · docs/education-copy-draft.md §A — a WHISPER: one line that explains why
// the app works the way it does or how to use it, shown ONCE, the first time its moment arrives. Secondary ink directly under the
// element it explains — no border, no card, no icon; never in a modal or a sheet, never on the bridge (the caller's gate). It leaves on
// the first tap (or key) anywhere on the screen; two whispers on one screen leave together. Every line lives in ONE file,
// shared/copy/education.json. SEEN-STATE IS SERVER-SIDE so the phone and the web agree: `user.whispersSeen` (a union, never shrinking)
// ∪ a per-account local set that survives being offline and is re-sent whole on the next signed-in load. Before an account exists (the
// plan reveal) the set is the browser's own and joins the account at the first signed-in load. 1A stands: teach by doing, not touring.
// Twin: ios Shared/Whisper.swift + WhisperState.swift.
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { education, type WhisperId } from "@/generated/copy";
import { updateMe } from "@/lib/api-client-crew";

interface SeenFacts { seen: string[]; userId: string | null }
const SeenContext = createContext<SeenFacts>({ seen: [], userId: null });
const ANONYMOUS = "anon";
const storeKey = (userId: string | null) => `crew.whispersSeen.${userId ?? ANONYMOUS}`;

function localSeen(userId: string | null): string[] {
  try {
    const stored: unknown = JSON.parse(window.localStorage.getItem(storeKey(userId)) ?? "[]");
    return Array.isArray(stored) ? stored.filter((id): id is string => typeof id === "string") : [];
  } catch {
    return []; // private mode, or a value this build did not write
  }
}

function remember(userId: string | null, ids: string[]): string[] {
  const all = [...new Set([...localSeen(userId), ...ids])];
  try { window.localStorage.setItem(storeKey(userId), JSON.stringify(all)); } catch { /* a browser without storage shows a whisper again next load */ }
  return all;
}

// The signed-in shell wraps its pages in this: the server's list for this account, and the one re-send per page load of anything this
// browser saw that the server has not (an offline dismissal, or the two reveal whispers seen before the account existed)
export function WhispersSeen({ seen, userId, children }: { seen: string[]; userId: string; children: ReactNode }) {
  useEffect(() => {
    const mine = remember(userId, localSeen(null));
    try { window.localStorage.removeItem(storeKey(null)); } catch { /* nothing to clear */ }
    if (mine.some((id) => !seen.includes(id))) void updateMe({ whispersSeen: mine }).catch(() => undefined);
  }, [seen, userId]);
  return <SeenContext.Provider value={{ seen, userId }}>{children}</SeenContext.Provider>;
}

export function Whisper({ id }: { id: WhisperId }) {
  const { seen, userId } = useContext(SeenContext);
  // The server's list is known at render, so an unseen whisper is part of the FIRST paint — it never arrives late and pushes the
  // controls under it out from under a finger (6.7; journey ⑤ lost a tap to exactly that). Only the browser's own set (an offline
  // dismissal the server has not heard of) is read after mount, and that can only take a whisper AWAY.
  const [showing, setShowing] = useState(!seen.includes(id));
  useEffect(() => {
    if (!showing) return undefined;
    if (localSeen(userId).includes(id)) {
      const hide = window.setTimeout(() => setShowing(false), 0);
      return () => window.clearTimeout(hide);
    }
    let gone = false;
    const dismiss = () => {
      if (gone) return; // the tap and the key both listen; the first one wins
      gone = true;
      setShowing(false);
      const mine = remember(userId, [id]);
      if (userId !== null) void updateMe({ whispersSeen: mine }).catch(() => undefined); // offline: the next signed-in load re-sends it
    };
    // `click` and `keyup`, never pointerdown / keydown: the whisper sits ABOVE the control it explains, so removing it while the press
    // is still down moves that control out from under the pointer and the click is lost (journeys ③ and ⑤ found exactly that)
    // CAPTURE phase: the tap that leaves the screen ("Looks good") unmounts this component inside its own handler, and a bubbling
    // listener would be removed before the event ever reached the document — the whisper would never be recorded as seen
    document.addEventListener("click", dismiss, { once: true, capture: true });
    document.addEventListener("keyup", dismiss, { once: true, capture: true });
    return () => {
      document.removeEventListener("click", dismiss, { capture: true });
      document.removeEventListener("keyup", dismiss, { capture: true });
    };
  }, [id, showing, userId]);
  if (!showing) return null;
  return <p className="whisper" role="note">{education.whispers.find((whisper) => whisper.id === id)?.line ?? ""}</p>;
}
