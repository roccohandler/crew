# Crew — owner review (end of the continuous build, 2026-09-04)

This is the final act of the continuous-build run (Appendix A amendment, 2026-09-04). It says what exists, what was proven
by command on this Windows machine, what is written but unverified, what could not be done here, and the exact ordered steps
that take the repo to a shipped app. Read this before anything else on a cold resume; `docs/progress.md` is the ledger,
`docs/ratification.md` (R-001 … R-049) holds every self-review and every gap call, `docs/debt.md` every compromise, and
`docs/testing-without-a-mac.md` is the owner's route from a Windows machine to an app on an iPhone.

## 1. Where it stands

- **Contracts (Phase 0)**: `shared/` is the single source of truth — spec-constants (25 sections, every number tagged to its
  rule, GAP-tagged where the spec named none), design tokens, three seed JSONs, 51 gamification vectors (V01–V44 + V18b,
  owner-ratified R-001; V45–V50 achievements appended 2026-09-05, R-037), generators and drift/vector/seed/doctrine checks. All green.
- **Server + web (Phases 1–4, verified here)**: one Next.js app on the App Router with `/api/v1` (every route in
  `docs/api.md`), MongoDB with Part IX unique indexes, custom auth (email + Sign in with Apple, jose HS256 15-min access /
  30-day rotating refresh, scrypt), Resend/APNs/Blob behind local substitutes, sharp photo pipeline, server-clock
  reconciliation, sync op replay, cron notifications, moderation, account export/delete cascade, pause. Full-parity web app:
  hero, onboarding, login/reset, invite landing, Home, session logging, posting, crew stream/chat/reactions, plan editor,
  progress, journal, settings, welcome-back and stale-session edge screens, a mid-workout swap (E7) and an adjustable rest
  timer (G9). The TS engine passes all 51 vectors; the 15 seed achievements are awarded by one pass after every recompute;
  `npm run metrics` prints the Part IV readings from first-party facts.
- **The Swift ENGINE (verified here, 2026-09-08)**: `ios/Package.swift` builds `Crew/Engine/` + the generated constants and
  seed data + the API DTOs on the open-source toolchain, and `swift test` runs 18 tests including all 51 shared vectors —
  green in Docker on the Windows machine, and now a CI job on Linux. The Phase 1 "green on BOTH engines" gate is closed.
- **iOS app half (WRITTEN — UNVERIFIED)**: the complete 5.6 tree — 127 Swift files (engine twins incl. achievements, the mid-workout swap, SwiftData store, SyncQueue and the driver that runs it, fresh-phone hydration, every
  screen with its five states, edge prompts, plan editor, progress, settings), unit tests, vector runner, XCUITest journeys
  ① and ②, XcodeGen project, doctrine lint. Not one file has been compiled: this machine has no Xcode.
- **Half done here, half deferred**: T045 (the metrics report exists and is tested; TestFlight + web beta need credentials),
  T047 (the registry audit is done and the launch checklist is §8; the submission needs a Mac). T046 production env is §5/§7.

## 2. Proof — commands run on 2026-09-04 and 2026-09-05 and their results

