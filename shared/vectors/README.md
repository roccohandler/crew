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

- `postCreated { kind: workout|meal|text, dayKey|at+tz, isPlannedDay, workoutCompleted?, plannedWeekdays?, trainingDays? }`
  - Not paused: the FIRST post of the day pays `+xpFirstPostOfDay`, whatever its kind. The day COUNTS
    (`streak + 1`, or `1` when starting; `lastCountedDayKey = dayKey`) only when the post is a completed
    workout on a planned day — or, under an all-rest plan (`plannedWeekdays: []`), any completed workout
    (A22 G1 (a), 2026-09-18: rest days are exempt; a rest day neither requires nor breaks). A fixture
    without `plannedWeekdays` (pre-A22) counts a planned completed workout and nothing else. Then the
    kind's XP: workout with `workoutCompleted` on a planned day → `+xpPlannedWorkout` for the first
    completed workout of the day, `+xpBonusWorkout` for every further one and for any completed workout
    on a rest day (the streak unchanged, V70); meal → `+xpMealPost` for the first `mealXpDailyCap` meals
    of the day, then 0; text → 0 (meal and text are fixture-only kinds since A22 — no client creates them).
  - Comeback (R-069): when the post COUNTS the day and the number of non-paused PLANNED days (weekday in
    `plannedWeekdays`; every day when the field is absent) strictly between `lastCountedDayKey` and this
    dayKey is ≥ `comebackMissedDaysThreshold`, it also awards `comeback` and `+xpComeback`. Never on the
    first-ever counted day. Once per return. An all-rest plan misses nothing and never earns one.
  - Perfect week (Decision Registry G6 as amended by A22 G1 (a)): after each post, if EVERY weekday in
    `plannedWeekdays` of the Mon–Sun week of this dayKey carries a completed workout (≥1 planned day),
    award `perfectWeek`, `+xpPerfectWeek`, and `shieldEarned` if `shields < maxShields`. Fires once per
    week, on the event that completes it. An event without `plannedWeekdays` completes no week.
  - Training-days history (A27 (a), owner-ruled 2026-09-18): an event may carry `trainingDays`, the plan's history —
    entries `{ from, weekdays }`, each in effect from its dayKey, append-only, `from` never going backwards — and when it
    does it supersedes `plannedWeekdays`. A day is judged by the entry in effect ON it (the last entry whose `from` ≤ that
    day; a day before every entry takes the first — R-082); a day the post has not reached yet is judged by the entry in
    effect on the post's own day (a later change had not been made). So "all-rest" reads the post's day, the comeback
    counts each day between by its own entry, and the perfect week asks whether every day of the week planned AT THE TIME
    carries a completed workout. The post's `isPlannedDay` is a fact stamped at creation and is never re-judged (V89).
  - Paused day: nothing happens — no XP, no counting, no awards (V20).
  - Level (G2): `level = max N ≥ 1 with totalXP ≥ levelBaseXp × (N−1) × N / 2`; when an event
    raises the level, one `levelUp(newLevel)` award is emitted last.
- `postUndone { dayKey }` — reverses the most recent post of that day. If that day is still the
  current (not yet rolled-over) day and the undone post was the one that counted it, the streak
  increment, `lastCountedDayKey` and `longestStreak` revert with the XP, atomically (V34). A post
  from an already rolled-over day is a deletion: no gamification change (E3, V43). Earned
  achievements are never removed (V35).
- `dayRolledOver { dayKey, hadRequirement }` — 3 AM passed for `dayKey`. `hadRequirement` is the
  caller's word that `dayKey` was a planned training day of a started, unpaused account (A22 G1 (a): a
  rest day is never required, so it rolls over with `false` — V66). No-op when `hadRequirement` is
  false or when the day was counted.
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

## Retired vectors — the marker

