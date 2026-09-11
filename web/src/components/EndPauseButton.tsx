"use client";
// SPEC: A18.6c · Flow 7 · S17 — the one control the paused Home card was missing. Flow 7 gave that state zero
// controls, which left a paused user reading "your streak is frozen until Sat Sep 12" with no route off it that any
// word on the screen named; the action existed only inside Settings. The wording is the one Settings already uses
// (SettingsView.tsx: "End the pause now") so one action never grows a second phrasing (6.6).
//
// Outline, never filled: ending a pause is a choice the screen offers, not the thing the day is asking for
// (Part III law ① — every control is ink either way). Twin of the iOS SecondaryButton on TodayCard's paused branch.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { endPause } from "@/lib/api-client-crew";

export function EndPauseButton() {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  return (
    <button
      type="button"
      className="button button--secondary"
      disabled={busy}
      onClick={async () => {
        setBusy(true);
        await endPause();
        router.refresh(); // the page is server-rendered from homeFacts; the pause is gone on the next pass
      }}
    >
      End the pause now
    </button>
  );
}
