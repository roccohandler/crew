// GENERATED FILE — DO NOT EDIT. Source: shared/spec-constants.json · Generator: shared/scripts/generate.mjs
// Re-run `node shared/scripts/generate.mjs`; `node shared/scripts/check-drift.mjs` fails CI when this file drifts.
// SPEC: C7 — every tunable in the spec, named for its rule.

enum SpecConstants {
    // MARK: day
    /// SPEC: E8; Flow 7; V04–V06 — the day ends 3 AM local
    static let dayBoundaryHour: Int = 3
    /// SPEC: E20; V38 — Monday week-start worldwide (ISO weekday 1)
    static let weekStartWeekday: Int = 1
    /// SPEC: Flow 4 — same-day backfill only; yesterday is closed
    static let backfillMaxDaysBack: Int = 0

    // MARK: streak
    /// SPEC: V01 — first-ever post starts streak at 1
    static let streakAfterFirstPost: Int = 1
    /// SPEC: V02, V03, V11 — one increment per counted day
    static let streakIncrementPerCountedDay: Int = 1
    /// SPEC: Flow 7; V04 — no shield → streak → 0
    static let streakAfterUnshieldedMiss: Int = 0
    /// SPEC: Flow 6; V29; V39 — quiet for 3+ days → comeback
    static let comebackMissedDaysThreshold: Int = 3
    /// SPEC: E4; S18 — 14+ quiet days → Welcome back screen
    static let lapsedUserQuietDays: Int = 14

    // MARK: shields
    /// SPEC: Flow 7; V14; Part IX — hold max 2
    static let maxShields: Int = 2
    /// SPEC: Flow 7; V13 — earned per PERFECT week, never sold
    static let shieldsEarnedPerPerfectWeek: Int = 1

    // MARK: pause
    /// SPEC: Flow 7; V23; S17; Part IX — max 3 weeks (endDay ≤ start+21)
    static let pauseMaxDays: Int = 21
    /// SPEC: Flow 7; Part IX — one active pause at a time
    static let maxActivePauses: Int = 1
    /// SPEC: GAP (agent, 2026-09-05): Flow 7 / S17 — the pre-filled return day is one week out (never above pauseMaxDays)
    static let pauseDefaultDays: Int = 7

    // MARK: xp
    /// SPEC: Part IV table; V24 — first post of day = 25
    static let xpFirstPostOfDay: Int = 25
    /// SPEC: Part IV table; V25; E7 — planned workout = +100
    static let xpPlannedWorkout: Int = 100
    /// SPEC: Flow 4; Part IV table; V26 — +15 per meal
    static let xpMealPost: Int = 15
    /// SPEC: Flow 4; V26 — first 3 meals earn XP; 4th+ = 0
    static let mealXpDailyCap: Int = 3
    /// SPEC: Part IV table; V28 — perfect week bonus = +150
    static let xpPerfectWeek: Int = 150
    /// SPEC: Part IV table; V29 — first post after 3+ missed = +50
    static let xpComeback: Int = 50
    /// SPEC: Flow 5; E7; V30; V31 — bonus/second workout same day = +25
    static let xpBonusWorkout: Int = 25
    /// SPEC: Decision Registry G1 (2026-09-04); V27 — +2 per counted reaction, max 10 XP/day
    static let xpReaction: Int = 2
    /// SPEC: V27 — 6th+ reaction of day = 0 XP
    static let reactionXpDailyCap: Int = 5
    /// SPEC: Flow 7; V20 — no XP accrues while paused
    static let xpDuringPause: Int = 0

    // MARK: levels
    /// SPEC: Decision Registry G2 (2026-09-04) — a user starts at level 1 with 0 XP
    static let startingLevel: Int = 1
    /// SPEC: Decision Registry G2 (2026-09-04) — level N (N ≥ 2) requires totalXP ≥ levelBaseXp × (N−1) × N / 2; formula, never a table
    static let levelBaseXp: Int = 500
    /// SPEC: Decision Registry G2 (2026-09-04) — the /2 of the triangular formula levelBaseXp × (N−1) × N / 2
    static let levelFormulaDivisor: Int = 2

    // MARK: identity
    /// SPEC: GAP (agent, 2026-09-04): E1 initials fallback — first letters of up to two names
    static let initialsMaxLetters: Int = 2

