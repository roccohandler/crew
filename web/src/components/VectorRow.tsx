// SPEC: A14 (owner-directed 2026-09-09) — Workout · Cardio · Meals, three co-equal logging vectors. The owner named
// these as the three primary vectors; F10 measured how far Home was from treating them that way, so logging a
// 45-minute walk changed Home not at all.
//
// A18.5 (owner-directed 2026-09-10) — THE GEOMETRY AND THE GRAMMAR MOVE; A14's content does not. The owner's report
// was "three strange divs at the bottom with workout, cardio, and meals", and there were three reasons for it: three
// equal-width bordered cells in a row is Apple's own definition of a SEGMENTED CONTROL (a one-of-three picker) rather
// than three independent buttons; the grammar was a stat readout, a caption NOUN over a value carrying the verb, while
// 6.6 requires verb-first control labels; and the border measured 1.26:1 against 6.5's 3:1 gate, so the one mark that
// says "this is a control" could not be seen (A18.11 gives it its own `controlOutline` token).
//
// Full-width rows: ink verb leading, today's status trailing when there is one. A8 — an unlogged row REPORTS NOTHING
// rather than reporting a zero or an em dash (H028 established that "—" reads as disabled); the verb is the invitation.
// Part III law ① — no row ever wears ember: a filled INK dot marks a logged vector, and law ④ keeps ember scarce for
// the flame, the ring and the strip. Keyboard-complete: every row is a link.
// Mirrors ios Features/Home/VectorRow.
import Link from "next/link";
import type { VectorSlots } from "@/lib/home-facts";

function LogRow({ verb, status, href }: { verb: string; status: string | null; href: string }) {
  return (
    <Link className="logrow" href={href} aria-label={`${verb}, ${status === null ? "nothing logged today" : `${status} today`}`}>
      <span className="logrow__verb" aria-hidden="true">{verb}</span>
      {status === null ? null : (
        <span className="logrow__status" aria-hidden="true">
          {/* the dot is the redundant encoder (6.5 / WCAG 1.4.1): the shape says logged without anyone reading the number */}
          <span className="logrow__dot" />
          {status}
        </span>
      )}
    </Link>
  );
}

export function VectorRow({ slots, workoutHref }: { slots: VectorSlots; workoutHref: string }) {
  return (
    <div className="logrows">
      <LogRow verb="Log workout" status={slots.workoutDone ? "Done" : null} href={workoutHref} />
      <LogRow verb="Log cardio" status={slots.cardioMinutes === null ? null : `${slots.cardioMinutes} min`} href="/log-cardio" />
      <LogRow verb="Log a meal" status={slots.meals > 0 ? `${slots.meals}` : null} href="/post" />
    </div>
  );
}