A vector is never edited or deleted (CLAUDE.md rule 7). When a ruling repeals the behaviour it asserts,
the vector RETIRES: it gains `"retired": { "by", "reason", "replacedBy": [ids] }` right after its `id`,
its expectations stay as written, both runners skip it (the web runner as `it.skip`, the Swift runners by
`continue`; their count assertions exclude it), and `check-vectors` still shape-checks it and verifies
that every `replacedBy` id exists and is not itself retired. Precedent: the twenty-three vectors A22
G1 (a) retired on 2026-09-18 (V01, V03, V04, V09–V15, V17, V18, V18b, V20, V21, V24, V26, V28–V30, V35,
V36, V43), replaced by V66–V84 in `streak-rest-days.vectors.json`.

## kind: `recompute` — server truth from facts

`variants[]` each give `sessions[]` (`{ id, dayKey, completed, sets }`), `posts[]` (`{ dayKey, kind,
isPlannedDay, sessionId? }` — `isPlannedDay` is stamped on the post at creation, like `dayKey`) and
`reactions[]` (`{ dayKey }`); with the vector's `pauses`, `tz` and `asOfDayKey`, `recompute(...)` must
return `expect.state` for EVERY variant (V36: set edits never change the state). Recompute folds the
facts chronologically through the same rules as `apply` (a workout post's `workoutCompleted` is its
session's `completed`), judging every day up to `asOfDayKey`. The vector's `trainingWeekdays` (ISO 1–7; `[]`
when absent) is the plan: every synthesized post carries it as `plannedWeekdays`, and a day before
`asOfDayKey` is required only when its weekday is in it (V77, V78; A22 G1 (a)).

A27 (a) (2026-09-18): a vector may instead give `trainingDays`, the plan's history (never both). Every synthesized post
carries it (see "Training-days history" above) and a day before `asOfDayKey` is required only when the entry in effect ON
that day plans it (V85–V90). The runners read a `trainingWeekdays` vector as a history of one entry — the same answer, since a
day before the first entry is judged by it. With `cycle` and `expect.nextWorkoutKind` the vector also pins the rotation pointer
(A1): sessions carry `workoutKind`, completed ones in the order of their dayKeys, and
`nextWorkoutKind(lastRotationKind(sessions, cycle), cycle)` must equal it on both engines (V89).

## kind: `nutrition` — the nutrition twins (V57–V65; nutrition addendum §3, §4, §6, §7)

`cases[]`, each with an `op` and an `expect`:
- `derive { bodyweightTenths, unit: lb|kg }` → `deriveTargets`: `{ energyKcal, proteinG, carbsG, fatG, carbsOverageKcal }`. A
  bodyweight is TENTHS of its unit; kilograms are carried as hundredths (the exact international pound, half-up); energy =
  kg × `kcalPerKgMaintenance` rounded to `energyKcalRoundTo`; protein = kg × 1.8; fat = max(`fatFloorPercentOfEnergy` of the
  energy ÷ 9, 0.5 g/kg); carbs = the rest ÷ 4; grams round half-up to `macroGramsRoundTo`. Integers only, on both engines.
- `carbs { energyKcal, proteinG, fatG }` → `{ carbsG, carbsOverageKcal }`: floored at 0, the overage stated (V60).
- `remaining { targets, logs }` → `{ protein, carbs, fat, calories }`, each `{ logged, target, toGo, over }`; the calorie line
  is the macros in Atwater kilocalories on both sides (V61).
- `logging { logs, entries }` → the logs after each entry is logged in order, idempotent on `clientId` (V62).
- `gameEvents { logs }` → `{ eventCount: 0 }` — a macro entry is never a game event (V63, clause ③; the checker refuses any other count).
- `bodyweightOf { targets | null }` → `{ bodyweightTenths, unit } | null` — the bodyweight lives inside the targets (V64).
- `availability { birthYear | null, currentYear }` → `available | askBirthYear | absent` (V65; `nutritionAdultAgeYears`).

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
