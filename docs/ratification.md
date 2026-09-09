# Crew — ratification ledger

Continuous build mode (Appendix A, 2026-09-04): every former 🛑 becomes a recorded self-review here, every
SPECIFICATION GAP becomes a conservative call tagged `// GAP:` in code and logged here, and every dev-only
substitute for a real service is logged here (and in docs/debt.md). The owner ratifies at the end via
docs/OWNER-REVIEW.md. Entries are append-only, newest last.

Entry format — `### <id> · <date> · <task> · <checkpoint | gap | substitute>` then What was checked / Verdict
/ Look at.

### R-001 · 2026-09-04 · T003 · checkpoint (vector review) — RATIFIED BY OWNER
- What was checked: all 45 vectors against Part VIII 8.1, Flows 5–7, E3, E8, E16, E20, Decision Registry
  G1/G2/G6; independent reference fold reproduced every expected value (0 mismatches); check-vectors green.
- Verdict: approved by the owner in full, including every reviewNote interpretation (logged in Appendix A).
- Look at: nothing further.

### R-002 · 2026-09-04 · T004 · checkpoint (seed exercises) — self-reviewed, proceeding
- What was checked: shared/seed/exercises.json against Part IX seed shape (pattern, equipment, level, type,
  cueLine, swapGroup, holdSeconds?), E20 (names ≤ 60), Flow 3 (setup cues one line; mobility holds
  duration-based, no reps/weight), Flow 1 step 4 (3–5 swap alternatives) — `node shared/scripts/check-seeds.mjs` green.
- Verdict: 101 exercises (86 strength, 15 mobility) — above the spec's "~80" because dumbbell-only and
  bodyweight users needed real swap alternatives (the checker proved the promise fails below ~95).
- Gap calls: (a) swapGroup vs "same pattern" — SwapFinder widens in tiers swapGroup → pattern → region only
  while fewer than 3 candidates exist, never returns the incumbent (recorded as `swapRule` in the seed);
  (b) `perSide` added to mobility holds (the timer runs once per side, "couch stretch 90s each" in Flow 3);
  (c) `enums.region` maps every pattern to push/pull/legs/core for tier 3 and for Progress layer 2 balance.
- Look at: exercise levels (which lifts a Brand-new user may see), cue-line voice, the 15 holds and their
  seconds — all cheap JSON edits; re-run check-seeds after any change.

### R-003 · 2026-09-04 · T005 · checkpoint (plan templates) — self-reviewed, proceeding
- What was checked: shared/seed/plan-templates.json against Flow 1 step 3 (Brand new = 4 at 3×10 ·
  Experienced = 6 incl. barbell lifts · mobility block 2–3 holds ~5–10 min · Full-Body A/B at ≤2 days),
  G7 (Some = 5 at 3×8–10), the equipment question (Full gym / Dumbbells / Bodyweight) — 45 lists, every
  exercise exists, equipment-available, level-appropriate, swap-covered; every block 5–6.5 min.
