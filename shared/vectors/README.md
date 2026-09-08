# Gamification vectors — the fixture contract

SPEC: Part VIII 8.1 · CLAUDE.md rule 7 (append-only) · 5.6.1 engine signatures.
Both engines (`ios/Crew/Engine`, `web/src/lib/engine`) load every `*.vectors.json` here and must produce
EXACTLY these outputs. A red vector on either engine blocks every merge. Vectors are never edited —
a behavior change is a Decision Registry entry plus a NEW vector.

Check the fixtures: `node shared/scripts/check-vectors.mjs` (shape + arithmetic invariants).

## File shape

```
{ "file": "<name>", "spec": "<Part VIII group>", "vectors": [ <vector>, ... ] }
```

Every vector carries `id` (V01…), `title` (the 8.1 wording), `spec` (tags), `kind`, `rule` (the one
sentence the expectation encodes) and optionally `reviewNote` (an interpretation the owner confirmed
or must confirm at the 🛑 review).

## Dates, days, weeks

- `dayKey` = "YYYY-MM-DD". `dayKey(instant, tz)` is the local date D such that
  `startOfDay(D, tz) + 3h ≤ instant < startOfDay(D + 1, tz) + 3h`, with `+3h` counted in absolute
  seconds (`dayBoundaryHour`). On every ordinary day this equals "local date of (instant − 3 h)".
  On a DST spring-forward night the day keeps a full 24 h (the boundary lands at 04:00 wall clock),
  which is the "user's favor" resolution of E8/V08; on a fall-back night nothing special happens.
- `weekKey` = the dayKey of that week's Monday (`weekStartWeekday`).
- Events may name the day directly (`dayKey`) or as `at` (ISO-8601 with offset) + `tz` (IANA);
  the runner converts `at`+`tz` with the DayKey engine before applying. A post's dayKey is fixed
  at creation with the device timezone of that moment and never re-derived (E8, V10).
- Pause: `{ startDay, endDay }` covers `startDay ≤ d < endDay`; `endDay` is the return day (the first
  day that requires a post again). `endDay − startDay ≤ pauseMaxDays`.

## kind: `apply` — GamificationEngine.apply, folded over `events`

`initialState` is always an end-of-day snapshot: no activity has happened yet on any day the events
touch. Fields asserted by `expect.state`: `currentStreak`, `longestStreak`, `totalXP`, `level`,
`shields`, `lastCountedDayKey`, `earnedAchievementIds`. Engines may carry extra internal fields
(per-day counters, per-week facts, the last judged day); vectors never assert on those.

Events, applied in the listed (chronological) order:

- `postCreated { kind: workout|meal|text, dayKey|at+tz, isPlannedDay, workoutCompleted? }`
  - Not paused: the FIRST post of the day counts the day: `streak + 1` (or `1` when starting),
    `lastCountedDayKey = dayKey`, `+xpFirstPostOfDay`. Then the kind's XP: workout with
    `workoutCompleted` on a planned day → `+xpPlannedWorkout` for the first completed workout of
    the day, `+xpBonusWorkout` for every further one and for any completed workout on a rest day;
    meal → `+xpMealPost` for the first `mealXpDailyCap` meals of the day, then 0; text → 0.
  - Comeback: when the number of non-paused days strictly between `lastCountedDayKey` and this
    dayKey is ≥ `comebackMissedDaysThreshold`, the first post of the day also awards `comeback`
    and `+xpComeback`. Never on the first-ever post. Once per return.
  - Perfect week (Decision Registry G6): after each post, if the Mon–Sun week of this dayKey now
    has ≥1 post on EVERY day, a completed workout on EVERY planned day, and ≥1 planned day, award
    `perfectWeek`, `+xpPerfectWeek`, and `shieldEarned` if `shields < maxShields`. Fires once per week,
    on the event that completes it.
  - Paused day: nothing happens — no XP, no counting, no awards (V20).
  - Level (G2): `level = max N ≥ 1 with totalXP ≥ levelBaseXp × (N−1) × N / 2`; when an event
    raises the level, one `levelUp(newLevel)` award is emitted last.
- `postUndone { dayKey }` — reverses the most recent post of that day. If that day is still the
  current (not yet rolled-over) day and the undone post was the one that counted it, the streak
  increment, `lastCountedDayKey` and `longestStreak` revert with the XP, atomically (V34). A post
  from an already rolled-over day is a deletion: no gamification change (E3, V43). Earned
  achievements are never removed (V35).
- `dayRolledOver { dayKey, hadRequirement }` — 3 AM passed for `dayKey`. No-op when
  `hadRequirement` is false (paused, or before the first-ever post) or when the day was counted.
  Otherwise the day is missed: consume one shield (`shieldConsumed`, streak intact) or, with none,
  `currentStreak = 0` (`streakTo(0)`, emitted only if the streak was above 0). Fixtures list a
  rollover for EVERY missed day, in order; rollovers for counted days may be omitted.
- `reactionGiven { dayKey }` — `+xpReaction` for the first `reactionXpDailyCap` reactions of the
  day, then 0. Reactions are not posts: no counting, no first-post XP. Nothing during a pause.