    // MARK: crew
    /// SPEC: Flow 6 — 2–10 people
    static let crewMinMembers: Int = 2
    /// SPEC: Flow 6; E2 — full crew = crew full
    static let crewMaxMembers: Int = 10
    /// SPEC: Flow 6; Part IX; 8.2 — one crew per user in MVP
    static let crewsPerUserMax: Int = 1
    /// SPEC: Flow 6; S12 — feed shows 7 days; journal keeps everything
    static let feedWindowDays: Int = 7
    /// SPEC: Flow 6; Part IX — the only five reactions
    static let reactionEmojis: [String] = ["🔥", "💪", "👏", "😂", "❤️"]
    /// SPEC: GAP (agent, 2026-09-05): Flow 6 'a name, an emoji' — one emoji, ZWJ sequences included, counted in UTF-16 units
    static let crewEmojiMaxChars: Int = 16

    // MARK: limits
    /// SPEC: E20; Part IX
    static let captionMaxChars: Int = 280
    /// SPEC: E20; Part IX
    static let crewNameMaxChars: Int = 30
    /// SPEC: E20
    static let exerciseNameMaxChars: Int = 60
    /// SPEC: E20; Part IX; 8.2
    static let chatMessageMaxChars: Int = 1000
    /// SPEC: GAP (agent, 2026-09-04): E1 names a display name but no limit; conservative default = the crew-name limit
    static let displayNameMaxChars: Int = 30
    /// SPEC: GAP (agent, 2026-09-04): E18 standard resets, no password floor stated; conservative common floor
    static let passwordMinChars: Int = 8
    /// SPEC: GAP (agent, 2026-09-04): E9 report flow, no length stated; docs/api.md reports
    static let reportReasonMaxChars: Int = 500
    /// SPEC: Flow 8 — ≤15 exercises/day
    static let planMaxExercisesPerDay: Int = 15
    /// SPEC: Flow 8; Decision Registry G3 (2026-09-04) — ≤20 sets per exercise; 15 × 20 is the day ceiling
    static let planMaxSetsPerExercise: Int = 20
    /// SPEC: GAP (agent, 2026-09-05): Flow 3 / Flow 8 name no reps ceiling — above 100 reps a set is a typo, not training
    static let planTargetRepsMax: Int = 100

    // MARK: planGeneration
    /// SPEC: Flow 1 step 3; S04 — Full-Body A/B at ≤2 days
    static let fullBodyMaxTrainingDays: Int = 2
    /// SPEC: 1B; S03 — Mon/Wed/Fri pre-selected (ISO weekdays)
    static let defaultTrainingWeekdays: [Int] = [1, 3, 5]
    /// SPEC: 1B — Continue requires ≥ 1 day
    static let minTrainingDaysToContinue: Int = 1
    /// SPEC: A4 (owner-directed 2026-09-08) — the editor's ~minutes estimate rounds to 5
    static let planEstimateRoundingMinutes: Int = 5
    /// SPEC: Flow 1 step 3 — Brand new = 4 simple exercises
    static let beginnerExerciseCount: Int = 4
    /// SPEC: Flow 1 step 3 — at 3×10
    static let beginnerTargetSets: Int = 3
    /// SPEC: Flow 1 step 3 — at 3×10
    static let beginnerTargetReps: Int = 10
    /// SPEC: Flow 1 step 3 — Experienced = 6 incl. barbell lifts
    static let experiencedExerciseCount: Int = 6
    /// SPEC: Decision Registry G7 (2026-09-04) — Some experience = 5 exercises per workout
    static let someExperienceExerciseCount: Int = 5
    /// SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10
    static let someExperienceTargetSets: Int = 3
    /// SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10
    static let someExperienceTargetRepsMin: Int = 8
    /// SPEC: Decision Registry G7 (2026-09-04) — at 3×8–10
    static let someExperienceTargetRepsMax: Int = 10
    /// SPEC: Flow 1 step 3 — 2–3 holds close each workout
    static let mobilityHoldsMin: Int = 2
    /// SPEC: Flow 1 step 3 — 2–3 holds close each workout
    static let mobilityHoldsMax: Int = 3
    /// SPEC: Flow 1 step 3 — ~5–10 min
    static let mobilityMinutesMin: Int = 5
    /// SPEC: Flow 1 step 3 — ~5–10 min
    static let mobilityMinutesMax: Int = 10
    /// SPEC: Flow 1 step 4 — 3–5 alternatives
    static let swapCandidatesMin: Int = 3
    /// SPEC: Flow 1 step 4; 5.6.1 SwapFinder — ≤5, never incumbent
    static let swapCandidatesMax: Int = 5

