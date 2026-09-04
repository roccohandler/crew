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
  /** SPEC: V27 — 6th+ reaction of day = 0 XP */
  reactionXpDailyCap: 5,
  /** SPEC: Flow 7; V20 — no XP accrues while paused */
  xpDuringPause: 0,

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

  // --- limits ---
  /** SPEC: E20; Part IX */
  captionMaxChars: 280,
  /** SPEC: E20; Part IX */
  crewNameMaxChars: 30,
  /** SPEC: E20 */
  exerciseNameMaxChars: 60,
  /** SPEC: E20; Part IX; 8.2 */
  chatMessageMaxChars: 1000,
  /** SPEC: Flow 8 — ≤15 exercises/day */
  planMaxExercisesPerDay: 15,
  /** SPEC: Flow 8 — ≤20 sets (read as per training day; owner to confirm, see progress.md) */
  planMaxSetsPerDay: 20,

  // --- planGeneration ---
  /** SPEC: Flow 1 step 3; S04 — Full-Body A/B at ≤2 days */
  fullBodyMaxTrainingDays: 2,
  /** SPEC: 1B; S03 — Mon/Wed/Fri pre-selected (ISO weekdays) */
  defaultTrainingWeekdays: [1, 3, 5],
  /** SPEC: 1B — Continue requires ≥ 1 day */
  minTrainingDaysToContinue: 1,
  /** SPEC: Flow 1 step 3 — Brand new = 4 simple exercises */
  beginnerExerciseCount: 4,
  /** SPEC: Flow 1 step 3 — at 3×10 */
  beginnerTargetSets: 3,
  /** SPEC: Flow 1 step 3 — at 3×10 */
  beginnerTargetReps: 10,
  /** SPEC: Flow 1 step 3 — Experienced = 6 incl. barbell lifts */
  experiencedExerciseCount: 6,
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
  /** SPEC: S01 — stale (>day) in-progress session triggers the stale-session prompt */
  staleInProgressSessionAfterHours: 24,

  // --- onboarding ---
  /** SPEC: Flow 1; 1B — three questions, the '1 of 3' whisper */
  onboardingQuestionCount: 3,
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
  /** SPEC: 1C — hero, days-confirm, experience, equipment, auth */
  decisionsBeforeHomeOrganic: 5,
  /** SPEC: 1C — invited 5 */
  decisionsBeforeHomeInvited: 5,

  // --- interactionBudgets ---
  /** SPEC: Flow 1 step 4; S04 — Swap in 2 taps */
  swapMaxTaps: 2,
  /** SPEC: S07 — ≤3 taps launch→fast-logged */
  fastLogMaxTapsFromLaunch: 3,
  /** SPEC: S11 — text-only ≤ 3 taps */
  textOnlyPostMaxTaps: 3,
  /** SPEC: Flow 2; Flow 4 — under 15 seconds */
  nutritionPostTargetSeconds: 15,
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
  /** SPEC: 6.2; S11 — shutter → optimistic posted < 500 ms */
  photoPostOptimisticMaxMs: 500,
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
  /** SPEC: E19; 5.6.3; 8.6 — after ~24h the user chooses Retry / Post without photo / Delete */
  failedUploadChoiceAfterHours: 24,
  /** SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s */
  chatPollIntervalMinSeconds: 5,
  /** SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s */
  chatPollIntervalMaxSeconds: 10,

  // --- authAndPolicy ---
  /** SPEC: Part IV email table; 8.2 Auth — single-use token, 30-min expiry */
  passwordResetTokenExpiryMinutes: 30,
  /** SPEC: E9; Appendix A — age floor 13+ */
  minimumAgeYears: 13,
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
} as const;
