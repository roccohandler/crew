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

## R-058 — 2026-09-09, after CI run 34354352786: two test bugs fixed, and the owner's "check it locally first" answered (F24)

- **What the run said.** The whole rewritten app compiled; 89 unit tests ran; 3 assertions failed in two `SyncDeliveryTests`
  cases. Both were the tests' own mistakes, not the queue's: they enqueued at `Date()` and stepped the queue at a 1970 clock,
  so the head op was `.waiting` (5.6.3 backoff — an op is not due before its `nextAttemptAt`), and `attachPhotoKey`
  re-serialised the payload with `JSONSerialization`, whose default escapes `/` as `\/`, so a `contains("blob/abc")` read
  false on a payload that was in fact correct. The journeys never ran — the unit step failed first.
- **What changed.** The two tests share one clock (`now: when` on enqueue and processNext); `SyncDelivery.attachPhotoKey`
  and `PostPayloadPhotoStripper.strip` re-serialise with `.withoutEscapingSlashes` (the wire JSON is identical either way —
  `\/` and `/` decode to the same string — so no server or vector is affected; the stored payload now reads as the encoder
  wrote it). No behaviour rule moved; no vector changed.
- **The owner's question** ("how can this get checked locally before it fails so many times on GitHub?") — three answers,
  each verified here: (1) `shared/scripts/swift-xref.mjs`, a compiler-free cross-reference check over every Swift file
  (declared types → members, initializer labels incl. memberwise ones by Swift's rules → every `Type.member`, `Type(...)`,
  `Type.f(...)`, typed `.case` literal checked). Calibrated to zero findings on the tree that compiled in this run (165 files,
  341 types, 0.24 s); a scratch copy with the four historical errors re-introduced (the dropped `PlanLoadState.offline`,
  `PlanLocal.replace(plan:)`, the unqualified `Stepper(value:in:step:)`, a struct field removed under its callers) reports
  all four. It is now the first step of the `contracts` job. (2) `expectNoHorizontalScroll` measures again under a wide
  fallback font — the a11y spec passed on all three viewports here (11 passed, 1 skipped by design), and this is the check
  that would have caught the 11 px the runner's DejaVu Sans produced. Its first full-suite run then caught a real one: the crew header's name + pulse row pushed the pulse 9 px past a 375 edge in journeys ② and ③ (`CrewHeader.tsx` gains `row--wrap`; both journeys 6/6 green on the three viewports after the fix). The failure message now names the element. (3) The `ios` job runs the unit suite and the
  journeys even when the first fails, and a `verdict` step writes both logs' error lines and totals to the run summary.