- Verdict: complete; every experienced/fullGym list carries barbell lifts as Flow 1 requires.
- Gap calls (also in the file's gapNotes): experienced = 3×8 (spec silent; continues 10 → 8–10 → 8);
  rep ranges stored as targetReps (floor) + targetRepsMax; PPL cycles P→P→L across 3–7 sorted training
  days within the week; workout display names "Push day / Pull day / Leg day / Full body A/B".
- Look at: the exercise choice per list (taste), the 3×8 experienced default, the P-P-L cycle for 4–5 days.

### R-004 · 2026-09-04 · T006 · checkpoint (achievements + API contract → Phase 1 unlocked) — self-reviewed, proceeding
- What was checked: shared/seed/achievements.json (15: 11 solo + 4 crew, every trigger a counter derivable
  from Sessions + Posts + crew facts, nothing from a rejected list — no leaderboards, no calories, no effort
  scores) — check-seeds green; docs/api.md against 5.2's route tree, 5.6.4's canonical shape, 8.2's matrix,
  Part IX's invariants, E2/E3/E9/E15/E19/E20, G11 rate limits; generate.mjs now emits SeedData.swift + seed.ts
  (drift check green).
- Verdict: Phase 0 contracts complete; Phase 1 may start.
- Gap calls / tree additions (5.2 route list was not exhaustive): `photos` (EXIF strip + resize must run
  server-side via sharp, so uploads go through the server — the pending-photo post flow of E19 needs a
  separate upload step); `auth/reset` + `auth/reset/confirm` (T011 needs endpoints); `crews/[id]/stream`
  (the ONE unified stream, distinct from sending messages); `crews/[id]/messages/[messageId]` DELETE
  (tombstones); `crews/[id]/mute`; `events` (client funnel events for 1D/E10); reactions are on posts only
  in MVP (Flow 6 says "long-press a post"; Part IX's messageId target stays unused — no scope added);
  DELETE `posts/[id]` never changes server gamification (the same-day undo of V34 is the client's optimistic
  path; the server recompute is the truth per 5.6.3).
- Look at: achievement copy/thresholds (cheap edits), the `photos` route decision (server-side pipeline vs
  direct-to-blob presign — the spec says both "presigned" and "EXIF strip via sharp"; server-side is the
  only way to guarantee the strip, so it wins), api.md as the contract every route test will enforce.

### R-005 · 2026-09-04 · T007 · substitute + checkpoint (monorepo scaffold) — proceeding
- What was checked: web/ scaffold (Next 16.3 · React 19.2 · TypeScript 6 · zod 4 · vitest 5 · Playwright 1.62)
  against 5.2 (scripts dev · test · vectors · e2e · lint · typecheck · generate; `@/` the only alias; strict TS) —
  `npm run typecheck` and `npm run lint` clean, `npm test` green on the empty suite. iOS: `ios/project.yml`
  (XcodeGen) + CrewApp/RootView + two smoke tests — WRITTEN — UNVERIFIED (needs Mac / the CI macOS job).
- Substitutes (rule 3b, also in Appendix A "dev-only tooling additions"): `@types/*`, `eslint-config-next`,
  `@playwright/test`, `mongodb-memory-server` as devDependencies; XcodeGen on the Mac. `.env.example` complete.
- Look at: nothing blocking; `xcodegen generate` on a Mac is the first thing to try.

### R-006 · 2026-09-04 · T008 · checkpoint (CI + doctrine lint) — proceeding
- What was checked: .github/workflows/ci.yml (contracts → web → e2e; ios on macos-latest with xcodegen + xcodebuild
  test) against Phase 1's exit gate; doctrine lint = ESLint (no-magic-numbers with allowlist [0,1], max-lines 150,
  max-lines-per-function 40, TODO ban, no barrel/re-export, no class/generic/interface-extends in src) +
  shared/scripts/doctrine-lint.mjs (Swift: single-conformer protocol ban, magic numbers outside Generated, 200-line
  cap, TODO ban; hand-written CSS: color literals). Locally: lint, typecheck, test, doctrine-lint all green.
- Verdict: the pipeline cannot be executed here (no GitHub); every step it runs was run locally and is green except
  `next build` (run before Phase 4) and the iOS job (needs the macOS runner).
- Gap calls: HTTP statuses, crypto parameters and time units are implementation numbers, not spec numbers — they
  live in three named files (http-status.ts, crypto-params.ts, time-units.ts) exempted by name from the
  magic-number rule; C7's intent (one place per number) holds.
- Look at: whether the 40-line function cap should stay an error for React screens (kept strict for now).

### R-007 · 2026-09-04 · T009 · checkpoint (db + indexes) — proceeding
- What was checked: Part IX collections and every UNIQUE invariant as a unique index (one plan per user, one crew
  per user, one reaction per user-target, one state per user, case-insensitive unique email) proven against a real
  MongoDB — `npm test tests/api/db` green (5 tests).
- Gap calls: Part IX additions carried from the vectors — Post.isPlannedDay, Post.workoutCompleted, Post.crewId,
  GamificationState.earnedAchievementIds, ExerciseTemplate.targetRepsMax; operational collections (refreshTokens,
  passwordResets, pushTokens, events, photos, rateLimits) documented in documents-auth.ts.
- Look at: nothing.

### R-008 · 2026-09-04 · T010 · checkpoint (server auth) — proceeding
- What was checked: register/login/refresh/logout against Part IV (scrypt, jose JWTs, Keychain vs httpOnly cookie),
  G11 (15-min access, 30-day rotating refresh, reuse kills the family, 10 req/min/IP), E9 (EULA + 13+ gates before
  any write), E18, docs/api.md shapes — `npm test tests/api/auth` green (9 tests).
- Gap calls (new named constants, tagged GAP in spec-constants.json): displayNameMaxChars 30, passwordMinChars 8,
  birthYearMin 1900, reportReasonMaxChars 500; the client declares itself with `X-Crew-Client: ios` to receive tokens
  in the body (web gets cookies) — documented in api.md conventions; the age gate asks a birth year (least data).
- Look at: the password floor (8) and display-name cap (30).

### R-009 · 2026-09-04 · T011 · checkpoint + substitute (Resend email + password reset) — proceeding
- What was checked: lib/email.ts carries exactly the three touchpoints (Part IV: reset · report received · account
  deleted; never marketing) in gym-buddy voice without "!" (6.6); the reset flow against 8.2 Auth — single-use, 30-min
  expiry (`passwordResetTokenExpiryMinutes`), old token dead after use, reset revokes every refresh token; 202 always
  (no account enumeration) — `npm test tests/api/auth-reset` green (3 tests).
- Substitute (rule 3b): without RESEND_API_KEY every email lands in the `emailOutbox` collection — the dev/test transport;
  tests read the link from it. Real Resend wiring = set RESEND_API_KEY / RESEND_FROM / MODERATION_INBOX (deferred list).
- Look at: the email copy (three short texts in lib/email.ts).

### R-010 · 2026-09-04 · T012 · checkpoint + substitute (Sign in with Apple) — proceeding
- What was checked: server verification with jose against a JWKS URL, issuer https://appleid.apple.com, audience = the
  iOS bundle id or the web Services ID; find-or-create by appleSub (E18 fresh identity after deletion); E9 gates only on
  first sign-in; the web flow = Apple's OAuth redirect + `auth/apple/callback` (form_post) setting cookies —
  `npm test tests/api/auth-apple` green (4 tests). iOS: Api/AuthStore.swift + KeychainStore.swift WRITTEN — UNVERIFIED
  (they reference Api.swift / ApiModels.swift / AppError from T013).
- Substitute (rule 3b): tests run a local JWKS server (tests/api/apple-jwks.ts) with a generated RSA key and point
  APPLE_JWKS_URL at it — the real jose verification path runs; only Apple's keys are substituted. The manual device
  check (real Apple credential → real Apple keys) is on the deferred list, as is linking a same-email password
  account to an Apple subject (implemented, needs a real verified Apple email to exercise).
- Gap calls: a first Apple sign-in without an email (cannot happen on Apple's first authorization, but the token is
  optional-email) gets a private placeholder address `apple-<sub>@privaterelay.crew.invalid`; display name defaults
  to the email's local part when Apple gives no name. `tokenRefreshLeadSeconds` = 60 added (GAP-tagged).
- Look at: whether same-email account linking (Apple ↔ password) should exist at all; it is the conservative choice
  over a duplicate-email 409 on an Apple sign-in.

### R-011 · 2026-09-04 · T013 · checkpoint (iOS shells) — WRITTEN — UNVERIFIED
- What was checked (by reading, not by compiling): RootView auth routing + monochrome tab bar (Home · Plan · Crew ·
  Progress · Settings), Api.swift transport (URLSession, X-Crew-Client: ios, AppError from the standard shape),
  ApiModels DTOs mirroring lib/validate.ts, Store.swift (SwiftData container, typed fetches, in-memory for tests),
  Models.swift/ModelsSocial.swift mirroring Part IX, Shared/ (PrimaryButton, Card, EmptyState, ErrorState + OfflineBanner,
  Skeleton incl. HomeSkeleton = the launch frame, WeeklyRing, StreakFlame unlit at 0, AvatarView initials, Haptics,
  Motion = the one spring), five shell screens each declaring five states (6.1). doctrine-lint clean (38 Swift files).
- Gap calls: design-tokens.json gains `sizes` (avatar 40 · ring 64 · skeleton rows · corner 16 · ring start −90°) so no
  layout number is typed inline; `initialsMaxLetters` 2; iOS named-constants files HttpStatus.swift + TimeUnits.swift
  exempted from the literal scan by name (the web twin exempts three files); Api split into Api.swift + ApiSync.swift
  (+ ApiPlans/ApiPosts/ApiCrews with their tasks) and Models into Models.swift + ModelsSocial.swift for the C9 cap.
- Look at: on the Mac — `xcodegen generate`, build, run the CrewTests scheme. Expect compile fixes; none of this Swift
  has seen a compiler.

### R-012 · 2026-09-04 · T014 · checkpoint (SyncQueue) — WRITTEN — UNVERIFIED
- What was checked (by reading): OpRecord @Model (id, kind, payload, createdAt, attempts, state pending|inFlight|held),
  enqueue → processNext FIFO with backoff 1·2·4·8·16 s then held (`syncBackoffSeconds`, `syncMaxAttemptsBeforeHeld`),
  poison ops (4xx) held immediately without blocking the line, reconcile = server gamification REPLACES local, heldOver24h
  + resolve(retry | postWithoutPhoto | delete) for E19; SyncQueueTests against Store(inMemory: true) with a test-provided
  sender function (C4: no mocks — a function parameter is a concrete dependency, C3).
- Look at: whether a held op should surface in the UI immediately (currently: after 24 h per E19).

### R-013 · 2026-09-04 · T015 · checkpoint (standing-checks generator) — proceeding
- What was checked: tests/api/standing-checks.gen.test.ts discovers every route.ts under app/api/v1, fails for any
  (route, method) absent from tests/api/standing-registry.ts, and generates ② (expired JWT → 401, then refresh
  recovers), ③ (malformed JSON → 400 standard shape), ① (foreignPath → 403/404) and ④ (clientId twice → same id) per
  entry — 17 generated checks green over the 8 auth methods; `npm test` = 38 green.
- Look at: nothing — every later route must register itself or the suite goes red.

### R-014 · 2026-09-04 · T016 · checkpoint (DayKey twin) — TS verified, Swift written
- What was checked: day-key.ts implements the README rule (startOfDay + 3 h in absolute seconds; Monday weekKey) —
  `npm run vectors` V05–V08 green (all 21 cases incl. the DST spring-forward and fall-back nights, timezone travel via
  the at+tz resolution in V09/V10). DayKey.swift is the name-for-name twin — WRITTEN — UNVERIFIED.
- Gap calls: ESLint treats −1 as the allowlisted 1 with a sign (the allowlist and its negations).
- Look at: nothing.

### R-015 · 2026-09-04 · T017 + T018 + T019 (+ T032 engine part, pulled forward) · checkpoint (the engine) — TS verified, Swift written
- What was checked: gamification.ts / -post.ts / -day.ts / -recompute.ts, completion.ts, pause-validation.ts, crew-rules.ts
  against shared/vectors/README.md — `npm run vectors`: 45 / 45 green on the TS engine (V01–V44 + V18b), i.e. the Phase 2
  mini-gate "V01–V36 green" holds on TS and V37–V40 (T032's engine part) already hold, pulled forward because engines
  precede UI (12.1) and the crew rules are pure functions with no dependency on Phase 3. Swift twins
  (GamificationEngine/Post/Day/Recompute, Completion, PauseValidation, CrewRules) + VectorRunnerTests/VectorRunnerCrewTests
  — WRITTEN — UNVERIFIED; the CI macOS job is the first place they run.
- Gap calls: achievements are NOT awarded inside apply() — V35 uses an opaque id and asserts exact award lists, so a
  separate `achievementsEarned(before, after, seed)` step (T026 celebration / server recompute) awards them; the engine
  split into four files is a C9 cap consequence (5.6.1 names one file); `levelFormulaDivisor` (2) added so the G2
  formula carries no literal.
- Look at: the engine's internal memory (per-day counters, per-week facts, judgedThroughDayKey, undo snapshots) is
  what makes apply() honest for undo and perfect weeks; it is never asserted by vectors and never stored server-side.

### R-016 · 2026-09-04 · T020 · checkpoint (PlanGenerator + SwapFinder twins + property test) — TS verified, Swift written
- What was checked: generatePlan over all 127 day subsets × 3 experiences × 3 equipment accesses = 1143 plans — every one
  respects the counts (4/5/6), planMaxExercisesPerDay, planMaxSetsPerExercise, name limits, equipment availability,
  a 2–3-hold mobility block of 5–10 min, PPL vs Full-Body at ≤2 days, ordered rows; swapCandidates over every templated
  exercise at every access: 3–5 same-region alternatives, never the incumbent, same type — `npx vitest run tests/engine`
  15 green. Swift twins PlanGenerator/SwapFinder/SeedCatalog + tests — WRITTEN — UNVERIFIED.
- Gap calls: swapCandidates takes the user's experience for RANKING only (same-or-lower level first) — the 5.6.1
  signature has no experience parameter; nothing is filtered out (Flow 1 step 4: no questions asked). Mobility rows in a
  plan carry targetSets 1 / targetReps 0 + holdSeconds (duration-based, Flow 3).
- Look at: nothing.

### R-017 · 2026-09-04 · T021 + T022 · checkpoint (onboarding screens) — WRITTEN — UNVERIFIED
- What was checked (by reading): OnboardingFlow (hero → days → experience → equipment → reveal → save; back-swipe keeps
  the model), DaysQuestion (7 toggles ≥ 56 pt, Mon/Wed/Fri pre-selected, live encouragement line, Continue ≥ 1 day),
  single-select questions auto-advancing after the 250 ms beat with a selection haptic, "1 of 3" whisper, GeneratedPlan
  reveal (stagger ~0.5 s, instant under Reduce Motion, one-time swap whisper, equipment chip + targets + mobility block),
  SwapSheet (two taps), SaveAuthScreen (Sign in with Apple black + primary; email with textContentType; field-exit
  validation; EULA line + birth year for E9), LoginScreen (Log in = a failure state, forgot-password → reset), DraftStore
  (S05: the draft survives abandon and resumes at save), OnboardingModelTests. doctrine-lint clean.
- Gap calls: LoginScreen.swift, DraftStore.swift, OnboardingFlow.swift are folder additions (5.2 lists the screens, not
  the flow container or the pre-auth draft file); `opacity.disabled` 0.5 added to design tokens; question numbers come
  from an enum, never a literal.
- Look at: nothing until a Mac compiles it.

### R-018 · 2026-09-04 · T023 · checkpoint (plans / sessions / sync API) — proceeding
- What was checked: plans GET/PUT (one per user, forward-only replace, limits 400), sessions POST/GET + [id] GET/PATCH
  (clientId idempotency, snapshot immunity to later plan edits, warm-ups excluded from x/y, holds by seconds, partial
  completion per V32 creates the workout post — post ≠ log — and recomputes: day-one +125 verified), sync (ops in order,
  per-op results, replay is idempotent, last-write-wins on plan, a bad op never fails the batch, future-dated client
  timestamps yield to the server clock) — `npm test tests/api/{plans,sessions,sync}` green; the standing checks cover
  8 more methods (foreign session → 404; malformed PATCH → 400; sessions POST ④).
- Gap calls: server-clock.ts — E15 "server clock wins" reconciled with E19 (delivery lag never retro-breaks): a client
  timestamp stands when within [now − 7 days, now + 5 min] (`syncClientTimestampMaxAgeDays`,
  `clientClockSkewToleranceMinutes`, GAP-tagged), else the server clock wins; mobility holds COUNT in x/y (Flow 2:
  "5 exercises + mobility" = "18/18 sets"); a completed session is final — later edits are stats (V36); sync op kinds for
  crews/messages/pause/pushToken are rejected as retryable until their routes land (T029/T030/T033/T041).
- Look at: the 7-day client-timestamp window.

### R-019 · 2026-09-04 · T026 (web half: Posts API) · checkpoint — proceeding
- What was checked: posts POST/GET, posts/[id] GET/PATCH/DELETE, posts/[id]/reactions POST/DELETE against docs/api.md,
  E3 (delete keeps the log and the streak; captions editable, photos not), E15 (server dayKey), V26 (3-meal XP cap
  server-enforced), Flow 10 (a shared post with no crew is journal-only), 8.2 ④ — `npm test tests/api/posts` green;
  reactions are crew-gated (`notInCrew` 403) and their XP cap flows through recompute (V27).
- Look at: nothing; the iOS half (CelebrationScreen + share flow) follows with T024–T025.

### R-020 · 2026-09-04 · T027 (web half: photos + lib/blob.ts) · checkpoint + substitute — proceeding
- What was checked: POST photos (multipart → sharp: auto-orient, resize to ≤ photoMaxEdgePx, JPEG stepping quality down
  until ≤ imageUploadMaxKb, ALL metadata dropped) + GET photos/[key] (owner or crew-mate; 404 otherwise) — the GPS-tagged
  fixture test proves the stored object has no EXIF and is 1600 px wide and under 300 KB; a text file → 400.
- Substitute (rule 3b): without BLOB_READ_WRITE_TOKEN photos live under web/.blob-dev/ (gitignored) and the GET route
  streams them; with the token they go to Vercel Blob (public, random-suffixed = unguessable) and the GET redirects.
- Gap calls: `photos` constants (max edge 1600, quality 82 → 60 by 8, 25 MB source cap) GAP-tagged in spec-constants.
- Look at: whether Vercel Blob "public" objects satisfy 8.7 "unguessable + auth-checked" (the key is 16 random bytes plus
  Vercel's own suffix; only the auth-checked GET reveals the URL) — or whether private blobs are wanted.

### R-021 · 2026-09-04 · T024 + T025 + T026/T027 (iOS halves) · checkpoint (the core loop on iPhone) — WRITTEN — UNVERIFIED
- What was checked (by reading): HomeModel's today-state machine (bridge until the first post per 1D; workout / rest / paused /
  allDone; Quick Complete hidden once today counts; Resume banner; crew strip nil for solo; weekly ring per ISO weekday with
  missed = gray) + HomeModelTests; GamificationLocal (the engine's memory persisted in engineStateJSON; foreground
  judging of elapsed days = the client-side rollover; server state replaces the public fields); SessionActions (start from the
  template snapshot, complete per V32 → LocalPost + engine apply + patchSession op, quick complete); SessionModel/Screen
  (one-tap check at pre-fill, ghost row, warm-ups excluded, steppers ±1 / ±5 lb / ±2.5 kg with long-press repeat, plate math
  on tap-hold, setup cues, neutral skips, out-of-order focus, hold countdown with per-side repeat, rest timer with a local
  notification only if already authorized, screen awake, Complete always visible, VoiceOver labels) + SessionModelTests;
  CelebrationScreen (numbers from the engine, ≤ 2.5 s count-up, skippable, thump, share default remembered, solo skips share,
  badges for comeback / perfect week / level / PR / achievement); PostModel/NutritionPostScreen/PostComposer/CameraCapture
  (camera-first, library, time-smart tag, same-as-yesterday ↻, text-only, earlier-today, camera denied → text-first, optimistic
  insert + engine apply + createPost op; the photo waits in the outbox and SyncTransport uploads it before the op — E19).
  PlateMath/MealTag twins verified on TS (`npx vitest run tests/engine` 18 green); doctrine scan clean over 88 Swift files.
- Gap calls: plate math bar/plate sets and the long-press repeat interval GAP-tagged; percentScale (100) named; the rest-timer
  chime cannot fire through a locked phone until notification permission exists, which by 1D is asked only after the first
  completed workout — the first workout's rest timer is foreground-only.
- Look at: PR badges — `prBadge` is emitted only when a logged weight beats the exercise's previous best (wired in
  SessionActions once weights exist locally; the celebration renders it) — confirm that "previous best" means the max
  weight of any done set for that exercise in completed sessions.

### R-022 · 2026-09-04 · T028 · checkpoint (Phase 2 gate: Journey ①) — WRITTEN — UNVERIFIED, gate NOT passable here
- What was checked: ios/CrewUITests/Journey1_NewUserTests.swift walks hero → questions → reveal → email save → bridge →
  first workout (or first meal) → celebration → Home without the bridge, against a local server. It cannot run on this
  machine (XCUITest needs a simulator); the Phase 2 gate's "genuinely smooth on a real phone" judgement is the owner's
  (12.5) and stays on the deferred list. The web side of Phase 2 (engine 45/45, plans/sessions/sync/posts/photos suites)
  is green here.
- Look at: run journey ① on a phone before anything in Phase 3 is trusted on iOS.

### R-023 · 2026-09-04 · T029 + T030 (+ T034 blocks, pulled forward) · checkpoint (crews, messages, reactions APIs) — proceeding
- What was checked: crews create (Captain; one crew per user; name ≤ 30), join via link (public preview; full-crew 409;
  alreadyInCrew 409; a block in either direction → 403; system line "X joined the crew"), regenerate link (old dies), rename
  (Captain only), members (streak / today-dot / ⏸ / captain), leave/remove (Captain only for others; captaincy auto-passes to
  the longest-tenured; last one out archives silently), per-crew mute, the ONE unified stream (posts + messages + system,
  time-merged, 7-day window, join-forward, blocked users filtered both ways, reactions summarised, comeback banners per
  V39 through crew-rules), messages (≤ 1,000; idempotent; own tombstone; Captain delete), reactions (crew-mates only; one
  per target with replacement; un-react; XP through recompute = V27), blocks POST/DELETE, sync ops for
  sendMessage/react/unreact — `npm test tests/api/{crews,messages}` green; the standing checks now cover every
  crews/[id]/* method for outsiders (404) — 218 tests green overall.
- Gap calls: the pulse "day" is the VIEWER's dayKey (each post carries its author's dayKey — E15); the stream's comeback
  banner uses the author's full post history (journal posts count as activity, only shared posts are shown); the invite
  token is 12 random bytes (short enough for iMessage, unguessable); fixtures register from distinct IPs so the G11 limiter
  never trips inside a suite.
- Look at: nothing.

### R-024 · 2026-09-04 · T031 (+ T032 wiring) · checkpoint (Crew feature, iOS) — WRITTEN — UNVERIFIED
- What was checked (by reading): CrewModel (last-synced snapshot first, then refresh; polling every 5 s while foregrounded —
  Part IV 5–10 s; optimistic send through the queue; react/unreact with the softTap haptic; create/join/leave/captainRemove/
  regenerateLink), CrewScreen (loading · solo invitation · offline banner + last-synced · error; unified stream with
  bottom-anchored composer), StreamList/PostCard/MessageRow (posts as in-stream cards, comeback banner, reactions with a
  visible React button per 6.7, tombstones), MemberStrip (pulse "4/5 today"), InviteScreen (ShareLink straight into iMessage,
  "crew full", Captain-only regenerate/remove), CreateCrewScreen (name ≤ 30 + emoji). doctrine scan clean.
- Look at: the Crew screen's polling cadence (5 s at the spec's lower bound) and battery.

### R-025 · 2026-09-04 · T033 · checkpoint + substitute (notifications) — web verified, device push deferred
- What was checked: push-token POST/DELETE; lib/push.ts (apns2 HTTP/2 token auth; without APNS_* the `pushOutbox` collection is
  the transport); the pure eligibility functions (reminder at the chosen time on a planned day only; streak-risk once within
  the hour after the usual post time when a live streak has nothing posted; a reaction on YOUR post buzzes, a crew-mate's post
  never nudges — Flow 6; digests never — Part IV) — 4 unit tests; the cron sender (`api/cron/notifications`, CRON_SECRET-gated,
  vercel.json every minute) sends the reminder naming the workout once per day and nothing while paused — 3 tests. 233+
  tests green.
- Substitute (rule 3b): `pushOutbox` for APNs; `notificationLog` records sends. The "manual push on device" half of the Verify
  is deferred (needs APNs credentials + a device). Vercel Cron per-minute schedules need a Pro plan — note for deployment.
- Gap calls: `streakRiskNudgeWindowMinutes` 60 and `usualPostTimeSampleSize` 14 GAP-tagged; the reminder subject is the
  workout name ("Push day is ready 💪").
- Look at: whether a crew-mate's POST should notify at all (kept off: Flow 6 "no nudge pings — the empty today-dot does the talking").

### R-026 · 2026-09-04 · T034 · checkpoint (moderation) — proceeding
- What was checked: reports POST (post/message/crewName/user; stored open; the Resend email to MODERATION_INBOX carries
  target + reporter + reason + a preview — that email IS the manual queue, E9), blocks POST/DELETE (both-way filtering proven
  in the stream and the join check), the EULA gate on register (auth.test.ts) — `npm test tests/api/moderation` green; the
  8.7 Keychain-only static check joined the doctrine scan.
- Look at: the reports collection has no admin UI — resolution is a manual `status: resolved` edit (E9 manual review).

### R-027 · 2026-09-04 · T035 · checkpoint (Phase 3 gate: Journey ② + security matrix 8.7) — partially verifiable here
- Journey ②: ios/CrewUITests/Journey2_FastLogTests.swift (warm start → Quick complete → celebration → Crew tab shows the
  card and a seeded crew-mate's reaction; ≤ 3 taps) — WRITTEN — UNVERIFIED (needs a simulator + seeded server).
- Security matrix (8.7), item by item: auto-generated cross-user 403/404 per route — GREEN (standing checks over every
  route.ts, 20+ methods) · Keychain-only tokens — GREEN (doctrine scan: no Swift file touches UserDefaults and a token) ·
  httpOnly/secure cookies on web — GREEN (auth.test.ts asserts HttpOnly, the refresh cookie's path scope, Secure via
  COOKIE_SECURE) · EXIF fixture — GREEN (photos.test.ts) · blob URLs unguessable + auth-checked — GREEN (random keys,
  photos/[key] owner-or-crew-mate, 404 otherwise) · post-delete cascade crawl — PENDING (T041 delete-account) · rate limits
  on auth + posting — GREEN (429 tests) · npm audit against the fixed list — GREEN locally (0 vulnerabilities at install)
  and a CI step.
- Verdict: everything in 8.7 that a machine without a Mac can prove is proven; the gate's device half is deferred.

### R-028 · 2026-09-04 · T036 · checkpoint (web onboarding + plan builder) — proceeding
- What was checked: the hero (one screen, three CTAs, invite-aware line from the crew token — S02/1A), the client onboarding
  flow (Mon/Wed/Fri pre-selected, live encouragement line, Continue ≥ 1 day, auto-advancing single-selects after the 250 ms
  beat, "1 of 3" whisper, reveal with equipment chip + targets + mobility block, Swap in 2 taps through the same swapCandidates
  engine, the one-time whisper, Save with Sign in with Apple primary + email with autocomplete + field-exit validation +
  EULA/birth-year line; the draft in localStorage survives auth abandon and resumes at save — S05), /login, /reset, the public
  /join/[token] landing (W1: name/emoji without auth, App Store + Continue on web, full and dead states, one-tap join when
  signed in), the (app) layout with silent refresh (1C) and a monochrome tab bar, /home with the bridge, today-state, flame,
  ring, crew strip absent for solo — `npm run build` green (28 routes), lint + typecheck clean.
- Gap calls: the web flow renders client-only (next/dynamic, ssr: false) because it reads localStorage at first render; the
  Apple web flow carries eula/next in `state`; after an Apple redirect DraftFlusher saves the draft plan on /home.
- Look at: the Playwright journey ① will be the proof (T039); Lighthouse budgets are deferred (no @lhci/cli in the allowlist).

### R-029 · 2026-09-04 · T037 · checkpoint (web session logging + posting) — proceeding
- What was checked: /session/new (snapshot from today's template; resumes an open session), /session/[id] (SessionLogger:
  one-tap check at pre-fill, ghost rows, warm-ups excluded, steppers ±1 / ±5 lb / ±2.5 kg, plate math on a visible button,
  hold countdowns with auto-check, skips gray, any exercise opens, last-time lines, every tap PATCHes, Complete always visible,
  share toggle when in a crew), /session/[id]/done (sets · minutes · streak · XP total · PR lines only where weights were
  logged), /post (native camera/library input, time-smart tag, same-as-yesterday ↻, text-only, earlier today, share; photo →
  POST photos → POST posts). Build green (31 routes).
- Look at: the web celebration shows the XP TOTAL and streak from the stored state (the per-event award list is an iOS
  engine artefact; the server reply carries state, not awards).

### R-030 · 2026-09-04 · T041 (web half: account routes) · checkpoint — proceeding
- What was checked: users/me GET/PATCH/DELETE, users/me/export, pause GET/POST/DELETE against docs/api.md, E9 (the cascade:
  leave the crew first so captaincy passes, then posts/sessions/plan/reactions/messages/pauses/blocks/tokens/state/photos,
  events anonymised, the user last, one "account deleted" email), E18 (re-signup after deletion is a fresh identity), 8.2
  Account (export completeness; after deletion the stream no longer shows the user, photos are gone, /users/me 404s) and
  8.2 Pause (create/end; a second active pause 409; retroactive and > 21 days 400; XP suppression proven through recompute)
  — `npm test tests/api/account` green; the standing checks cover the 7 new methods; sync ops for pause + pushToken land.
  257 tests green.
- Look at: reports filed BY a deleted user stay (safety records); a deleted user's messages are removed rather than
  tombstoned (their words are gone from the crew, matching "posts vanish from streams").

### R-031 · 2026-09-04 · T038 + T040/T041 (web halves) · checkpoint (web crew, plan editor, progress, settings) — proceeding
- What was checked: /crew (CrewView polling every 5 s; pulse "4/5 today"; member strip; unified stream with post cards,
  system lines, tombstones, comeback banner; reactions through a visible React row; composer; invite panel with share/copy,
  Captain-only regenerate/remove, "crew full"; create; leave; solo = one warm invitation), /plan (Flow 8: swap, adjust sets/
  reps within the input limits, reorder, add, remove, Undo, Save with "applies forward" copy, Rebuild → the questions),
  /progress (heat map 12 weeks with day detail = workout + plates; rings history 8 weeks; streak/longest/totals/meals this
  week; sets per week; Push/Pull/Legs balance; layer 3 strength lines ONLY where weights were logged, with a 🎉 on a new best;
  the empty state invites), /settings (name, units, timezone, reminder time as an in-app reminder on web, per-crew mute,
  pause with a date input bounded to 21 days and "end now", JSON export link, log out, two-step delete "can't be undone").
  Build green; token-parity test green (every color/spacing/size value identical in ember.css and the Swift tokens).
- Substitute: tests/e2e/dev-server.mjs boots an in-memory MongoDB + `next dev` for Playwright (rule 3b).
- Gap calls: Progress "balance" classifies sessions by workout name prefix (push/pull/leg); the web reminder is in-app only
  (Part IV: no push on web); the web settings page has no "notification toggles per row" beyond the reminder (E5: in-app
  banners are the web channel).
- Look at: the Playwright journeys ①③④ (next entry) are the proof for T036–T038.

### R-032 · 2026-09-04 · T039 (Playwright ①③④ × 375/768/1280 + token parity; Lighthouse deferred) · checkpoint — proceeding
- What was checked: `npm run e2e` boots an in-memory MongoDB + `next dev` (tests/e2e/dev-server.mjs) and runs journeys ①
  (fresh visitor → three questions → reveal → save → first meal post → the bridge is gone, "Streak 1"), ③ (invite link →
  landing renders crew name/emoji without auth → Continue on web → join → "Jordan joined the crew" → a later post → React 🔥
  → "🔥 1") and ④ (plan build → keyboard-first set log → Complete → celebration shows the engine's numbers "1/N sets · M min",
  "125 XP total" (V25), "Streak 1" → Home "Done for today." with Quick complete gone → /plan shows the week) on three
  projects: phone-375 (WebKit, iPhone 13 descriptor), tablet-768 and desktop-1280 (Chromium). Every journey asserts no
  horizontal scroll (8.9) on the pages it visits. Token parity (tests/token-parity.test.ts) green.
- Found and fixed by the matrix (all on phone-375 / WebKit): (1) the plan editor's Sets/Reps number inputs pushed a 375-wide
  row 111 px past the edge → `.row--wrap` + `.field--short` (6ch inputs); (2) the set row's four-column grid overflowed by
  6 px at 375 → the set row is now a wrapping flex row (the weight stepper drops under; the ✓ stays right-aligned);
  (3) a `fill` on the server-rendered /post page landed before React hydrated on WebKit and never reached state → the
  helper waits for React's mounted marker on the field before typing (`waitForHydration`); (4) in the full matrix the G11
  auth limiter (10 req/min/IP) tripped because every journey registers from 127.0.0.1 → each test context now carries its
  own `x-forwarded-for` (what Vercel sets), mirroring the vitest fixtures; (5) per-test timeout raised to 60 s because
  `next dev` compiles each page on first hit.
- Result: see the matrix line appended at the end of this entry (the run is recorded verbatim from the command output).
- Deferred (needs what this machine lacks): Lighthouse CI budgets (no @lhci/cli in the approved list — Phase 4 gate item
  "Lighthouse budgets met" stays open for the Mac/CI pass); an Xcode a11y audit.
- Result (final `npm run e2e` of the session, 2026-09-04): 20 passed, 1 skipped (the keyboard check on the phone descriptor), 0 failed — journeys ①③④ + the a11y/responsiveness audit on phone-375 (WebKit), tablet-768 and desktop-1280 in 45 s
- Look at: the WebKit hydration wait is a test-side accommodation, not an app change — the app itself is correct (a real
  person cannot type faster than hydration); the setrow wrap changes the S09 layout only under ~480 px.

### R-033 · 2026-09-04 · T040 + T041 (iOS halves: Progress/Journal, Settings/Pause/Export) · checkpoint — WRITTEN — UNVERIFIED
- What was written (needs a Mac to compile and run): Features/Progress/{ProgressModel, ProgressScreen, HeatMapView,
  ExerciseChartView (first-party Swift Charts), JournalScreen}; Features/Settings/{SettingsModel, SettingsScreen (real rows),
  PauseScreen, ExportView}; Api/ApiSettings.swift (users/me PATCH·DELETE, users/me/export, pause GET·POST·DELETE, crews/[id]/
  mute, push-token, reports, blocks DTOs). Same facts as the web halves (R-031): heat map 12 weeks → day detail = workout +
  plates; rings history 8 weeks; streak/longest/totals/meals this week; sets per week; Push/Pull/Legs balance by workout-name
  prefix; layer 3 ONLY where weights were logged with a 🎉 on a new best; the empty state invites. Settings: pause with a
  date picker bounded to 21 days and validated by the same PauseValidation twin the server runs (V22/V23/V44) before the
  request; end pause; units; reminder toggle with 7:30 pre-filled and never silently saved (G12); per-crew mute; JSON export
  to a temporary file + share sheet (E9); two-step delete "can't be undone" (E18) that wipes the local store after the server
  confirms; log out.
- Fixed while wiring: `UpdateMeRequestDTO` encoded a cleared reminder as an ABSENT key (Codable drops nil), which the server
  reads as "unchanged" — it now writes an explicit null (`clearsReminder`), matching docs/api.md PATCH semantics.
- Doctrine scan clean (111 → 114 Swift files). Progress spans use two new GAP constants (`progressHeatMapWeeks` 12,
  `progressRingHistoryWeeks` 8 — Flow 9 names no span) instead of arithmetic on unrelated constants; the web
  progress-facts.ts had the same abuse and now reads the same constants (generate + check-drift green).
- Look at: on a Mac, the Charts import (iOS 16+) and `@Observable` models (iOS 17+) set the deployment target floor — project.yml
  already targets 17.

### R-034 · 2026-09-04 · T042 (edge screens: welcome back, stale session, failed upload) · checkpoint — proceeding
- What was checked (web, verified): `lib/lapsed-user.ts` — quietDays / shouldShowWelcomeBack / isStaleSession with unit tests
  (tests/engine/lapsed-user.test.ts: 14 quiet days triggers, 13 does not; a user with no post never sees it; an answer dated
  after the last activity silences it until the next quiet spell; stale = more than staleInProgressSessionAfterHours). Home
  renders `WelcomeBack` (E4/S18: "Your record still stands", longest streak as a record not a recap, Keep my plan → Home /
  Rebuild → the questions) ahead of everything else, and `StaleSessionPrompt` (S01: Keep going → the open session; Discard →
  PATCH sessions/[id] status discarded, nothing counted per V32) in place of the Resume link when the open session is older
  than a day. The answer lives on the account: PATCH users/me { welcomeBackAckDay } (docs/api.md, updateMeSchema, PublicUser),
  proven by tests/api/welcome-back.test.ts (null for a new account; round-trips; a non-day-key is 400). Signed-in Rebuild on
  web: /onboarding now reads the session — a signed-in user starts at the questions, never touches the pre-auth draft, and the
  reveal's "Looks good" PUTs the plan and lands on /plan (Flow 8 "Rebuild = the questions again"; the plan editor's Rebuild
  link finally works).
- What was written (iOS, unverified): Engine/LapsedUser.swift (twin) + LapsedUserTests; HomeModel gains welcomeBack /
  staleSession / heldUploads (SyncQueue.heldOver24h), acknowledgeWelcomeBack (PATCH + Keychain user copy), keepGoing /
  discardStaleSession (ordinary discard → patchSession op), resolveUpload (SyncQueue.resolve: Retry · Post without photo ·
  Delete) — HomeModelEdgeTests cover all three triggers; HomeScreen presents them in priority order through `EdgePrompts`
  (welcome back full-screen → stale session sheet → held uploads sheet); Features/Settings/WelcomeBackScreen (per the 5.6
  map), Features/Home/StaleSessionPrompt + FailedUploadSheet (plain helpers of the feature). OnboardingFlow/Model gain a
  `rebuild` mode (questions → reveal → putPlan, no auth step, no draft persistence) used by Welcome back [Rebuild], Home's
  empty state and the Plan editor.
- Found and fixed (real defect): nothing on iOS ever WROTE LocalPlan — after signup or login the phone had no plan and Home
  would have shown "Build your week" forever. `Storage/PlanLocal.swift` is now the one writer (replace / pullFromServer),
  called after signup (the accepted draft), after login (GET plans), after a rebuild and by the plan editor's save.
- Also written in this session, outside any ledger task: the iOS S14 Plan editor (Features/Plan/{PlanModel, PlanScreen,
  PlanDayCard}) — the acceptance table names S14 as a must-have screen, the 5.6 map names PlanModel, but T038 is web-only
  and no task builds the iOS editor. Swap keeps the row's targets; sets clamp to 1…planMaxSetsPerExercise (G3), reps ≥ 1,
  ≤ planMaxExercisesPerDay (invalid states unreachable); ↑↓ reorder; remove; add (candidates by the day's gear tier); one-step
  Undo; Save = PlanLocal.replace + a putPlan op ("applies from your next workout on — history never rewrites"); Rebuild →
  the questions. 8.8 launch signposts (`Shared/Signposts.swift`, OSSignposter launchToHome from CrewApp.init to Home's first
  real state) written for the device-farm assertion that cannot run here.
- Gap calls: "quiet" = no post of any kind (a completed workout always leaves a workout post); the welcome-back answer is
  per quiet spell; a failed offline PATCH of the answer is not queued (no such OpKind in the 5.6.3 map) so the web may ask
  once more; the stale prompt offers exactly two choices (Keep going · Discard) — completing later counts on the completion
  day (V07), never retroactively.
- Look at: the iOS Rebuild path presents OnboardingFlow as a sheet (DaysQuestion as root); `EdgePrompts` is a ViewModifier
  (a first-party protocol conformance, allowed by C1's "no protocols with < 2 conformers" reading of custom protocols).

### R-035 · 2026-09-04 · T043 (a11y pass · offline matrix · perf signposts) · checkpoint — what is verifiable here is green
- 8.5 web, automated (substitute — axe-core is not in the approved dependency list): tests/e2e/a11y.spec.ts audits every
  public and signed-in page (/, /login, /reset, /onboarding, /home, /post, /plan, /crew, /progress, /settings, /session/[id])
  for exactly one main landmark and one h1, alt on every image, a name on every button/link, a label on every field, and no
  horizontal scroll; a responsiveness sweep at 360/414/600/1024/1920 on the two densest pages (8.9); a keyboard check (Tab →
  Enter on the hero, 6.5). Result: 11 passed, 1 skipped (the keyboard check on the phone descriptor, which has no hardware
  keyboard) across phone-375 / tablet-768 / desktop-1280. Finding fixed: the empty-state invitations (crew solo, plan empty,
  progress empty) were h2 with no h1 on the page → the invitation is now the page heading. Reduce Motion on web: the
  stylesheet declares no animation or transition at all (grep), so the reveal and the celebration are instant by
  construction; iOS honours accessibilityReduceMotion in the reveal stagger and the one spring (written, unverified).
- Also found by the matrix run: /settings hydrated with a warning because Node's and the browser's
  Intl.supportedValuesOf("timeZone") lists differ — the option list now comes from the server page as a prop.
- 8.5 deferred / manual (needs a Mac or a device): Xcode a11y audit; the scripted VoiceOver session (posting + reacting);
  Dynamic Type XXL on S07/S09/S12; Reduce Motion celebration on device; axe-core if the owner approves the dependency.
- 8.6 offline matrix: manual on an iPhone by definition. Automated pieces already in place (unverified until a Mac):
  SyncQueueTests (FIFO, backoff 1·2·4·8·16 s → held, reconcile replaces gamification silently, kill-survival through SwiftData),
  HomeModelEdgeTests (the 24 h Retry / Post without photo / Delete choice), GamificationLocal (local engine celebration).
  The checklist itself is reproduced in docs/OWNER-REVIEW.md for the first device pass.
- 8.8 perf: launch signposts written (Shared/Signposts.swift: launchToHome from CrewApp.init to Home's first real state) for
  the device-farm assertion; image pipeline proven by tests/api/photos.test.ts (EXIF/GPS stripped, resized, under
  imageUploadMaxKb for the fixture); scroll instrumentation on a 500-session seed, the 10k-user polling load and Lighthouse
  CI budgets are deferred (device / Atlas / @lhci/cli).
- Look at: the a11y spec is a floor, not axe — colour contrast is covered by the token pass (Part III law + G4 dark values),
  focus order by DOM order (single column), but no automated contrast or ARIA-role validation ran here.

### R-036 · 2026-09-04 · T044 (security sweep 8.7 + zero P0/P1) · Phase 5 gate self-review — proceeding
- Auto-generated cross-user checks per route: tests/api/standing-checks.gen.test.ts walks every route.ts through the registry
  (unauthenticated 401, expired token 401, foreign ids 404 in the sessions/posts/crews/messages suites) — a route missing from
  the registry fails the suite.
- Keychain-only tokens: shared/scripts/doctrine-lint.mjs 8.7 static check (no Swift file may put a token near UserDefaults)
  — clean over 114 files.
- httpOnly cookies on web: tests/api/auth.test.ts asserts HttpOnly on crew_access (Secure is set outside development —
  lib/auth.ts cookie options); Bearer-only for iOS (X-Crew-Client).
- EXIF fixture test + unguessable, auth-checked blob URLs: tests/api/photos.test.ts (strips EXIF/GPS, resizes, keeps the
  upload under budget, serves it back only to the owner; a non-image and a missing purpose are rejected).
- Post-delete cascade crawl: tests/api/account.test.ts (after DELETE users/me the stream no longer shows the user, photos are
  gone, users/me 404s, re-signup is a fresh identity).
- Rate limits: auth 10/min/IP (auth.test.ts: the 11th is 429) and, added in this sweep, post creation 60/hour/user
  (tests/api/rate-limit-posts.test.ts: the 61st is 429 and a second user is unaffected).
- npm audit: 0 vulnerabilities (production and full trees) on 2026-09-04; CI runs `npm audit --audit-level=high`; Swift has
  zero dependencies by law (Charts and OSLog are first-party).
- P0/P1: none open. Known non-blocking: the welcome-back acknowledgement is not queued offline on iOS (asks once more on
  web at worst); the iOS tree is WRITTEN — UNVERIFIED end to end until a Mac compiles it.
- Look at: secrets rotation, backups and monitoring (T046) are not part of this sweep — they need the production environment.

### R-037 · 2026-09-04 · achievements awarding pass (T006 debt repaid; V45–V50 appended) · checkpoint — proceeding
- What was checked: the seed's own rules (earned once at threshold, never removed) became a contract: README kind
  `achievements` with the eleven counters defined as facts, `shared/vectors/achievements.vectors.json` V45–V50 (the shape
  checker recomputes every expected award list from the seed, so a fixture cannot disagree with the seed), and the TS
  engine `achievementsEarned` — `npm run vectors`: 51 vectors green on the TS engine (V45–V50 included). Counter
  derivations: `personal-records.ts` (a new best = beats every EARLIER logged best; never-logged weight → no PR; warm-ups and
  undone sets ignored; chronological regardless of input order), `crew-rules.ts` `fullPulseDays` / `fullPulseWeeks`
  (membership as of each day per V40; total ≥ crewMinMembers so a crew of one never earns "All in"; only complete Mon–Sun weeks
  starting after the user joined), engine tallies for perfect weeks / shields consumed / comebacks (engine memory; reverted
  with the day on undo like every other counter — verified by the unchanged apply/recompute vectors). Server:
  `recomputeAndStore` gathers the counters (`achievement-facts.ts`), appends the new ids (never removes), logs
  `achievement_earned`, and replies with `newAchievementIds` next to `earnedAchievementIds` (docs/api.md conventions) —
  `tests/api/achievements.test.ts`: the first post earns First flame once, the second post earns nothing, deleting the post
  never takes it back (V35 server-side), the first completion earns Showed up on the completion reply. Web: the celebration
  and Home show the unlocked titles + lines (`EarnedAchievements`, ids ride the URL from the mutation reply); the done page's
  PR badges now use the same engine rule the counter uses. iOS (unverified): `Achievements.swift`, `PersonalRecords.swift`,
  CrewRules full-pulse twins, tallies in `GamificationState`, `AchievementFacts.swift` (solo counters from the local store),
  the pass inside `GamificationLocal.apply` (unlocks fold into the celebration, E8), PR badges appended at completion,
  `VectorRunnerTests` runs kind `achievements`, `AchievementsTests` mirrors the web unit cases.
- Gap calls: `crewJoined` = 1 while a membership exists (leaving keeps the achievement); crew counters are the server's only —
  the phone computes the solo counters, so a crew unlock reaches an iPhone with the next reconciled state and has no
  celebration moment there; the personal-record rule requires an EARLIER logged weight (the first logged weight is a
  baseline, not a PR) — the same rule the web celebration already used; achievements are appended AFTER `levelUp`, before
  `prBadge`, per the README's canonical order.
- Doctrine: 117 Swift files clean; TS lint/typecheck clean; the pass is plain functions — no new layer.
- Look at: the Appendix A entry (Gamification — achievements awarding pass) and the 8.1 catalog line for V45–V50; the
  `Achievements` twin names (achievementsEarned) are identical on both platforms.

### R-038 · 2026-09-05 · E7 mid-workout swap + G9 rest timer on both platforms; S16 journal on web · checkpoint — proceeding
- What was checked (web, verified): `SessionSwap.tsx` — Swap on any strength exercise → 3–5 candidates that do the same job
  (SwapFinder with the tier read off the session's gear, like the plan editor) → [Just today] rewrites this session's snapshot
  only (running sessions are snapshots, E7) · [Update my plan] also PUTs the plan with the replacement in this weekday's workout,
  forward-only (Flow 8). `RestTimer.tsx` — starts on every checked work set, quiet inline countdown, Skip rest, off toggle,
  ±`restTimerAdjustStepSeconds` (15 s, GAP constant: G9 says adjustable, names no step), no sound on web. `/journal` — every post
  forever, newest first, photo/caption/tag, delete yours (two taps: arm, then delete for good; E3 post ≠ log), the "never alters
  XP or streak" copy; linked from Progress (S15 → S16); the a11y audit visits it. vitest: 28 files, 283 tests green (2026-09-05, incl. the 51 vectors, the achievements API test and the metrics report). Playwright: 20 passed, 1 skipped (the keyboard check on the phone descriptor), 0 failed — journeys ①③④ + the a11y/responsiveness audit incl. /journal on phone-375 (WebKit), tablet-768 and desktop-1280 in 59 s (2026-09-05). Lint/typecheck clean.
- What was written (iOS, unverified): `Features/Session/SessionSwap.swift` (candidates, swap with scope; the plan half goes
  through PlanLocal + a putPlan op), `SessionModel.swapCandidates / swap`, the Swap entry + SwapSheet + "for how long?" dialog
  in SessionScreen; RestTimerView gains the ± step buttons with the same constant.
- Gap calls: the 5.6 SessionModel map lists no swap action while E7 names the interaction — implemented as a plain helper
  inside the feature (5.6.6), not a map change; swapping keeps the row's sets and targets (the job changes, the volume does not),
  the same call the plan editor makes; the rest timer restarts on every checked set (supersets are excluded, so that is the
  whole rule).
- Look at: whether "Update my plan" should also rename the workout when the swap crosses a pattern — it does not (Flow 8 says
  names are yours to edit).

### R-039 · 2026-09-05 · T045 (the metrics half: "metrics live from first-party events") · checkpoint — proceeding
- What was checked: `npm run metrics [from] [to]` (`web/scripts/metrics.mjs`, plain driver, ESM) prints the Part IV readings
  against the successTargets constants: install → first post same day · D7 retention · posts/user/week · crew ÷ solo D7 ·
  crash-free (n/a until device crash reports exist). `tests/api/metrics.test.ts` seeds users/posts/memberships and checks every
  reading by hand (60% same day, 50% D7, 1 post/user/week, 1.0× crew÷solo, nulls on an empty window). The script reads
  `shared/spec-constants.json` directly — a tool, not app code; the same source the Generated files come from.
- Gap calls (documented in the script header): install = account_created; "same day" = the user's own signup dayKey (3 AM rule,
  their zone); D7 = any post on or after calendar day 7 after signup; posts/user/week over users who posted in the window;
  crew vs solo = D7 of members ÷ D7 of non-members.
- Deferred: TestFlight + web beta (credentials, Mac); a dashboard UI (the weekly read is this report; a saved Atlas chart is the
  smallest next step).

### R-040 · 2026-09-05 · T047 (the audit half: nothing rejected exists; doctrine lint clean) · checkpoint — proceeding
- What was checked: a grep of web/src and ios/Crew for every rejected list — Flow 4 (calorie/macro entry, barcode, AI food
  recognition, healthiness ratings), Flow 6 (comments, DMs, nudges), Plan (goals system, supersets, cardio), E1 (sloth avatar
  set), Build (Firebase, a second backend vendor, marketing email) — zero hits in code; the only matches are comments stating
  the rule ("NO nudge pings" in notification-eligibility.ts). `node shared/scripts/doctrine-lint.mjs`: clean, 119 Swift files.
  Build green, 36 pages (2026-09-05).
- Recorded: the launch checklist in docs/OWNER-REVIEW.md §8 (App Store submission itself needs a Mac and App Store Connect).

### R-041 · 2026-09-05 · Journey ② on web (8.4: Playwright runs "the same two" as iOS, plus ③ and ④) · T035 web half / T039 · checkpoint — proceeding
- What was checked: `web/tests/e2e/journey2.spec.ts` — a returning member (log out → /login → Home in its normal state, the bridge
  long gone) → fast-log (Home → Quick complete → celebration → Done: three taps, S07; "Showed up" unlocks on the first completion,
  E8; Quick complete hidden once today counts) → a crew-mate (through the API: register, join, react 🔥) → the member opens /crew and
  "🔥 1" sits on their own "Workout ✓" card. Green on phone-375 (WebKit), tablet-768 and desktop-1280 (3 passed, 21 s). Playwright
  now covers ①②③④ as 8.4 asks; the 5.2 tree already named journey2.spec.ts. The e2e matrix is 23 passed, 1 skipped.
- Test design: the returning state is seeded through the API (a meal post lights the flame; PUT plans makes today a workout day,
  since the Mon/Wed/Fri default would make the journey weekday-dependent); the crew-mate's UI side is journey ③, so here the mate
  acts through the API and only the receipt is asserted. The login form (T036) is exercised by a journey for the first time.
- Defect found and fixed: `QuickCompleteButton` looked up today's workout by the calendar date while Home judged the 3 AM day
  (E8) — between midnight and 3 AM the button found no workout and silently did nothing. It now reads `dayKeyFor` (the engine).
- Two test defects found by running the matrix later in the day: journey ④ logged "today's" workout on a Mon/Wed/Fri plan and
  so passed only on those days (it ran on a Friday, then on a Saturday: `/session/new` redirected Home) — `ensureTodayHasAWorkout`
  adds today to the member's own plan, shared with journey ②; and a cold `next dev` (every CI run) pushed first-hit compiles past
  the journeys' waits under three workers — `tests/e2e/warm-up.ts` (Playwright globalSetup) hits every page and route once before
  the first test, and the expect default is 10 s. From a deleted `.next`: 23 passed, 1 skipped.
- Gap calls: none new.

### R-042 · 2026-09-05 · Swift desk-check — a blind cross-file pass over the whole iOS tree · T013–T043 (iOS halves) · checkpoint — proceeding
- What was checked: a scratch cross-reference script (type names, static members, argument labels, memberwise inits — 2,188
  call sites, every finding triaged by hand) plus a read of every model, storage, API, engine, screen and test file against the
  server's actual response shapes. Fixed (all still WRITTEN — UNVERIFIED): missing `import SwiftData` in GamificationLocal,
  SessionModel and ProgressModel; `PlanLocal` and `OnboardingModel` were not main-actor-isolated while the Store and every caller
  are (`@MainActor` added; OnboardingModelTests follows); `UserDTO(…)` in SyncQueueTests lacked `welcomeBackAckDay:`; `await`
  inside `XCTAssertEqual` autoclosures (hoisted); `if case .success(let authorization)` without `= result` in SaveAuthScreen and
  LoginScreen; `MessageRow` declared a stored `body` beside its View body (now `text`); InviteScreen filtered members by
  `isCaptain`, a field the iOS MemberDot never had (compares captainId); a redundant `LocalSession: Identifiable` extension
  (PersistentModel already is); `AchievementCounters` could not decode a vector's partial `counters` (a decodeIfPresent init —
  the web twin's Partial); `outcome.awards.suffix(2)` compared to an Array; ExerciseChartView's `count - 1 - 1`.
- Infrastructure: the CI ios job piped xcodebuild through `xcpretty` (not on the runner; a formatter in the pipe hides the exit
  status) and set no signing overrides — now raw output, `CODE_SIGNING_ALLOWED=NO`, the xcresult uploaded on failure.
  `docs/commit-queue.sh` had two blocks with a literal `\n` instead of a line continuation (git add would have received a file
  named "n") — fixed, `bash -n` clean. `VectorFiles.load()` accepts the vectors as a folder reference ("vectors/") or flat.
  `CrewApp` honours the `-resetState` launch argument the XCUITests pass (sign out, wipe the store, clear the draft);
  `-seededReturningUser` (journey ②'s server-side seed) is not wired — docs/debt.md.
- Look at: the desk-check is a heuristic, not a compiler; the Mac pass is still the verification. Every DTO the phone decodes
  was compared field by field with the server's reply builders (publicUser, postResponse, the stream item, memberDots, pulse,
  pause, photo, crew): no mismatch remains.

### R-043 · 2026-09-05 · The sync contract between the phone and the server (5.6.3 replay) · T014 / T023 · checkpoint — proceeding
- What was found (reading both sides together): (1) `SyncOpDTO.payload` was `Data`, which Codable encodes as a base64 STRING;
  `syncOpSchema` requires a JSON object — every replayed op would have been rejected as `validation` and held. (2) `patchSession`
  names the session by its clientId (the only id an offline phone has) while the server looked it up by ObjectId only — every
  completion replay would have 404'd. (3) Swift's Codable omits nil optionals; `weight`/`holdSeconds` were `.nullable()` (null
  required, absent rejected). (4) The `deletePost` op kind had no server handler (retried five times, then held).
- What was done: `ios/Crew/Api/JSONValue.swift` — one JSON value enum; the payload is forwarded as the object it was queued with
  and the photo step edits that object, not bytes. `findOwnSession` accepts the server id or the clientId (web and sync alike).
  `weight`/`holdSeconds` are `nullish` and normalised to null on the way in. `deletePost` = `{ clientId }` →
  `deletePostByClientId` (an idempotent tombstone; the batch recompute is the truth). `tests/api/sync.test.ts` replays an iPhone
  batch end to end (session by clientId, absent nil fields, delete by clientId) — green. docs/api.md rows updated.
- Gap calls: `deletePost` names the post by clientId (a phone never learns the server id from a replay); `JSONValue` is the one
  new file in Api/ (5.2 tree addition, noted in progress.md).

### R-044 · 2026-09-05 · Constant hygiene — C7 means every number is named for ITS rule · checkpoint — proceeding
- What was checked: numbers smuggled through unrelated constants — `feedWindowDays` (7) as "days in a week" and as the default
  pause length, `chatMessageMaxChars` (1000) as a reps / weight / ops ceiling, `mobilityHoldsMax` arithmetic (432 s) as a hold
  ceiling and (3 + 3) as an emoji length, `mobilityHoldsMax` as skeleton rows, `initialsMaxLetters` as an array index, `1 + 1`
  arithmetic for "two sides" and "four lines".
- What was done: honest constants, each GAP-tagged in `shared/spec-constants.json`: planTargetRepsMax 100 · setWeightMax 1000 ·
  holdSecondsMax 600 · syncBatchMaxOps 1000 · crewEmojiMaxChars 16 · pauseDefaultDays 7 · skeletonPlaceholderRows 3 ·
  chatComposerMaxLines 4 · captionComposerMaxLines 3 · barbellPlateSides 2 · perSideHoldRepeats 2; "days in a week" reads
  `TimeUnits.daysPerWeek` on both platforms; DayKey reads its parts by position. Behaviour changes: a set over 100 reps or a hold
  over 10 minutes is now rejected (typos the old ceilings let through); a family emoji now fits a crew emoji. Drift, doctrine,
  seeds, lint, typecheck green.
- Look at: whether any of these deserves a spec number — they are input ceilings and layout counts the spec never states.

### R-045 · 2026-09-06 · The sync queue runs — nothing drove it · T014 / T024 · checkpoint — proceeding
- What was found (reading the app for the moment an op leaves the phone): `SyncQueue.processNext` existed and no code in the
  app called it — no launch hook, no foreground hook, no post-enqueue kick. Every createSession, patchSession, createPost,
  sendMessage, react, unreact, putPlan, pause and pushToken the phone queued would have stayed pending forever; the server
  would never have seen a phone-made workout, and journey ② could never have received a reaction. Two more rules were wrong
  once a driver existed: (1) `nextDue` skipped a head op whose backoff was running and sent the op behind it — a patchSession
  could overtake the createSession it depends on (the server 404s it, which the queue treats as poison: held forever);
  (2) `AppError.offline` counted as a failed attempt — five attempts over 31 s of airplane mode would have held every op for
  the E19 24-hour choice, the opposite of E6/8.6 ("post queued with chip · reconnect → auto-send"). And an op left `inFlight`
  by a kill between send and reply was never picked up again (8.6 "kill mid-queue → nothing lost").
- What was done: `Storage/SyncDriver.swift` — `drain()` (one pass, in order, waits a backoff out, stops on idle or offline),
  `recoverInFlight()`, and the moments: after every enqueue (`autoDrain`, the app's queue only — a test's queue is stepped by
  hand), on every foreground (CrewApp scenePhase), at launch and whenever the network returns (NWPathMonitor — Apple's
  Network framework; the zero-dependency law is untouched). `processNext` is strictly FIFO (`.waiting(until:)` while the head
  backs off); offline returns `.offline` with the op untouched. HomeScreen re-judges elapsed days on every foreground (E8/V04 —
  it only did so at first appearance). A dead session (`AppError.unauthorized` — 1C, the refresh token died) is treated the
  same way as offline: `.signedOut`, the op untouched until the next sign-in. Six SyncQueue tests added (offline · signed out ·
  FIFO under backoff · drain · in-flight recovery; the backoff test now fails with a 503, `HttpStatus.serviceUnavailable`).
  All WRITTEN — UNVERIFIED.
- Gap calls: no background sending — Part IV names no background execution and 8.6 asks that nothing be lost, not that it be
  sent while backgrounded; an op enqueued and backgrounded mid-send goes out at the next foreground. "Offline" is what
  URLSession reports (`Api.perform`); a reachable server that times out is a retryable failure and backs off as before.
- Look at: the 5.6.3 surface gained `drain` and `recoverInFlight` (an extension in SyncDriver.swift) and `ProcessOutcome`
  gained `.waiting` / `.offline` — the map lists `enqueue · processNext · reconcile · heldOver24h` and says nothing about who
  calls them; this is the smallest concrete answer.

### R-046 · 2026-09-06 · A signed-in phone with an empty Store, and the journey ② seed · T024 / T035 / T042 · checkpoint — proceeding
- What was found: 1C says a Crew user authenticates once per device — the Keychain outlives a reinstall — so a phone can wake
  signed in with an empty SwiftData store. Home judged "never posted" from local rows (`hasEverPosted`), so a veteran saw the
  bridge again (1D: the bridge ends when the first post EXISTS — it exists on the server), the flame read 0 until the first
  sync reconciled, and a workout done on web the same day let Quick Complete offer a second one. Login without a draft pulled
  the plan only (PlanLocal). The same gap is exactly what the XCUITest journey ② needs: a returning member on a phone that has
  never seen them.
- What was done: `Storage/ServerHydrate.swift` — `isEmpty` (neither a plan nor a post for the user) · `pullIfEmpty` (plan via
  PlanLocal; GET posts → LocalPost rows already delivered; GET sessions → LocalSession rows with their snapshots and V33
  `asPlanned`; GET users/me → the gamification copy — the second copy of reconcile's body, a third extracts (C1); the crew
  snapshot through CrewModel.refresh) · `pullIfEmptyBounded` (RootView shows Home's skeleton while it pulls, never longer than
  `hydrationMaxWaitSeconds` = 10 s — GAP, 1A/6.1). RootView hydrates before MainTabs when the Store is empty for the signed-in
  user; OnboardingModel's login path pulls the same. `Api.me()`, `Api.myPosts()`, `Api.mySessions()` and their DTOs (MeDTO,
  SessionDTO, the lists); `PostDTO.clientId` — the server's postResponse now carries `clientId` (posts.test.ts, green) so a
  hydrated row keeps the id `deletePost` names. JournalScreen renders `photoKey` (it showed local files only).
  ServerHydrateTests (four, in-memory) cover the writers; the network half is the Mac pass.
- Journey ② seed (T035): `CrewUITests/SeedClient.swift` registers the member and the crew-mate through the real API on the
  local dev server (a fresh x-forwarded-for per call for the G11 limiter), PUTs a plan for every weekday (the journey never
  depends on the day it runs), posts the first meal, creates the crew, joins the mate, hands the member's register reply to
  the app in CREW_SEED_SESSION, and after the fast-log polls the stream and reacts 💪 as the mate. `CrewApp` on
  `-seededReturningUser` resets state and stores that session — nothing else in the app is test-only: the phone hydrates as a
  reinstalled phone would. The test matches "Workout ✓" and "💪 1" by label wherever they live (PostCard combines its children
  into one accessibility element — the old `staticTexts[...]` lookups could not have matched). LaunchTests passes `-resetState`
  (a signed-in simulator would land on Home, not the hero); Journey1's header no longer names a CREW_UI_TEST server flag that
  never existed. Info.plist gains NSAllowsLocalNetworking (http://localhost from the simulator; docs/debt.md).
- Gap calls: hydration runs only when the Store has neither a plan nor a post for the user — a phone with any local truth is
  kept current by the queue and the reconcile, never overwritten by a pull; a hydrated workout post carries no
  sessionClientId (the server names the session by its id; nothing on the phone reads the link); sessions arrive complete
  (no date window — the same "forever" GET the journal uses).
- Look at: whether hydration should also run on every login (today: an empty Store only); whether `hydrationMaxWaitSeconds`
  deserves a spec number; whether a Debug-only Info.plist should carry the local-networking key.

### R-047 · 2026-09-06 · The Playwright matrix flaked on WebKit under eight workers — the browser side of the warm-up · T039 · checkpoint — proceeding
- What was found: two full runs failed differently on phone-375 only (once the signed-in a11y page, then journeys ①②③ — all
  at the same instant, at the same step: after "Build my week" the onboarding page showed an empty <main> under the dev
  overlay for the whole 10 s wait). The trace (network + console) showed every request 200, then "[Fast Refresh] rebuilding":
  the run used Playwright's default workers (half the cores — eight here, not the three the config comment assumed), so eight
  contexts opened cold pages at once; `next dev` compiles a page's CLIENT bundle on its first browser hit (the fetch warm-up of
  R-041 compiled the server side only) and broadcasts a Fast Refresh to every open page on every compile — a page mid-mount of
  a client-only component (OnboardingClient) lost its lazy chunk and never rendered.
- What was done: `tests/e2e/warm-up.ts` now also opens every page once in a headless Chromium, signed in as a warm-up account
  (registered through the API from an address outside the journeys' fresh-IP range), so every client bundle is compiled before
  the first test; `workers: 3` (one per viewport) in playwright.config.ts. Two full runs since: 23 passed, 1 skipped, 0 failed —
  the second from a deleted `.next` in 1.6 min (the CI condition).
- Look at: the flake was never a product defect — the same pages passed on Chromium at 768 and 1280, and on WebKit whenever the
  server was warm; CI (two cores) runs one or two workers and would have met it rarely, which is worse than often.

### R-048 · 2026-09-08 · The Swift engine compiles and its vectors pass — on Windows · T016–T020 / T008 · checkpoint — proceeding
- Why: the owner has no Mac and asked how to test the app during development. "Every iOS task is WRITTEN — UNVERIFIED" had
  been treated as covering ALL Swift, but only the SwiftUI/SwiftData half actually needs Xcode. `Crew/Engine/` is Foundation
  only — the open-source toolchain compiles it anywhere, and this machine has Docker.
- What was done: `ios/Package.swift` — a SwiftPM manifest over Engine/ + Generated/SpecConstants + Generated/SeedData +
  TimeUnits + Api/ApiModels (the DTOs are Foundation too), with a test target of the eight engine test files. `project.yml`
  stays the real project; Package.swift exists only for `swift build` / `swift test`. Verified here:
  `docker run --rm -v "<repo>:/repo" -w /repo/ios swift:5.10 swift test` → **18 tests, 0 failures**, including both vector
  runners. Both runners now assert their share of the fixture count (47 non-crew + 4 crew = 51), so a vector neither engine
  half runs fails the suite. CI gains an `engine-swift` job (ubuntu, `swift:5.10` container) — 8.1's "green on BOTH engines"
  is enforced on every push instead of waiting for a Mac.
- Defects a real compiler found that two blind desk-checks did not: `render-spec-constants.mjs` typed an array from element 0
  alone, so `plateSetLb [45, 35, 25, 10, 5, 2.5]` was emitted as `[Int]` — Swift rejected the file (TypeScript accepted the
  same values, which is why only Swift could see it); the generator now reads every element, and PlateMath's three follow-on
  errors went with it. `URL.appending(path:)` and `Bundle.urls(...)`'s `[NSURL]` are Apple-only — VectorFiles reads
  shared/vectors by `#filePath` and keeps the bundle lookup behind `#if canImport(Darwin)`. AchievementsTests' one SwiftData
  case moved to AchievementsLocalTests (Xcode target only). doctrine-lint now skips `.build`.
- Look at: the engine half is no longer "unverified" in the honest sense — it compiles and its vectors pass. The app half
  (SwiftUI, SwiftData, screens, SyncQueue storage) is unchanged: still WRITTEN — UNVERIFIED until a macOS runner compiles it.

### R-049 · 2026-09-08 · The path from a Windows machine to an iPhone · T045 / T008 · checkpoint — proceeding
- Why: the owner asked whether this is Expo/EAS. It is not — the client is native SwiftUI with zero dependencies (Appendix A,
  Part IV), so neither applies. The native equivalents are GitHub's macOS runners for the build and TestFlight for delivery,
  and neither was wired.
- What was done: `docs/testing-without-a-mac.md` — three stages (Windows today · GitHub macOS runners · TestFlight), each
  with its exact commands, costs and limits. The CI `ios` job now also starts the web harness and runs the CrewUITests
  scheme, so journeys ① and ② run on a simulator on every push; `CrewUITests/Screenshots.swift` attaches a screenshot at
  every named moment of both journeys and the xcresult is uploaded on EVERY run, so the app can be looked at from a machine
  that is not a Mac. `.github/workflows/testflight.yml` (manual dispatch) archives, signs and uploads to App Store Connect
  using an App Store Connect API key — no `.p12` exported from a Mac, no local Xcode; `ios/ExportOptions.plist` sends it
  straight to TestFlight.
- Defect found while wiring it: `Api.baseURL` was the hard-coded string `http://localhost:3000/api/v1`. A TestFlight build
  would have talked to the phone itself and every request would have failed; so would a device plugged into a Mac. It now
  reads two Info.plist keys (`CrewApiScheme`, `CrewApiHost`) that project.yml fills per configuration — http + localhost:3000
  in Debug, https + the deployed host in Release — either overridable on the xcodebuild command line.
- Gap calls: the bundle id stays `com.yourteam.crew` in the repo and the TestFlight workflow rewrites it from a repository
  variable, so nothing here names the owner's Apple account; `testFlightInternalTestingOnly` is set, so an upload never
  reaches external testers by accident.
- Look at: TestFlight needs the paid Apple Developer Program ($99/yr) and a deployed server — there is no free path onto a
  phone without a Mac, and the doc says so plainly rather than implying otherwise.

### R-050 · 2026-09-08 · The first CI run on GitHub, and a second macOS CI as the backup · T008 / T028 / T035 · checkpoint — proceeding
- What was checked: the repo went to `github.com/roccohandler/crew` (public) and GitHub refused every job with "your
  account is locked due to a billing issue". `codemagic.yaml` was written as a browser-configured macOS CI with the same
  two jobs (compile + unit + vectors; journeys ①② against the web harness) and a TestFlight workflow — never run. The lock
  turned out to be a $14.86 charge declined three times on an expired card; re-saving the card paid it and Actions started
  within minutes. Run 34224403865 attempt 3: contracts, web, engine-swift (the 51 vectors on Linux) and web-e2e (Playwright
  journeys ①–④ on three viewports, Chromium + WebKit) GREEN on GitHub's machines — the first time any of it ran off this PC.
- Verdict: the `ios` job failed before compiling: the image (Xcode 26.6) ships iPhone 16e / 17 / 17 Pro simulators and no
  "iPhone 16". Both CI files now pick the newest plain "iPhone NN" the image has at run time (`xcrun simctl list devices
  available`, plain shell, tested against a sample of the runner's list → "iPhone 17"). Nothing in the app changed. The
  first Xcode compile of the SwiftUI half is the next push; R-042 and R-048 removed what a blind read and the Linux
  toolchain could find — the remaining errors are the ones only Xcode reports.
- Look at: two CI descriptions now exist (Actions + Codemagic) and must not drift — `docs/debt.md`; Codemagic is the backup
  and stays unrun unless GitHub locks again.

### R-051 · 2026-09-08 · The Swift app compiles under Xcode and its unit suite runs on a simulator · T013–T025 / T040–T042 / T008 · checkpoint — proceeding
- What was checked: run 34228816686 (the push carrying F03): the whole `Crew` target and the `CrewTests` target compiled
  under Xcode 26.6 (iOS 26.5 SDK, iPhone 17 simulator) with zero errors, and 49 XCTest cases ran — 48 passed, including BOTH
  vector runners: 47 + 4 = all 51 shared vectors green on the Swift twin under the real toolchain, so 8.1's "both engines"
  gate now holds under Xcode and not only on Linux (R-048). Also green: SyncQueue (9), ServerHydrate (4), HomeModel edge (5),
  LapsedUser (6), Onboarding (3), Session (3), SwapFinder (2), PlanGenerator (2), Achievements (4 + the SwiftData case),
  ShellStates (3), SpecConstants (2).
- Verdict: one failure, and it is the test's. `HomeModelTests.testBridgeUntilTheFirstPostThenWorkoutState` expected Friday
  of a Mon/Wed/Fri plan to be "Push day"; the generator cycles Push → Pull → Legs over the sorted days (plan-templates.json's
  documented GAP; the web's journey ④ asserts "Monday · Push day" by the same rule), so Friday is "Leg day" and HomeModel
  was right. The expectation is corrected (F04); no product behaviour changed. The compile-fix loop took four pushes for four
  one-line defects — a property named `set` parsed as an accessor, a Double/Int comparison, a doubly-unwrapped optional,
  and this expectation; the desk-checks (R-042) and the Linux build (R-048) had removed the rest.
- Look at: the SwiftUI screens have compiled but not yet run — journeys ① and ② (CrewUITests) are the next stage and the
  first time a screen renders; the eight main-actor warnings stay in debt; the ios job now carries a 45-minute timeout so a
  hung simulator cannot burn the six-hour default.

### R-052 · 2026-09-08 · The app runs on a simulator: the first four screens, one layout gap, one server rule · T021 / T028 / T035 · gap + checkpoint — proceeding
- What was checked: run 34243884907 (the push carrying F04): the unit suite went 49/49, then the CrewUITests scheme built,
  installed the app on the iPhone 17 simulator and drove it. `LaunchTests` passed (the bone frame, no splash). Journey ①
  walked the hero, the days question, both single-selects and the plan reveal, and filled the save screen — four screenshots
  came back in `UITestResults.xcresult` and were looked at: S02 hero, S03 days, S04 "Your week, built." (Monday · Push day
  with its three holds, Wednesday · Pull day), S05 "Save your plan". Three of the four are right. It failed at Home (the bridge
  never appeared), and journey ②'s seed failed earlier at `POST auth/register → 400`.
- Verdict, the 400: the server's `timezoneSchema` accepted only `Intl.supportedValuesOf("timeZone")` (plus a hand-added
  "UTC"); Foundation names a device set to UTC "GMT" — which is what a CI simulator is — and older phones report legacy names
  ("US/Pacific"), none of them in that list. A zone the runtime can format with is a zone the server can compute day keys
  with (E8), so the rule is now `new Intl.DateTimeFormat(…, { timeZone })` succeeding; "Mars/Olympus" still fails. The seed
  now quotes the response body in its error so the next 400 explains itself. (Stated as the cause from the evidence at hand;
  the dev-server log is now an artifact so the next run can confirm it.)
- Verdict, S03 (GAP): the spec asks for seven ≥ 56 pt circular toggles in one row; 7 × 56 pt plus any gap is wider than every
  iPhone inside the 24 pt margins, and the screenshot shows the row clipped on both edges and the Continue button stretched
  edge to edge. Conservative in-spec call: the tap area keeps ≥ 56 pt of height and the full column of width (≥ 44 pt, 6.3);
  the circle draws at the column width. Tagged `// GAP:` in PlanQuestionsScreen.swift.
- Also: journey ① waits 20 s (not 10) for Home after Save and prints the save screen's texts when it fails; CI warms every
  API route before the journeys (the Playwright warm-up already did — `next dev` compiles on first hit) and uploads the
  dev-server log; SaveAuthScreen's `allSatisfy { $0 == nil }` on non-optional values (a compiler warning) became `isEmpty`,
  same behaviour.
- Look at: the S03 circle size on a 375 pt phone is about 45 pt — smaller than the 56 pt the spec pictured; if the owner wants
  56 pt circles the row must wrap or the margins shrink, which is a design decision, not a build one.

### R-053 · 2026-09-08 · Journeys ① and ② green on a simulator — the Phase 2 and Phase 3 gates, as far as a simulator can take them · T028 / T035 · checkpoint — proceeding
- What was checked: run 34246649543 (the push carrying F05, `ec19295`): every job green for the first time. Unit suite 49/49
  (all 51 vectors on Swift under Xcode), then `CrewUITests`: LaunchTests (8.5 s), journey ① (69.8 s) and journey ② (49.8 s)
  all PASSED on the iPhone 17 simulator against the local harness. Journey ① = fresh install → hero → three questions → the
  built week → save with email → Home's bridge → post → the flame lit. Journey ② = a seeded returning member (plan for every
  day, one earlier post, a crew with a crew-mate) → Home → session → 3/3 sets → celebration → the crew-mate's 💪 arrives on the
  workout card. The dev-server log shows the phone's queue delivering through `POST /api/v1/sync` and the reaction landing.
- The nine screenshots were pulled from the result bundle and looked at, screen by screen: hero; the days question (the row
  now fits); "Your week, built."; "Save your plan"; Home in the bridge state (grey flame, 0/3 ring, one oversized CTA — the
  run fell on a Tuesday, so the CTA was "Start your streak — post a meal"); Home after the post ("Rest day — recovery is part
  of the plan." / "Today's posted. Streak safe.", flame lit, 🔥 1); journey ②'s Home (PUSH DAY card, Start workout, Quick
  complete, the crew strip with today's dots); the celebration sheet ("3/3 sets · 0 min", "+125 XP", 🔥 2, "Showed up",
  "Found your crew", Share to crew); the Crew screen ("NIGHT SHIFT 🌙 · 1/2 today", member strip, "Sam joined the crew", the
  JOURNEY TWO workout card with 💪 1).
- Defects seen and fixed (F06): the day toggles drew as ~23 pt circles — the F05 sizing (`aspectRatio` on a flexible frame)
  collapsed to the letter's height; now the circle is inscribed in a column-wide, 56 pt-tall frame, so it is ~48 pt on a
  402 pt phone and ~43 pt on a 375 pt one, with the full column tappable. Home's card said "1 exercises + mobility" for
  journey ②'s one-exercise seed plan — pluralised on both platforms. Not changed, for the owner to judge: the Crew stream is
  bottom-anchored like a chat, so with two items the top two-thirds of the screen is empty canvas under the "Crew" title.
- Verdict: journeys ① and ② hold on a simulator. What a simulator cannot prove stays open for the phone: gestures, haptics,
  the camera, push, the offline matrix (8.6), VoiceOver and Dynamic Type (8.5), the launch signposts (8.8). Phase 2 and 3
  are "green on a simulator", not yet "green on a device".
- Look at: whether the bottom-anchored Crew stream reads as intended when a crew is new; the celebration's "0 min" for a
  workout logged in seconds (true, but the copy could hide durations under a minute).

### R-054 · 2026-09-08 · Stage 2 begins: the accounts exist, three vendor limits checked, the beta tier recorded · T045 / T046 / T008 · checkpoint — proceeding
- What was checked: the owner's three screenshots. App Store Connect → Apps already lists "Crew — Train. Track. Show up."
  (iOS 1.0 Rejected — the earlier codebase) and a second app, so the paid Apple Developer Program is active and Stage 2's
  "enrol" step was done before it started; the page also carries the banner that the Program License Agreement was updated
  and awaits the Account Holder (unaccepted, the App Store Connect API refuses everything, cloud signing included). Atlas:
  project `Crew2`, cluster `Crew2`, 0 B of 512 MB (the free M0). Vercel: "Max's projects", Hobby, two unrelated projects.
- Three facts verified against the vendors' own pages rather than assumed: (1) Vercel Hobby cron jobs run at most once a
  day and a more frequent schedule fails the deployment ("Hobby accounts are limited to daily cron jobs") — so
  `web/vercel.json` with `* * * * *` would have failed the very first deploy; it now says `0 12 * * *` and the loss (no
  per-minute reminders in the beta) is in debt with its one-line repayment. (2) Resend delivers from `onboarding@resend.dev`
  only to the account's own address until a domain is verified. (3) Xcode's cloud signing issues a Distribution certificate
  only for an App Store Connect API key with the Admin role — the workflow comment and Stage 2 said App Manager, which would
  have failed the first TestFlight run with "Cloud signing permission error"; both now say Admin. Also corrected: a
  TestFlight build is App Store-signed, so its push tokens are production tokens — `APNS_ENVIRONMENT=production`, not the
  `sandbox` the step list had (sandbox is for a Debug build installed from a Mac the owner does not have).
- Also fixed: `commit_task` now skips any block whose message is already in `git log` — every committed block in the queue
  (fix or history) used to re-stage whatever had changed in the files it names, which is exactly how S38 was mis-attributed
  and would have swept this turn's ledger edits into F01. Verified read-only here: F05's message resolves to `ec19295`,
  F06's to nothing. The same dry check over all 69 blocks found 13 HISTORY blocks with no commit of their own (S38 and
  twelve docs/test blocks — swept, as S38 was), so the HISTORY section now ends the script with `exit 0`; the working tree
  holds exactly the eleven files F06 and F07 name, nothing else.
- Choices made without asking (the owner answers in their next message): the beta stays on the free tiers — Hobby with the
  daily cron, M0 open to the world, the sandbox sender — each in `docs/debt.md`; the existing App Store Connect record is
  reused (its bundle id becomes `CREW_BUNDLE_ID`, `APPLE_BUNDLE_ID`, `APNS_BUNDLE_ID`) rather than a new record with a new id.
- Verdict: nothing behavioural changed; `web/vercel.json` is the only runtime file touched. Stage 2's step list is now
  written around what exists. Next: the owner does the Atlas step and reports the record's bundle id.
- Look at: whether $20/month for Vercel Pro is worth having reminders in the beta (the agent recommends Hobby until a second
  tester joins); whether to keep the old record's name "Crew — Train. Track. Show up." for the new app.

### R-055 · 2026-09-08 (evening) · Cold-start full audit: every claim re-verified by command, the tree diffed against 5.2, six gaps closed · T001–T047 · checkpoint — proceeding
- Why: the owner reported the build incomplete, "notably the server", and asked for an audit that trusts no checkmark. A fresh
  session read the spec in full and re-ran every verify command (the table is at the top of `docs/progress.md`, rewritten from
  scratch): generate/drift/vectors/seeds/doctrine clean; `npm run typecheck`, `lint`, `test` (28 files, 285 tests), `vectors`
  (51), `build`, `npm audit` (0) all green; `docker … swift test` 18/18; `gh run view 34252964640` — every one of the five
  GitHub jobs green at HEAD `e9fe41f`, the macOS job included (compile, 49 unit tests, journeys ①② on an iPhone 17 simulator).
- The server, specifically: 32 route files, 45 exported methods; every route the spec (5.2, Part IV) and `docs/api.md` name
  EXISTS with a dedicated integration test in `tests/api/` plus the four standing checks — except `PATCH crews/[id]/mute`
  (standing checks only) and `POST events` (documented in api.md since R-004, never built, never called). The "unfinished
  server" impression is not borne out by the suite; the two gaps are closed below.
- The one red result: `npm run e2e` = 22 passed · 1 skipped (by design) · 1 FAILED — journey ① on phone-375/WebKit, "Post"
  stayed disabled after the caption was filled under three workers; alone it passed in 8 s. Cause: a `fill` that lands before
  hydration seeds React's value tracker with the exact text, so the retry's identical `fill` fires no change event.
  `fillWhenHydrated` now waits on the labelled field itself and clears before every fill. No product code changed.
- Secrets: only `.env.example` is tracked; `git log --all --full-history -- "*.env"` names only it; `.env`/`.env.*` are
  ignored. Two local files held real values — `web/.env` and a byte-identical stray `ios/.env` (deleted; nothing under ios/
  reads it). FINDING, fixed: `next dev` reads `web/.env`, and the Playwright harness pinned only the variables the tests
  needed, so a local `.env` with the beta's Resend and Blob keys would have reached the harness (no journey mails or uploads,
  but nothing forbade it). `dev-server.mjs` now pins every vendor variable to "" — each lib stays on its substitute. Also:
  `.env.example` lacked `APP_STORE_URL` (read by the join page) — added. The owner is rotating the Resend and Blob keys.
- Gaps closed (verify commands run, all green): Q03 `POST /api/v1/events` (5.6.4 shape; `logClientEvents` keeps the client's
  `at` and stamps `receivedAt`; 4 tests; the standing-checks generator discovered it — 139 checks) and the web funnel
  (`lib/funnel.ts` queues `onboarding_hero · days · experience · plan_built · saved` in sessionStorage pre-auth and flushes
  after sign-up, so the 1C "hero → Home" reading is computable server-side; a member's rebuild records nothing) · Q04 the
  mute test (per member, visible on `users/me`, outsider 404, bad body 400) · Q05 `tests/engine/validators.test.ts` — every
  input limit at the limit and one over (8.3) · Q06 DayKey unit tests on BOTH engines (`tests/engine/day-key.test.ts`,
  `CrewTests/DayKeyTests.swift` in `Package.swift`; docker swift test 25/25) — 8.3 named them and neither engine had them.
- Tree diff against 5.2 (the owner asked for every extra: keep with a reason, or delete). DELETED: `codemagic.yaml` (never
  run, a second CI that must not drift, the owner's email in a public repo; debt repaid) · `ios/.env` (stray duplicate).
  KEPT, with reason: `.github/workflows/testflight.yml` (the only path to TestFlight without a Mac, T045) · `ios/Package.swift`
  (the engine on the open-source toolchain — the 8.1 "both engines" gate on Linux, R-048) · `ios/project.yml` (XcodeGen makes
  `Crew.xcodeproj` on the runner; the .xcodeproj is generated, not committed, R-005) · `ios/ExportOptions.plist` (TestFlight
  export) · `ios/scripts/doctrine-lint.sh` (5.3 CI-blocking doctrine lint, the Swift half) · `docs/commit-queue.sh` (git is
  hook-blocked for the agent; the owner runs the queue) · `docs/api.md` (T006 deliverable) · `docs/ratification.md`,
  `docs/OWNER-REVIEW.md`, `docs/testing-without-a-mac.md` (the continuous-build amendment's own artefacts) · `web/vercel.json`
  (the cron schedule, T033/T046) · `web/scripts/metrics.mjs` (T045 metrics) · `web/.prettierrc` (5.3 formatting machine-owned)
  · `web/AGENTS.md` + `web/CLAUDE.md` (written by `next dev` itself on every start; committing them keeps the tree clean) ·
  `web/src/app/api/cron/notifications` + `api/v1/photos/*` + `crews/[id]/{stream,mute}` + `api/v1/events` (api.md tree
  additions, R-004) · `/journal` and `/onboarding` outside the `(app)` group (S16; onboarding is pre-auth by Flow 1) ·
  `shared/scripts/{render-*,check-*,vector-*,doctrine-lint}.mjs` (generate.mjs split under the C9 cap) · `ios/Crew/AppError.swift`
  (C13's one enum), `TimeUnits.swift` (unit arithmetic, not spec numbers) · Api/ and Storage/ per-resource files (C9 cap; names
  in progress.md "plan notes") · `.gitattributes`. SPEC PATHS ABSENT and why: `ios/Crew.xcodeproj` (generated on CI) ·
  `Onboarding/SoloOrCrewScreen` (S06 removed v1.9) · `Plan/WorkoutEditorScreen` + `RebuildFlow` (folded into PlanScreen /
  PlanDayCard / PlanModel — a C10 split is queued as optional) · `CrewTests/DayKeyTests.swift` (ADDED today) ·
  `CrewUITests/OfflineSessionTests.swift` + `CameraDeniedTests.swift` (ADDED today, see below) · `Crew/MessageRow` +
  `CreateCrewScreen` were inside StreamList.swift / InviteScreen.swift (C10 "one screen per file") — SPLIT today into their own
  files, no behaviour change.
- Dependencies: `web/package.json` holds exactly the allowlist (next react react-dom mongodb zod sharp @vercel/blob jose apns2
  resend; dev typescript vitest prettier eslint) plus the six dev-only additions the Registry already logs (R-005); nothing else.
- Scope sweep: no calorie/macro/barcode/leaderboard/follower/superset/cardio/food-recognition code; no `*Manager`/`*Service`/
  `*Handler`/`Base*` classes; no `protocol` declarations in ios/Crew at all; no comments/DMs.
- 8.4 state probes ADDED (WRITTEN — UNVERIFIED; the CI ios job runs the whole CrewUITests scheme, so the next push is their
  first run): `CameraDeniedTests` (a simulator has no camera, exactly like a denied phone: the S11 permission-denied line, no
  Snap, Library + text still offered, the text post lights the flame) · `OfflineSessionTests` (Resume-after-kill: set 1 checked,
  `app.terminate()`, relaunch signed-in → the Resume banner, the set still done). Airplane mode stays a device item (8.6).
- Verdict: the repo is where the ledger said, with the corrections above. Nothing behavioural changed on the server except the
  new events route; the web gained the funnel calls; iOS gained two files split out, one unit test file and two UI probes.
- Look at: the funnel event names in api.md (yours to rename before any dashboard reads them); whether the two UI probes pass
  on the next CI run (their first); the Plan/ C10 split (WorkoutEditorScreen, RebuildFlow) if you want the 5.6 file names
  literal.

### R-056 · 2026-09-08 (night) · The server is live and the first TestFlight archive signed itself; the upload wanted an icon · T045 / T046 · checkpoint — proceeding
- What was checked: the deployed server. Vercel project `crew` at `https://crew-eta-one.vercel.app`, built from master `e9fe41f`
  once the Root Directory was saved as `web` (the first two builds ran at the repo root: "No Next.js version detected"). `/`
  answers 200, `/api/v1/users/me` 401. The variables the owner could not land in the browser went in through the Vercel CLI
  (`vercel env add`, the owner typing the secret values; the agent added only the public ones). Journey ① against the
  deployment reached the save screen and got "Something went wrong on our side": the runtime log says `MongoServerError:
  bad auth`, so `MONGODB_URI` carries a wrong password — the owner is regenerating it. No test user was created.
- The TestFlight workflow ran for the first time (run 34281494452) against a NEW App Store Connect record, bundle id
  `com.maxwellcuenca.crew` (the owner chose not to reuse the rejected earlier record). XcodeGen, the full Release compile
  and `xcodebuild archive` with cloud signing SUCCEEDED — the Admin-key requirement (R-054) held. `-exportArchive` with
  `destination: upload` then failed on App Store Connect's validation: ITMS 90022 / 90713 / 90023 — the bundle has no app
  icon and no CFBundleIconName. The spec names no icon; the project had no asset catalog at all.
- Fixed: `ios/Crew/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — the owner's own 1024 × 1024, alpha-free PNG from the
  earlier product (the rugged sloth with the ember stripe; sharp confirmed the dimensions and the missing alpha channel,
  which App Store Connect insists on) — in the single-size catalog format, plus `ASSETCATALOG_COMPILER_APPICON_NAME` in
  `project.yml`; Xcode derives every size and injects CFBundleIconName. Nothing else changed in the app.
- Verdict: cloud signing from a Windows machine through GitHub's macOS runner is proven; the next run should upload. Open
  behind it: the Atlas password, the Blob connection, the APNs key, the Services ID for web Sign in with Apple.
  UPDATE, minutes later: run 34282978517 (build 2, commit 344791a, which also carried the audit's F08–F13) went through
  every step — archive, export, upload — and App Store Connect accepted the build. T045's "TestFlight" half is done up to
  the owner's own phone. Then the server: the regenerated Atlas password went in, register still answered 500, and the
  runtime log had moved on from `bad auth` to `MongoInvalidArgumentError: Database names cannot contain the character
  '.'` — `MONGODB_DB` no longer held `crew` (edited in the dashboard at some point). Reset through the CLI, redeployed:
  `POST auth/register` → 201 against Atlas at 22:03Z, and journey ① PASSED against production at 22:08Z (19.6 s, one
  viewport): the whole stack — Vercel, Atlas, the JWT cookies, the plan generator, the first post, the flame — holds on
  the real services. Photos remain the one dead path until the Blob store is connected. One finding from cleaning up:
  `DELETE users/me` on the smoke account answered 500 although the account was gone (`users/me` → 404 right after) — the
  cascade completed and the "account deleted" email then failed, because Resend's sandbox sender delivers only to the
  account owner's address; a completed, irreversible cascade must not be reported as a failure → gap-queue Q12.
- Look at: the icon — it is the earlier product's mark and can be replaced by dropping another 1024 px opaque PNG on the
  same path; whether "Crew: Train. Track. Show up." is the name you want on TestFlight.
- UPDATE: the owner rejected the earlier product's mark the moment it showed in TestFlight ("an old application that
  shouldn't be involved"). The icon is now drawn from the Ember system itself: the streak flame in ember `#FF6600` with a
  bone core on the bone canvas `#FAF8F5` — the same frame the launch screen shows, so the tap and the first frame match.
  Source: `shared/brand/app-icon.svg`; rendered to the 1024 px opaque PNG with sharp (`.flatten().removeAlpha()`), which is
  what App Store Connect insists on. Build 1 (the sloth) stays in TestFlight until build 2 replaces it. Run 34285838041
  then uploaded the flame build ("Upload succeeded", 22:29Z): the third TestFlight run in a row to sign and archive cleanly.

### R-057 · 2026-09-09 · The smoke-test amendments A1–A8 built end to end: PPL rotation, cardio, the rest-day Home, the two-level plan editor, the crew tab, the journal, settings · T021–T027, T031, T036–T041 · checkpoint — proceeding

- **Checkpoint.** The owner's first review of the app on their iPhone (build 0.1.0 (2), 2026-09-08 evening) became eight
  owner-directed amendments in Appendix A (A1–A8) with the contract in `docs/improvement-plan-2026-09-08.md`. Fifteen
  research and code briefs preceded the plan (in the session scratchpad; the decisions they support are in the plan's §0).
  Two contract agents (shared/engine, server/client), eight client agents (five iOS folders, three web areas) and one Swift
  compile-risk reader implemented it; this entry records what was checked and what the owner should look at.
- **What was checked, by command (2026-09-09 morning).** `node shared/scripts/generate.mjs && check-drift.mjs` → all seven
  Generated files match; `check-vectors` → 52 vectors across 7 files (V51 appended, V01–V50 byte-identical); `check-seeds` →
  110 exercises (86 strength · 15 mobility · 9 cardio), 45 template lists consistent; `doctrine-lint` → clean (165 Swift
  files, 1 CSS file). Web: `npm run typecheck` clean · `npm run lint` clean · `npm test` **34 files, 340 tests passed** ·
  `npm run vectors` **52 passed** · `npm run build` green (new routes `/plan/[kind]`, `/log-cardio`, `/privacy`, `/terms`) ·
  `npm run e2e` **23 passed, 1 skipped (by design)** across 375 / 768 / 1280 — journeys ① ② ③ ④ and the a11y sweep, which
  now audits `/plan/push`, `/log-cardio`, `/privacy` and `/terms`. Swift engine under Docker (`swift:5.10`): **43 tests,
  0 failures** — all 52 vectors on the Swift engine plus the new PlanRotation (9), DayLabel, SessionSummaryLine and the
  rewritten PlanGenerator property test (127 day subsets × 3 × 3 → always the three PPL workouts).
- **What is WRITTEN — UNVERIFIED.** Every SwiftUI/SwiftData file (about sixty changed or added under `ios/Crew/Features`,
  `Storage`, `Api`, `Shared`) — no Xcode here. Each implementer self-checked labels, optionals and switches; a separate
  compile-risk read cross-checked every call against its callee. The macOS CI job is the compiler: the owner runs the queue,
  pushes, and the agent reads `gh run view`. The XCUITest journeys will also need their selectors re-read against the new
  Home/Plan copy on that run.
- **Verdict.** The amendments are in the code on both platforms with the doctrine intact (files under the caps, numbers through
  the constants, twins named identically, vectors append-only, gamification numbers untouched). Deviations from the plan are
  in `docs/debt.md` (2026-09-09 lines): no snackbar timer, no cardio timer, the seed's unused full-body templates, the
  placeholder legal pages, no SwiftData migration, the blocked-user strip rule.
- **What the owner should look at.** (1) Appendix A 2026-09-08: ratify or strike A1–A8, the GAP constant
  `distanceDecimalScale`, and `planEstimateRoundingMinutes`. (2) The ≤ 2-day question: PPL rotates at every frequency as
  asked; the evidence (Schoenfeld 2016, ACSM 2026, Pedersen 2022 in `r-programming.md`) favours full-body at 1–2 days — say
  the word and the seed's Full-Body A/B comes back for ≤ 2 days. (3) On the phone after the next TestFlight build: the rest-day
  Home (Post a meal · Log cardio · Bonus workout · the what's-next line), the Plan week map → editor → sheet, the Crew tab with
  the strip on top and the invite card, the Journal's day labels and summary lines, Settings › profile photo / notification
  toggles / blocked people / legal pages. (4) The Blob store is still not connected on Vercel — photo posts from the phone keep
  failing until it is; the A3 sync fix now keeps the local streak honest while they wait.