| Command (from the repo root unless noted) | Result |
|---|---|
| `node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs` | generate done; all Generated files match shared/ |
| `node shared/scripts/check-vectors.mjs` · `check-seeds.mjs` | 51 vectors valid (V45–V50 added 2026-09-05); seeds valid with swap coverage |
| `node shared/scripts/doctrine-lint.mjs` | clean — 127 Swift files, 1 hand-written CSS file (2026-09-08) |
| `web: npm run lint` · `npm run typecheck` | clean · clean |
| `web: npm test` (vitest: API integration on a real in-memory MongoDB, engines, 51 vectors, token parity, metrics) | vitest: 28 files, 284 tests green (2026-09-06, incl. the 51 vectors, the achievements API test, the metrics report, the iPhone-batch sync replay and the journal's clientId). |
| `web: npm run build` | Build green, 36 pages (2026-09-06). |
| `web: npm run e2e` (Playwright: journeys ①②③④ + the a11y/responsiveness audit × phone-375 WebKit / tablet-768 / desktop-1280) | Playwright: 23 passed, 1 skipped (the keyboard check on the phone descriptor), 0 failed — journeys ①②③④ + the a11y/responsiveness audit incl. /journal on phone-375 (WebKit), tablet-768 and desktop-1280, from a deleted `.next` (the warm-up of R-041 + R-047 makes a cold run as steady as a warm one; three workers) in 1.6 min (2026-09-06). |
| `docker run --rm -v "<repo>:/repo" -w /repo/ios swift:5.10 swift test` | **18 tests, 0 failures** — the Swift engine compiled and its 51 vectors green, on Windows, no Mac (2026-09-08, R-048) |
| `web: npm audit` (production and full trees) | 0 vulnerabilities |
| `web: npm run metrics` | the Part IV report (install → first post, D7, posts/user/week, crew ÷ solo); proven by tests/api/metrics.test.ts against seeded facts |

Everything above except the last-but-one row is web and shared. On iOS, the ENGINE is compiled and green; the app half
(SwiftUI, SwiftData, screens, storage) still carries `WRITTEN — UNVERIFIED (needs Mac)` in every header.
**How to test it without a Mac: `docs/testing-without-a-mac.md`** — three stages, from the web app on your phone today,
through GitHub's macOS runners compiling the app and running journeys ①② on a simulator with screenshots, to TestFlight.

## 3. Everything ratifiable — the gap calls that need your yes

Each is logged in `docs/ratification.md` with its reasoning; the code is tagged `// GAP:`. A "no" on any of them is a small,
local change.

1. **Reactions are on posts only** (messages have no reactions) — R-023.
2. **Achievements are awarded by a separate pass** after every server recompute and every local apply, never inside
   `apply()`, pinned by V45–V50 (kind `achievements`); the V35 placeholder id stays because vectors are append-only — R-015, R-037.
3. **Swap tiers / swap keeps the row's targets** in the plan editor — R-016, R-034.
4. **Server-clock window**: client timestamps accepted within 7 days back / 5 minutes forward — R-018.
5. **Mobility holds count in "x/y sets"** (Flow 2 reading) — R-018.
6. **Photos**: server-side sharp pipeline; Vercel Blob public-unguessable keys with an auth-checked GET — R-020.
7. **Web reminder is in-app only** (no push on web, Part IV) — R-031.
8. **Progress balance by workout-name prefix**; heat map 12 weeks / rings history 8 weeks (`progressHeatMapWeeks`,
   `progressRingHistoryWeeks`) — R-031, R-033.
9. **Welcome back**: "quiet" = no post of any kind; the answer is per quiet spell and stored on the account
   (`welcomeBackAckDay`); an offline iOS acknowledgement is not queued — R-034, `docs/debt.md`.
10. **Stale session**: exactly two choices (Keep going · Discard); completing later counts on the completion day — R-034.
11. **iOS S14 plan editor** was built although no ledger task owns it (the acceptance table and the 5.6 map both name it)
    — R-034.
12. **Empty-state invitations are the page's h1** (a11y finding) — R-035.
13. **Dev-only substitutes** (rule 3b): mongodb-memory-server for tests, an in-memory Mongo + `next dev` harness for
    Playwright, a local fake Apple JWKS, outboxes for Resend/APNs, local Blob — R-005, R-009, R-010, R-020, R-025, R-031.
15. **Mid-workout swap is a plain helper inside the Session feature** (the 5.6 SessionModel map lists no swap action; E7 names
    it) and keeps the row's sets and targets — R-038. **Rest-timer step** `restTimerAdjustStepSeconds` 15 s — R-038.
16. **Metrics denominators** (install = account_created; same day in the user's own zone; D7 = any post on or after day 7;
    crew ÷ solo by membership) — R-039.
17. **The phone's replay contract**: a sync op's payload is the JSON object it was queued with; `patchSession` names the session
    by its clientId; absent `weight`/`holdSeconds` mean null; `deletePost` names the post by clientId — R-043.
18. **Input ceilings and layout counts the spec never states**, now named honestly instead of borrowed from unrelated rules:
    planTargetRepsMax 100 · setWeightMax 1000 · holdSecondsMax 600 · syncBatchMaxOps 1000 · crewEmojiMaxChars 16 ·
    pauseDefaultDays 7 · skeletonPlaceholderRows 3 · chatComposerMaxLines 4 · captionComposerMaxLines 3 · barbellPlateSides 2 ·
    perSideHoldRepeats 2 — R-044. (A set over 100 reps or a hold over 10 minutes is now rejected as a typo.)
19. **A signed-in phone with an empty Store hydrates first** (plan · journal · sessions · gamification · crew, bounded by
    `hydrationMaxWaitSeconds` 10 s): 1C says the Keychain outlives the app and 1D says the bridge ends when the first post
    exists — the spec never says how a reinstalled phone learns that. Only an empty Store pulls; a phone with any local truth is
    kept current by the queue and the reconcile — R-046.
20. **The sync queue's driver**: it drains after every enqueue, on every foreground and when the network returns
    (NWPathMonitor); strictly FIFO — a backoff on the head holds the line; offline leaves the op untouched (no attempt
    counted); an op left in flight by a kill is recovered at launch; no background sending (Part IV names none) — R-045.
21. **The XCUITest seed lives in the test bundle** (SeedClient through the real API; the app only takes a session from
    CREW_SEED_SESSION and hydrates), and Info.plist allows local networking for the simulator — R-046, `docs/debt.md`.
14. **GAP constants added by the agent** (each tagged in `shared/spec-constants.json`): displayNameMaxChars 30,
    passwordMinChars 8, reportReasonMaxChars 500, birthYearMin 1900, tokenRefreshLeadSeconds 60, levelFormulaDivisor 2,
    initialsMaxLetters 2, percentScale 100, syncClientTimestampMaxAgeDays 7, clientClockSkewToleranceMinutes 5, barbell/plate
    sets, longPressStepIntervalMs 120, photo pipeline parameters, streakRiskNudgeWindowMinutes 60, usualPostTimeSampleSize 14,
    progressHeatMapWeeks 12, progressRingHistoryWeeks 8.

Open owner decision still unresolved: **Firebase Auth ⏳ (Appendix B)** — custom auth proceeded by default (12.5). Nothing
was built against Firebase.

## 4. Everything deferred, by what it needs

**Needs Xcode — but NOT a Mac you own: the CI `ios` job on GitHub's macOS runners does all of it (docs/testing-without-a-mac.md)**
- Compile and run the iOS app half: `cd ios && xcodegen generate && xcodebuild test -scheme Crew`, then `-scheme CrewUITests`
  for journeys ① and ②. Both now run in CI on every push, and the journeys' screenshots come back as an artifact.
  Expect compile errors: 127 files were written blind (the engine's are gone — it compiles, R-048); the desk-check of 2026-09-05 (R-042) removed the ones a careful read
  finds, not the ones only a compiler finds. Fix them without changing behaviour; the tests are the contract.
**Needs real hardware (a Mac, or a rented cloud Mac, plus an iPhone)**
- Xcode accessibility audit; VoiceOver scripted session; Dynamic Type XXL on S07/S09/S12; Reduce Motion celebration.
- The 8.6 offline matrix on an iPhone (checklist in §6).
- Launch signposts on device (8.8): `Signposts.launchToHome` is emitted; assert < 1.0 s warm / < 2.5 s cold.
- The XCUITest journeys need the local server running on the Mac: `cd web && node tests/e2e/dev-server.mjs` (in-memory Mongo
  + next dev on :3000). Journey ① registers a fresh account; journey ② seeds itself through `CrewUITests/SeedClient.swift`
  (R-046) — that seed and the hydration it relies on meet a compiler for the first time there.

**Needs credentials / accounts**
- MongoDB Atlas (`MONGODB_URI`), Vercel project + Blob (`BLOB_READ_WRITE_TOKEN`), Resend (`RESEND_API_KEY`, `RESEND_FROM`
  on a verified domain), APNs key (`APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_PRIVATE_KEY`, `APNS_ENVIRONMENT`), Sign in with Apple
  (`APPLE_BUNDLE_ID`, `APPLE_SERVICES_ID`, the web callback), `JWT_SECRET`, `CRON_SECRET`. `web/.env.example` is complete.
- Real-service wiring checks: send one Resend email, one APNs push to a device, one Blob upload from production.

**Needs an owner-approved dependency**
- Lighthouse CI budgets (`@lhci/cli`) and axe-core (`@axe-core/playwright`) — both listed in `docs/debt.md`; the
  hand-rolled a11y audit and the 8.8 budget constants are already in place to receive them.

**Needs a map change (plan note)**
- `OpKind.patchMe` so the welcome-back acknowledgement (and future profile edits) can queue offline on iOS.

## 5. Exact ordered steps to ship

1. **Commit the queue.** `bash docs/commit-queue.sh` from the repo root (git is hook-blocked for the agent; every task's
   conventional commit with its `[SPEC:]` tag is queued in order and idempotent — 61 blocks as of 2026-09-08). Check
   `git log --oneline`.
2. **Push and watch CI.** `.github/workflows/ci.yml` runs contracts → web (lint, typecheck, test, vectors, build, audit) →
   web-e2e (Chromium + WebKit) → ios (macOS runner: xcodegen, doctrine lint, xcodebuild test). The ios job is the first
   compile of the Swift tree; iterate there or on a Mac until green.
3. **Mac pass.** Install Xcode + XcodeGen; `cd ios && xcodegen generate`; `xcodebuild test -scheme Crew`; then the XCUITest
   journeys on a phone. Record results in `docs/progress.md` by flipping `[~]` to `[x]` per task, one commit each.
4. **Phase gates, in order (owner ratification of the self-reviews).** Phase 1: R-015 (both engines green). Phase 2: R-022
   (Journey ① on device). Phase 3: R-027 (Journey ② + 8.7). Phase 4: R-032 (Playwright + Lighthouse once approved).
   Phase 5: R-036 (security sweep).
5. **Production environment (T046).** Create Atlas (M10+, backups on, IP allowlist for Vercel), Vercel (env vars from
   `.env.example`, `vercel.json` cron every minute with `CRON_SECRET`), Resend domain, APNs key, Sign in with Apple
   service id + key. Rotate `JWT_SECRET` procedure: set the new secret, all access tokens expire within 15 min, refresh tokens
   are server-side records and survive. Enable Vercel log drains/alerts and Atlas alerts.
6. **Deploy web** (`vercel --prod`), then run the journeys against production once: `BASE_URL=https://… npx playwright test`
   after pointing `playwright.config.ts` `use.baseURL` at the deployment and disabling the local webServer.
7. **TestFlight (T045).** Bundle id, capabilities (Sign in with Apple, Push), `APNS_ENVIRONMENT=sandbox` first; upload;
   internal testers; the E10 metrics come from the `events` collection (first-party events are already logged by every
   mutation) — a dashboard is not built; a saved Atlas chart per metric is the smallest thing that works.
8. **App Store (T047).** Screenshots from the five-state screens, privacy nutrition labels (photos, email, Apple id, usage
   events), EULA link (E9), review notes for Sign in with Apple. Run the registry audit: `node shared/scripts/doctrine-lint.mjs`
   clean and `grep -rn "GAP:" web/src ios/Crew` reviewed against §3.

## 6. The 8.6 offline matrix — first device pass checklist

Airplane mode: view plan · full session · complete + celebration (local engine) · post queued with chip · reconnect →
auto-send, silent reconcile · chat draft held · kill mid-queue → nothing lost · 24 h failed upload → Retry / Post without
photo / Delete. Tick each in `docs/progress.md` under T043 when done on a phone.

## 7. Defects found and fixed during the run that you should know about

- iOS never wrote `LocalPlan` after signup/login (Home would have shown "Build your week" forever) → `Storage/PlanLocal.swift`
  (R-034).
- iOS `UpdateMeRequestDTO` dropped a cleared reminder instead of sending null → explicit null (R-033).
- Web at 375 px: the plan editor and the set row overflowed; `/post` typed before hydration on WebKit; the auth limiter tripped
  when the whole matrix registered from one address; `/settings` hydrated with a mismatched timezone list (R-032, R-035).
- Progress spans were computed from unrelated constants → honest GAP constants (R-033); the same class again on 2026-09-05
  (reps/weight/hold/ops ceilings, emoji length, pause default, skeleton rows, composer lines, "two sides") → R-044.
- **The phone could never have synced** (found 2026-09-05 by reading both sides together, R-043): the sync payload went out as a
  base64 string where the server wants an object; sessions were addressed by clientId where the server wanted an ObjectId;
  Swift omits nil `weight`/`holdSeconds` where zod required null; `deletePost` had no server handler. All four fixed and covered
  by an iPhone-batch replay test.
- Quick complete on web read the calendar date while Home judged the 3 AM day — dead between midnight and 3 AM (R-041).
- The Swift tree, read blind against the server's reply shapes (R-042): missing SwiftData imports, two models outside the main
  actor, an `if case` without `= result` in both auth screens, a `body` clash in MessageRow, a MemberDot field iOS never had,
  a redundant Identifiable conformance, `await` inside XCTAssert autoclosures, a vector decoder that could not take partial
  counters — fixed before the first compile. The CI ios job would have failed on a missing `xcpretty`; two commit-queue blocks
  would have added a file named "n".
- **Nothing drove the sync queue** (found 2026-09-06, R-045): `processNext` existed and nothing in the app called it — every
  session, post, message and reaction the phone queued would have stayed on the phone forever. `SyncDriver` now runs it after
  every enqueue, on every foreground and when the network returns. Along the way the queue became strictly FIFO under backoff
  (a patchSession could overtake the createSession it needs — the server 404s it and the queue would have held it as poison),
  offline stopped counting as a failed attempt (31 s of airplane mode would have parked every op behind the E19 24-hour
  choice), and an op left in flight by a kill is recovered at launch (8.6).
- **A reinstalled phone showed the bridge to a veteran** (R-046): the Keychain outlives the app, so a signed-in phone can wake
  with an empty Store; Home judged "never posted" from local rows only and the streak read 0 until the first sync. `ServerHydrate`
  pulls plan, journal, sessions, gamification and crew before Home judges today; login on a fresh phone pulls the same. The iOS
  journal never showed a server-side photo (local files only) — it now renders `photoKey`. Home re-judges elapsed days on every
  foreground (E8), which it only did at first appearance. The XCUITest journey ② looked for `staticTexts` inside a card that
  combines its children into one accessibility element — it now matches by label.
- **A generated constant was a type error only Swift could see** (R-048): the generator typed an array from its first element,
  so `plateSetLb [45, 35, 25, 10, 5, 2.5]` was emitted as `[Int]`. TypeScript accepted the same values happily; the Swift
  compiler rejected the file outright. It surfaced the moment a real toolchain ran, which is the argument for the new
  Linux engine job.
- **The app's API address was a hard-coded `localhost`** (R-049): a TestFlight build would have looked for the server on the
  phone itself and failed every request. It is now a build setting, Debug and Release differing.
- **The Playwright matrix flaked on WebKit at 375 under eight workers** (R-047): Playwright's default worker count opened the
  same cold pages eight at a time, and `next dev` broadcasts a Fast Refresh on every first-hit client-bundle compile — a page
  mid-mount lost its lazy chunk. The warm-up now opens every page in a headless browser first and the matrix runs three
  workers, one per viewport. Not a product defect; CI would have met it rarely.

## 8. Launch checklist (T047) — tick in order, nothing ships with an open line

1. `bash docs/commit-queue.sh` run; `git log` shows one commit per task with its `[SPEC:]` tag; CI green on all four jobs.
2. Mac pass complete: `xcodebuild test -scheme Crew` green (unit + 51 vectors on the Swift engine); Journey ① and ② green on
   a device; the 8.6 offline matrix (§6) ticked; Xcode a11y audit + VoiceOver session done; Dynamic Type XXL on S07/S09/S12.
3. Owner ratifications recorded for R-015 (Phase 1), R-022 (Phase 2), R-027 (Phase 3), R-032 (Phase 4), R-036 (Phase 5) and
   every gap call in §3 answered (a "no" is a small local change — do it before tagging).
4. Production environment live (§5 step 5): Atlas with backups + alerts, Vercel env from `.env.example`, cron with
   `CRON_SECRET`, Resend domain verified, APNs key uploaded, Sign in with Apple service id + return URL registered.
5. Real-service smoke: one reset email arrives; one push reaches a device; one photo lands in Blob and serves only to its
   owner; `BASE_URL=https://… npx playwright test` green against production.
6. `npm run metrics` runs against Atlas and prints a report (empty is fine); the weekly read is on the calendar (XII Beta).
7. App Store Connect: bundle id, capabilities (Sign in with Apple, Push), privacy nutrition labels (photos, email, Apple id,
   first-party usage events), EULA + privacy links (E9), 13+ age rating, review notes with a test account and an invite link,
   screenshots from the five-state screens (no ember on chrome — law ①).
8. Registry audit at the tag: `node shared/scripts/doctrine-lint.mjs` clean; `grep -rn "GAP:" web/src ios/Crew` reviewed
   against §3; nothing on the rejected lists exists (R-040 repeated at the release commit).
9. Tag, submit, and open the parking lot for everything that came up during the beta — nothing else changes after this line.

## 9. Production notes (T046) — the parts that are decisions, not steps

- **Backups**: Atlas continuous backup on the cluster, 7-day point-in-time; a restore drill once before launch.
- **Monitoring**: Vercel log drain + alert on 5xx rate; Atlas alerts on connections/latency; the cron endpoint logs one line
  per run (the `events` collection is the audit trail for everything user-facing).
- **Secrets rotation**: `JWT_SECRET` — set the new value, all access tokens expire within 15 minutes, refresh tokens are
  server-side records and survive; `CRON_SECRET` — rotate in Vercel and `vercel.json` together; APNs/Resend/Blob keys —
  rotate at the provider, redeploy, confirm one smoke each (§8.5).
- **Data**: photos live in Blob under unguessable keys and are deleted by the account cascade; the JSON export (E9) is the
  user's copy; nothing is ever sold or aggregated beyond the Part IV metrics.
