// GENERATED FILE — DO NOT EDIT. Source: shared/spec-constants.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: C7 — every tunable in the spec, named for its rule.

export const SpecConstants = {
  // --- day ---
  /** SPEC: E8; Flow 7; V04–V06 — the day ends 3 AM local */
  dayBoundaryHour: 3,
  /** SPEC: E20; V38 — Monday week-start worldwide (ISO weekday 1) */
  weekStartWeekday: 1,
  /** SPEC: Flow 4 — same-day backfill only; yesterday is closed */
  backfillMaxDaysBack: 0,

  // --- streak ---
  /** SPEC: V01 — first-ever post starts streak at 1 */
  streakAfterFirstPost: 1,
  /** SPEC: V02, V03, V11 — one increment per counted day */
  streakIncrementPerCountedDay: 1,
  /** SPEC: Flow 7; V04 — no shield → streak → 0 */
  streakAfterUnshieldedMiss: 0,
  /** SPEC: Flow 6; V29; V39 — quiet for 3+ days → comeback */
  comebackMissedDaysThreshold: 3,
  /** SPEC: E4; S18 — 14+ quiet days → Welcome back screen */
  lapsedUserQuietDays: 14,

  // --- shields ---
  /** SPEC: Flow 7; V14; Part IX — hold max 2 */
  maxShields: 2,
  /** SPEC: Flow 7; V13 — earned per PERFECT week, never sold */
  shieldsEarnedPerPerfectWeek: 1,

  // --- pause ---
  /** SPEC: Flow 7; V23; S17; Part IX — max 3 weeks (endDay ≤ start+21) */
  pauseMaxDays: 21,
  /** SPEC: Flow 7; Part IX — one active pause at a time */
  maxActivePauses: 1,
  /** SPEC: GAP (agent, 2026-09-05): Flow 7 / S17 — the pre-filled return day is one week out (never above pauseMaxDays) */
  pauseDefaultDays: 7,

  // --- xp ---
  /** SPEC: Part IV table; V24 — first post of day = 25 */
  xpFirstPostOfDay: 25,
  /** SPEC: Part IV table; V25; E7 — planned workout = +100 */
  xpPlannedWorkout: 100,
  /** SPEC: Flow 4; Part IV table; V26 — +15 per meal */
  xpMealPost: 15,
  /** SPEC: Flow 4; V26 — first 3 meals earn XP; 4th+ = 0 */
  mealXpDailyCap: 3,
  /** SPEC: Part IV table; V28 — perfect week bonus = +150 */
  xpPerfectWeek: 150,
  /** SPEC: Part IV table; V29 — first post after 3+ missed = +50 */
  xpComeback: 50,
  /** SPEC: Flow 5; E7; V30; V31 — bonus/second workout same day = +25 */
  xpBonusWorkout: 25,
  /** SPEC: Decision Registry G1 (2026-09-04); V27 — +2 per counted reaction, max 10 XP/day */
  xpReaction: 2,
  /** SPEC: V27 — 6th+ reaction of day = 0 XP */
  reactionXpDailyCap: 5,
  /** SPEC: Flow 7; V20 — no XP accrues while paused */
  xpDuringPause: 0,

  // --- levels ---
  /** SPEC: Decision Registry G2 (2026-09-04) — a user starts at level 1 with 0 XP */
  startingLevel: 1,
  /** SPEC: Decision Registry G2 (2026-09-04) — level N (N ≥ 2) requires totalXP ≥ levelBaseXp × (N−1) × N / 2; formula, never a table */
  levelBaseXp: 500,
  /** SPEC: Decision Registry G2 (2026-09-04) — the /2 of the triangular formula levelBaseXp × (N−1) × N / 2 */
  levelFormulaDivisor: 2,

  // --- identity ---
  /** SPEC: GAP (agent, 2026-09-04): E1 initials fallback — first letters of up to two names */
  initialsMaxLetters: 2,

  // --- crew ---
  /** SPEC: Flow 6 — 2–10 people */
  crewMinMembers: 2,
  /** SPEC: Flow 6; E2 — full crew = crew full */
  crewMaxMembers: 10,
  /** SPEC: Flow 6; Part IX; 8.2 — one crew per user in MVP */
  crewsPerUserMax: 1,
  /** SPEC: Flow 6; S12 — feed shows 7 days; journal keeps everything */
  feedWindowDays: 7,
  /** SPEC: Flow 6; Part IX — the only five reactions */
  reactionEmojis: ["🔥", "💪", "👏", "😂", "❤️"],
  /** SPEC: GAP (agent, 2026-09-05): Flow 6 'a name, an emoji' — one emoji, ZWJ sequences included, counted in UTF-16 units */
  crewEmojiMaxChars: 16,

  // --- limits ---
  /** SPEC: E20; Part IX */
  captionMaxChars: 280,
  /** SPEC: E20; Part IX */
  crewNameMaxChars: 30,
  /** SPEC: E20 */
  exerciseNameMaxChars: 60,
  /** SPEC: GAP (agent, 2026-09-04): E1 names a display name but no limit; conservative default = the crew-name limit */
  displayNameMaxChars: 30,
  /** SPEC: GAP (agent, 2026-09-04): E18 standard resets, no password floor stated; conservative common floor */
  passwordMinChars: 8,
  /** SPEC: GAP (agent, 2026-09-04): E9 report flow, no length stated; docs/api.md reports */
  reportReasonMaxChars: 500,
  /** SPEC: Flow 8 — ≤15 exercises/day */
  planMaxExercisesPerDay: 15,
  /** SPEC: Flow 8; Decision Registry G3 (2026-09-04) — ≤20 sets per exercise; 15 × 20 is the day ceiling */
  planMaxSetsPerExercise: 20,
  /** SPEC: GAP (agent, 2026-09-05): Flow 3 / Flow 8 name no reps ceiling — above 100 reps a set is a typo, not training */
  planTargetRepsMax: 100,

  // --- planGeneration ---
  /** SPEC: Flow 1 step 3; S04 — Full-Body A/B at ≤2 days */
  fullBodyMaxTrainingDays: 2,
  /** SPEC: 1B; S03 — Mon/Wed/Fri pre-selected (ISO weekdays) */
  defaultTrainingWeekdays: [1, 3, 5],
  /** SPEC: 1B — Continue requires ≥ 1 day */
  minTrainingDaysToContinue: 1,
  /** SPEC: A4 (owner-directed 2026-09-08) — the editor's ~minutes estimate rounds to 5 */
  planEstimateRoundingMinutes: 5,
  /** SPEC: Flow 1 step 3 — Brand new = 4 simple exercises */
  beginnerExerciseCount: 4,
  /** SPEC: Flow 1 step 3 — at 3×10 */
  beginnerTargetSets: 3,
  /** SPEC: Flow 1 step 3 — at 3×10 */
  beginnerTargetReps: 10,
  /** SPEC: Flow 1 step 3 — Experienced = 6 incl. barbell lifts */
  experiencedExerciseCount: 6,
  /** SPEC: Decision Registry G7 (2026-09-04) — Some experience = 5 exercises per workout */
  someExperienceExerciseCount: 5,
  /** SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10 */
  someExperienceTargetSets: 3,
  /** SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10 */
  someExperienceTargetRepsMin: 8,
  /** SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10 */
  someExperienceTargetRepsMax: 10,
  /** SPEC: Flow 1 step 3 — 2–3 holds close each workout */
  mobilityHoldsMin: 2,
  /** SPEC: Flow 1 step 3 — 2–3 holds close each workout */
  mobilityHoldsMax: 3,
  /** SPEC: Flow 1 step 3 — ~5–10 min */
  mobilityMinutesMin: 5,
  /** SPEC: Flow 1 step 3 — ~5–10 min */
  mobilityMinutesMax: 10,
  /** SPEC: Flow 1 step 4 — 3–5 alternatives */
  swapCandidatesMin: 3,
  /** SPEC: Flow 1 step 4; 5.6.1 SwapFinder — ≤5, never incumbent */
  swapCandidatesMax: 5,

  // --- session ---
  /** SPEC: Flow 3 smart steppers — reps ±1 */
  repsStep: 1,
  /** SPEC: Flow 3 smart steppers — weight ±5 lb */
  weightStepLb: 5,
  /** SPEC: Flow 3 smart steppers — weight ±2.5 kg */
  weightStepKg: 2.5,
  /** SPEC: A9, owner-directed 2026-09-09 — the exact international pound, 0.45359237 kg, as an integer scaled by weightConversionScale so both engines convert with integer arithmetic (the distanceDecimalScale precedent: JS and Swift disagree on an exact binary half) */
  kilogramsPerPoundScaled: 45359237,
  /** SPEC: A9, owner-directed 2026-09-09 — the divisor for kilogramsPerPoundScaled (1e8) */
  weightConversionScale: 100000000,
  /** SPEC: A9, owner-directed 2026-09-09 — a converted weight snaps to the nearest half pound (scale 2 = halves), the smallest increment a lb gym can load */
  weightDisplayScaleLb: 2,
  /** SPEC: A9, owner-directed 2026-09-09 — a converted weight snaps to the nearest quarter kilogram (scale 4 = quarters), matching the 1.25 kg smallest plate per side */
  weightDisplayScaleKg: 4,
  /** SPEC: A10, owner-directed 2026-09-09 — the distance between two adjacent tape notches. One notch is one plate step (weightStepLb / weightStepKg), so 45→225 lb is 36 notches ≈ one flick; wide enough that a snapped notch is unambiguous under a thumb */
  weightTapeTickSpacingPt: 24,
  /** SPEC: A10, owner-directed 2026-09-09 — every fifth notch carries its number (25 lb / 12.5 kg apart); the rest are bare marks, so the ruler reads as a scale rather than a list */
  weightTapeLabelEveryTicks: 5,
  /** SPEC: A10, owner-directed 2026-09-09 — the tape's own height; it is a drag surface, so it is a full touch target tall (6.3) */
  weightTapeHeightPt: 44,
  /** SPEC: A10, owner-directed 2026-09-09 — a labelled notch's mark */
  weightTapeMajorTickHeightPt: 16,
  /** SPEC: A10, owner-directed 2026-09-09 — an unlabelled notch's mark, half the major so the eye finds the labelled ones */
  weightTapeMinorTickHeightPt: 8,
  /** SPEC: A10, owner-directed 2026-09-09 — the fixed centre marker the notches snap under; wider than a hairline so it reads as the pointer rather than as another notch */
  weightTapeMarkerWidthPt: 2,
  /** SPEC: A11, owner-directed 2026-09-09 — the width of the Remove control a swiped set row reveals; wide enough for the word at accessibility sizes and for a thumb (6.3) */
  swipeRemoveWidthPt: 96,
  /** SPEC: A11, owner-directed 2026-09-09 — how far a finger travels before the row starts following it, so a tap meant for the set never begins a swipe */
  swipeRemoveMinimumDistancePt: 12,
  /** SPEC: A11, owner-directed 2026-09-09 — released past this fraction of the control width the row snaps open, otherwise closed */
  swipeRemoveOpenFraction: 0.5,
  /** SPEC: A10, owner-directed 2026-09-09 — the tape is padded by this fraction of (viewport − one notch) at each end, so the FIRST and LAST weights can still sit under the centre marker */
  weightTapeCenterFraction: 0.5,
  /** SPEC: Flow 3 rest timer; Decision Registry G9 (2026-09-04) — default 90 s, per-workout adjustable, off-able */
  restTimerDefaultSeconds: 90,
  /** SPEC: GAP (agent, 2026-09-05): G9 says per-workout adjustable but names no step — 15 s per tap, the smallest step a resting lifter notices */
  restTimerAdjustStepSeconds: 15,
  /** SPEC: GAP (agent, 2026-09-04): Flow 3 plate math ('45 + 25 + 2.5 per side') — a standard bar */
  barbellBarWeightLb: 45,
  /** SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — a standard bar */
  barbellBarWeightKg: 20,
  /** SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — the common gym plate set */
  plateSetLb: [45, 35, 25, 10, 5, 2.5],
  /** SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — the common gym plate set */
  plateSetKg: [25, 20, 15, 10, 5, 2.5, 1.25],
  /** SPEC: GAP (agent, 2026-09-04): Flow 3 smart steppers — long-press fast-scroll repeat interval */
  longPressStepIntervalMs: 120,
  /** SPEC: S01 — stale (>day) in-progress session triggers the stale-session prompt */
  staleInProgressSessionAfterHours: 24,
  /** SPEC: GAP (agent, 2026-09-05): Flow 3 names no weight ceiling — 1000 lb/kg keeps a typo out of the plate math */
  setWeightMax: 1000,
  /** SPEC: GAP (agent, 2026-09-05): Flow 3 plate math 'per side' — plates load on both ends of the bar */
  barbellPlateSides: 2,
  /** SPEC: GAP (agent, 2026-09-05): Flow 3 mobility '90s each' — a per-side hold runs once per side */
  perSideHoldRepeats: 2,
  /** SPEC: GAP (agent, 2026-09-05): Flow 1 mobility block 5–10 min — one hold never runs past 10 min */
  holdSecondsMax: 600,

  // --- cardio ---
  /** SPEC: A2, owner-directed 2026-09-08 — a cardio log is at least one minute */
  cardioMinutesMin: 1,
  /** SPEC: A2, owner-directed 2026-09-08 — a cardio log never runs past five hours */
  cardioMinutesMax: 300,
  /** SPEC: A2, owner-directed 2026-09-08 — the minutes stepper moves in fives */
  cardioMinutesStep: 5,
  /** SPEC: A2, owner-directed 2026-09-08 — the optional distance; a 100 km ceiling keeps a typo out */
  cardioDistanceMaxMeters: 100000,
  /** SPEC: A2, owner-directed 2026-09-08 — distance is stored in meters and shown in km (units kg) at one decimal */
  metersPerKilometer: 1000,
  /** SPEC: A2, owner-directed 2026-09-08 — distance is stored in meters and shown in mi (units lb) at one decimal */
  metersPerMile: 1609.344,
  /** SPEC: GAP (agent, 2026-09-08): A2/A6 'Walk · 25 min · 2.1 km' — distance rounds half-up to tenths (scale 10 = one decimal) with integer arithmetic so both engines print the same digit */
  distanceDecimalScale: 10,

  // --- progress ---
  /** SPEC: GAP (agent, 2026-09-04): S15 layer 1 heat map — weeks shown; Flow 9 names no span (12 = a quarter, the smallest span where a weekly pattern reads) */
  progressHeatMapWeeks: 12,
  /** SPEC: GAP (agent, 2026-09-04): S15 rings history — weeks of past rings shown; Flow 9 names no span */
  progressRingHistoryWeeks: 8,

  // --- journal ---
  /** SPEC: A6, owner-directed 2026-09-08 — Today · Yesterday · a weekday name up to six days back · then Mon Sep 8 */
  dayLabelWeekdayWithinDays: 6,

  // --- nutrition ---
  /** SPEC: A16.c; nutrition addendum §6; A22 G3 — the nutrition surface exists only at 18+ (the app itself stays 13+) */
  nutritionAdultAgeYears: 18,
  /** SPEC: nutrition addendum §3 — a bodyweight is entered to one decimal and carried as TENTHS of its unit (integer arithmetic on both engines) */
  bodyweightEntryScale: 10,
  /** SPEC: nutrition addendum §3 — kilograms are carried as hundredths through the derivation */
  bodyweightKilogramScale: 100,
  /** SPEC: GAP (agent, 2026-09-18; R-074): the addendum names no bodyweight bounds — below 30 kg the entry is refused as a typo, in either unit */
  bodyweightMinKg: 30,
  /** SPEC: GAP (agent, 2026-09-18; R-074): above 300 kg the entry is refused as a typo, in either unit */
  bodyweightMaxKg: 300,
  /** SPEC: nutrition addendum §3 — energy estimate, maintenance only (Q1, 2026-09-18: there is no goal) */
  kcalPerKgMaintenance: 33,
  /** SPEC: nutrition addendum §3; A16 protein-first — 1.8 g/kg, scaled by macroFactorScale */
  proteinGramsPerKgScaled: 18,
  /** SPEC: nutrition addendum §3; A16's floor — 0.5 g/kg, scaled by macroFactorScale */
  fatFloorGramsPerKgScaled: 5,
  /** SPEC: nutrition addendum §3 — the divisor of the two per-kilogram factors */
  macroFactorScale: 10,
  /** SPEC: nutrition addendum §3; A16 — fat is at least 20 % of the energy estimate */
  fatFloorPercentOfEnergy: 20,
  /** SPEC: nutrition addendum §3 — the divisor of fatFloorPercentOfEnergy */
  macroPercentScale: 100,
  /** SPEC: nutrition addendum §4 — the target marker (ink hairline) sits at 80 % of a macro bar's track, so an overage has room to show as LENGTH and never as colour (clause ②; R-075) */
  macroBarTargetPercent: 80,
  /** SPEC: nutrition addendum §3 — Atwater */
  kcalPerGramProtein: 4,
  /** SPEC: nutrition addendum §3 — Atwater */
  kcalPerGramCarbs: 4,
  /** SPEC: nutrition addendum §3 — Atwater */
  kcalPerGramFat: 9,
  /** SPEC: nutrition addendum §3 — derived grams round half-up to the nearest 5 */
  macroGramsRoundTo: 5,
  /** SPEC: GAP (agent, 2026-09-18; R-074): the energy estimate rounds to 50 kcal, so 80 kg and 176 lb derive the same four lines (V58) and an estimate never reads as a measurement */
  energyKcalRoundTo: 50,
  /** SPEC: GAP (agent, 2026-09-18; R-074): §2 'grams are integers within bounds' — one saved meal, quick add or log carries 0–500 g of each macro */
  macroGramsMaxPerEntry: 500,
  /** SPEC: GAP (agent, 2026-09-18; R-074): a daily target carries 0–1000 g of each macro */
  macroTargetGramsMax: 1000,
  /** SPEC: nutrition addendum §2 — savedMeals.name */
  savedMealNameMaxChars: 40,
  /** SPEC: GAP (agent, 2026-09-18; R-074): a user keeps at most 100 saved meals */
  savedMealsMax: 100,
  /** SPEC: nutrition addendum §1, §2 — a daily template of 1–6 slots */
  dayTemplateMaxSlots: 6,
  /** SPEC: GAP (agent, 2026-09-18; R-074): §2 names a slot label and no length — 20 characters */
  dayTemplateSlotLabelMaxChars: 20,
  /** SPEC: GAP (agent, 2026-09-18; R-074): one day holds at most 50 logs (an abuse bound, never a target) */
  mealLogsPerDayMax: 50,
  /** SPEC: nutrition addendum §5 — the chains actually shipped in shared/seed/fast-food.json, stated honestly (the addendum proposed ~10; four are HELD with reasons in docs/fast-food-seed-sources.md) */
  fastFoodChainCount: 6,
  /** SPEC: nutrition addendum §5 — every shipped chain carries at least 15 items read from its own published nutrition facts */
  fastFoodItemsPerChainMin: 15,

  // --- reminders ---
  /** SPEC: Decision Registry G12 (2026-09-04) — no silent default; 7:30 AM pre-filled at the post-first-workout opt-in */
  reminderSuggestedMinuteOfDay: 450,
  /** SPEC: GAP (agent, 2026-09-04): Flow 4 rhythm reminder 'at YOUR usual time' — the nudge may fire within this many minutes after the user's usual post time */
  streakRiskNudgeWindowMinutes: 60,
  /** SPEC: GAP (agent, 2026-09-04): the user's usual post time = the median of the last N post times */
  usualPostTimeSampleSize: 14,

  // --- onboarding ---
  /** SPEC: Flow 1; 1B; A21.1 (owner-approved 2026-09-17) — two questions (days, experience), the '1 of 2' whisper; was 3 until the equipment question was removed */
  onboardingQuestionCount: 2,
  /** SPEC: 1B — selection haptic → 250 ms beat → next screen */
  autoAdvanceDelayMs: 250,
  /** SPEC: 1B; S03 — seven circular toggles ≥ 56 pt */
  dayToggleMinPt: 56,
  /** SPEC: 1C — day cards stagger in over ~0.5 s (instant under Reduce Motion) */
  planRevealStaggerMs: 500,
  /** SPEC: 1A; 1C — organic hero→Home median ≤ 90 s */
  organicHeroToHomeMedianSeconds: 90,
  /** SPEC: 1A; 1C — invited ≤ 60 s */
  invitedHeroToHomeMedianSeconds: 60,
  /** SPEC: 1C; A21.1 (owner-approved 2026-09-17) — hero, days-confirm, experience, auth; was 5 with the equipment question */
  decisionsBeforeHomeOrganic: 4,
  /** SPEC: 1C; A21.1 GAP confirmed by the owner 2026-09-17 — hero, paste the code, days-confirm, experience, auth under the A21.3 code path (4 once universal links carry the token, W7) */
  decisionsBeforeHomeInvited: 5,

  // --- interactionBudgets ---
  /** SPEC: Flow 1 step 4; S04 — Swap in 2 taps */
  swapMaxTaps: 2,
  /** SPEC: S07 — ≤3 taps launch→fast-logged */
  fastLogMaxTapsFromLaunch: 3,
  /** SPEC: S13 — join ≤ 2 taps with app */
  inviteJoinMaxTapsApp: 2,
  /** SPEC: W1 — joining via web ≤ 3 interactions post-auth */
  inviteJoinMaxInteractionsWeb: 3,

  // --- performanceBudgets ---
  /** SPEC: 6.2; S01 — warm launch → Home interactive < 1.0 s */
  warmLaunchToHomeMs: 1000,
  /** SPEC: 6.2 — cold launch → Home < 2.5 s */
  coldLaunchToHomeMs: 2500,
  /** SPEC: 6.2 — any tap → visible feedback < 100 ms */
  tapFeedbackMaxMs: 100,
  /** SPEC: 6.2 — set-check → haptic + UI update < 50 ms */
  setCheckFeedbackMaxMs: 50,
  /** SPEC: 6.2 — session/history scroll 60 fps */
  scrollTargetFps: 60,
  /** SPEC: 6.2 — no hangs > 250 ms */
  hangMaxMs: 250,
  /** SPEC: 6.2 — web LCP (Home, Crew) < 2.5 s on 4G */
  webLcpMaxMs: 2500,
  /** SPEC: 6.2 — web INP < 200 ms */
  webInpMaxMs: 200,
  /** SPEC: 6.1 — skeleton/spinner within 100 ms */
  loadingSkeletonWithinMs: 100,
  /** SPEC: S07; 5.6.2 HomeModel.refresh — today-state < 500 ms warm */
  homeTodayStateWarmMaxMs: 500,
  /** SPEC: S04 — renders < 500 ms */
  generatedPlanRenderMaxMs: 500,
  /** SPEC: S11 — [+] → live camera < 1 s */
  cameraOpenMaxMs: 1000,
  /** SPEC: 6.4; S10 — celebrations ≤ 2.5 s, skippable on first tap */
  celebrationMaxSeconds: 2.5,
  /** SPEC: 8.8 — image pipeline: 12 MP → ≤ ~300 KB upload */
  imageUploadMaxKb: 300,

  // --- photos ---
  /** SPEC: GAP (agent, 2026-09-04): 8.8 image pipeline 12 MP → ≤ ~300 KB; the long edge after resize (docs/api.md photos) */
  photoMaxEdgePx: 1600,
  /** SPEC: GAP (agent, 2026-09-04): first JPEG quality tried by the pipeline */
  photoJpegQuality: 82,
  /** SPEC: GAP (agent, 2026-09-04): the pipeline steps quality down toward this floor until the upload fits imageUploadMaxKb */
  photoJpegQualityFloor: 60,
  /** SPEC: GAP (agent, 2026-09-04): quality step between attempts */
  photoJpegQualityStep: 8,
  /** SPEC: GAP (agent, 2026-09-04): the largest source file the photos route accepts (a 12 MP HEIC/JPEG is well under) */
  photoMaxSourceMb: 25,

  // --- touchAndLayout ---
  /** SPEC: 6.3 — targets ≥ 44×44 pt */
  minTouchTargetPt: 44,
  /** SPEC: 6.7 — ≥44 px touch targets below 768 px */
  webMinTouchTargetPx: 44,
  /** SPEC: 6.7 — below 768 px */
  webTouchTargetBreakpointPx: 768,
  /** SPEC: 6.7 — centered single column, max-width ~640 px */
  webAppMaxWidthPx: 640,
  /** SPEC: 6.7 — Progress may widen to ~960 px for charts */
  webProgressMaxWidthPx: 960,
  /** SPEC: 6.7 — from 360 px up; no horizontal scroll 360–1920 */
  webMinViewportPx: 360,
  /** SPEC: 6.7 — no horizontal scroll 360–1920 */
  webMaxViewportPx: 1920,

  // --- accessibility ---
  /** SPEC: 6.5 — text ≥ 4.5:1 */
  textContrastMin: 4.5,
  /** SPEC: 6.5 — components ≥ 3:1 */
  componentContrastMin: 3,

  // --- sync ---
  /** SPEC: 5.6.3 SyncQueue — backoff 1s·2s·4s·8s·16s then .held */
  syncBackoffSeconds: [1, 2, 4, 8, 16],
  /** SPEC: 5.6.3 SyncQueue — five attempts, then .held */
  syncMaxAttemptsBeforeHeld: 5,
  /** SPEC: E19; 5.6.3; 8.6 — after ~24h the user chooses Retry / Delete (A22 G2, 2026-09-18: no queued op carries a photo) */
  failedUploadChoiceAfterHours: 24,
  /** SPEC: GAP (agent, 2026-09-04): E15 server clock wins + E19 delivery lag never retro-breaks — the server keeps a client's creation timestamp when it is at most this old; older, and the server clock wins */
  syncClientTimestampMaxAgeDays: 7,
  /** SPEC: GAP (agent, 2026-09-04): E15 — a client timestamp further in the future than this is replaced by the server clock (device-clock skew, 8.2 Sync) */
  clientClockSkewToleranceMinutes: 5,
  /** SPEC: Part IV; 5.6.2 CrewModel.poll — the stream is polled every 5–10 s (A21.2 / W3, 2026-09-17: renamed from chatPollIntervalMinSeconds — the chat is gone, the value is not) */
  streamPollIntervalMinSeconds: 5,
  /** SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10 s (A21.2 / W3: renamed from chatPollIntervalMaxSeconds) */
  streamPollIntervalMaxSeconds: 10,
  /** SPEC: GAP (agent, 2026-09-05): 5.6.3 names no batch size — one sync replay carries at most 1000 ops */
  syncBatchMaxOps: 1000,

  // --- authAndPolicy ---
  /** SPEC: Part IV email table; 8.2 Auth — single-use token, 30-min expiry */
  passwordResetTokenExpiryMinutes: 30,
  /** SPEC: Decision Registry G11 (2026-09-04) — access token 15 min */
  jwtAccessTokenMinutes: 15,
  /** SPEC: Decision Registry G11 (2026-09-04) — refresh token 30 days, rotating */
  jwtRefreshTokenDays: 30,
  /** SPEC: GAP (agent, 2026-09-04): clients refresh the access token this long before it expires so no request ever races the 15-min expiry */
  tokenRefreshLeadSeconds: 60,
  /** SPEC: 8.7 rate limits; Decision Registry G11 (2026-09-04) — auth endpoints 10 req/min/IP */
  rateLimitAuthRequestsPerMinutePerIp: 10,
  /** SPEC: 8.7 rate limits; Decision Registry G11 (2026-09-04) — post creation 60/hour/user; everything else unlimited in MVP */
  rateLimitPostCreationPerHourPerUser: 60,
  /** SPEC: E9; Appendix A — age floor 13+ */
  minimumAgeYears: 13,
  /** SPEC: GAP (agent, 2026-09-04): the age gate asks a birth year; validator floor */
  birthYearMin: 1900,
  /** SPEC: Part IV email table; lib/email.ts — the only three */
  transactionalEmailKinds: ["passwordReset", "reportReceived", "accountDeleted"],

  // --- ember ---
  /** SPEC: Part III — 70 / 20 / 10 */
  canvasSharePct: 70,
  /** SPEC: Part III — 70 / 20 / 10 */
  inkSharePct: 20,
  /** SPEC: Part III — ≤10% Ember, the reward layer only */
  emberMaxSharePct: 10,

  // --- successTargets ---
  /** SPEC: Part IV; 1D — ≥50% install→first post same day */
  targetInstallToFirstPostSameDayPct: 50,
  /** SPEC: Part IV — ≥30% D7 retention */
  targetD7RetentionPct: 30,
  /** SPEC: Part IV — ≥4 posts/user/week */
  targetPostsPerUserPerWeek: 4,
  /** SPEC: Part IV — crew retention ≥1.5× solo */
  targetCrewVsSoloRetentionMultiplier: 1.5,
  /** SPEC: Part X Phase 6 — crash-free ≥ 99.5% */
  targetCrashFreePct: 99.5,

  // --- testMatrix ---
  /** SPEC: 6.7; 8.9 — iPhone SE 3rd gen */
  deviceSmallestPt: [375, 667],
  /** SPEC: 6.7 — iPhone 13 mini */
  deviceCompactTallPt: [375, 812],
  /** SPEC: 6.7; 8.9 — Pro Max */
  deviceLargestPt: [440, 956],
  /** SPEC: 8.9 — Playwright viewport matrix */
  webViewportsPx: [375, 768, 1280],
  /** SPEC: 8.8 — scroll instrumentation on a 500-session History seed */
  historyScrollSeedSessions: 500,
  /** SPEC: 8.8 — polling load: 10k users at 5–10 s */
  pollingLoadUsers: 10000,
  /** SPEC: 8.8 — image pipeline: 12 MP source */
  imageSourceMegapixels: 12,

  // --- build ---
  /** SPEC: Part IV; Appendix A — iOS 17+ */
  iosMinimumMajorVersion: 17,
  /** SPEC: C9 — Swift ≤ 200 lines */
  swiftFileMaxLines: 200,
  /** SPEC: C9 — TS ≤ 150 lines */
  tsFileMaxLines: 150,
  /** SPEC: C9 — functions ≤ ~40 lines */
  functionMaxLines: 40,
  /** SPEC: 5.3 lint — no numeric literal outside Generated (allowlist: 0, 1) */
  numericLiteralAllowlist: [0, 1],
  /** SPEC: GAP (agent, 2026-09-04): the percent → fraction scale (photoJpegQuality, success-target percentages) */
  percentScale: 100,
} as const;
