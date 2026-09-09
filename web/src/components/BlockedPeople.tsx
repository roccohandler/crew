"use client";
// SPEC: E9 · A7 — Blocked people: the list (GET blocks), Unblock with a two-choice confirmation ("Unblock {name}?" —
// Unblock / Keep blocked), "No one blocked." when empty. Blocking itself happens on a post's menu, never here; both
// directions stay silent toward the other person. Web twin of ios BlockedPeopleScreen.
import { useEffect, useState } from "react";
import { listBlocks, unblock, type BlockedPerson } from "@/lib/api-client-crew";

function Row({ person, confirming, onConfirm, onRelease, onKeep }: { person: BlockedPerson; confirming: boolean; onConfirm: () => void; onRelease: () => void; onKeep: () => void }) {
  return (
    <div className="row row--between">
      <span>{confirming ? `Unblock ${person.displayName}?` : person.displayName}</span>
      {confirming
        ? <span className="row"><button type="button" className="button button--text" onClick={onRelease}>Unblock</button><button type="button" className="button button--text" onClick={onKeep}>Keep blocked</button></span>
        : <button type="button" className="button button--text" onClick={onConfirm}>Unblock</button>}
    </div>
  );
}

export function BlockedPeople() {
  const [people, setPeople] = useState<BlockedPerson[] | null>(null);
  const [confirming, setConfirming] = useState<string | null>(null);
  const reload = () => listBlocks().then((reply) => setPeople(reply.blocked)).catch(() => setPeople([]));
  useEffect(() => { void reload(); }, []);
  const release = async (userId: string) => {
    await unblock(userId).catch(() => undefined);
    setConfirming(null);
    await reload();
  };
  return (
    <section className="card stack stack--tight" aria-label="Blocked people">
      <h2>Blocked people</h2>
      {people === null ? <div className="skeleton" /> : null}
      {people !== null && people.length === 0 ? <p className="muted">No one blocked.</p> : null}
      {people?.map((person) => <Row key={person.userId} person={person} confirming={confirming === person.userId} onConfirm={() => setConfirming(person.userId)} onRelease={() => void release(person.userId)} onKeep={() => setConfirming(null)} />)}
    </section>
  );
}