- **What is still not checkable here** and is said so in docs/testing-without-a-mac.md: anything that needs SwiftData or
  SwiftUI to execute — test logic against Foundation behaviour (this run's two bugs are exactly that) meets the macOS job
  first. A fourth option was NOT taken without the owner: letting the agent push a throwaway branch through the GitHub API
  so the macOS job compiles uncommitted work before the queue runs — it is a remote git write by the agent, which the
  owner's hook rule reserves for them.
- **Verdict.** WRITTEN — UNVERIFIED for the two Swift files (the next `ios` run is the proof); DONE-VERIFIED for the check
  script (`node shared/scripts/swift-xref.mjs` clean; probe: 7 findings covering the 4 seeded errors), the e2e change
  (`npx playwright test tests/e2e/a11y.spec.ts`: 11 passed, 1 skipped; `npm run typecheck` clean; eslint clean), the
  workflow file (parses), doctrine-lint clean.

## R-059 — 2026-09-09, run 34360394481 read from Windows: the set row was never a button, and never fit a phone (F25)

- **What the run said.** contracts (now with swift-xref) ✓ · web ✓ · web e2e ✓ · ios engine ✓ · ios unit 89/0 · journeys 3 of 5:
  journey ① and OfflineSessionTests (Q09) failed at the same query, `app.buttons` matching "set 1 of" after "Start your
  first workout".
- **How it was read without a Mac.** The `ios-test-results` artifact's `.xcresult/Data` files are zstd-compressed; Node 22
  decompresses them, and the text that starts `Application, 0x…` is the accessibility hierarchy XCUITest captured at the
  failure. It showed the session screen OPEN — "Push day", Machine Chest Press, three rows labelled "…, set 1 of 3, 10 reps"
  — with each row typed `Other`, not `Button`: SetRow is an HStack with a tap gesture and an accessibility label, which is a
  plain element to XCUITest and to VoiceOver (E20 asks for "double-tap to complete", a button's hint). The same dump gave
  frames: the exercise name at x = −41, Skip at x = 418, the Complete button 516 pt wide — on a 402 pt window. The row's
  fixed parts (a 64-pt label, two steppers of 44 + 64 + 44, the 44-pt check, four gaps) sum to 476 pt before any padding;
  an HStack never shrinks them, so the card, the scroll content and the bottom bar all grew past the edge.
- **Why it passed before.** 2026-09-08 was a Tuesday: journey ①'s Mon/Wed/Fri plan put it on the bridge's meal branch and
  it never touched a set row; Q09 (all seven days) has failed at this exact line since its first run. Today is a Wednesday.
- **What changed (F25).** SetRow: `.accessibilityAddTraits(.isButton)`; a `ViewThatFits` — one line where it fits, on a
  phone the steppers under the label (the web's `.setrow` flex-wrap, mirrored); the stepper label's minimum width is a touch
  target, not the ring diameter. SessionScreen: exercise names wrap. Journey ①: selects all seven days, so it always logs
  a set (the meal-first bridge is CameraDeniedTests' path). `CrewUITests/JourneySteps.swift`: the day-toggle step shared on
  its third occurrence, and `expectOnScreen` — journey ① and the offline test assert that the set row, the first Skip and
  Complete lie inside the window: the iOS twin of `expectNoHorizontalScroll`, so a layout that passes past the edge fails
  the journey instead of hiding in a screenshot.
- **Checked here.** `node shared/scripts/swift-xref.mjs` clean (166 files, 342 types); doctrine-lint clean. Not checkable
  here: the SwiftUI layout and the trait — the next `ios` verdict is the proof (WRITTEN — UNVERIFIED).

## R-060 — 2026-09-09, run 34364030257: the row is a button and fits; its centre was the wrong control (F26)

- **What the run said.** Every job green but `ios`, and `ios` only at the journeys: unit 89/0; journeys 3 of 5. Journey ①
  and the offline test both found the set row as a Button, both on-screen assertions passed (the dump's frames: the card
  338 pt wide, Skip at x = 345 on a 402 pt window — F25's layout holds), and both tapped it. The tap changed the row's label
  from "…, 10 reps" to "…, 10 reps, 0.0 lb": XCUITest, like VoiceOver's activate, touches an element at its centre, and the
  centre of the wrapped 96-pt row is the steppers line — the weight stepper's minus took the touch (weight nil → 0) and
  the set stayed unchecked. Journey ① then pressed Complete and got "Check off at least one set and this counts."; the
  offline test never saw ", done".
- **What changed (F26).** The check button is the row to assistive tech: it carries the full "Machine Chest Press, set 1
  of 3, 10 reps, 135 lb, done" label (weight written as displayed) and the double-tap hint; the row container is
  `.accessibilityElement(children: .contain)`, so the steppers are reachable as their own buttons and now say what they
  change — `Stepper` gains `noun` ("Decrease reps", "Increase weight", "Decrease minutes" in CardioRow, "Increase sets" in
  the exercise sheet). The row's whole-area tap gesture stays for fingers (Flow 3). The journeys' `firstSet` query now
  resolves to a 44-pt button whose centre is unambiguous. Nothing about behaviour or copy moved.
- **Checked here.** swift-xref clean (the `noun:` label is checked at all three call sites), doctrine-lint clean. The
  rest — the tap, the check, the celebration, the resume after a kill — is the next `ios` verdict (WRITTEN — UNVERIFIED).

## R-061 — 2026-09-09, run 34367618719: journey ① green end to end; the last journey lost its session to an unsigned build (F27)

- **What the run said.** contracts · web · web e2e · ios engine ✓; ios unit 89/0; journeys 4 of 5 — journey ① passed for the
  first time on a simulator (install → seven days → plan → save → bridge → set 1 checked → Complete → "+XP" → Done → the
  bridge gone), with journey ②, CameraDenied and Launch. OfflineSessionTests checked set 1, photographed it, killed the app
  — and the relaunch woke on the hero: "One plan. Every week…", Build my week, I have an invite, Log in. Signed out.
- **Why.** The job built the simulator app with `CODE_SIGNING_ALLOWED=NO`. An app that is never signed carries no
  entitlements, and on a simulator an app without entitlements cannot write the Keychain: every SecItemAdd answers
  errSecMissingEntitlement (-34018), which KeychainStore does not inspect (C6: four plain calls). The session therefore lived
  in memory only, and the kill took it. Journeys ① and ② never relaunch, so only Q09 could see this — and it has been Q09's
  failure since its first run, behind the set-row defects fixed in F25/F26. A TestFlight build is signed for real; the
  phone is unaffected.
- **What changed (F27).** Both xcodebuild steps sign ad hoc — `CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=-
  CODE_SIGNING_REQUIRED=NO`: no certificate, no team, no profile, the entitlements embedded (the fix Apple's own thread on
  -34018 names: give the app an entitlements file). OfflineSessionTests asserts Home ("Today") before it looks for the Resume
  banner and says "signed out after a kill — the Keychain did not keep the session" with the screen's first lines, so the
  next failure of this kind reads as what it is. docs/testing-without-a-mac.md records the rule.
- **Checked here.** The workflow parses; swift-xref and doctrine-lint clean. Whether ad-hoc signing accepts the project's
  entitlements (Sign in with Apple, push, associated domains) without a team is the next run's first line; if it refuses, the
  verdict names the setting to change. WRITTEN — UNVERIFIED.

## R-062 — 2026-09-09, run 34371679615: the signed build wants an Info.plist for the test bundles (F28)

- **What the run said.** Ten seconds into the first ad-hoc-signed simulator build: "Cannot code sign because the target does
  not have an Info.plist file and one is not being generated automatically … (in target 'CrewTests')". Both steps stopped
  before compiling. The signing override itself was taken ("Using codesigning identity override: -").
- **What changed.** `GENERATE_INFOPLIST_FILE: YES` on CrewTests and CrewUITests in `ios/project.yml` — the app target
  already has `Crew/Info.plist`; the test bundles never needed one while nothing was signed. project.yml parses.
- **Verdict.** WRITTEN — UNVERIFIED; whether ad-hoc signing accepts the app's entitlements without a team remains the next
  run's first line (R-061).

## R-063 — 2026-09-09, run 34373681818: the signed build works; the signup field met Automatic Strong Password (F29)

- **What the run said.** The ad-hoc-signed simulator build compiled and its unit suite passed (89/0): signing with the app's
  entitlements needs no team. Journeys 2 of 5 — journey ② and Launch green; journey ①, CameraDenied and Offline all stopped
  at "Save your plan". The three failure dumps agree: the form still up, `At least 8 characters.` under the password (the
  validation error, SaveAuthScreen line 49), the SecureTextField holding one character (`value: •`), Birth year focused.
  The dev server saw no register POST from the app; the unsigned run (34367618719) had five.
- **Why.** Signing turned on Password AutoFill. A `.newPassword` field answers focus with iOS's Automatic Strong Password:
  the generated text replaces what XCUITest types, one character survives the keyboard swap, `submit()` fails its guard
  silently. The F27 Keychain fix is what exposed it — the same build that keeps a session across a kill is the build that
  offers passwords.
- **What changed (F29).** `SaveAuthScreen`: the password field is `.textContentType(.password)` — iOS still offers to save
  the username/password pair at signup and autofills it at login (S05); the strong-password suggestion is deferred
  (docs/debt.md, 2026-09-09, T022). `JourneySteps.swift`: `dismissSystemPrompts()` installs a UI-interruption monitor that
  answers Save Password / permission prompts with the quiet button (Not Now, Don't Allow, OK); the four tapping journeys
  call it in setUp — a signed build shows those prompts, an unsigned one never did.
- **Checked here.** swift-xref clean, doctrine-lint clean. WRITTEN — UNVERIFIED: the next `ios` verdict decides.

## R-064 — 2026-09-09, run 34377505665: every job green, all five iPhone journeys; TestFlight build 3 started

- **What the run said.** contracts (generate · drift · vectors · seeds · doctrine · swift-xref) ✓ · web ✓ · web e2e 23
  passed, 1 skipped ✓ · ios engine (Linux) ✓ · ios: 89 unit tests, 0 failures; journeys 5 of 5 on an iPhone 17 simulator —
  journey ①, journey ②, CameraDenied, Launch, OfflineSessionTests. Q09 (the resume-after-kill probe, red since its first run)
  is closed: with the signed build the Keychain keeps the session, the relaunch lands on Home with the Resume banner, and
  the checked set is still there.
- **The day's chain, for the record.** Six fix commits after the A1–A8 rewrite compiled: two test bugs (F24), the set row
  that was never a button and never fit a phone (F25), the row activated at its centre (F26), the unsigned build's dead
  Keychain (F27), the signed build's Info.plist (F28), Automatic Strong Password on the signup field (F29). Each was read
  from the run's own result bundle on Windows; the local checks added in F24 (swift-xref, the wide-font overflow sweep)
  ran before every push and stayed clean.
- **Verdict.** The A1–A8 amendments are DONE-VERIFIED on both platforms by the machine's own record (CLAUDE.md rule 6: Part
  VIII tests green on both engines, the journeys green). TestFlight build 3 (`gh workflow run testflight.yml -f
  build_number=3`, run 34379733146) is the owner's phone pass; the phone-only checks (gestures, camera, push, airplane
  mode, VoiceOver, Dynamic Type) stay on the OWNER-REVIEW device checklist.

## R-065 — 2026-09-09 evening, TestFlight build 3 crashes at launch on the owner's phone (F31, provisional)

- **What is known.** Build 3 (run 34379733146) installed on the owner's iPhone and crashes immediately. The crash log is
  requested (the phone's Analytics Data `.ips`, mailed to the PC). Build 3 is the first build after A1/A2 reshaped the
  SwiftData schema (LocalPlan → trainingWeekdays + ordered workouts; LocalSession.workoutKind; LocalSetLog.distanceMeters;
  LocalPost.summary) and the beta has no migration (debt, 2026-09-09).
- **The likely line.** `Store.init` did `fatalError("SwiftData container failed")` when `ModelContainer(for:)` threw — which
  is what an old store does under an incompatible schema. The simulator never saw it (every journey starts from
  `-resetState` or a fresh simulator); build 2's store on the phone is exactly the case nobody had.
- **What changed (F31).** For the on-disk store only: on a container failure the store file and its -shm/-wal are removed
  and the container is created again; only a second failure is fatal. The phone loses unsynced local rows (the queue's
  pending ops included) and re-hydrates from the server on the next signed-in frame — acceptable for a beta of one, and
  said so in debt.md; a VersionedSchema migration is still owed before release. swift-xref and doctrine-lint clean.
- **Provisional.** If the `.ips` names another line (the API URL guard, the seed decode), that fix follows in the same
  build; F31 stays because a schema change must never brick the app again.

## R-066 — 2026-09-09 evening, build 2's crash report read: a token-refresh data race (F32)

- **The report.** `"build_version":"2"`, captured 07:49 local after 37 minutes in the app. `EXC_BAD_ACCESS (SIGBUS)`,
  `KERN_PROTECTION_FAILURE` writing at the address of Foundation's `URLComponents` value witness table — `swift_retain` was
  handed a metadata pointer where an object was expected, on `com.apple.root.user-initiated-qos.cooperative` (an async
  task) inside Crew code whose registers hold URLComponents, Date and URLRequest values: an API call. A second cooperative
  thread was inside `SecItemDelete` from Crew code — KeychainStore.write deletes before it adds, so that is `AuthStore.store`.
- **The race.** `AuthStore` was a plain `@Observable` class. `Api.send` awaits `validAccessToken()` from a nonisolated context,
  so a refresh — and its `store(session)` writing four properties and the Keychain — ran on the cooperative pool, while the
  main thread read `currentUser` / `isSignedIn` (RootView, every model) and a second concurrent call (sync drain, Home
  refresh, crew poll) could refresh at the same time. Two writers and readers on the same Strings: torn pointers, a
  `swift_retain` of garbage. Debug builds and the simulator journeys never reproduced it; -O did, on the phone.
- **What changed (F32).** `AuthStore` is `@MainActor`. Every model that reads it is already main-actor isolated, Api and
  the photo/settings calls `await` it, SessionActions and SyncQueue are main-actor, the tests that touch it are `@MainActor`
  classes — no call site changes. Keychain I/O now happens on the main thread (four small calls per sign-in; acceptable).
- **Still open.** Build 3's launch crash has no log yet (the owner's report was build 2's); F31 (the store) is the standing
  hypothesis. Both fixes ship in one push; TestFlight build 4 follows the green run. WRITTEN — UNVERIFIED.

## R-067 — 2026-09-09, run 34405436792: one default argument, and the check that now catches its kind (F33)

- **What the run said.** `HomeModel.swift:40:163: error: main actor-isolated property 'currentUser' can not be referenced
  from a nonisolated context` — the only unique error across all 91 files (the module was fully type-checked). F32 made
  `AuthStore` `@MainActor`; a parameter's default value is evaluated in a nonisolated context even inside a `@MainActor`
  type, so `welcomeBackAckDay: String? = AuthStore.shared.currentUser?.welcomeBackAckDay` stopped compiling. The many
  `store: Store = .shared` defaults are unaffected: a main-actor `static let` read is a warning in Swift 5 mode, and those
  warnings have been in the log since the first Xcode run — it is reading a mutable PROPERTY through it that is an error.
- **What changed.** The default is `nil`; `HomeScreen` passes `AuthStore.shared.currentUser?.welcomeBackAckDay`, the same
  way ProgressScreen, SettingsScreen and CelebrationScreen already read `units` from the account (5.6.6 holds: the screen
  passes data, the model keeps the rule). `HomeModelEdgeTests` passes the ack day explicitly at every call, so E4's
  behaviour is untouched and no test changed.
- **The local check grew with it (the standing rule).** `swift-xref` now collects every `@MainActor` type and reports a
  parameter default that reads `<MainActorType>.shared.<property>`. Verified both directions: clean on the fixed tree
  (166 files, 342 types), and a scratch copy with the exact line restored reports it at HomeModel.swift:42. Three classes
  of macOS-only error are now caught on Windows: removed members, mismatched argument labels, main-actor defaults.
- **Verdict.** WRITTEN — UNVERIFIED (swift-xref and doctrine-lint clean); the next `ios` verdict is the proof, and
  TestFlight build 4 follows it.


## R-068 — 2026-09-18, the builder's readings of A22 G1 (a) for the two engines (continuous-build mode; each open to the owner)

- **The ruling.** Rest days are exempt; the streak counts planned training days only; a rest day neither requires nor breaks
  it; a bonus or cardio day pays its XP and leaves the streak unchanged; an all-rest plan counts any completed workout day;
  perfect week = every planned workout day completed; the meal-carrying vectors retire by marker; new vectors from V66.
- **Reading 1 — `dayRolledOver` keeps its shape.** `hadRequirement` was always the caller's word; it now means "an uncompleted
  planned training day of the CURRENT plan, not paused". iOS derives it in `GamificationLocal.judgeElapsedDays` from
  `store.plan(for:)?.trainingWeekdays` (the one-liner `PostModel` already used); the server derives it in the recompute fold
  from `findPlan(userId)` threaded into `recomputeState`. Plan history is not kept (PUT plans is forward-only, no
  effectiveFrom), so an unposted past day is judged by the plan of today — the conservative reading, because the alternative
  (plan-effective dates) is a new data model. A post's stamped `isPlannedDay` stands as before (V36's note).
- **Reading 2 — `postCreated` gains an optional `plannedWeekdays: [Int]`** (the plan's ISO weekdays; `[]` = an all-rest plan).
  The streak counts a completed workout on a planned day, or any completed workout under an all-rest plan; nothing else counts
  a day. The first-post-of-day XP (+25) stays for any first post of a day — V25's day-one total 125 is a planned workout and
  survives; a bonus day pays 25 + 25 and the streak stands (the repeal of V30). Why an optional field rather than reusing
  `isPlannedDay: true` for all-rest plans: that would pay +100 for an all-rest workout, widening XP; the ruling widened only the
  streak.
- **Reading 3 — perfect week from the plan.** With `plannedWeekdays` present, a week is perfect when every planned weekday of
  that week carries a completed workout (`week.plannedDone`), so a skipped planned day or a partial first week is never perfect;
  `everyDayPosted` is dropped. A legacy fixture WITHOUT the field keeps the pre-A22 clause (`week.planned ⊆ plannedDone` and
  every day posted), so V02, V16, V25, V31, V34, V41 and V42 stay green unedited — a fixture-only branch, the shape A22 already
  accepted for meal XP.
- **Reading 4 — comeback stays calendar-quiet.** `quietDaysBetween` counts non-paused calendar days since the last COUNTED day;
  the crew banner (`comebackBanner`, V39) counts post days the same way, so they agree. A two-day plan (Mon/Thu) therefore sees
  three quiet days every week and fires a comeback weekly — recorded here and in debt.md, not widened; the owner may narrow
  "quiet" to planned days with a registry entry and new vectors.
- **Reading 5 — the `retired` marker.** A retired vector carries `"retired": { "by": "<Appendix A entry>", "reason": "…",
  "replacedBy": ["V66", …] }`; its `expect` is never edited; `check-vectors.mjs` requires the three fields when present and
  still requires V01–V50 + V18b to EXIST; both runners skip it (the iOS `checked == total − crewKinds` assertion subtracts
  retired non-crew vectors); the README gains the contract. 23 retire: the 21 meal carriers (V01, V03, V09–V12, V13–V15, V17,
  V18, V18b, V20, V21, V24, V26, V28, V29, V35, V36, V43), V04 (a rest day's silence broke the streak) and V30 (a bonus day
  incremented it). V11 and V20 retire for their meal payloads only and return as workout-only fixtures; V36's `recompute`
  coverage returns with `trainingWeekdays` in the case; V24's `text` kind and V26's `mealXpDailyCap` return as fixture-only
  branches no client reaches (A22's constraint).
- **Verdict.** READINGS, not rulings: each is the smallest change that satisfies the owner's words on both engines with the
  surviving vectors unedited. Any of the five may be overturned by an Appendix A line; the vectors they add are append-only.

- **R-069 · 2026-09-18 · A22 G1 (a), the comeback — READING (supersedes R-068 reading (4)).** G1 (a) names no comeback rule. The
  engine's `comebackMissedDaysThreshold` counts "missed days"; under G1 (a) a rest day is never missed ("neither requires nor
  breaks"), so the engine counts only non-paused PLANNED weekdays strictly between the last counted day and the counting post
  (`missedDaysBetween` on both twins, tagged `// GAP:`). Consequences: a Mon/Wed/Fri plan earns a comeback after three missed
  planned days (Mon, Wed, Fri → the next Monday, V82), not after one missed Monday (V68 shows none); an all-rest plan never earns
  one (nothing can be missed); a pre-A22 fixture (no `plannedWeekdays`) keeps the calendar count, so every surviving vector runs
  unedited. The crew's comeback BANNER (V37–V39, `quietDaysBetween`) is a different rule — silence in the stream — and is untouched;
  "engine and banner agree" in R-068 (4) is withdrawn. Why this reading: it awards less and follows the ruling's letter; the calendar
  reading would pay +50 for a single missed Monday on every three-day plan. Overturnable by an Appendix A line; V82 is append-only.

- **R-070 · 2026-09-18 · A22 G1 (a), the rest-day BRIDGE — READING.** 1D's rest-day bridge CTA was "Start your streak — post a
  meal"; the meal is gone and the ruling asks nothing of a rest day. The conservative in-spec reading keeps §1D's ONE control and
  gives it the bonus workout A3 already offers on every rest day ("Start a bonus workout" → the next rotation workout; iOS opens the
  BonusWorkoutSheet, web `/session/new?bonus=<kind>`); the copy stops promising a flame a rest day cannot light: "Your plan rests
  today. Your first flame lights on your first planned workout." A workout-day bridge is unchanged. TodayState.rest loses its
  `posted` payload on both platforms — nothing on a rest day depends on a post any more; the rest card reads "Nothing to do here. A
  rest day asks nothing of your streak." and carries no control (A18.4's premise line is deleted with the requirement it explained).
  Tagged `// GAP:` in TodayCard on both platforms. Overturnable by an Appendix A line.
- **R-071 · 2026-09-18 · A22 G1 (a), the streak nudge — READING.** "Flow 4's rhythm reminder" nudged when "nothing was posted yet
  today"; under G1 (a) the streak is at risk only on a PLANNED day with no completed workout, so `streakRiskDue` gates on
  `isPlannedDay && !workoutDoneToday` (a rest day never nudges; the morning reminder already worked this way) and the copy names the
  open workout — "Push day is still open. Finish it and the streak holds." — instead of the plate journal. The usual-post-time window
  is unchanged. Recorded as a reading because G1 (a) speaks of the streak, not of notifications.
- **R-072 · 2026-09-18 · A22 G2 / MEAL_POST_REMOVAL_MAP "Server" — READINGS.** (1) POST posts is REMOVED rather than narrowed: no
  client creates a post through it once the composer is gone (a workout post rides PATCH sessions/[id] `post`); GET posts and
  posts/[id] GET · PATCH caption · DELETE stay. (2) G11's post-creation limiter moves to that PATCH when the body carries `post` —
  the spec limits post creation, and that is where posts are created now. (3) "Blob serves profile photos only": the read
  (`readablePhoto`) serves `purpose: "profile"` rows alone — a legacy post photo is 404 to everyone, including its owner, until the
  account's cascade deletes it; the upload accepts "profile" and nothing else. (4) A queued `createPost` sync op from an older phone is
  refused per op as `postsRetired`, non-retryably, the A21.2 chatRetired shape — the phone holds it, the batch lands. (5) Legacy meal
  and text rows stay readable on both platforms (the journal prints their caption or "Post"); nothing writes their kinds, photo keys,
  meal tags or the backfill label again, and PostResponse drops those three fields. (6) The SwiftData LocalPost keeps its legacy stored
  properties (photoKey, localPhotoPath, mealTag, earlierToday) untouched — dropping them is a schema change that waits for W9's
  VersionedSchema; nothing writes them.

- **R-073 · 2026-09-18 · A22 × A17.2, the rest-day hole — READING + FIX.** A22 took the rest card's control and the meal row away
  (~108 px of content). Home bottom-anchors its day group (6.7, A17.2), so on a rest day all of that slack became ONE gap above the
  card: 217 px (25.4%) at 393×852 and about a third of a Pro Max — the hole A17.2 removed, and the first red of the layout gate since
  it was written (it had passed in CI only because that run fell on a training day). On a REST day the group now FLOATS — the slack
  is split above and below it (web: `.stack--floating`; iOS: a second Spacer on `.rest`) — so no single gap outgrows the group it
  introduces, the log rows stay in the thumb half, and every other state keeps its bottom anchor. The layout test measures both a rest
  day and a training day on any weekday (`ensureTodayIsARestDay`). Why a reading: A22 did not speak about layout; A17.2's limit did.

- **R-074 · 2026-09-18 · W8, the nutrition addendum — READINGS (each the smallest in-contract answer; overturnable by a registry line).**
  (1) The ENERGY estimate rounds to `energyKcalRoundTo` (50 kcal): V58 requires 176 lb to derive the same lines as 80 kg, and only
  a rounded energy does; an estimate also should not read as a measurement. (2) With the ratified maintenance factors the FAT FLOOR
  never binds (20 % of 33 kcal/kg ÷ 9 = 0.73 g/kg > 0.5 g/kg at every bodyweight), so V59 asserts the guard at both bodyweight
  bounds instead of a binding case that cannot exist. (3) BOUNDS the addendum leaves unnamed are named constants and nothing more:
  bodyweight 30–300 kg, 0–500 g per entry, 0–1000 g per target, 100 saved meals, a 20-character slot label, 50 logs a day — typo and
  abuse bounds, never a judgement of a food (clause ⑤ is untouched). (4) Today's CALORIE line is the three macros in Atwater
  kilocalories on both sides, so it always agrees with the grams the user set; the kg × 33 estimate lives on the methodology screen
  and in `estimate`. (5) V63's mechanism is `gameEvents(logs)` — the one place a macro entry could become a game event, empty by
  construction; the vector checker refuses any other count. (6) V64's mechanism is `bodyweightOf(targets)`: the bodyweight is read
  out of the targets document and exists nowhere else. (7) `savedMeals` gains a unique `clientId` (the sessions precedent), so the
  phone's `upsertSavedMeal` is idempotent. (8) Settings' "Delete my nutrition data" is `DELETE nutrition/targets { everything: true }`
  rather than a seventh route, and is network-only on the phone (no op kind — the endPause precedent). (9) The GATE: under 18 every
  route is a 404 (the surface does not exist, so nothing names it); a missing birth year is `birthYearRequired` and is stored ONCE
  through PATCH users/me behind the 13+ floor; `users/me.nutrition` exposes the availability and never the year. (10) The FAST-FOOD
  SEED ships six of the ~ten proposed chains — Chick-fil-A, Chipotle, Panera Bread, Starbucks, Subway, Wendy's — each read on
  2026-09-18 from the chain's own publication (Starbucks and Wendy's by rendering their own product pages, which carry the numbers
  only after JavaScript runs). Four are HELD, with their reasons and any verified rows in docs/fast-food-seed-sources.md: McDonald's
  (its site refused every non-browser client, and reading it meant presenting a script as a browser — held for the owner's word),
  Burger King (the only readable official document is dated November 2022), Five Guys (publishes per component only, and its patty
  row does not reconcile with its own calories), Taco Bell (publishes through a third-party host only). `fastFoodChainCount` says 6.

- **R-075 · 2026-09-18 · W8c, the nutrition screens — READINGS (each the smallest in-contract answer; overturnable by a registry line).**
  (1) CLAUSE ② SAYS AN OVERAGE NAMES TOMORROW "IN THE SAME BREATH", and the addendum's Today cites clause ②: one ink sentence sits
  under the four lines whenever any of them is over — "Tomorrow starts from your full targets." — a fact, never a verb aimed at the
  user, and silent on a day at or under target (`MacroDay.horizonText`, both engines). (2) EXACTLY ON TARGET prints no "0 to go": the
  amounts already say it, and a zero is never a verdict (A8). (3) THE BAR's target marker sits at `macroBarTargetPercent` (80 %) of
  the track so an overage has room to show as LENGTH; the colour never bends (§7.4 ⑤). (4) "TODAY CARRIES NO INK-FILLED PRIMARY" is
  read as the populated Today (Q3: the Home row is the action); its FIRST-RUN state is one number and one ink button ("Estimate my
  targets"), and the birth-year ask has one too — a state with a single action keeps Part III law ①'s one primary. (5) THE HOME ROW
  reports a COUNT ("2 logged") or nothing (A8) — never grams, never a verdict. (6) THE GRAM STEPPERS step by `macroGramsRoundTo` AND
  the number is typeable on both platforms: forty grams is eight taps otherwise. (7) WEB: "Saved meals & template" is two routes under
  one segment (the ProgressSegments precedent, A19.4), and the chain picker prints the chain's NAME alone — the seed's neutral icons
  are SF Symbols, which the phone draws. (8) THE BODYWEIGHT FORM speaks the account's CURRENT weight unit (a bodyweight typed in
  pounds reads in kilograms after the switch, A9's `weightIn`); one parser on both engines accepts "80.5" and "80,5" and rounds to a
  tenth. (9) THE PHONE PULLS NUTRITION ONLY WHEN NUTRITION OPENS (never at launch, §6) and ONLY while no nutrition op is queued — a
  pull REPLACES the phone's rows, so while the phone is ahead it waits (the A3 reconcile-guard precedent); a row arriving from the
  server names its meal by server id and is translated to the clientId the phone keys by. (10) A QUEUED DELETE IS IDEMPOTENT on the
  server: a log or a meal that is already gone is the state the op asked for, so the op is delivered, never held as poison for the user
  to "retry" (E19 is for real failures). (11) AN ACCOUNT WITH NO BIRTH YEAR sees the Settings rows; its "Nutrition targets" row leads to
  where the year is asked (the page on web, Today on the phone). A user cached by a build that predates `user.nutrition` reads as
  ABSENT until the next signed-in frame refreshes it — the surface is never shown on a guess. (12) WEB WRITES SURVIVE THE PAGE GOING
  AWAY: `apiFetch` sets `keepalive` on every JSON write (never on a file upload), and an undo tapped while its log is still on the way
  up waits for that create to land — found by journey ⑤, which reloaded straight after an optimistic delete and read the old day.
  (13) AN ERROR ON A NUTRITION SURFACE IS INK (`.notice`): the semantic red does not exist there (law ⑥'s exception), and
  `launch-audit.mjs` now fails CI on one. (14) `shared/copy/*.json` is the ONE place shared words live; its numbers are
  {placeholders} the generator resolves from spec-constants (C7), `check-copy.mjs` holds its rules, and the methodology page's four
  sources were each read on 2026-09-18 before being linked (Kerksick 2018 for 25–35 kcal/kg, Jäger 2017 for 1.4–2.0 g/kg protein, the
  Institute of Medicine's 2005 AMDR for fat at 20–35 % of energy, FAO paper 77 for the Atwater 4 · 4 · 9).

- **R-076 · 2026-09-18 · A23, the education layer — BUILT ON THE OWNER'S ORDER OF 2026-09-18 (item 5), WITH THE DRAFT COPY; READINGS.**
  The copy document says nothing reaches a screen until it is ratified line by line; the owner's later order says build the
  mechanism now with the copy in ONE file and the note from Max marked DRAFT — the order governs, and ratification is an owner task
  that edits one file (`shared/copy/education.json`; both platforms regenerate from it, `check-copy.mjs` holds rule 5's twelve words).
  (1) THE NOTE IS MARKED ON SCREEN: a secondary-ink "Draft" under "A note from Max" while `page.note.draft` is true; the launch audit
  prints a NOTE line for it and never fails on it. (2) SEEN-STATE as the draft proposed it: `User.whispersSeen`, PATCH users/me UNIONS
  (`$addToSet`), an unknown id is refused; the phone keeps server ∪ a per-account UserDefaults set and re-sends the WHOLE set on every
  signed-in frame that finds the server behind; the web does the same with localStorage. (3) BEFORE AN ACCOUNT EXISTS (the plan reveal's
  two whispers) the set is the device's own and joins the account at the first signed-in load; a log out forgets it, so the next
  person on the phone sees the reveal's whispers. (4) RULE 3 BEATS A PLACEMENT: on the phone S13 Invite is a SHEET, and a whisper
  never renders in a sheet — so `how.invite` sits under the crew-of-one card's "Invite friends" on the Crew tab, the invite control
  that screen itself carries (on the web the invite controls are inline, and it sits under them as drafted). For the same reason the
  reveal's two whispers render at signup only: a REBUILD is a sheet on the phone. (5) "THE FIRST TAP ANYWHERE" is one simultaneous tap
  gesture on the root view (never taking a tap from the control under it) on the phone, and the first pointer or key event on the web,
  so a keyboard user clears a whisper too. (6) `how.swapSkip` sits under the ACTIVE exercise's Swap · Skip on the phone (A21.11 shows one
  card) and under the first exercise's on the web; `how.overload` under the first row that prints a last-time line. (7) `why.crews` needs
  a crew, not a crew of one (`crewMinMembers`). (8) S19 under 18 OR with no birth year on file: the Protein section drops its numeric
  sentence and its source, and the three nutrition whispers leave the list — the page reads `user.nutrition === available` and says
  nothing about the omission. (9) The whisper ids are GENERATED (`WhisperId` on both platforms), so a call site naming an id the copy
  file does not hold cannot compile.

- **R-077 · 2026-09-18 · 6.9 SCREEN DENSITY (A25) MEETS THE NUTRITION ADDENDUM'S TODAY — a GAP reading, the most conservative one that
  keeps both.** The addendum (§4, ratified the same day, earlier) stacks four lines, "Your template", "Quick add" with three steppers,
  the day's log and a link on ONE screen; built that way it measured more than two scroll-lengths at 375 pt. 6.9 is pass/fail and part
  of every NEW screen's definition of done: "when a screen needs a second scroll-length of content to do its job, the content is split
  into a destination screen, never compressed to fit". So Today keeps its ONE job — the lines and one-tap template logging (with its
  undo) — and carries two labelled outline buttons: "Quick add" (its own screen, whose one filled primary is Add, returning to Today)
  and "Logged today · N" (its own screen, every entry with its visible Delete; the button is absent with nothing logged, A8), plus the
  addendum's text link to Saved meals & template. Nothing the addendum gives Today is lost, and every piece is one tap away behind a
  clear, well-sized control, which is 6.9's own sentence. S19 "How Crew works" is NOT split: A23's draft defines it as "one scrolling
  page" of prose reached from Settings → About — it is itself the destination, and it holds no controls but source links. Both are the
  owner's to overturn; docs/OWNER-REVIEW.md lists them.

- **R-078 · 2026-09-18 · W9, launch readiness — READINGS (each the smallest in-order answer; overturnable by a registry line).**
  (1) THE STORE'S VERSION ONE IS BUILD 150's SCHEMA. The stored models have not changed since 2026-09-10 (f814300), so one V1 covers
  every TestFlight build a tester can still have; it is declared from the CURRENT classes for the ten models that did not change and
  from a nested `CrewSchemaV1.LocalPost` for the one that did. A store older than that matches no version and takes F31's path
  (start over, the server refills) — the plan makes the common update lossless and leaves the safety net where it was. The version
  number is a constant (`storage.storeSchemaVersion`), because a literal 2 is a lint error and a schema version is a spec number.
  (2) THE LEGAL PAGES SAY ONLY WHAT THE CODE DOES, and leave three blanks: the operator's legal name, a governing-law sentence and
  the EULA choice are facts and decisions the builder does not have, so none is invented. The contact is the server's
  `SUPPORT_EMAIL`, never an address typed into the repository. The copy lives in `shared/copy/legal.json` (web only — the phone
  opens these pages in its in-app browser) and passes check-copy like every other shared string. (3) STORE SCREENSHOTS REUSE THE A24
  TOUR rather than the journeys the order names: the tour is the journeys' successor for pictures (seeded through the real API with a
  crew, a streak and six workout days, every step already a named shot), and a second set of screenshot tests would be a second
  mechanism for one job (C5). The required sizes are reached by picking the simulator per App Store display class at run time and
  REPORTING the pixels (`SIZES.md`), because the runner image, not this repository, decides which simulators exist. (4) "T047 RUN AND
  ITS FINDINGS FIXED" is `shared/scripts/launch-audit.mjs` in the contracts job: eighteen scans, clean; its two findings on the way
  (a `danger` class on the nutrition Settings notice, now ink — R-075 (13); and "healthy adults" inside a publisher's own title,
  which is a citation and not Crew labelling a food — the exemption is written into the script) were settled in W8c. (5) `TEST_EMAIL_ALLOWLIST` "confirmed unset in production" is answered as far as this machine can see: no server code
  reads the name, so production cannot behave differently because of it; the variable list itself is the owner's to open (debt).
  (6) THE LISTING COPY promises nothing on A21.13's Not Building list and states no health outcome; the age-rating answers are left
  to the owner (A16.b), with the facts that bear on them stated once.

- **R-079 · 2026-09-18 · A26, the canonical templates — READINGS (each the smallest in-ruling answer; overturnable by a registry line).**
  (1) A ROW MAY REPEAT AN EXERCISE. The owner's Pull writes the cable rope curl at rows 2, 4 and 6, so the template carries it three
  times and nothing pretends they are three exercises. Every place that named a row by its exercise id was wrong the moment that
  became possible, and each now names it by `order`: the reveal's swap (iOS `OnboardingModel.swap(order:in:with:)`, the ForEach keyed
  by order; web `GeneratedPlan` / `OnboardingFlow`), "Update my plan" from a mid-workout swap (ONE plan row changes — the one at the
  session row's order when it still holds that exercise, else the first that does: `SessionSwap.planRowToSwap` ⇄ `planRowToSwap`), the
  web editor's move (the sheet follows the row one slot, not the first row sharing its id). The phone editor's swap stops hiding a
  candidate "already in this workout" — the owner names the dumbbell curl as the swap for EACH curl row, and the web editor never hid
  one. Left as they are, and recorded in debt: prefill and "last time" read the FIRST row of that exercise in the last session, and
  Progress's strength trend takes a point per row.
  (2) NAMED SWAPS ARE GUARANTEED BY DATA. The ruling says "ensure each template row and each named swap exists with the right pattern,
  equipment tag, swap group and cue line", so the mechanism is the swap group, not a new finder rule: `namedSwaps` in
  plan-templates.json records the owner's pairs, and a row that has one keeps 3–5 OTHER members in its group — the finder stops at the
  group tier and returns the group whole, whatever the experience and however the two engines sort names (TS `localeCompare`, Swift
  `<`). Four groups were cut for it: `inclinePress` (machine incline · incline dumbbell · Smith incline · low-to-high cable fly ·
  decline push-up), `lowerChest` (machine decline · machine chest fly · cable fly · high-to-low cable fly · dip), `bodyweightRow`
  (inverted row · suspension trainer row, out of `row` so the seated row's five are the five offered) and `curlVariation`
  (concentration curl · underhand inverted row, out of `curl` for the same reason). check-seeds fails a group that drifts outside 3–5.
  (3) THE OWNER'S WORDS BECOME THE NAMES. "Triceps extension — cable bar" IS the seeded pushdown (its cue already said "push the bar
  down"), so that id takes the name "Cable Bar Triceps Extension" and the rope gets a new id; "machine chest fly" is the pec deck;
  "dumbbell reverse fly" the rear delt fly; "lunges — dumbbell" the walking lunge, whose cue now allows alternating in place. The
  seeded "Cable Curl" is a BAR curl (its cue says so), so the rope curl is a new id and the bar curl stays in the catalog. Ids never
  move; a saved plan or session stores its own names, so history reads as it did.
  (4) "LAT PULLDOWN — MACHINE": the tag moves cable → machine on the one seeded pulldown. "CALF RAISE — MACHINE" is the seeded standing
  machine raise, unrenamed.
  (5) THE WEB CHIP STAYS WORDS. The ruling lists "web twins" among the places that gain an SF Symbol. An SF Symbol is drawn by Apple's
  platforms from the system font; no browser has one, Apple's licence keeps them to software on Apple's platforms, and the same ruling
  says "no assets and no dependency" — so the only way to put a picture on the web chip is to draw five new icons, which is a design
  act nobody ruled (and the owner's design session is about to set a direction). R-075 took the same reading for the fast-food chain
  icons. The mapping IS generated into `seed.ts` (`equipmentSymbol`) so the one source stays one; no web component reads it. A "yes,
  draw them" is a small change: five inline SVG paths beside the five names.
  (6) THE SYMBOLS: barbell `figure.strengthtraining.traditional` · dumbbell `dumbbell` (already drawn by the app on two screens) ·
  machine `gearshape.2` · cable `cable.connector` · bodyweight `figure.stand` — all in SF Symbols ≤ 4, so iOS 17 has every one;
  `EquipmentSymbolTests` asks the system for each, because a wrong name draws nothing and fails no build. There is no barbell, machine
  or cable-stack glyph in SF Symbols; these are the nearest honest ones and any of the five is a one-word change in exercises.json.
  (7) NO SCHEMA, ROUTE OR VECTOR MOVED. A plan stores its rows, so an existing account keeps its plan until Rebuild my plan; the
  server accepts the new rows as it accepted the old (ids are free strings ≤ 60). The tour member now trains the canonical templates.
  (8) ADDED AFTER THE FIRST TOUR (run 35405384572, ui-reviewer): "OFFERED" WAS NOT ENOUGH — THE OWNER'S FIRST NAMED SWAP LEADS THE LIST. The
  dumbbell bench press carried level "some", so for a brand-new lifter it sorted behind the level gate — fifth of five, under the fold of the
  phone's half-height swap sheet, on the first row of every plan. Its level is now "brandNew" (the field gates nothing since A26 (3); it only
  ranks), which puts it first at every experience, and both engines' SwapFinder tests assert that a row's FIRST named swap is within the
  first `swapCandidatesMin` offered. The finder is still unchanged. Barbell row stays last among the seated row's five, as "barbell never the
  default" reads. The swap sheet also gained a Cancel button (DESIGN.md 4.2: every swipe has a visible-button equivalent) — it could only be
  pulled down, on all three of its entry points.

### R-080 · 2026-09-19 · W7 activation: the custom domain, the association file, the applinks entitlement · checkpoint — proceeding
- What was checked: the owner attached `trycrew.fit` (with `www`) to the Vercel project, set `APP_BASE_URL=https://trycrew.fit`,
  `APPLE_TEAM_ID`, `SUPPORT_EMAIL` and `RESEND_FROM`, and ticked Associated Domains on `com.maxwellcuenca.crew`. The order was:
  set `CREW_APPLINKS_HOST`, verify the association file, confirm the `onOpenURL` path and the landing page, repoint stale hosts.
  Five readers and a critic went over the AASA route, the entitlement wiring, the iOS deep-link path, `/join/[token]` and every
  host string in the repo; every live claim below was then re-checked by hand with `curl` before it was written down.
- Verdict, seven readings:
  (1) **THE APEX REDIRECT IS NOT A BLOCKER — CHECKED, NOT ASSUMED.** `https://trycrew.fit/.well-known/apple-app-site-association`
  answers `308 → www` (Vercel makes `www` the primary domain by default; nothing in the repo does it — `web/vercel.json` holds only
  a crons array and `next.config.ts` declares no redirects). Apple's documentation says the file must be served with no redirect,
  which reads as fatal. It is not, here: `https://app-site-association.cdn-apple.com/a/v1/trycrew.fit` answers **200** with
  `{"appIDs":["PZ56UL99NM.com.maxwellcuenca.crew"],"components":[{"/":"/join/*"}]}` and the header
  `Apple-From: https://trycrew.fit/…, https://www.trycrew.fit/…` — Apple fetched the apex, followed the 308, and stored the result
  under the apex key. A nonsense host on the same CDN answers 404, so that 200 is a real fetched association and not an echo. The
  entitlement therefore validates as configured. The reading taken: **ship the entitlement on the apex now, and ask the owner to
  flip the Vercel primary domain anyway** (§2.1) — undocumented behaviour that works today is not something to depend on, and the
  apex is what `APP_BASE_URL` mints links from, so the two should agree without a hop.
  (2) **ONE HOST IS CLAIMED, NOT TWO.** `testflight.yml` writes a one-element `applinks:` array from the variable, so a link shared
  as `www.trycrew.fit/join/…` opens the web page. Claiming both would mean teaching that `sed` a list and editing the placeholder
  in `ios/project.yml` in lockstep (the `sed` matches that comment byte for byte) — on the FIRST build that exercises the ad-hoc
  signing path at all. One change at a time: the second host is `docs/debt.md`, not this build.
  (3) **`CREW_API_HOST` STAYS ON `crew-eta-one.vercel.app`, DELIBERATELY.** It is compiled into the app (`Api.swift` reads
  `CrewApiHost` from Info.plist) and is the transport, not a shared link. `POST https://trycrew.fit/api/v1/auth/login` answers
  `308 → www`, so moving it today would put a redirect hop under every authenticated request, on the same build that debuts the
  entitlement — two variables at once, and a failure impossible to attribute. The old host is verified alive (root 200, API 401,
  association 200) and is the same deployment and the same database, so a `trycrew.fit` invite token resolves through it.
  (4) **A BLANK NAME NOW COUNTS AS UNSET** — the one code defect the confirmation turned up. The route read
  `process.env.APPLE_TEAM_ID ?? process.env.APNS_TEAM_ID`, and `??` only catches `undefined`: a host that holds `APPLE_TEAM_ID` as
  an EMPTY string — which is exactly what a provider's console produces when a name is created and left blank — took the empty
  value, skipped the APNs fallback the file's own header documents, and answered 404 with nothing to read. That is the failure
  the owner spent a step on. Both ids are now taken as trimmed strings, empty falling through, because an id pasted with a
  trailing newline is worse still: it builds a syntactically valid appID that Apple silently never matches.
  (5) **THE OLD HOST STAYS IN THE PARSER FIXTURES.** `inviteToken` and `InviteCode.token(from:)` read the path and ignore the host,
  so a fixture's host asserts nothing about production — and rewriting the old-host cases would have DELETED the evidence that the
  parser is host-agnostic. The production host was ADDED beside them in both twins, with the reason in a comment.
  (6) **BUILD 201 IS THE FIRST ARCHIVE EVER SIGNED WITH THE PROJECT'S OWN ENTITLEMENTS.** The ad-hoc `codesign` step in
  `testflight.yml` is gated on `CREW_APPLINKS_HOST`, which did not exist until 00:51Z today, so it has never run: every upload
  before this one archived unsigned and let the export derive its entitlements from the App Store profile. From now the archive
  carries `ios/project.yml`'s, which include `aps-environment: development`, and the export re-signs over them. The workflow
  asserts in a comment that the re-sign turns that into `production`; nothing has ever observed it on this pipeline. It was NOT
  pre-empted — changing the value would be wrong for every Debug and simulator build — it is READ OFF THE RUN, from the step
  "What the export signed", and the answer is recorded with the build below. If it ever says `development`, push notifications
  fail silently with `BadDeviceToken` and the entitlement needs splitting per configuration.
  (7) **LIVE DOCS REPOINTED; THE LEDGER LEFT ALONE.** `docs/OWNER-REVIEW.md` (its §2.2 prescribed the OLD host in a command the
  owner would have pasted), `docs/app-store-listing.md` and `docs/testing-without-a-mac.md` are instructions and now name
  `trycrew.fit`. Every other hit — dated entries in `docs/progress.md`, R-056's reading, Appendix A, `docs/debt.md`,
  `docs/commit-queue.sh` — is a record of what was true when it was written and was not touched.
- Look at: §2.1 of `docs/OWNER-REVIEW.md` (flip the Vercel primary domain to the apex, then move `CREW_API_HOST`), and reading (6)
  in the run log before trusting push on build 201.

### R-081 · 2026-09-19 · A23 education copy RATIFIED by the owner with eight amendments · checkpoint — RATIFIED BY OWNER (one builder's wording inside it, open to a "no")
- What was checked: the owner's ratification of `docs/education-copy-draft.md`, with eight amendments; `shared/copy/education.json`
  becomes the ratified source of truth and `page.note.draft` flips to false (Appendix A, the line under A23). Every amendment was
  applied to the one file, regenerated into `web/src/generated/copy.ts` and `ios/Crew/Generated/CopyData.swift`, and read back:
  `check-copy` passes; the twelve lines run 6–11 words (why.crews 10, why.freeDinner 8; the cap is `copy.whisperMaxWords` = 12);
  the three `adult` gates are unchanged; `launch-audit` no longer prints its draft NOTE, because it prints only while
  `page.note.draft` is true.
- Verdict, two readings:
  (1) **THE STREAK SENTENCE WAS CHECKED AGAINST THE ENGINE BEFORE IT WENT ON THE PAGE.** Amendment 3 says "a rest day never breaks
  it". A22 G1 (a), ruled 2026-09-18, is exactly that — "the streak counts planned training days only; a rest day neither requires nor
  breaks it" — and both engines carry it (R-068, vectors from V66). The page no longer says less than the rule, and A23's own
  rest-day silence (written while G1 was open) is superseded, not rewritten.
  (2) **THE CREWS SECTION'S FIRST SENTENCE IS THE BUILDER'S WORDING — "Being seen is the whole system."** The owner's instruction:
  "Its first sentence is reworded off the old algorithm line to match the new whisper." Only the first sentence is authorised to move,
  and the second, which stays, already says "Your crew sees you show up and reacts". Copying the whisper in whole ("Your crew sees
  you show up. That's the whole system.") would put the same clause twice in a row. So the first sentence carries the whisper's
  CLAIM — being seen is the system — and the unchanged second sentence says what being seen looks like. "Match" was read as "agree
  with", not "repeat". The section now reads: "Being seen is the whole system. Your crew sees you show up and reacts; that's it — no
  feed, no chat, no scores. Two to ten people, one link or code." A different first sentence is a one-string change in the file.
- Not touched, and why: the Crew tab's own empty state ("Two to ten friends. A link, a name, an emoji." — `CrewSoloView.swift`,
  `CrewView.tsx`) still says "friends". Amendment 5 names the page's crews section, and the empty state is a different line on a
  different screen, so it was left for the owner rather than widened into.
- Look at: the crews sentence above, and the three new tour shots of S19 (`tour_settingstests/0N_settings_howcrewworks_*`).

### R-082 · 2026-09-19 · A27 (a) — the training-days history, built on both engines, the server and the phone · checkpoint — the builder's readings, each open to the owner
- What was checked: the owner's ruling of the A27 (a) gap (Appendix A, the line under A27): a day is judged by the training days in
  effect on that day; a change takes effect from the dayKey it is saved, forward, never backward; a completed session is never
  re-judged. Vectors V85–V90 were computed by hand first, then run on both engines (`npm run vectors`; `swift test`, 105 tests), and
  each was checked to FAIL under the old reading (the current plan judging every day) — all six do, so none is green by accident.
- The builder's readings, where the ruling was silent:
  (1) **A day before the history's first entry is judged by the first entry.** Before its first recorded change a plan has only ever
      had its first days. Every one-entry history — every plan that never changed its days, every seed, every test that saves a plan
      "now" and reads a past date — therefore judges exactly as before, and V77/V78 run unchanged as a one-entry history.
  (2) **A queued edit's day is its `savedAt`, inside E15's window.** The phone sends when the change was made; the server keeps that
      moment when it lies within [now − syncClientTimestampMaxAgeDays, now + clientClockSkewToleranceMinutes], and otherwise its own
      now — the rule every other client timestamp already follows (`server-clock.ts`). A web PUT carries none: now.
  (3) **The history never goes backwards.** An edit whose day falls before the last entry's (a phone that synced late after a web
      change) takes effect from that entry's day, never behind it; the plan's `trainingWeekdays` is always the last entry.
  (4) **A day the post has not reached yet is judged by the entry in effect on the post's own day.** That is what "planned AT THE
      TIME" means for the rest of a week: a change made later in the week was not known when the perfect week was earned, so it can
      never take the reward back (V90).
  (5) **The migration is written once, on the plan's first read.** One entry, the plan's days, `from` = the document's creation dayKey
      (its ObjectId timestamp, in the user's stored timezone), written only while the history is still missing — so it can never land
      on top of an appended entry. No script to run.
  (6) **The phone's history starts empty after the update.** An install from before A27 holds no LocalTrainingDays rows until its plan
      next arrives from the server or its days next change on the phone; until then its current days stand as a one-entry history,
      which (1) makes exact. SwiftData CrewSchemaV3 adds the entity; nothing in V1 or V2 changed.
  (7) **The same days saved again append nothing; two changes saved the same day are two entries**, the later one in effect from it.
- The web message: "Saved · Changes apply from your next workout on." — the page's own sentence, held in one constant so the two can
  never disagree again.
- Look at: `shared/vectors/training-days.vectors.json` (V85–V90) and `docs/api.md` plans.

### R-083 · 2026-09-19 · A28 — the Focus Card redesign recorded, the tokens moved (R0) · checkpoint — the builder's readings, each open to the owner; ten SPECIFICATION GAPS for the owner
- What was checked: the owner's six rulings (Appendix A, A28 (a)–(f)) against `design/focus-card-system.md`, the twelve approved
  mockups in `design/targets/` (light and dark; `01` dark only) and the whole spec. A nine-agent sweep read Parts I–XII and Appendix A
  line by line (every passage each ruling overturns — 35 marker lines and 9 screen-head markers now point at A28), the code for every
  timer, duration, accent use and Home/Logger touchpoint (the work orders R1–R3 inherit, `docs/debt.md`), every token consumer, and
  the design docs. The token table is checked row for row against the system document by a test (`web/tests/contrast.test.ts`), and
  every contrast figure the system publishes was recomputed (all match).
- What changed in R0 (no screen file): `shared/design-tokens.json` — `colors` is the system's 18-row table; A16's six macro colours
  sit apart, unchanged; twelve legacy names are aliases of one row each; the type scale is 21 roles (§4's table plus §8's
  primary label and text button) → `EmberColors.swift`,
  `EmberTokens.swift` (`EmberTokens.Typography`, `TypeRole`), `ember.css` (`--ember-type-*`). `design/DESIGN.md`'s owner sections
  carry the system's words; `design/targets/README.md` maps each mockup to its tour shots; `ui-reviewer` judges the matching mode.
- The builder's readings (numbered as the A28 entry cites them):
  (1) **Tokens.** `colors` is the table verbatim; every legacy name a screen still reads is an ALIAS of one row, so the app recolors
      with no screen edit: hairline → hairlineOnCanvas (17 of its 21 uses sit on the canvas) · inkText, primaryButtonFill,
      secondaryButtonLabel → ink · primaryButtonLabel → onInk · controlOutline → inkMuted · secondaryText → inkSecondary · missedGray →
      inkMuted · ember → accent · emberText → ink · emberTint → ringTrack · danger → destructive. An alias leaves when its last reader
      is redesigned. secondaryButtonOutline and success had no reader and are retired (an alias named "button outline" at 1.2:1
      would re-arm A18.11's trap; a navy "success" invites misuse). The alias targets follow each token's role (ember's successor is
      the accent, danger's the destructive red) — where the role itself is narrowed by A28, the over-use is debt per screen.
  (2) **A control's mark still clears 3:1** (6.5, A18.11). controlBorder (~1.6:1) is the stepper's ring and never its only mark —
      the ink glyph is; an open check is a 2 pt ink ring; done segments are ink and the current exercise's are taller; the quiet fact
      row's mark is its inkSecondary text (5.84:1) with the button trait. A legacy outline control keeps controlOutline → inkMuted
      (3.32 / 3.64 light, 3.98 / 3.29 dark) until its screen is redesigned; controlBorder would have failed it.
  (3) **Large text.** 6.5's text gate reads with WCAG 1.4.3's large-text threshold (3:1 at ≥ 24 pt, or ≥ 18.66 pt Bold — the
      system states the 24 pt half, §11); (b) needs it for the XP numeral and unit (accent 3.15:1 on the canvas). The numeral (46 pt
      Bold) qualifies; the unit qualifies only at a large-text size — heroUnit (22 pt Semibold) does not, so R2 sets it at ≥ 24 pt or
      ≥ 18.66 pt Bold. Law ③ reads with (b): those two are its
      one sanctioned orange text; #B84D00 retires, and every other orange word becomes ink (emberText → ink).
  (4) **Laws ②, ⑤, ⑥ read with (a).** ② keeps the canvas family warm (Varsity cream) and (a) makes the ink navy; ⑥'s "no second
      hue" is the system's "no third hue" — navy ink and the orange accent are the two; ⑤'s "lifts, never inverts" governs the accent
      (#FF8A2B is #DE6400 lifted), and the capsule's mode inversion is two table rows, not an inverted ember.
  (5) **Spacing, radii, sizes.** On every redesigned screen they are the system's — (d) "per the mockups" and (f) "the component
      list" carry them (gutter 20, card padding 22, reward block to card 30, radii 28 / 26 / 14 / 8 / 4 / 3 / capsule). G5's
      "nothing off-scale" and cornerRadius 16 govern screens not yet redesigned. Each value enters `design-tokens.json` in the
      session that first draws it (C7) — none was added in R0, where nothing draws them. §12's literal snippets and §5's 59 / 34 /
      49 pt are illustrations; 6.7's safe-area-relative layout and C7 stand.
  (6) **(c)'s "durations" are time spent training** — rest, holds, the session clock, workout minutes, time estimates. A season's
      "N weeks" ((e) itself), a pause's return date and "max 3 weeks" are calendar facts and stay. `mobilityMinutesMin/Max` and
      `holdSecondsMax` can stay as seed / server data bounds (never shown); R2 decides with the constants it retires.
  (7) **Eyebrows.** The string stays sentence case (6.6) and the type role renders it uppercase (VoiceOver reads the string). §11's
      "uppercase labels stacked above values" is field chrome; an eyebrow over a read-only fact ("LAST TIME", "TOMORROW") is §4's role.
  (8) **The light lock** stays through R0 (the owner's "no screen file"; the lock is Info.plist and the root view) and lifts in R1
      on both platforms, not while any dark pair fails its gate (today: A16's dark carbs, GAP 6).
  (9) **Tone.** (e) adopts the system's tone with its vocabulary; new copy follows it. Copy the owner already ratified (A23's
      whispers, the protein line, 6.1's "what to do" error pattern, notifications) stands until its session re-cuts it with the
      owner (GAP 7).
  (10) **Web.** 6.8 stands — parity of capability, not pixel-cloning: the same table in both modes, the same structure, flows and
      copy, the type scale through system font stacks (`--ember-font-text`, `--ember-font-rounded`).
  (11) **Platform-native controls** (6.8) are admitted where a job cannot be done without one — a text field, the keyboard, a date or
      time picker, a toggle, Sign in with Apple (whose style Apple mandates) — drawn without field chrome, in the table's colours.
      Without this reading (f) would leave auth, crew names, the pause date and the reminder time with no control at all.
  (12) **Emoji.** User content — A21.2's five reactions, a crew's emoji, a caption — is not a glyph; §11's ban governs the app's own
      chrome, so the app's own emoji (🎉, 🛡, 🧊, 💪 in copy; the web's 🔥 / 🧊 flame) become SF Symbols or words as their screens
      are redesigned.
  (13) **6.1's five states stand**, composed from the list: a quiet line for loading and offline; an error is one sentence and the
      one filled "Try again". A23's whisper is §11's "a tip appears once".
  (14) **A season does not restart when the training days change** (A27 (a) appends an entry; only a build, a rebuild or a pause's
      end starts one).
  (15) **Mechanics stand under the tone**: the comeback (V39), Welcome back (S18) and the reminders keep their rules and every
      gamification number (Appendix C); only their words move.
  (16) **A21.12's Build B is overtaken**: A28 (d) lays Home out; the branch stays preserved and untouched, nothing lands from it
      without a ruling. (A20.6's "crew strip off Home" was Build B's and never landed — the strip IS on Home today on both clients;
      A28 (d) removes it in its own right.)
  (17) §11's "per-workout settings" are settings like the rest length (G9) and a session's unit (A9), not plan content — A4's
      workout editor stands.
  (18) "Edit today's log" (mockup 05) opens today's day in the Journal with the powers it already has (A6's delete, E3's caption) —
      no new edit capability.
  (19) The Asset Catalog instruction (§2, §12) is met by the generated adaptive colours — one Any/Dark pair per row, named as the
      token; no `.colorset` files are made (6.8's pipeline).
  (20) Every stated height (the 56 / 58 pt capsule, the 52 pt stepper, the 44 / 56 pt rows) is a MINIMUM: at accessibility sizes
      the label wraps and the control grows — nothing truncates (6.7, system §10).
  (21) Finish has two doors to one job: the mobility checklist's ends the workout, the whole-workout sheet's finishes early. Discard
      sits under ⋯ behind its destructive confirm (the one place red appears); the back chevron leaves with the session open. Where set
      removal lives on the set screen is R2's to draw (A28 (d)).
  (22) The "+" offers what exists today where it exists today — Log cardio in every state with a plan, a bonus workout on rest and
      done days (A3, Flow 5) — a route to two existing screens, not a new screen with its own job.
  (23) An open session makes "Resume workout" the card's one filled primary in any state (A18.8's capability; one filled button).
  (24) The two new Logger screens take the system's jobs (§9) until the owner words them: the whole-workout sheet "jump between
      exercises, finish"; the mobility checklist "tick the holds, finish".
  (25) Table marks below 3:1 — segmentEmpty, segmentCurrent, ringTrack, heatEmpty, chevron — are never a state's only carrier.
- SPECIFICATION GAPS for the owner (each answered before the session it names; the spec stands until then):
  GAP 1 (R3) five screen types or the system's six (the data screen — Progress, and every screen that is none of the five) ·
  GAP 2 (R2) haptics: 6.4's tick / double / thump / softTap or §10's light / medium / success ("nothing else vibrates" drops softTap) ·
  GAP 3 (R1) the reward block: "4 OF 7" vs A18.1's planned-workout count, the zero-done week (A18.2), the shields line ·
  GAP 4 (R1) cardio's entered minutes under (c) ·
  GAP 5 (R1) "Your season starts today": the plan reveal (onboarding, no redesign session), first-day Home's card, or both ·
  GAP 6 (R1's lock lift, R7) A16's macro colours under "no third hue"; dark carbs is 2.79:1 on the Midnight card ·
  GAP 7 (R6) How Crew works has no tone section; its Mobility sentence states a duration; ratified imperatives meet the tone ·
  GAP 8 (R9) illustrations: what they are (exercise media is A21.13 Not Building) ·
  GAP 9 (R2) the celebration's phrase ("Seven straight"; S10 has "Counted.") and where its badges go ·
  GAP 10 (R3) the season label's inputs are not stored (no rebuild date; the phone drops an ended pause) and its arithmetic.
- Found on the way, recorded in `docs/debt.md`: the crew strip is on Home (A20.6 never landed); the iOS rest timer's local
  notification plays the default SOUND (haptics-only law); the web's Quick complete posts to the crew without A21.9's choice; the web
  heat map's cardio outline never drew (a colour inside `calc()`); the tour step "the rest timer is running"; 01's missing light frame.
- Look at: the A28 entry and its markers (`docs/crew-mvp-spec.md`), `design/DESIGN.md`, `design/targets/README.md`, the token diff
  (`shared/design-tokens.json`), and the recolored tour (every screen changes; no baseline is approved).

### R-084 · 2026-09-19 · A28 R1 — Home redesigned (six states, light and dark) under the owner's standing order for gaps · checkpoint — the builder's readings, each open to the owner
- The order (owner, queued 2026-09-19, the redesign build order): "a gap takes the most conservative in-spec reading, tagged
  `// GAP:`, logged in ratification.md; never widen scope; the Not Building list stands; no new dependencies; vectors
  append-only." GAPs 3, 4, 5 and 6 of R-083 were R1's preconditions. Each is read below as the reading that changes the least of
  what the spec already rules. Each carries a `// GAP:` tag where it is coded, and each gives way to the owner's answer.
- What changed (iOS; the web twin is noted, not built):
  - Home is the Focus Card: the reward block (`HomeRewardBlock`: `FocusRing` + the flame + its numeral), then ONE `FocusCard`
    holding the day, then the quiet rows. The nav bar carries only the "+" (`HomeAddSheet`).
  - The week strip, the vector rows, the header group and the crew strip are gone (`WeekStrip`, `VectorRow`, `HomeHeader` deleted).
    `CrewStrip` stays: it is the Crew tab's member strip.
  - The shared kit: `TypeRoleStyle` (`.typeRole`, Dynamic Type through UIFontMetrics), `FocusCard`, `FocusRing`, `QuietFactRow`,
    and `Chrome` (the nav and tab bar appearance). `PrimaryButton` is the ink capsule, with its height a token.
  - The tokens gained `focus` (the system's sizes that Home draws with) and `elevation` (the two light shadows), plus `relativeTo`
    on each type role (C7).
  - The `SessionSummaryLine` twins drop the workout's minutes (A28 (c)): "Push day · 12 of 12 sets". Cardio keeps its entered
    minutes and distance. There is no wall-clock fallback.
  - Unchanged: the light lock's removal (`UIUserInterfaceStyle` absent, no forced scheme in Release), Sign in with Apple
    following the mode, and "End the pause".
- The builder's readings:
  (1) **GAP 3, the reward block.** The ring keeps A18.1's count: completed planned workouts OF the week's planned count, so a
      four-day plan reads "OF 4". Mockup 03's "4 OF 7" is read as seeded content (targets README: content is illustrative).
      A18.2's gate stands: the ring appears once the week holds a completed planned workout, and never on the first day or with
      no plan. The shield fact (A17.1 / H020) stays as one quiet caption under the flame. Off-season keeps the ring in accent,
      because those workouts happened (mockup 06), and turns the flame into an inkSecondary snowflake.
  (2) **GAP 4, cardio minutes.** A cardio block's minutes are a target the user set, or minutes they entered. That makes them an
      answer, not time spent training measured by the app, so they stay. The card reads "Cardio · 25 min", the cardio log keeps
      its stepper, and the summary line keeps "Walk · 25 min · 2.1 km". What (c) removes here is the session's wall clock.
  (3) **GAP 5, "Your season starts today".** The line appears on first-day Home's card only (mockup 01). The plan reveal is
      onboarding, and no redesign session names it, so it is untouched.
  (4) **GAP 6, the light lock.** It lifts on iOS. The one dark pair that fails its gate is A16's carbs fill on the Midnight
      CARD (2.79:1). No shipped screen draws it: `MacroLines` sits on the canvas, where dark carbs measures 3.5:1 and is gated in
      both modes (`web/tests/contrast.test.ts`). A macro bar moved onto a card before the owner rules is a defect. A16's colours
      are unchanged. The web keeps `color-scheme: light` until its parity session. R-083 (8) said both platforms; the build order
      notes web parity and does not build it.
  (5) **The "+"** (R-083 (22)). It shows in every state with a plan. "Log cardio" is always offered. "Bonus workout" is offered
      on rest, done and off-season days — the days that had it before R1 (A3, Flow 5; the workout vector's fallback). It is a
      route to two existing screens, not a new job. On a training day the day's workout is the card's primary, so the sheet
      offers cardio alone.
  (6) **"Edit today's log"** (R-083 (18)) opens the Progress tab on its Journal. The segment switches and today's row is at the
      top. No new edit power is added.
  (7) **Quick complete** stays: text under a training day's card (A28 (d)), hidden once today counts. A21.9's celebration choice
      follows it as before.
  (8) **The Macros row** is a `QuietFactRow`: "Macros · N logged", or "Macros · nothing logged yet". It shows on training, rest and
      done days, and is absent under 18 (A22 G4). It is a count and never grams (A22 G4, law ⑥: no macro fill on Home). It is
      absent on the first day, with no plan and off-season, which each keep one job.
  (9) **The chrome.** The nav bar is transparent at rest and canvas when scrolled, with ink titles. The tab bar is the table's
      `tabBar` row, selected in ink and normal in inkSecondary (Part III law ①). Text a screen does not colour is ink, not the
      platform's black. The chrome is a `UIAppearance`, so every tab changes with it, including screens not yet redesigned. Their
      lists, sheets and fields keep their R0 recolor until their own session (`docs/debt.md`).
- Tour: every Home state is photographed in both modes (`-uiDark`, DEBUG only), and the "+" sheet is photographed on a training day
  and a rest day. The map is in `design/targets/README.md`.
- Look at: the Home shots in both modes against `design/targets/01`–`06`, the "+" sheet against DESIGN.md, and whether the ring's
  count (1) and the Macros row's states (8) are what the owner wants.

- Round 1 of ui-reviewer (CI run 35440565004, TestFlight build 207): 1 PASS · 21 FAIL. The same two findings recur on every Home shot.
  The CI simulator is iOS 26, which draws the tab bar as a floating Liquid Glass capsule and puts a glass disc behind every
  toolbar glyph. The Chrome appearance proxies are overridden there. The review also found the missing holds row, and the text-face
  numerals inside sentences. Further readings:
  (5) **The "+" amended.** It shows in every state, no-plan Home included, because mockup 02 draws it there. "Log cardio" is always
      offered; the bonus workout only with a plan.
  (10) **No glass.** `UIDesignRequiresCompatibility` is set in Info.plist (`project.yml`). It is Apple's key for an app that keeps
       the classic bars, and it is what §11's "no glass blur" and the approved mockups (a flat `tabBar` with a seam, a bare "+")
       ask for. Earlier iOS versions ignore the key.
  (11) **The tab glyphs are outline, and Settings is sliders**, as every mockup draws them. SwiftUI would otherwise fill them.
  (12) **The streak numeral.** It is ink, except off-season, where it is `inkSecondary` (mockup 06). At zero it has no eyebrow, because
       nothing captions a streak of zero (A8, A18.1). DESIGN.md 1.3 now carries this, so a reviewer does not read it as a miss.
  (13) **Numerals inside sentences** ("Push day · 6 of 6 sets", "3×8", "1 exercise") set their digit runs in SF Pro Rounded Bold,
       and their words in the role's face. This is `Text(numerals:)`, system §4.
  (14) **The bonus sheet's footer** is now Flow 5's own words, "A bonus workout is never expected." It replaces a builder's
       imperative ("Pick whatever you feel like."), which A28 (e) bars outside a button label.
  - Also fixed: the tour plan now carries each workout's canonical mobility block (plan-templates.json), so the card shows its
    holds as a real install does. The card's sub-line is a step under its rows (secondary 15), and the "+" sheet fits its rows,
    with 28 pt corners.
  - Residue, recorded in `docs/debt.md`:
    - the sheet scrim is UIKit's dimming, not `sheetScrim`;
    - the rebuild sheet gains a grabber but still has no Cancel (onboarding's rebuild mode);
    - no redesign session in the worklist names the bonus and rebuild sheets.

### R-085 · 2026-09-19 · A28 R2 — the Logger redesigned (one set per screen, the sheet, the checklist, the celebration) under the owner's standing order for gaps · checkpoint — the builder's readings, each open to the owner
- The order is the same standing order as R-084. GAP 2 (haptics) and GAP 9 (the celebration's phrase and badges) were R2's
  preconditions. Each takes the reading that changes least of what the spec already rules, and gives way to the owner's answer.
- What changed (iOS; web where A28 (c) names both clients):
  - `SessionScreen` is the Logger:
    - the bar (`WorkoutBar`), the count and "Whole workout";
    - the set screen (`SetScreenBody` with `SetCard` / `MetricRow`) or the checklist (`MobilityChecklist`);
    - Swap exercise and Skip as text, and one filled "Log set N" (Finish on the checklist).
  - `WholeWorkoutSheet` carries Finish. `CelebrationScreen` is the system's celebration.
  - `SessionModel` drops the rest timer and the unit question, and gains `logSet`, `displayedSet`, `selectedSetOrder`,
    `toggleHold`, `markAllHolds` and `nothingOpen`.
  - Deleted: `RestTimer`, `RestTimerView`, `WeightTape`, `SetRow` (its `Stepper` moved to `StepButton.swift`), `SwipeToRemove`,
    `UnitConfirmLine`, `MobilityHoldRow`, `CardioRow`, and `StreakFlame` (no reader left).
  - Constants retired: the seven `weightTape*`, the three `swipeRemove*`, and `restTimerAdjustStepSeconds`.
    `restTimerDefaultSeconds` and `perSideHoldRepeats` stay: the plan editor's estimate reads them until R4.
  - The tokens gain the Logger's sizes (stepper, check, segments, set card, row button, the celebration flame) and the `xpUnit`
    role. `focus.scale` admits the one half-point size, the stepper's 1.5 pt ring.
  - Web: the rest timer and the hold countdown are gone, a hold is a tap-to-check, and the done page reads "Push day · 1 of 12 sets".
- The builder's readings:
  (1) **GAP 2, haptics.** 6.4's fixed language stands. `tick` sounds on Log set and on ticking a hold. `double` sounds when an
      exercise's last set is logged and on "Mark all done". `thump` sounds on Finish. §10's light / medium / success language is
      not adopted, and a stepper tap adds no haptic.
  (2) **GAP 9, the celebration.** The phrase is S10's own "Counted.", in the phrase slot; mockup 11's "Seven straight" is
      seeded content. The badges (comeback, perfect week, level, PR, achievement) stay on the celebration as ink words under
      the day's line, with no emoji and no confetti (A28 (b); R-083 (12)). The flame shows the streak this workout leaves: the
      engine's new value, or else the phone's current streak. It is inkMuted at zero.
  (3) **One set per screen.** The card shows:
      - a logged set picked from the ledger (to correct it: Flow 3's out-of-order);
      - otherwise the first open set, with a warm-up before the work sets;
      - otherwise the exercise's last set.
      "Log set N" logs the set on the card and moves on: to the next set, or to the next open exercise. A logged set is never
      "un-logged"; it is corrected on the card, or removed under ⋯. A skipped exercise shows no filled button, only "Unskip".
  (4) **The count** is the engine's facts: holds and cardio count, warm-ups never ("1 of 10 sets"). The bar, the sheet, the
      celebration and the journal therefore say the same number. Mockup 07's "0 of 6" is seeded content.
  (5) **The bar.** It has one segment per work set, and the holds are ONE segment at the end, because the checklist is one screen.
      Every segment is the same width, so a group is as wide as its sets. A group on a long workout is narrower than 44 pt; the
      sheet's rows are the full-size route (`docs/debt.md`).
  (6) **Finish** is the checklist's filled button and the sheet's. When every exercise is done or skipped and no checklist is left,
      the sheet opens itself, because Finish lives there.
  (7) **⋯** holds:
      - "+ set" and "+ warm-up" (strength);
      - "Remove set N" (A11, absent on the last work set, V55), with "Undo the removal" while one is pending. This keeps A11's undo
        without a snackbar, which (f) bans;
      - "Show the plates" for a barbell weight (plate math on demand);
      - "Discard workout", an ink menu item that opens the destructive confirm. The confirm is the only red.
  (8) **The value buttons** open the platform's alert and keypad (R-083 (11)): the number pad for reps and minutes, the decimal pad
      for a weight or a distance. A typed weight is clamped and snapped to the unit's step; reps are clamped at `planTargetRepsMax`.
  (9) **A cardio block's set screen** has two rows. Its minutes have steppers in `cardioMinutesStep`, opening at the plan's
      target (GAP 4 as R-084 (2)). Its distance is a value button in the user's unit (A9). Then "Log set 1". The ledger reads
      "Set 1 · 25 min".
  (10) **The equipment tag leaves the Logger.** The mockups draw none, the seed names carry the equipment word ("Barbell Bench
       Press"), and §11 bans stacked redundancy. Tapping the title still shows the cue.
  (11) **The Logger's bottom group has no rule above it** (the mockups), so it is `safeAreaInset` directly rather than
       `crewBottomBar`. Log set and Finish stay bottom-anchored and rise above the keyboard (A19.1, 6.7).
  (12) **A9's in-session unit line is gone**, and its per-device flag is no longer read (`docs/debt.md`).
- Tour: start, keypad, mid-set, swap, ⋯, discard, the sheet, the longest name (through the sheet), the checklist, then mid-set,
  the sheet and the checklist in dark, then Finish → celebration → Home done. The dark celebration is shot in Tour_HomeTests
  (Quick complete). The map is in `design/targets/README.md`.
- Look at: the Logger shots against `design/targets/07`–`11`, the phrase and badges (2), and whether a stepper should tick (1).

### R-086 · 2026-09-19 · A28 R3 — Progress redesigned (the data screen, the season line, the heat map), Charts and the Journal one tap below · checkpoint — the builder's readings, each open to the owner
- The order: the same standing order as R-084. GAP 1 (the data screen) and GAP 10 (the season label's inputs) were R3's
  preconditions.
- What changed:
  - `ProgressScreen` is the data screen: title, the season line (`SeasonFacts`), and the heat map card (`HeatMapView`: two
    states, ink and `heatEmpty`, weekday letters, the season's weeks).
  - A tapped day's card appears below the heat map, then two row buttons, Charts (`ChartsScreen`) and Journal.
  - The strength charts are ink. The weekly-ring view is deleted, and `DayRingState` stays.
  - The journal reads a stored summary without its minutes (the `withoutWorkoutMinutes` twins). Its swipe Delete is ink,
    before a red confirm, and "Sending" is a quiet word.
  - The web: the season line on its Progress page, and the journal's minutes stripped.
- The builder's readings:
  (1) **GAP 1.** The data screen is the type mockup 12 draws, and approving the mockup admits it for Progress alone. No other
      screen uses it until the owner answers GAP 1.
  (2) **A19.4 without its segment.** The segmented control is not on A28 (f)'s component list. Its promise — both halves of Flow 9
      one tap from the tab — is kept by two row buttons under the card: Charts and Journal. "Edit today's log" pushes the Journal.
  (3) **GAP 10.** A season starts at the plan's FIRST training-days entry (its build), or at the end of the latest pause that has
      run its course, whichever is later. A days change never restarts it (R-083 (14)). The phone cannot see a rebuild or a pause
      ended early, so both are recorded as debt. The twins are `SeasonFacts.swift` and `seasonFacts`, with identical cases.
  (4) **Weeks and workouts.** Weeks are the calendar weeks the season touches, this one included (mockup 12: six weeks, six rows).
      Workouts are completed workouts; a standalone cardio log is not one (A14).
  (5) **The heat map** runs from the season's first week, capped at `progressHeatMapWeeks`, to this Sunday. Days still to come draw
      empty and answer no tap. "Done" is a completed workout. A cardio-only or posted-only day draws empty, and its VoiceOver
      label and the day card say what it held. A tapped day wears an ink ring in the gap around the cell.
  (6) **Charts, one tap below** (DESIGN.md 3.2–3.3). It holds:
      - "Did I show up?": the streak, the longest streak, workouts and posts;
      - "How much work?": sets per week, the Push / Pull / Legs balance, and this week's entered cardio minutes (GAP 4);
      - "Am I stronger?": the charts, in ink, with "New best" in words.
      The ring history leaves, because the heat map's rows are the weeks (§11). The mobility minutes leave, because there is no
      hold timer (A28 (c)).
  (7) **Stored summaries** read without the workout's minutes, on both clients, at render. Nothing stored is rewritten, and a
      cardio line's entered minutes stand. The crew stream's cards are R5's.
  (8) **The Journal** is pushed with its own title:
      - the day labels are eyebrows;
      - the rows sit on `card` with every numeral Rounded Bold;
      - the swipe's Delete is ink and opens the destructive confirm (the only red);
      - "Sending" is a word (chips are not on the list).
  (9) **Empty Progress** is one card with S15's invitation and one filled "Go to today", and no rows: there is nothing to chart,
      and nothing in the Journal.
- Look at: the Progress shots against `design/targets/12` (light and dark), and (3), (5) and (6) above.