    // MARK: session
    /// SPEC: Flow 3 smart steppers — reps ±1
    static let repsStep: Int = 1
    /// SPEC: Flow 3 smart steppers — weight ±5 lb
    static let weightStepLb: Int = 5
    /// SPEC: Flow 3 smart steppers — weight ±2.5 kg
    static let weightStepKg: Double = 2.5
    /// SPEC: A9, owner-directed 2026-09-09 — the exact international pound, 0.45359237 kg, as an integer scaled by weightConversionScale so both engines convert with integer arithmetic (the distanceDecimalScale precedent: JS and Swift disagree on an exact binary half)
    static let kilogramsPerPoundScaled: Int = 45359237
    /// SPEC: A9, owner-directed 2026-09-09 — the divisor for kilogramsPerPoundScaled (1e8)
    static let weightConversionScale: Int = 100000000
    /// SPEC: A9, owner-directed 2026-09-09 — a converted weight snaps to the nearest half pound (scale 2 = halves), the smallest increment a lb gym can load
    static let weightDisplayScaleLb: Int = 2
    /// SPEC: A9, owner-directed 2026-09-09 — a converted weight snaps to the nearest quarter kilogram (scale 4 = quarters), matching the 1.25 kg smallest plate per side
    static let weightDisplayScaleKg: Int = 4
    /// SPEC: A10, owner-directed 2026-09-09 — the distance between two adjacent tape notches. One notch is one plate step (weightStepLb / weightStepKg), so 45→225 lb is 36 notches ≈ one flick; wide enough that a snapped notch is unambiguous under a thumb
    static let weightTapeTickSpacingPt: Int = 24
    /// SPEC: A10, owner-directed 2026-09-09 — every fifth notch carries its number (25 lb / 12.5 kg apart); the rest are bare marks, so the ruler reads as a scale rather than a list
    static let weightTapeLabelEveryTicks: Int = 5
    /// SPEC: A10, owner-directed 2026-09-09 — the tape's own height; it is a drag surface, so it is a full touch target tall (6.3)
    static let weightTapeHeightPt: Int = 44
    /// SPEC: A10, owner-directed 2026-09-09 — a labelled notch's mark
    static let weightTapeMajorTickHeightPt: Int = 16
    /// SPEC: A10, owner-directed 2026-09-09 — an unlabelled notch's mark, half the major so the eye finds the labelled ones
    static let weightTapeMinorTickHeightPt: Int = 8
    /// SPEC: A10, owner-directed 2026-09-09 — the fixed centre marker the notches snap under; wider than a hairline so it reads as the pointer rather than as another notch
    static let weightTapeMarkerWidthPt: Int = 2
    /// SPEC: A11, owner-directed 2026-09-09 — the width of the Remove control a swiped set row reveals; wide enough for the word at accessibility sizes and for a thumb (6.3)
    static let swipeRemoveWidthPt: Int = 96
    /// SPEC: A11, owner-directed 2026-09-09 — how far a finger travels before the row starts following it, so a tap meant for the set never begins a swipe
    static let swipeRemoveMinimumDistancePt: Int = 12
    /// SPEC: A11, owner-directed 2026-09-09 — released past this fraction of the control width the row snaps open, otherwise closed
    static let swipeRemoveOpenFraction: Double = 0.5
    /// SPEC: A10, owner-directed 2026-09-09 — the tape is padded by this fraction of (viewport − one notch) at each end, so the FIRST and LAST weights can still sit under the centre marker
    static let weightTapeCenterFraction: Double = 0.5
    /// SPEC: Flow 3 rest timer; Decision Registry G9 (2026-09-04) — default 90 s, per-workout adjustable, off-able
    static let restTimerDefaultSeconds: Int = 90
    /// SPEC: GAP (agent, 2026-09-05): G9 says per-workout adjustable but names no step — 15 s per tap, the smallest step a resting lifter notices
    static let restTimerAdjustStepSeconds: Int = 15
    /// SPEC: GAP (agent, 2026-09-04): Flow 3 plate math ('45 + 25 + 2.5 per side') — a standard bar
    static let barbellBarWeightLb: Int = 45
    /// SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — a standard bar
    static let barbellBarWeightKg: Int = 20
    /// SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — the common gym plate set
    static let plateSetLb: [Double] = [45, 35, 25, 10, 5, 2.5]
    /// SPEC: GAP (agent, 2026-09-04): Flow 3 plate math — the common gym plate set
    static let plateSetKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    /// SPEC: GAP (agent, 2026-09-04): Flow 3 smart steppers — long-press fast-scroll repeat interval
    static let longPressStepIntervalMs: Int = 120
    /// SPEC: S01 — stale (>day) in-progress session triggers the stale-session prompt
    static let staleInProgressSessionAfterHours: Int = 24
    /// SPEC: GAP (agent, 2026-09-05): Flow 3 names no weight ceiling — 1000 lb/kg keeps a typo out of the plate math
    static let setWeightMax: Int = 1000
    /// SPEC: GAP (agent, 2026-09-05): Flow 3 plate math 'per side' — plates load on both ends of the bar
    static let barbellPlateSides: Int = 2
    /// SPEC: GAP (agent, 2026-09-05): Flow 3 mobility '90s each' — a per-side hold runs once per side
    static let perSideHoldRepeats: Int = 2
    /// SPEC: GAP (agent, 2026-09-05): Flow 1 mobility block 5–10 min — one hold never runs past 10 min
    static let holdSecondsMax: Int = 600

