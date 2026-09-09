# Crew — the smoke-test improvement plan (2026-09-08)

Owner-directed, from the first TestFlight smoke test (build 0.1.0 (2)). The owner's review, verbatim in spirit: Home on a
rest day has no point; the Plan editor crams small controls; Crew is bland and unclear for a new user; the Journal shows
raw data; Settings is close but thin; the only recommended workouts should be Push · Pull · Legs and they must balance
over the months for ANY number of training days; cardio must be tracked; stretching must be tracked; everything must tie
together. This document is the builder's contract for that work. Research briefs behind every decision live in the session
scratchpad (`briefs/r-*.md`, `briefs/u-*.md`); the decisions themselves are logged in Appendix A of the spec (2026-09-08
owner-directed amendments A1–A8) — vectors stay append-only, gamification numbers do not move, every number enters through
`shared/spec-constants.json`, and the Concrete Doctrine C1–C14 holds.

## 0. Decisions (Appendix A, 2026-09-08)

- **A1 Rotation.** A plan is `trainingWeekdays` (ISO 1–7, ≥1) plus an ORDERED list of workouts — Push day, Pull day, Leg day
  for every generated plan, at every frequency 1–7 (Full-Body A/B is no longer generated; the seed keeps the templates and
  legacy plans with those kinds keep working). Workouts rotate: the next workout is the one after the LAST COMPLETED
  rotation workout, and only a completed workout advances the pointer — never a missed day, a pause, or a plan edit.
  Balance is automatic: over any 3k completed workouts each kind occurs k times. The pointer is DERIVED from history
  (the latest completed session whose kind is in the plan's cycle), never stored.
- **A2 Cardio.** "No cardio workouts MVP" is lifted. Cardio is a third exercise type, duration-based like mobility
  (`holdSeconds` = seconds), with one optional number, `distanceMeters`. Nine seeded activities. Two homes: a block inside
  a planned workout (part of the +100, no extra XP) and a standalone log from Home (a session of kind `cardio`, unplanned →
  +25 per V30/V31; it sustains the streak like any post; it never advances the rotation). No pace, effort, calories, heart
  rate, goals, or targets — ever. Progress shows cardio minutes per week and mobility minutes per week as facts.
- **A3 Home.** Every non-bridge Home state carries: a what's-next line (`Tomorrow: Pull day · 5 exercises` /
  `Next workout: Wed · Pull day`), a way to post a meal, `Log cardio`, and (rest / all-done) `Bonus workout` (the next
  rotation workout, +25). A counted-but-undelivered post never lowers the local streak (E19 wins over 5.6.3 while
  undelivered post ops exist).
- **A4 Plan editor.** Two disclosure levels: the week map (7 rows, zero controls) → the workout editor (one workout,
  Cancel/Save, rows with one tap target) → the exercise sheet (44 pt steppers, Swap, Move up/down, Remove + Undo).
  Training days are editable without a rebuild. Forward-only, stated in copy.
- **A5 Crew.** Header pinned at the top; the solo tab explains the loop in three lines then one CTA; a crew of one shows an
  invite card, the pulse in words, and no composer until two members; report and block are one long-press away.
- **A6 Journal.** Grouped by day with readable labels (Today · Yesterday · Mon · Mon Sep 8), one summary line per post
  (`Push day · 12/12 sets · 44 min`, `Walk · 25 min · 2.1 km`, `Dinner · 4:31 PM`), an empty state, a `Sending ↻` chip
  for undelivered posts. Sets/week counts strength work sets; mobility and cardio are minutes.
- **A7 Settings.** Profile (name + photo, camera or library), per-row notification toggles backed by server fields,
  correct reminder and mute state, blocked people (list + unblock), privacy policy and terms, version, a real log out.
- **A8 Copy law for these screens.** Never a zero as a verdict (`0/5 today` → `No posts yet today`), never red for a miss,
  orange only on rewards, sentence case, verb-first CTAs.

Assumption stated to the owner: the evidence favours full-body at 1–2 days/week; the owner asked for PPL only, so PPL
rotates at every frequency and the days picker shows a neutral line (`Most people start at 3 days`).

## 1. Contracts (the shapes every implementer codes against)

### 1.1 Plan (server, engine, iOS)

