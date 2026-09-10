// SPEC: A14 (owner-directed 2026-09-09) — Workout · Cardio · Meals, three co-equal slots. The owner named these as the three
// primary logging vectors; F10 measured how far Home was from treating them that way (one filled primary, one outline button
// whose position MOVED between states, one nav-bar glyph that vanished on the bridge), so logging a 45-minute walk changed
// Home not at all.
//
// Why this is legal under "one primary action per view" (6.1 · §1B · S07 · §1D): every slot is an OUTLINE control and the
// day's workout keeps the single filled primary inside the card above. Position makes them peers; weight still says which
// one the plan is asking for today.
//
// Part III law ① — no slot ever wears ember, even when done: a filled INK dot marks a logged vector, and law ④ keeps ember
// scarce for the flame, the ring and the strip. A8 — a slot with nothing to report reads "—", never "0" and never "0/3".
// Keyboard-complete: every slot is a link. Mirrors ios Features/Home/VectorRow.
import Link from "next/link";
import type { VectorSlots } from "@/lib/today-state";

function Slot({ title, value, isLogged, href }: { title: string; value: string; isLogged: boolean; href: string }) {
  return (
    <Link className="vectorslot" href={href} aria-label={`${title}, ${isLogged ? `${value} today` : "nothing logged today"}`}>
      <span className="vectorslot__title" aria-hidden="true">{title}</span>
      <span className="vectorslot__value" aria-hidden="true">
        {/* the dot is the redundant encoder: the shape says logged-or-not without asking anyone to read the number (6.5) */}
        <span className={isLogged ? "vectorslot__dot vectorslot__dot--logged" : "vectorslot__dot"} />
        {value}
      </span>
    </Link>
  );
}

export function VectorRow({ slots, workoutHref }: { slots: VectorSlots; workoutHref: string }) {
  return (
    <div className="vectorrow">
      {/* A17 / H028 — an unlogged slot says "Log", not "—". The em dash is spec-blessed on an INPUT surface (spec:203)
          but was never ratified on a STATUS surface, and beside a near-invisible hollow ring it read as the universal
          idiom for DISABLED — exactly what the owner reported. A verb turns three dead cells into three invitations. */}
      <Slot title="Workout" value={slots.workoutDone ? "Done" : "Log"} isLogged={slots.workoutDone} href={workoutHref} />
      <Slot title="Cardio" value={slots.cardioMinutes === null ? "Log" : `${slots.cardioMinutes} min`} isLogged={slots.cardioMinutes !== null} href="/log-cardio" />
      <Slot title="Meals" value={slots.meals > 0 ? `${slots.meals}` : "Log"} isLogged={slots.meals > 0} href="/post" />
    </div>
  );
}
