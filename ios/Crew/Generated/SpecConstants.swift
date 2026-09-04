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
    /// SPEC: V27 — 6th+ reaction of day = 0 XP
    static let reactionXpDailyCap: Int = 5
    /// SPEC: Flow 7; V20 — no XP accrues while paused
    static let xpDuringPause: Int = 0

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

    // MARK: limits
    /// SPEC: E20; Part IX
    static let captionMaxChars: Int = 280
    /// SPEC: E20; Part IX
    static let crewNameMaxChars: Int = 30
    /// SPEC: E20
    static let exerciseNameMaxChars: Int = 60
    /// SPEC: E20; Part IX; 8.2
    static let chatMessageMaxChars: Int = 1000
    /// SPEC: Flow 8 — ≤15 exercises/day
    static let planMaxExercisesPerDay: Int = 15
    /// SPEC: Flow 8 — ≤20 sets (read as per training day; owner to confirm, see progress.md)
    static let planMaxSetsPerDay: Int = 20

    // MARK: planGeneration
    /// SPEC: Flow 1 step 3; S04 — Full-Body A/B at ≤2 days
    static let fullBodyMaxTrainingDays: Int = 2
    /// SPEC: 1B; S03 — Mon/Wed/Fri pre-selected (ISO weekdays)
    static let defaultTrainingWeekdays: [Int] = [1, 3, 5]
    /// SPEC: 1B — Continue requires ≥ 1 day
    static let minTrainingDaysToContinue: Int = 1
    /// SPEC: Flow 1 step 3 — Brand new = 4 simple exercises
    static let beginnerExerciseCount: Int = 4
    /// SPEC: Flow 1 step 3 — at 3×10
    static let beginnerTargetSets: Int = 3
    /// SPEC: Flow 1 step 3 — at 3×10
    static let beginnerTargetReps: Int = 10
    /// SPEC: Flow 1 step 3 — Experienced = 6 incl. barbell lifts
    static let experiencedExerciseCount: Int = 6
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
    /// SPEC: S01 — stale (>day) in-progress session triggers the stale-session prompt
    static let staleInProgressSessionAfterHours: Int = 24

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
    /// SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s
    static let chatPollIntervalMinSeconds: Int = 5
    /// SPEC: Part IV; 5.6.2 CrewModel.poll — polling 5–10s
    static let chatPollIntervalMaxSeconds: Int = 10

    // MARK: authAndPolicy
    /// SPEC: Part IV email table; 8.2 Auth — single-use token, 30-min expiry
    static let passwordResetTokenExpiryMinutes: Int = 30
    /// SPEC: E9; Appendix A — age floor 13+
    static let minimumAgeYears: Int = 13
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
}