```ts
// web/src/lib/documents.ts
interface WorkoutTemplateDoc { kind: "push"|"pull"|"legs"|"fullBodyA"|"fullBodyB"|"custom"; name: string; exercises: ExerciseTemplateDoc[] }
interface PlanDoc { _id; userId; trainingWeekdays: number[]; workouts: WorkoutTemplateDoc[]; updatedAt: Date }
// ExerciseTemplateDoc.type: "strength" | "mobility" | "cardio"; holdSeconds = seconds for mobility holds AND cardio blocks
```
- `putPlanSchema`: `trainingWeekdays` int 1..7, unique, min 1, max 7 · `workouts` min 1, max 7, `kind` unique across the list
  (order = rotation order, stored as given) · exercises 1..planMaxExercisesPerDay · `type` enum with `cardio`.
- `findPlan` normalises a LEGACY document (no `trainingWeekdays`): `trainingWeekdays = sorted unique workouts[].weekday`,
  workouts deduped by kind in first-seen order, `weekday` dropped. Written back on the next PUT only.
- `PlanResponse { trainingWeekdays, workouts, updatedAt }`; web `PlanReply` mirrors; iOS `PlanDTO { trainingWeekdays, workouts, updatedAt }`,
  `PutPlanRequestDTO { trainingWeekdays, workouts }`.
- Engine `PlanDraft { trainingWeekdays: number[]; workouts: PlanDraftWorkout[] }`, `PlanDraftWorkout { kind; name; exercises }`
  (no weekday). `generatePlan(days, exp, access, seed)` → trainingWeekdays = sorted unique days; workouts = `split.pplCycle`
  kinds in order (3 workouts, always). Property tests updated: every combination yields exactly the cycle's kinds once.
- iOS SwiftData: `LocalPlan.trainingWeekdays: [Int]` (new, default `[]`), `LocalWorkoutTemplate` loses `weekday`.
  The owner's phone reinstalls the beta; no migration plan is written (logged in debt.md).

### 1.2 Rotation (engine twin: `web/src/lib/engine/plan-rotation.ts` ⇄ `ios/Crew/Engine/PlanRotation.swift`)

```ts
// SPEC: A1 — pure; the cycle is the plan's workout kinds in stored order (PPL for generated plans)
nextWorkoutKind(lastCompletedKind: string | null, cycle: string[]): string        // cycle[(i+1) % n], or cycle[0]
workoutKindFromName(name: string): string | null                                  // "push…"→push, "pull…"→pull, "leg…"→legs, "full body a"→fullBodyA, "full body b"→fullBodyB, else null (legacy sessions)
lastRotationKind(sessions: { kind: string | null; name: string; completedAt: number | null; status: string }[], cycle): string | null
                                                                                  // latest COMPLETED session whose (kind ?? kindFromName) ∈ cycle
projectWeek({ weekKey, todayKey, trainingWeekdays, cycle, nextKind, completedKindByDay: Record<string,string> }): DayProjection[]
// 7 entries Mon..Sun: { dayKey, weekday, state: "done"|"planned"|"open"|"rest", kind: string|null }
//   done   = a completed rotation session that day (kind from completedKindByDay)
//   rest   = weekday ∉ trainingWeekdays
//   open   = past training day, nothing completed (no word, no red)
//   planned= today/future training day; kinds assigned sequentially from nextKind (advances per planned day)
nextTrainingDayKey(afterDayKey: string, trainingWeekdays: number[]): string | null // the next planned day strictly after
```
Swift names identical (`PlanRotation.nextWorkoutKind(lastCompletedKind:cycle:)` etc.). Both engines get unit tests:
4 days → 12 completions → 4/4/4; misses never advance; 1 day → P, then Pull three weeks later; 7 days → PPLPPLP / PLPPLPP;
a cardio session never advances; legacy names infer; a plan without the last kind (custom) cycles its own kinds.

### 1.3 Sessions

- `createSessionSchema.workoutSnapshot` gains `kind: z.enum([push,pull,legs,fullBodyA,fullBodyB,custom,cardio]).optional()`;
  `weekday` stays accepted (ignored). `SessionDoc.workoutKind: string | null`; responses include `workoutKind`.
- `sessionExerciseInputSchema.type` adds `cardio`; `setLogInputSchema.distanceMeters: int 0..cardioDistanceMaxMeters nullish`;
  `SetLogDoc.distanceMeters: number | null`. `sessions.ts` `toSetLog` copies it. Completion rule unchanged (≥1 done work set;
  a done cardio set is a work set — vector V51 pins it, kind `completion`, append-only).
