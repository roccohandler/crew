"use client";
// SPEC: E9 · A5 — report any post, block any user, one tap from the card: a "…" menu on others' posts with Report post /
// Block {name}; own posts carry no menu. The parent posts the report or block and shows the one-line confirmation.
// Web twin of the iOS long-press dialog.
import { useState } from "react";

export function PostMenu({ authorName, onReport, onBlock }: { authorName: string; onReport: () => Promise<void>; onBlock: () => Promise<void> }) {
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const run = async (action: () => Promise<void>) => {
    setBusy(true);
    await action().catch(() => undefined);
    setBusy(false);
    setOpen(false);
  };
  return (
    <span className="row">
      <button type="button" className="button button--text" aria-label="More" aria-expanded={open} onClick={() => setOpen(!open)}>…</button>
      {open ? (
        <span className="row" role="group" aria-label="Post actions">
          <button type="button" className="button button--text" disabled={busy} onClick={() => run(onReport)}>Report post</button>
          <button type="button" className="button button--text danger" disabled={busy} onClick={() => run(onBlock)}>Block {authorName}</button>
        </span>
      ) : null}
    </span>
  );
}
