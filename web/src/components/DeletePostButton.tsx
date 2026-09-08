"use client";
// SPEC: E3 — delete yours anytime; post ≠ log: deleting a post never deletes sets, never retro-breaks a streak (the server
// recompute is the truth, V43). Two taps, no modal: the first arms it, the second deletes. Web twin of the journal swipe.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { deletePost } from "@/lib/api-client";

export function DeletePostButton({ id }: { id: string }) {
  const router = useRouter();
  const [armed, setArmed] = useState(false);
  const [busy, setBusy] = useState(false);
  const remove = async () => {
    setBusy(true);
    await deletePost(id).catch(() => undefined);
    router.refresh();
  };
  if (!armed) return <button type="button" className="button button--text" onClick={() => setArmed(true)}>Delete</button>;
  return (
    <span className="row">
      <button type="button" className="button button--text danger" disabled={busy} onClick={remove}>Delete for good</button>
      <button type="button" className="button button--text" onClick={() => setArmed(false)}>Keep</button>
    </span>
  );
}