    // MARK: cardio
    /// SPEC: A2, owner-directed 2026-09-08 — a cardio log is at least one minute
    static let cardioMinutesMin: Int = 1
    /// SPEC: A2, owner-directed 2026-09-08 — a cardio log never runs past five hours
    static let cardioMinutesMax: Int = 300
    /// SPEC: A2, owner-directed 2026-09-08 — the minutes stepper moves in fives
    static let cardioMinutesStep: Int = 5
    /// SPEC: A2, owner-directed 2026-09-08 — the optional distance; a 100 km ceiling keeps a typo out
    static let cardioDistanceMaxMeters: Int = 100000
    /// SPEC: A2, owner-directed 2026-09-08 — distance is stored in meters and shown in km (units kg) at one decimal
    static let metersPerKilometer: Int = 1000
    /// SPEC: A2, owner-directed 2026-09-08 — distance is stored in meters and shown in mi (units lb) at one decimal
    static let metersPerMile: Double = 1609.344
    /// SPEC: GAP (agent, 2026-09-08): A2/A6 'Walk · 25 min · 2.1 km' — distance rounds half-up to tenths (scale 10 = one decimal) with integer arithmetic so both engines print the same digit
    static let distanceDecimalScale: Int = 10

    // MARK: progress
    /// SPEC: GAP (agent, 2026-09-04): S15 layer 1 heat map — weeks shown; Flow 9 names no span (12 = a quarter, the smallest span where a weekly pattern reads)
    static let progressHeatMapWeeks: Int = 12
    /// SPEC: GAP (agent, 2026-09-04): S15 rings history — weeks of past rings shown; Flow 9 names no span
    static let progressRingHistoryWeeks: Int = 8

    // MARK: journal
    /// SPEC: A6, owner-directed 2026-09-08 — Today · Yesterday · a weekday name up to six days back · then Mon Sep 8
    static let dayLabelWeekdayWithinDays: Int = 6

    // MARK: nutrition
    /// SPEC: Flow 4 time-smart tags; Decision Registry G10 (2026-09-04) — breakfast 04:00–10:30 local (minutes since local midnight)
    static let mealTagBreakfastFromMinute: Int = 240
    /// SPEC: Decision Registry G10 (2026-09-04) — lunch 10:30–15:30 local
    static let mealTagLunchFromMinute: Int = 630
    /// SPEC: Decision Registry G10 (2026-09-04) — dinner 15:30–21:00 local
    static let mealTagDinnerFromMinute: Int = 930
    /// SPEC: Decision Registry G10 (2026-09-04) — after 21:00 and before 04:00 = snack
    static let mealTagDinnerUntilMinute: Int = 1260

