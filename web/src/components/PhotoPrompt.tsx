"use client";
// SPEC: 1C ("profile photo prompted at first crew join — skippable") / W4 (owner-approved 2026-09-17) — once, on the first Crew
// screen a member sees with a crew and no photo: one line, Add a photo (Settings holds the picker, E1) or Not now. The answer is
// remembered in this browser; the twin is ios ProfilePhotoPrompt.swift. Ink acts (Part III law ①); an invitation, never a nag (6.1).
// CrewView renders this only after its client-side load, so the browser's memory can be read as the initial state (no SSR pass).
import Link from "next/link";
import { useState } from "react";
import type { MemberDot } from "@/lib/crew-stream";

const KEY = "photoPromptAnswered";

function rememberedAnswer(): boolean {
  try { return window.localStorage.getItem(KEY) === "1"; } catch { return false; }
}

export function PhotoPrompt({ myUserId, members }: { myUserId: string; members: MemberDot[] }) {
  const [answered, setAnswered] = useState(rememberedAnswer);
  const me = members.find((member) => member.id === myUserId);
  if (answered || me === undefined || me.profilePhotoKey) return null;
  const dismiss = () => {
    try { window.localStorage.setItem(KEY, "1"); } catch { /* private mode: it asks again next visit, harmlessly */ }
    setAnswered(true);
  };
  return (
    <div className="card stack stack--tight" role="region" aria-label="Add a profile photo">
      <p>Add a photo so your crew knows it&apos;s you.</p>
      <Link className="button button--secondary" href="/settings" onClick={dismiss}>Add a photo</Link>
      <button type="button" className="button button--text" onClick={dismiss}>Not now</button>
    </div>
  );
}
