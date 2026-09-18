"use client";
// SPEC: nutrition addendum §4 ("Add from a chain": chain list → item list) · §5 · clause ① — the curated seed, as published by the
// chains themselves: a chain's NAME as plain text (no logo, no mark, no food photo), an item's name, serving label and grams. No
// rating, no rank, no search, no filter beyond chain → item (§8), and the order is the seed's alphabetical sort — a sort is not a
// ranking. Picking an item hands its numbers to the meal form, where they are copied and the user's to edit.
// R-075: the web prints the chain name alone — the seed's icon names are SF Symbols, which the phone draws.
// Twin: ios Features/Nutrition/ChainPickerSheet.swift.
import { useState } from "react";
import { gramsSpoken, gramsText } from "@/lib/engine/macro-day";
import { fastFood, type SeedFastFoodItem } from "@/generated/seed";

export function ChainPicker({ onPick, onCancel }: { onPick: (item: SeedFastFoodItem) => void; onCancel: () => void }) {
  const [chainId, setChainId] = useState<string | null>(null);
  const chain = fastFood.chains.find((candidate) => candidate.id === chainId) ?? null;
  if (chain === null) {
    return (
      <section className="card stack stack--tight" aria-label="Add from a chain">
        <h2>Add from a chain</h2>
        <div className="logrows">
          {fastFood.chains.map((candidate) => <button key={candidate.id} type="button" className="logrow" onClick={() => setChainId(candidate.id)}><span className="logrow__verb">{candidate.name}</span></button>)}
        </div>
        <p className="whisper">{"Numbers are the chains' own published nutrition facts."}</p>
        <button type="button" className="button button--text" onClick={onCancel}>Cancel</button>
      </section>
    );
  }
  return (
    <section className="card stack stack--tight" aria-label={chain.name}>
      <h2>{chain.name}</h2>
      <div className="logrows">
        {fastFood.items.filter((item) => item.chainId === chain.id).map((item) => (
          <button key={item.id} type="button" className="logrow logrow--tall" aria-label={`${item.name}, ${item.servingLabel}, ${gramsSpoken(item)}`} onClick={() => onPick(item)}>
            <span aria-hidden="true"><span className="logrow__verb">{item.name}</span><br /><span className="whisper">{item.servingLabel}</span></span>
            <span className="logrow__status" aria-hidden="true">{gramsText(item)}</span>
          </button>
        ))}
      </div>
      <a className="whisper" href={chain.sourceUrl} target="_blank" rel="noreferrer">{`Source: ${chain.name}, published nutrition facts`}</a>
      <button type="button" className="button button--text" onClick={() => setChainId(null)}>All chains</button>
    </section>
  );
}