    // MARK: reminders
    /// SPEC: Decision Registry G12 (2026-09-04) — no silent default; 7:30 AM pre-filled at the post-first-workout opt-in
    static let reminderSuggestedMinuteOfDay: Int = 450
    /// SPEC: GAP (agent, 2026-09-04): Flow 4 rhythm reminder 'at YOUR usual time' — the nudge may fire within this many minutes after the user's usual post time
    static let streakRiskNudgeWindowMinutes: Int = 60
    /// SPEC: GAP (agent, 2026-09-04): the user's usual post time = the median of the last N post times
    static let usualPostTimeSampleSize: Int = 14

    // MARK: onboarding
    /// SPEC: Flow 1; 1B — three questions, the '1 of 3' whisper
    static let onboardingQuestionCount: Int = 3
    /// SPEC: 1B — selection haptic → 250 ms beat → next screen
    static let autoAdvanceDelayMs: Int = 250
    /// SPEC: 1B; S03 — seven circular toggles ≥ 56 pt
    static let dayToggleMinPt: Int = 56
    /// SPEC: 1C — day cards stagger in over ~0.5 s (instant under Reduce Motion)
    static let planRevealStaggerMs: Int = 500
    /// SPEC: 1A; 1C — organic hero→Home median ≤ 90 s
    static let organicHeroToHomeMedianSeconds: Int = 90
    /// SPEC: 1A; 1C — invited ≤ 60 s
    static let invitedHeroToHomeMedianSeconds: Int = 60
    /// SPEC: 1C — hero, days-confirm, experience, equipment, auth
    static let decisionsBeforeHomeOrganic: Int = 5
    /// SPEC: 1C — invited 5
    static let decisionsBeforeHomeInvited: Int = 5

    // MARK: interactionBudgets
    /// SPEC: Flow 1 step 4; S04 — Swap in 2 taps
    static let swapMaxTaps: Int = 2
    /// SPEC: S07 — ≤3 taps launch→fast-logged
    static let fastLogMaxTapsFromLaunch: Int = 3
    /// SPEC: S11 — text-only ≤ 3 taps
    static let textOnlyPostMaxTaps: Int = 3
    /// SPEC: Flow 2; Flow 4 — under 15 seconds
    static let nutritionPostTargetSeconds: Int = 15
    /// SPEC: S13 — join ≤ 2 taps with app
    static let inviteJoinMaxTapsApp: Int = 2
    /// SPEC: W1 — joining via web ≤ 3 interactions post-auth
    static let inviteJoinMaxInteractionsWeb: Int = 3

    // MARK: performanceBudgets
    /// SPEC: 6.2; S01 — warm launch → Home interactive < 1.0 s
    static let warmLaunchToHomeMs: Int = 1000
    /// SPEC: 6.2 — cold launch → Home < 2.5 s
    static let coldLaunchToHomeMs: Int = 2500
    /// SPEC: 6.2 — any tap → visible feedback < 100 ms
    static let tapFeedbackMaxMs: Int = 100
    /// SPEC: 6.2 — set-check → haptic + UI update < 50 ms
    static let setCheckFeedbackMaxMs: Int = 50
    /// SPEC: 6.2 — session/history scroll 60 fps
    static let scrollTargetFps: Int = 60
    /// SPEC: 6.2 — no hangs > 250 ms
    static let hangMaxMs: Int = 250
    /// SPEC: 6.2; S11 — shutter → optimistic posted < 500 ms
    static let photoPostOptimisticMaxMs: Int = 500
    /// SPEC: 6.2 — web LCP (Home, Crew) < 2.5 s on 4G
    static let webLcpMaxMs: Int = 2500
    /// SPEC: 6.2 — web INP < 200 ms
    static let webInpMaxMs: Int = 200
    /// SPEC: 6.1 — skeleton/spinner within 100 ms
    static let loadingSkeletonWithinMs: Int = 100
    /// SPEC: S07; 5.6.2 HomeModel.refresh — today-state < 500 ms warm
    static let homeTodayStateWarmMaxMs: Int = 500
    /// SPEC: S04 — renders < 500 ms
    static let generatedPlanRenderMaxMs: Int = 500
    /// SPEC: S11 — [+] → live camera < 1 s
    static let cameraOpenMaxMs: Int = 1000
    /// SPEC: 6.4; S10 — celebrations ≤ 2.5 s, skippable on first tap
    static let celebrationMaxSeconds: Double = 2.5
    /// SPEC: 8.8 — image pipeline: 12 MP → ≤ ~300 KB upload
    static let imageUploadMaxKb: Int = 300

