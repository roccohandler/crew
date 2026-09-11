// SPEC: A14 · A17.1 · A18.1 · A18.2 · A18.3 · A18.6b — Home's header group (the flame, the ring, the week strip,
// the shield line and the two captions that name the numbers) and the what's-next block below it.
//
// Split from page.tsx the way ios Features/Home/HomeHeader.swift is split from HomeScreen.swift, and for the same
// reason: this is one composed group with its own gating rules, and the page was carrying all of them inline.
import { StreakFlame } from "@/components/StreakFlame";
import { WeeklyRing } from "@/components/WeeklyRing";
import { WeekStrip } from "@/components/WeekStrip";
import type { HomeFacts } from "@/lib/today-state";

// SPEC: A14 — one group: the flame, the ring and the week strip belong together, separated from what follows by the section
// gap rather than by the same 16 px that separated everything from everything (F09).
//
// A18.1 — EVERY NUMERAL IS NAMED WHERE IT SITS. A17.1 diagnosed this exactly ("a sighted user gets a glyph, two bare
// numerals and seven dots") and then gave copy to the strip and the crew avatar only. The two bare numerals were the
// flame and the ring, and on the screen the owner photographed they both read "1" while counting different things.
// secondaryText ink, never tappable, bridge-gated — A17.1's three limits, carried verbatim. The captions live here
// rather than inside the components because the Progress page renders the same ring under its own week caption.
// Twin of ios Features/Home/HomeHeader.
export function WeekHeader({ facts, streak, shields, isBridge }: { facts: HomeFacts; streak: number; shields: number; isBridge: boolean }) {
  const isPaused = facts.today.kind === "paused";
  // A18.1 — A8 branch: no caption at a streak of zero, so the word "streak" never appears beside a 0 as a verdict.
  const streakCaption = isPaused ? "streak paused" : streak > 0 ? "day streak" : null;
  // A18.2 / A18.6b — the ring is the reward layer (law ④), so it renders only when there IS a reward: at least one
  // completed planned workout this week, never on the bridge, and never while the plan is frozen. It was gated on
  // `ringPlanned > 0 && !isBridge`, which printed "0/3" on every non-bridge Monday — the same zero-as-verdict (A8)
  // that got it removed from the bridge, one day in seven, on six states nobody checked.
  const showsRing = facts.ringPlanned > 0 && facts.ringDone > 0 && !isBridge && !isPaused;
  return (
    <div className="stack stack--tight">
      <div className="row row--between">
        <div className="stack stack--tight">
          <StreakFlame streak={streak} paused={isPaused} />
          {!isBridge && streakCaption !== null ? <p className="whisper">{streakCaption}</p> : null}
        </div>
        {showsRing ? (
          <div className="stack stack--tight center">
            <WeeklyRing done={facts.ringDone} planned={facts.ringPlanned} />
            <p className="whisper">workouts this week</p>
          </div>
        ) : null}
      </div>
      {!isBridge ? <WeekStrip marks={facts.weekMarks} /> : null}
      {/* A17.1 / H020 — the shield, computed since day one and rendered nowhere. Reassurance, never a countdown
          (spec:452); shown only above zero, so a shieldless user is never told they have none (A8). */}
      {!isBridge && shields > 0 ? (
        <p className="muted">{shields === 1 ? "1 shield ready — one missed day won't break the streak." : `${shields} shields ready — a missed day won't break the streak.`}</p>
      ) : null}
    </div>
  );
}

// SPEC: A18.3 — the what's-next fact as a titled block, in the space that used to be empty. A17.2 named the right
// cause of that void ("too few content elements to justify the whitespace") and then filled it with two facts that do
// not render for an ordinary user. This one Home already computes and renders as the card's quietest caption. Idle
// states only: on a workout day the card IS what is next. Never a control (law ①), never orange (law ③).
// Twin of ios NextUpBlock.
export function NextUpBlock({ facts }: { facts: HomeFacts }) {
  if (facts.nextUp === null || facts.today.kind === "bridge") return null;
  return (
    <div className="stack stack--tight" aria-label={`${facts.nextUp.heading}, ${facts.nextUp.detail}`} role="group">
      <p className="nextup__heading" aria-hidden="true">{facts.nextUp.heading}</p>
      <p className="nextup__detail" aria-hidden="true">{facts.nextUp.detail}</p>
    </div>
  );
}