- Standalone cardio session: `workoutSnapshot { name: <Activity name>, kind: "cardio", isPlannedDay: false, exercises: [ { type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: <target>, sets: [ { targetReps: 0, actualReps: 0, holdSeconds: <actual>, distanceMeters, isWarmup: false, done: true } ] } ] }`,
  created and completed in one client flow. `lastRotationKind` ignores it (kind ∉ cycle).
- `PostDoc.summary?: string` — set by the server at completion (`sessions.ts`): strength `"{workoutName} · {setsDone}/{setsPlanned} sets · {minutes} min"`;
  cardio `"{name} · {minutes} min"` + `" · {distance} {km|mi}"` when distance exists (poster's units, 1 decimal). Returned in
  `postResponse` and the crew stream; iOS `LocalPost.summary: String?` computed locally at completion (same format, `SessionSummaryLine.swift` ⇄ `session-summary-line.ts` twin) and hydrated from the server.
- iOS: `LocalSession.workoutKind: String?`, `LocalSetLog.distanceMeters: Int?`, DTOs mirror. `SessionActions.startSession(from:kind:isPlannedDay:)`;
  `SessionActions.logCardio(activity:minutes:distanceMeters:...)` creates + completes in one call and returns the CelebrationOutcome.
- `lastCompletedRotationKind` sources: server `sessions.find({userId,status:"completed"}).sort({completedAt:-1})` walk until a rotation kind; iOS `Store.completedSessions(for:)` sorted desc.

### 1.4 Seed + constants

- `shared/seed/exercises.json`: `enums.type` += `cardio`, `enums.pattern` += `cardio`, `enums.region.cardio = "cardio"`; nine rows
  `{ id: "walk"|"run"|"bike"|"swim"|"row"|"elliptical"|"stairs"|"hike"|"other-cardio", name: "Walk"|"Run"|"Bike"|"Swim"|"Row"|"Elliptical"|"Stairs"|"Hike"|"Other cardio", pattern: "cardio", swapGroup: "cardio", equipment: "bodyweight", level: "brandNew", type: "cardio", holdSeconds: 1200 for walk, 1800 for hike, 600 otherwise, cueLine ≥ 20 chars }`.
- `check-seeds.mjs`: cardio ⇒ holdSeconds int > 0 and pattern `cardio`; strength ⇒ pattern ∉ {mobility, cardio}; templates still strength-only; summary print by type.
- `render-seed.mjs`: `Pattern` += `"cardio"`, `Region` += `"cardio"`, `SeedExercise.type: "strength" | "mobility" | "cardio"`.
- `shared/spec-constants.json` new section `cardio` (every `spec` string cites "A2, owner-directed 2026-09-08"):
  `cardioMinutesMin 1`, `cardioMinutesMax 300`, `cardioMinutesStep 5`, `cardioDistanceMaxMeters 100000`, `metersPerKilometer 1000`, `metersPerMile 1609.344`;
  section `journal`: `dayLabelWeekdayWithinDays 6` (A6). Regenerate; never edit Generated/.
- `shared/vectors/completion.vectors.json`: append V51 "a duration-only session (one done cardio set, targetReps 0) is complete: setsDone 1, setsPlanned 1, setsAsPlanned 1" (spec A2; both runners already handle kind `completion`).
- `shared/seed/plan-templates.json` gapNotes[2] replaced by the A1 sentence; `split.fullBodyMaxTrainingDays` stays (unused by generation, still validated).

### 1.5 Users, notifications, blocks

- `UserDoc.notificationPrefs?: { workoutReminder: boolean; streakRisk: boolean; crewActivity: boolean }` — absent = all true.
  `updateMeSchema.notificationPrefs: z.object({...}).partial().optional()` (merged server-side). `PublicUser.notificationPrefs` always present (defaults filled).
- `notification-eligibility.ts`: `reminderDue` requires `prefs.workoutReminder`, `streakRiskDue` requires `prefs.streakRisk`, `crewActivityDue` requires `prefs.crewActivity && !muted`; facts gain the prefs. Tests extended.
- `GET /api/v1/blocks` → `{ blocked: [{ userId: string; displayName: string }] }` (standing registry entry `blocks:GET`); `DELETE` unchanged (unblock).
- `PATCH users/me { profilePhotoKey }` now verifies the key belongs to the caller with purpose `profile` (400 otherwise). Photos routes unchanged.
- Web client (`api-client.ts` / `api-client-crew.ts`, owned by the server agent): `PlanReply`, `putPlan({ trainingWeekdays, workouts })`, `SessionSummary` gains `workoutKind`, `SetView.distanceMeters`, `SessionExerciseView.type` union, `listBlocks()`, `unblock(userId)`, `MeUpdate.notificationPrefs`, `MeUpdate.profilePhotoKey`, `PostReply` unchanged, `StreamItem.post.summary`.
- iOS `Api`: `blockedUsers()`, `unblock(userId:)`; `UpdateMeRequestDTO.profilePhotoKey`, `.notificationPrefs`; `UserDTO.notificationPrefs`; `PostDTO.summary`; `StreamPostDTO.summary`.

### 1.6 Day labels (engine twin `day-label.ts` ⇄ `DayLabel.swift`)

`dayLabel(dayKey, todayKey)`: same → `Today`; yesterday → `Yesterday`; within `dayLabelWeekdayWithinDays` days back → weekday name (`Mon`);
same year → `Mon Sep 8`; else `Mon Sep 8, 2025`. `weekHeader(weekKey, todayWeekKey)`: `This week` · `Last week` · `Week of Sep 1`.
English names live in the engine file. Unit tests both engines.

## 2. Screens (what appears, exact copy)

### 2.1 Home (S07) — iOS `Features/Home`, web `(app)/home`
- Toolbar: a camera button (`Post a meal`, a11y label) on every non-bridge state → NutritionPostScreen / `/post`.
- Card by state (title / line / controls):
  - workout, not done: `PUSH DAY` caption · `5 exercises + mobility` (+ ` + cardio` when the workout has a cardio block) · `Start workout` primary · below the card `Quick complete` (existing) · `Log cardio` secondary.
  - rest, unposted: `Rest day — recovery is part of the plan.` · `One post keeps it lit.` · `Post a meal` primary · `Log cardio` · `Bonus workout` secondaries · what's-next line.
  - rest, posted: `Rest day — recovery is part of the plan.` · `Today counts.` · what's-next line · `Post another` · `Log cardio` · `Bonus workout` secondaries.
  - allDone: `Done for today.` · what's-next line · `Post a meal` · `Log cardio` · `Bonus workout` secondaries.
  - paused: unchanged copy; `until` rendered through `dayLabel` (never raw ISO).
  - bridge: unchanged (1D: nothing else competes) plus ONE ink line under the CTA: `Tomorrow: Push day — your first workout.` / `Next workout: Wed · Push day` (rest-day installs only).
- What's-next line: `Tomorrow: {name} · {n} exercises` when the next planned day is tomorrow, else `Next workout: {Wed} · {name}`; nothing when today is an undone training day. Names come from the rotation projection.
- `Bonus workout` → a sheet listing the plan's workouts, the next one first and labelled `Next up`; starting one creates a session with `isPlannedDay: false` (rest day) or `true` only when today is an undone training day (then it is simply the planned workout). Web: `/session/new?bonus=<kind>`.
- `Log cardio` → CardioLogScreen (iOS, `Features/Session/CardioLogScreen.swift`) / `/log-cardio` (web): activity grid (9 tiles, ≥44 pt, last-used first), minutes stepper (`cardioMinutesStep`, bounds from constants, pre-filled with the last log for that activity or the seed default), optional distance field with unit suffix from `User.units` (`Skip it if you don't know.`), CTA `Log {activity}`. On success the normal celebration (+25 or +25, streak) then Home.
- HomeModel/today-state derive today's workout from `projectWeek` (the training-day check plus `nextWorkoutKind`); `isPlannedDay` for meal posts = `trainingWeekdays.contains(weekday)`.
- iOS sync fixes (E19): `SyncQueue.reconcile` skips the gamification replace while any `createPost`/`patchSession` op is pending, in flight, or held; `ok:false, retryable:true` results schedule a retry (never delete); `ApiPhotos.uploadPhoto` maps `URLError` to `AppError.offline` like `Api.perform`; held ops younger than `failedUploadChoiceAfterHours` return to `pending` with attempts 0 on foreground and on network return (`SyncQueue.releaseHeldForRetry(now:)` from `SyncDriver`); on a delivered `createPost` the `LocalPost` gets `deliveredAt`, `serverId`, `photoKey`. `SyncQueueTests` cover each rule.

### 2.2 Plan (S14) — iOS `Features/Plan`, web `(app)/plan`
- `PlanScreen` = the week map: subtitle `Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.`;
  seven rows from `projectWeek` — `Mon · Push day` / `5 exercises + mobility` (chevron; done days show `✓ Push day`; open past days show `Mon · —` in secondary, no word); rest rows `Tue · Rest`; then a quiet line `Next week starts with {Pull day}` when the cycle does not divide the days; buttons `Change days` (sheet: the seven ≥56 pt toggles from onboarding, `Save days`) and `Rebuild my week`.
- Tap a workout row → `WorkoutEditorScreen(kind)` (push, full screen): title `{name}` · `Cancel` / `Save` (Save disabled until dirty) · header `{n} exercises + mobility · ~{minutes} min` (`~` minutes = strength sets × restTimerDefaultSeconds + hold seconds + cardio seconds, rounded to 5) · section `Exercises` with a trailing `Reorder`/`Done` (`EditButton` + `onMove`) · rows `{name}` / `{sets} × {reps} · {equipment}` (one tap target, chevron) · `Add exercise` (picker = existing SwapSheet list over all allowed strength exercises) · `Add cardio` (picker over the nine activities; inserts one cardio row after the strength rows) · footer `Mobility · {n} holds · ~{m} min · closes the workout` listing holds (read-only) · cardio row reads `{Activity} · {min} min` and opens the same sheet with a Minutes stepper instead of Sets/Reps.
- Exercise sheet (`ExerciseSheet.swift`, `.medium` detent): name + equipment chip + cue line · `Sets` `[−] 3 [+]` · `Reps` `[−] 10 [+]` (44 pt segments, bounds 1…planMaxSetsPerExercise / 1…planTargetRepsMax, long-press repeat via `Stepper`) · `Swap exercise` (SwapSheet, keeps targets) · `Move up` · `Move down` · `Remove from {name}` → row leaves, snackbar `Removed {name} · Undo` (one-step undo in the draft; as built the row stays until the next edit, Save or Cancel rather than timing out — debt.md, A4).
- Cancel with a dirty draft → `Discard changes to {name}?` — `Discard changes` / `Keep editing`. Save → `PlanLocal.replace` + `putPlan` (queue) → pop → toast `Saved · applies from your next {name}`.
- Web: `/plan` (week map, `WeekOverview.tsx`), `/plan/[kind]` (`WorkoutEditor.tsx` + `ExerciseSheet.tsx` as a `<dialog>`), `plan-draft.ts` (pure draft mutations shared by both web screens; ≤150 lines each). `Change days` inline toggles. Steppers = the existing `.stepper` 44 px buttons.
- Onboarding reveal (S04) both platforms: `Your week, built.` then the projection for THIS week (`Mon · Push day` …) and the line `Every workout rotates in, so each gets equal time.`; swap keeps working by kind. The days question adds the neutral whisper `Most people start at 3 days.`

### 2.3 Crew (S12/S13) — iOS `Features/Crew`, web `CrewView`
- Layout: `MemberStrip` (name, pulse, strip) pinned ABOVE the scroll view; the stream keeps the bottom anchor.
- Solo: `EmptyState`-style screen: title `Start a crew` · three ink lines with SF symbols `Post a workout or a meal photo.` / `It lands here for your crew.` / `They react 🔥💪👏😂❤️ and chat.` · line `Two to ten friends. A link, a name, an emoji.` · CTA `Start a crew`.
- Crew of one (members < 2): under the strip an ink card `Only your crew sees this.` / `Send the link and your first post lands here for them.` · `Invite friends` primary (share sheet) · `Copy link` text button (captain); non-captain members read `Ask your Captain for the link.`; the composer is hidden until members ≥ 2; `Quiet in here…` stays for crews ≥ 2 with an empty stream.
- After `Start a crew` succeeds the invite sheet opens automatically (Flow 6).
- Pulse: `{n}/{m} today` when n ≥ 1; `No posts yet today` when n = 0 (secondary ink).
- Post card: a summary line under the author (`item.post.summary`) when present; long-press / `React` dialog gains `Report post` and `Block {name}` (own posts excluded) → `Api.report` / `Api.block`, then a one-line confirmation `Reported. A human will look.` / `Blocked. You won't see each other.` (web: a `…` menu on the card).

### 2.4 Journal + Progress (S15/S16)
- Journal: sections per dayKey, header `{dayLabel}` (+ `Rest day` when not a training day and no workout); rows: workout `{summary}` (fallback computed from the local session), cardio `{summary}`, meal `{Breakfast|Lunch|Dinner|Snack} · {time}` (+ ` · earlier today`), caption, photo; `Sending ↻` chip while undelivered; swipe delete keeps its two-tap confirm on web; empty state `Your first post lands here.` / `Workouts and meals stack up day by day.` / `Post something` (works on iOS: presents NutritionPostScreen).
- Progress: `RingRecord/WeekRecord` gain `cardioMinutes`, `mobilityMinutes`; `sets` = strength done non-warm-up sets; Layer 2 shows `Sets per week` (unchanged), `Push N · Pull N · Legs N` (+ ` · Full body N` on iOS too), and `Cardio {n} min · Mobility {m} min this week` (omitted when both are 0); ring captions use `weekHeader`; heat-map day-tap card uses `dayLabel`; `plannedWeekdays = trainingWeekdays`. The empty-state CTA on iOS presents the post sheet. `.failed` is assigned on a Store error.

### 2.5 Settings (S17)
- Profile row → `EditProfileScreen`: avatar (tap → `Take photo` / `Choose photo` / `Remove photo`; camera-denied line + `Open Settings`), `Name` field (≤ displayNameMaxChars), `Save`. Upload with purpose `profile` → PATCH `profilePhotoKey` (+ `displayName`); `AvatarView` renders the photo when a key exists (Settings, member strips).
- Plan: `Pause my plan` (detail `Off` / `Until {dayLabel}`), `Units`.
- Notifications: `Workout reminder` toggle + `Time` (initialised from the stored `reminderTime`; the suggestion 7:30 only pre-fills the picker when nothing is stored and is never saved by `onAppear`), `Streak reminder` toggle, `Crew activity` toggle, `Mute {crew}` (initial state from `Api.me().crew.muted`). Footer: `We only email you for password resets and account deletion.`
- Privacy & safety: `Blocked people` (list, `Unblock` with `Unblock {name}?` — `Unblock` / `Keep blocked`; empty `No one blocked.`), `Privacy policy`, `Terms` (open `{APP_BASE_URL}/privacy` and `/terms` in an in-app browser; web pages are static placeholders the owner replaces before submission).
- Account: `Export my data (JSON)` (re-exportable), `Log out` (calls `Api.logout(refreshToken:)` then clears local state INCLUDING `OpRecord` and `LocalPause`), `Delete account` (two-step, unchanged copy). About row: `Version {short} ({build})`.
- Web `SettingsView`: same rows; photo via `<input type=file>` → `uploadPhoto(file, "profile")`; blocked list; legal links; version from `NEXT_PUBLIC_APP_VERSION ?? "beta"`.

### 2.6 Session (S09/S10)
- `CardioRow` (iOS `Features/Session/CardioRow.swift`, web `components/CardioRow.tsx`): `{Activity}` · target `{min} min` · minutes stepper (±cardioMinutesStep, pre-filled with the target) · optional distance field (`km`/`mi`) · `Done` → set done (`holdSeconds = minutes × 60`, `distanceMeters`), haptic tick. Skippable like any exercise. The session summary line (`setsDone/setsPlanned sets · min`) is unchanged; `+ {Activity} {min} min` is appended when a cardio set is done.
- Celebration copy: `Counted.` appears above the share choice (S10).

## 3. Ownership map (implementation agents; every file listed once)

- **C1 shared+engine**: shared/spec-constants.json · shared/seed/exercises.json · shared/seed/plan-templates.json · shared/scripts/check-seeds.mjs · shared/scripts/render-seed.mjs · shared/vectors/completion.vectors.json · Generated/* (via generate) · web/src/lib/engine/{plan-generator,plan-rotation,day-label,session-summary-line}.ts · web/tests/engine/{plan-generator,plan-rotation,day-label,session-summary-line}.test.ts · ios/Crew/Engine/{PlanGenerator,PlanRotation,DayLabel,SessionSummaryLine,SeedCatalog}.swift · ios/CrewTests/{PlanGeneratorTests,PlanRotationTests,DayLabelTests,SessionSummaryLineTests}.swift · ios/Package.swift.
- **C2 server+web client**: web/src/lib/{documents,documents-social,validate,validate-plans,validate-sessions,plans,sessions,posts,users,today-state,notification-facts,notification-eligibility,progress-facts,blocks,crew-stream,export,api-client,api-client-crew}.ts · web/src/app/api/v1/{plans,sessions,sessions/[id],users/me,blocks,posts,crews/[id]/stream}/route.ts · web/src/app/api/cron/notifications/route.ts · docs/api.md · web/tests/api/* · web/tests/api/standing-registry.ts · web/tests/e2e/helpers.ts.
- **I1 iOS storage/api/sync**: ios/Crew/Storage/{Models,ModelsSocial,Store,PlanLocal,ServerHydrate,SyncQueue,SyncDriver,SyncTransport}.swift · ios/Crew/Api/{Api,ApiModels,ApiPlans,ApiSessions,ApiPhotos,ApiCrews,AuthStore}.swift · ios/Crew/Features/Session/{SessionActions,SessionSwap}.swift · ios/CrewTests/{SyncQueueTests,ServerHydrateTests}.swift · ios/CrewUITests/SeedClient.swift.
- **I2 iOS Home+Post**: ios/Crew/Features/Home/* · ios/Crew/Features/Post/PostModel.swift · new ios/Crew/Features/Home/{BonusWorkoutSheet,NextUpLine}.swift · ios/Crew/Features/Session/{CardioLogScreen,CardioLogModel}.swift · ios/CrewTests/{HomeModelTests,HomeModelEdgeTests}.swift.
- **I3 iOS Plan+Onboarding**: ios/Crew/Features/Plan/* (PlanScreen, PlanModel, WorkoutEditorScreen, ExerciseSheet, WeekRow, DaysSheet; PlanDayCard deleted) · ios/Crew/Features/Onboarding/{OnboardingModel,GeneratedPlanScreen,PlanQuestionsScreen,OnboardingFlow}.swift · ios/CrewTests/OnboardingModelTests.swift.
- **I4 iOS Session+Progress**: ios/Crew/Features/Session/{SessionScreen,SessionModel,CardioRow,CelebrationScreen,SetRow,MobilityHoldRow}.swift · ios/Crew/Features/Progress/* · ios/CrewTests/SessionModelTests.swift.
- **I5 iOS Crew+Settings**: ios/Crew/Features/Crew/* · ios/Crew/Features/Settings/* (+ EditProfileScreen, BlockedPeopleScreen) · ios/Crew/Api/ApiSettings.swift · ios/Crew/Shared/AvatarView.swift · ios/Crew/CrewApp.swift · ios/Crew/RootView.swift.
- **W1 web Home+Session+Post**: web/src/app/(app)/{home,session,post,log-cardio}/** · web/src/components/{QuickCompleteButton,SessionLogger,SetRow,HoldRow,CardioRow,CardioLogForm,PostComposer,StreakFlame,WeeklyRing,SessionSwap}.tsx.
- **W2 web Plan+Onboarding**: web/src/app/(app)/plan/** · web/src/components/{PlanEditor→WeekOverview,WorkoutEditor,ExerciseSheet}.tsx · web/src/lib/plan-draft.ts · web/src/components/onboarding/* · web/src/app/onboarding/** · web/tests/e2e/{journey1,journey4-web-parity}.spec.ts.
- **W3 web Crew+Journal+Progress+Settings**: web/src/components/{CrewView,CrewHeader,CrewInvitePanel,StreamList,SettingsView,HeatMap,EmptyState,DeletePostButton}.tsx · web/src/app/(app)/{crew,journal,progress,settings}/** · web/src/app/{privacy,terms}/page.tsx · web/src/app/app.css · web/tests/e2e/{journey2,journey3-invite,a11y}.spec.ts · web/tests/e2e/warm-up.ts.

## 4. Verification (run from the repo root, Git Bash)

```
node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs && node shared/scripts/check-vectors.mjs && node shared/scripts/check-seeds.mjs && node shared/scripts/doctrine-lint.mjs
cd web && npm run typecheck && npm run lint && npm test && npm run vectors && npm run build && npm run e2e
docker run --rm -v "C:\Users\princ\CREW_2.0:/repo" -w /repo/ios swift:5.10 swift test
```
The iOS app compiles only on the GitHub macOS job (`ios`): the owner pushes, the agent reads `gh run view`. Every Swift file
is WRITTEN-UNVERIFIED until then.

## 5. Deferred (parking lot, logged in debt.md)
Cardio timer inside the row · Apple Health import · mobility-only standalone sessions · a "Wind down" rename · digest push ·
report acknowledgement email · web open-source licences page · SwiftData migration plan for the plan schema.