    // MARK: photos
    /// SPEC: GAP (agent, 2026-09-04): 8.8 image pipeline 12 MP → ≤ ~300 KB; the long edge after resize (docs/api.md photos)
    static let photoMaxEdgePx: Int = 1600
    /// SPEC: GAP (agent, 2026-09-04): first JPEG quality tried by the pipeline
    static let photoJpegQuality: Int = 82
    /// SPEC: GAP (agent, 2026-09-04): the pipeline steps quality down toward this floor until the upload fits imageUploadMaxKb
    static let photoJpegQualityFloor: Int = 60
    /// SPEC: GAP (agent, 2026-09-04): quality step between attempts
    static let photoJpegQualityStep: Int = 8
    /// SPEC: GAP (agent, 2026-09-04): the largest source file the photos route accepts (a 12 MP HEIC/JPEG is well under)
    static let photoMaxSourceMb: Int = 25

    // MARK: touchAndLayout
    /// SPEC: 6.3 — targets ≥ 44×44 pt
    static let minTouchTargetPt: Int = 44
    /// SPEC: 6.7 — ≥44 px touch targets below 768 px
    static let webMinTouchTargetPx: Int = 44
    /// SPEC: 6.7 — below 768 px
    static let webTouchTargetBreakpointPx: Int = 768
    /// SPEC: 6.7 — centered single column, max-width ~640 px
    static let webAppMaxWidthPx: Int = 640
    /// SPEC: 6.7 — Progress may widen to ~960 px for charts
    static let webProgressMaxWidthPx: Int = 960
    /// SPEC: 6.7 — from 360 px up; no horizontal scroll 360–1920
    static let webMinViewportPx: Int = 360
    /// SPEC: 6.7 — no horizontal scroll 360–1920
    static let webMaxViewportPx: Int = 1920
    /// SPEC: GAP (agent, 2026-09-05): Five States Law loading state — placeholder rows in a list skeleton
    static let skeletonPlaceholderRows: Int = 3
    /// SPEC: GAP (agent, 2026-09-05): S13 chat composer grows to four lines before it scrolls
    static let chatComposerMaxLines: Int = 4
    /// SPEC: GAP (agent, 2026-09-05): S11 caption field grows to three lines before it scrolls (captions are ≤ captionMaxChars)
    static let captionComposerMaxLines: Int = 3

    // MARK: accessibility
    /// SPEC: 6.5 — text ≥ 4.5:1
    static let textContrastMin: Double = 4.5
    /// SPEC: 6.5 — components ≥ 3:1
    static let componentContrastMin: Double = 3

    // MARK: sync
    /// SPEC: 5.6.3 SyncQueue — backoff 1s·2s·4s·8s·16s then .held
    static let syncBackoffSeconds: [Int] = [1, 2, 4, 8, 16]
    /// SPEC: 5.6.3 SyncQueue — five attempts, then .held
    static let syncMaxAttemptsBeforeHeld: Int = 5
    /// SPEC: E19; 5.6.3; 8.6 — after ~24h the user chooses Retry / Post without photo / Delete
    static let failedUploadChoiceAfterHours: Int = 24
    /// SPEC: GAP (agent, 2026-09-04): E15 server clock wins + E19 delivery lag never retro-breaks — the server keeps a client's creation timestamp when it is at most this old; older, and the server clock wins
    static let syncClientTimestampMaxAgeDays: Int = 7
    /// SPEC: GAP (agent, 2026-09-04): E15 — a client timestamp further in the future than this is replaced by the server clock (device-clock skew, 8.2 Sync)
    static let clientClockSkewToleranceMinutes: Int = 5
    /// SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s
    static let chatPollIntervalMinSeconds: Int = 5
    /// SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s
    static let chatPollIntervalMaxSeconds: Int = 10
    /// SPEC: GAP (agent, 2026-09-05): 5.6.3 names no batch size — one sync replay carries at most 1000 ops
    static let syncBatchMaxOps: Int = 1000
    /// SPEC: GAP (agent, 2026-09-06): 1A/6.1 — a signed-in phone with an empty Store (a reinstall: the Keychain outlives the app, 1C) shows Home's skeleton while it pulls its account from the server, never longer than this; then Home opens with what has arrived
    static let hydrationMaxWaitSeconds: Int = 10