`expect.awardsByEvent[i]` is the exact ordered award list for `events[i]`. Canonical order inside one
event: `xp` entries in reason order `firstPostOfDay, plannedWorkout, bonusWorkout, meal, reaction,
comeback, perfectWeek` → `streakTo` → `comeback` → `perfectWeek` → `shieldEarned` → `shieldConsumed`
→ `levelUp` → `achievement` → `prBadge`. Award objects: `{ "award": "xp", "amount", "reason" }`,
`{ "award": "streakTo", "value" }`, `{ "award": "levelUp", "value" }`, `{ "award": "achievement", "id" }`,
`{ "award": "prBadge", "exercise" }`, and bare `{ "award": "comeback" | "perfectWeek" | "shieldEarned" | "shieldConsumed" }`.

## kind: `dayKey` — DayKey engine

`cases[]`: `{ at, tz, dayKey, weekKey }` → `dayKey(for:tz:)` and `weekKey(for:)` must match.

## kind: `completion` — Session completion rules (Flow 3, V32–V33)

`cases[]`: `sets[]` of `{ targetReps, actualReps, done, isWarmup }` → `expect`
`{ complete, setsDone, setsPlanned, setsAsPlanned, sets: [{ done, asPlanned }] }`. Warm-up rows are
excluded from every count; `complete = setsDone ≥ 1`; `asPlanned = done && actualReps ≥ targetReps`.

## kind: `recompute` — server truth from facts

`variants[]` each give `sessions[]` (`{ id, dayKey, completed, sets }`), `posts[]` (`{ dayKey, kind,
isPlannedDay, sessionId? }` — `isPlannedDay` is stamped on the post at creation, like `dayKey`) and
`reactions[]` (`{ dayKey }`); with the vector's `pauses`, `tz` and `asOfDayKey`, `recompute(...)` must
return `expect.state` for EVERY variant (V36: set edits never change the state). Recompute folds the
facts chronologically through the same rules as `apply` (a workout post's `workoutCompleted` is its
session's `completed`), judging every day up to `asOfDayKey`.

## kind: `pauseValidation` — SettingsModel.pause(until) / POST /api/v1/pause

`cases[]`: `{ today, startDay, endDay, existingPauses }` → `{ accepted, reason? }` with reasons
`retroactive` (startDay < today), `tooLong` (endDay − startDay > pauseMaxDays), `alreadyPaused`
(an existing pause with endDay > today). Checked in that order.

## kind: `crewPulse`, `crewWeeklyRing`, `comebackBanner` — crew rules (V37–V40)

- Membership on a day: `joinedDayKey ≤ day` and (`leftDayKey` absent or `leftDayKey > day`).
- `crewPulse`: `{ dayKey, members, posts }` → `{ posted, total }` = distinct members-of-that-day
  with ≥1 post keyed to that day, over members of that day.
- `crewWeeklyRing`: `cases[]` `{ asOfDayKey, members, posts }` → `days[]` = one `{ dayKey, posted,
  total }` per day from that week's Monday through `asOfDayKey`, each computed like `crewPulse`
  with membership as of THAT day (a joiner never changes earlier days — V40; the ring restarts every
  Monday — V38).
- `comebackBanner`: `{ posts[], pauses }` for one member → per post `{ dayKey, comeback }` using the
  engine's comeback rule (≥ `comebackMissedDaysThreshold` non-paused quiet days since the previous
  post; never on the first post; once per return).

## kind: `achievements` — Achievements.earned (seed thresholds; earned once; never removed)

Appended 2026-09-04 (V45–V50) with the awarding pass. The definitions live in `shared/seed/achievements.json`
(`trigger` + `threshold`, in seed order). Counters are FACTS each platform derives (integers ≥ 0; a missing
counter is 0):

- `postsTotal` — the user's live (non-deleted) posts · `workoutsCompleted` — completed sessions ·
  `currentStreak` — the engine state's streak · `reactionsGiven` — reactions the user has given.
- `perfectWeeks`, `shieldsConsumed`, `comebacks` — the engine's tallies of `perfectWeek`, `shieldConsumed`
  and `comeback` awards emitted so far (engine memory, folded like everything else; an undo reverts them
  with the day). Never asserted by `apply` vectors.
- `prCount` — (completed session, exercise) pairs whose best done work-set weight beats every EARLIER
  completed session's best for that exercise, where an earlier logged weight exists (Flow 3 "new best";
  Flow 9 layer 3 — never logged weight → no PR).
- `crewJoined` — 1 while the user is in a crew, else 0.
- `crewFullPulseDays` — days from the user's own `joinedDayKey` through `asOfDayKey` on which the crew
  pulse was full (`posted == total`) with `total ≥ crewMinMembers`, membership as of each day (V40) ·
  `crewFullPulseWeeks` — complete Mon–Sun weeks (Monday ≥ the user's `joinedDayKey`, Sunday ≤ `asOfDayKey`) whose seven days were all full.

`cases[]`: `{ counters, alreadyEarned }` → `expect { awards, earnedAfter }`. `awards` = one
`{ "award": "achievement", "id" }` per seed achievement, IN SEED ORDER, whose counter ≥ threshold and whose
id is not in `alreadyEarned`; `earnedAfter` = `alreadyEarned` followed by the awarded ids. A counter that
falls later awards nothing and takes nothing (V35). The platforms run the pass after every recompute /
local apply and append the awards after `levelUp` (canonical order).