    // MARK: authAndPolicy
    /// SPEC: Part IV email table; 8.2 Auth — single-use token, 30-min expiry
    static let passwordResetTokenExpiryMinutes: Int = 30
    /// SPEC: Decision Registry G11 (2026-09-04) — access token 15 min
    static let jwtAccessTokenMinutes: Int = 15
    /// SPEC: Decision Registry G11 (2026-09-04) — refresh token 30 days, rotating
    static let jwtRefreshTokenDays: Int = 30
    /// SPEC: GAP (agent, 2026-09-04): clients refresh the access token this long before it expires so no request ever races the 15-min expiry
    static let tokenRefreshLeadSeconds: Int = 60
    /// SPEC: 8.7 rate limits; Decision Registry G11 (2026-09-04) — auth endpoints 10 req/min/IP
    static let rateLimitAuthRequestsPerMinutePerIp: Int = 10
    /// SPEC: 8.7 rate limits; Decision Registry G11 (2026-09-04) — post creation 60/hour/user; everything else unlimited in MVP
    static let rateLimitPostCreationPerHourPerUser: Int = 60
    /// SPEC: E9; Appendix A — age floor 13+
    static let minimumAgeYears: Int = 13
    /// SPEC: GAP (agent, 2026-09-04): the age gate asks a birth year; validator floor
    static let birthYearMin: Int = 1900
    /// SPEC: Part IV email table; lib/email.ts — the only three
    static let transactionalEmailKinds: [String] = ["passwordReset", "reportReceived", "accountDeleted"]

    // MARK: ember
    /// SPEC: Part III — 70 / 20 / 10
    static let canvasSharePct: Int = 70
    /// SPEC: Part III — 70 / 20 / 10
    static let inkSharePct: Int = 20
    /// SPEC: Part III — ≤10% Ember, the reward layer only
    static let emberMaxSharePct: Int = 10

    // MARK: successTargets
    /// SPEC: Part IV; 1D — ≥50% install→first post same day
    static let targetInstallToFirstPostSameDayPct: Int = 50
    /// SPEC: Part IV — ≥30% D7 retention
    static let targetD7RetentionPct: Int = 30
    /// SPEC: Part IV — ≥4 posts/user/week
    static let targetPostsPerUserPerWeek: Int = 4
    /// SPEC: Part IV — crew retention ≥1.5× solo
    static let targetCrewVsSoloRetentionMultiplier: Double = 1.5
    /// SPEC: Part X Phase 6 — crash-free ≥ 99.5%
    static let targetCrashFreePct: Double = 99.5

    // MARK: testMatrix
    /// SPEC: 6.7; 8.9 — iPhone SE 3rd gen
    static let deviceSmallestPt: [Int] = [375, 667]
    /// SPEC: 6.7 — iPhone 13 mini
    static let deviceCompactTallPt: [Int] = [375, 812]
    /// SPEC: 6.7; 8.9 — Pro Max
    static let deviceLargestPt: [Int] = [440, 956]
    /// SPEC: 8.9 — Playwright viewport matrix
    static let webViewportsPx: [Int] = [375, 768, 1280]
    /// SPEC: 8.8 — scroll instrumentation on a 500-session History seed
    static let historyScrollSeedSessions: Int = 500
    /// SPEC: 8.8 — polling load: 10k users at 5–10 s
    static let pollingLoadUsers: Int = 10000
    /// SPEC: 8.8 — image pipeline: 12 MP source
    static let imageSourceMegapixels: Int = 12

    // MARK: build
    /// SPEC: Part IV; Appendix A — iOS 17+
    static let iosMinimumMajorVersion: Int = 17
    /// SPEC: C9 — Swift ≤ 200 lines
    static let swiftFileMaxLines: Int = 200
    /// SPEC: C9 — TS ≤ 150 lines
    static let tsFileMaxLines: Int = 150
    /// SPEC: C9 — functions ≤ ~40 lines
    static let functionMaxLines: Int = 40
    /// SPEC: 5.3 lint — no numeric literal outside Generated (allowlist: 0, 1)
    static let numericLiteralAllowlist: [Int] = [0, 1]
    /// SPEC: GAP (agent, 2026-09-04): the percent → fraction scale (photoJpegQuality, success-target percentages)
    static let percentScale: Int = 100
}
