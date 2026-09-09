# Crew build progress

Updated: 2026-09-09 morning (the smoke-test amendments A1–A8 built; web green, iOS written) — earlier: 2026-09-08 evening (cold-start full audit, then gap closures Q01–Q10) · Current phase: 5 → 6 (everything runnable
on this Windows machine is green; the beta wiring — Vercel host, Apple keys, TestFlight, the device pass — is the open front)

This file was REWRITTEN FROM SCRATCH on 2026-09-08 after a cold-start audit that trusted no prior checkmark. Every
state below names the command that produced it TODAY. Four states:

- **DONE-VERIFIED** — its verify command was run on this machine today (or read from GitHub with `gh run view`) and passed
- **WRITTEN-UNVERIFIED** — Swift app code (SwiftUI / SwiftData / screens / XCUITests). No Mac here. The GitHub macOS job
  compiled it, ran 49 unit tests and journeys ①② on an iPhone 17 simulator (run 34252964640, green, 2026-09-08 16:45Z),
  but nothing has run on a device: gestures, haptics, camera, push, offline, VoiceOver, Dynamic Type remain unproven
- **PARTIAL** — part verified, part missing; the missing part is named
- **NOT STARTED**

## Audit evidence (2026-09-08, commands run here)

| Command | Result |
|---|---|
| `node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs` | generate done; all 7 Generated files match shared/; working tree unchanged |
| `node shared/scripts/check-vectors.mjs` | 51 vectors across 7 files — shape and invariants hold |
| `node shared/scripts/check-seeds.mjs` | 15 achievements · 101 exercises · 45 template lists — consistent |
| `node shared/scripts/doctrine-lint.mjs` | clean — 127 Swift files, 1 hand-written CSS file |
| `web: npm run typecheck` · `npm run lint` | exit 0 · exit 0 |
| `web: npm test` | 28 files, 285 tests passed (56 s; real in-memory MongoDB) |
| `web: npm run vectors` | 51 passed |
| `web: npm run build` | green |
| `web: npm audit --audit-level=high` | 0 vulnerabilities |
| `web: npm run e2e` | **22 passed, 1 skipped, 1 FAILED** — journey ① on phone-375 (WebKit): "Post" stayed disabled after the caption was filled. Re-run alone: passed (8.1 s). A hydration/value-tracker flake under three workers, not a product defect — queue Q02 |
| `docker run --rm -v "C:\Users\princ\CREW_2.0:/repo" -w /repo/ios swift:5.10 swift test` | 18 tests, 0 failures (all 51 vectors on the Swift engine) |
| `gh run view 34252964640` (HEAD e9fe41f, master) | contracts ✓ · web ✓ · web e2e ✓ · ios engine (Linux) ✓ · ios (xcodegen · build · unit + vectors · journeys ①②, macOS) ✓ |
| **After the gap closures (same evening)**: `npm test` · `npm run e2e` · docker swift test · doctrine-lint · check-drift | **31 files, 309 tests green** · **23 passed, 1 skipped (by design), 0 failed** on 375/768/1280 · **25 tests, 0 failures** · clean (132 Swift files) · clean |

Server route inventory (spec 5.2 + Part IV + docs/api.md): 32 route files, 45 exported methods. Every spec-required route
EXISTS and has a dedicated integration test plus the four standing checks — with two exceptions: `PATCH crews/[id]/mute`
EXISTS-BUT-UNTESTED beyond the standing checks (Q04), and `POST events` (promised by docs/api.md, R-004) is MISSING with no
client calling it (Q03). Secrets: only `web/.env.example` is tracked; `git log --all --full-history -- "*.env"` shows only
that file; `.env` and `.env.*` are gitignored; `web/.env` and a stray duplicate `ios/.env` exist locally with real values
(the owner is rotating the Resend and Blob keys). `.env.example` lacks `APP_STORE_URL` (read by the join page) — Q01.

## 2026-09-09 — the smoke-test amendments A1–A8 (owner-directed; Appendix A 2026-09-08; contract docs/improvement-plan-2026-09-08.md; ratification R-057)

The owner reviewed build 0.1.0 (2) on the phone and redirected the product: PPL-only rotation balanced over the months at any
days/week (A1), cardio tracked (A2), a rest-day Home that answers "what now / what's next" (A3), a two-level plan editor (A4), a
Crew tab that explains itself (A5), a journal with day labels and summary lines (A6), fuller Settings (A7), the copy law (A8).
State after the build (commands run 2026-09-09 morning):

| Area | State | Evidence |
|---|---|---|
| shared: constants (cardio, journal, planEstimateRoundingMinutes, distanceDecimalScale GAP), 9 cardio seed rows, check-seeds rules, V51 | DONE-VERIFIED | generate + check-drift ok · check-vectors 52/7 files · check-seeds 110 exercises · doctrine-lint clean (165 Swift files) |
| engine twins PlanGenerator (A1), PlanRotation, DayLabel, SessionSummaryLine | DONE-VERIFIED both engines | `npm run vectors` 52 · `npx vitest run tests/engine` green · docker `swift test` **43 tests, 0 failures** |
| server: plan shape + legacy normaliser, sessions workoutKind/distanceMeters/summary, rotation in today-state/cron/notification-facts, progress minutes, notificationPrefs, GET blocks, profilePhotoKey ownership, docs/api.md | DONE-VERIFIED | `npm test` **34 files, 340 tests** · typecheck + lint clean |
| web: Home (A3), /session/new + done, /log-cardio, CardioRow, /plan week map + /plan/[kind] editor + sheet, onboarding projection, Crew (A5), journal + progress (A6), Settings + /privacy + /terms (A7) | DONE-VERIFIED | `npm run build` green · `npm run e2e` **23 passed, 1 skipped (by design)** at 375/768/1280 (journeys ①②③④ + a11y incl. /plan/push, /log-cardio, /privacy, /terms) |
| iOS: Storage/Api/Sync (A1 shapes, A3 sync fixes), Home + CardioLog (A3), Plan editor (A4), Session CardioRow + Journal/Progress (A2/A6), Crew + Settings (A5/A7) — ~95 Swift files changed or added | WRITTEN-UNVERIFIED | no Xcode here; every file self-checked plus one compile-risk read (R-057); doctrine-lint clean; the macOS CI job compiles it on the next push |

Deviations and parking lot: docs/debt.md 2026-09-09 lines. Owner asks: ratify A1–A8 + the two GAP constants; decide ≤ 2-day full-body
vs PPL (built as PPL, evidence favours full-body); replace the placeholder legal pages; connect the Blob store.

## Ledger

Phase 0 — contracts
- [x] T001 spec-constants ⚙ — DONE-VERIFIED (generate + check-drift, 2026-09-08)
- [x] T002 generate pipeline + check-drift ⚙ — DONE-VERIFIED (generate + check-drift, 2026-09-08)
- [x] T003 vectors V01–V40 (+V18b, V41–V50 = 51) — DONE-VERIFIED (check-vectors + `npm run vectors` 51/51, 2026-09-08); owner-ratified R-001
- [x] T004 seed exercises.json — DONE-VERIFIED (check-seeds, 2026-09-08)
- [x] T005 seed plan-templates.json — DONE-VERIFIED (check-seeds, 2026-09-08)
- [x] T006 achievements.json + docs/api.md — DONE-VERIFIED (check-seeds; achievements.test.ts + V45–V50 in `npm test`); the api.md `POST events` route that was missing now exists and is tested (Q03, events.test.ts 4 green)

Phase 1 — foundation
- [x] T007 monorepo scaffold ⚙ — DONE-VERIFIED (web: typecheck + lint + build 2026-09-08; ios: `project.yml` generated and built by the CI ios job, run 34252964640). No `Crew.xcodeproj` is committed — XcodeGen makes it on the runner (logged R-005)
- [x] T008 CI + doctrine lint ⚙ — DONE-VERIFIED (`gh run view 34252964640`: five jobs green; doctrine-lint clean here). `codemagic.yaml` is a never-run duplicate CI → Q07 deletes it (debt repaid)
- [x] T009 lib/db.ts + indexes — DONE-VERIFIED (`npm test` → db.test.ts, 2026-09-08)
- [x] T010 server auth — DONE-VERIFIED (auth.test.ts in `npm test`)
- [x] T011 email + password reset — DONE-VERIFIED (auth-reset.test.ts in `npm test`; Resend behind the outbox substitute)
- [~] T012 Sign in with Apple — PARTIAL: server verification + web callback DONE-VERIFIED (auth-apple.test.ts via a local JWKS); iOS AuthStore compiles on CI; the real Apple round-trip and the "manual device check" are BLOCKED-CREDENTIALS (Services ID, bundle id, a device)
- [~] T013 iOS shells + five-state scaffolds ⚙ — WRITTEN-UNVERIFIED (CI: compiles; ShellStatesTests 3 green on the simulator)
- [~] T014 SyncQueue + in-memory SwiftData tests — WRITTEN-UNVERIFIED (CI: SyncQueueTests 9 green on the simulator)
- [x] T015 standing-checks.gen.test.ts — DONE-VERIFIED (in `npm test`; every route under app/api/v1 is discovered)

Phase 2 — core loop
- [x] T016 DayKey twin — DONE-VERIFIED (V05–V10 in `npm run vectors`; Swift: docker swift test 25/25). The 8.3 DayKey UNIT tests both engines lacked were added (Q06): `tests/engine/day-key.test.ts` 9 green, `CrewTests/DayKeyTests.swift` 7 green on Linux
- [x] T017 engine streak + XP — DONE-VERIFIED (vectors 51/51 TS; Swift docker 18/18)
- [x] T018 shields + pause — DONE-VERIFIED (same)
- [x] T019 completion/undo/edit — DONE-VERIFIED (same; the "both engines" gate holds: TS 51/51, Swift 51/51 on Linux and under Xcode on CI)
- [x] T020 PlanGenerator + SwapFinder + property test — DONE-VERIFIED (plan-generator.test.ts + swap-finder.test.ts in `npm test`; Swift PlanGeneratorTests + SwapFinderTests in docker swift test)
- [~] T021 Onboarding S02–S04 — WRITTEN-UNVERIFIED (CI: journey ① walks S02→S04 on the simulator; screenshots reviewed R-052/R-053)
- [~] T022 SaveAuthScreen + Login (S05; S06 removed v1.9) — WRITTEN-UNVERIFIED (CI: journey ① saves with email)
- [x] T023 plans/sessions/sync API — DONE-VERIFIED (plans.test.ts, sessions.test.ts, sync.test.ts in `npm test`, incl. the iPhone batch replay)
- [~] T024 Home S07 — REBUILT for A3 on 2026-09-09 (rest-day and all-done CTAs, next-up line, bonus workout sheet, cardio log, camera toolbar button; HomeModelTests rewritten, 6 tests) — WRITTEN-UNVERIFIED (CI: HomeModelTests + HomeModelEdgeTests green; bridge and post-state screenshots reviewed R-053)
- [~] T025 Session S09 — CardioRow + live summary line + "Counted." added for A2 on 2026-09-09 (SessionModelTests +3) — WRITTEN-UNVERIFIED (CI: SessionModelTests green; journey ② logs 3/3 sets)
- [~] T026 Celebration + workout post + Posts API (S10) — PARTIAL: Posts API DONE-VERIFIED (posts.test.ts); web celebration DONE-VERIFIED (e2e journey ④); iOS half WRITTEN-UNVERIFIED (CI: journey ② reaches the celebration)
- [~] T027 Nutrition posting S11 + lib/blob.ts — PARTIAL: photos API DONE-VERIFIED (photos.test.ts: EXIF/GPS fixture stripped, ≤ budget, owner-only read); web posting DONE-VERIFIED (e2e journey ①, when it does not flake — Q02); iOS half WRITTEN-UNVERIFIED
- [~] T028 🛑 Journey ① (Phase 2 gate) — PARTIAL: green on a CI SIMULATOR (run 34252964640) and on web (three viewports); NOT run on a device; the gate is the owner's ratification of R-022/R-053

Phase 3 — crews & social
- [x] T029 Crews API — DONE-VERIFIED (crews.test.ts, incl. the mute test added by Q04: per member, visible on users/me, outsider 404)
- [x] T030 Messages + Reactions (+ blocks) API — DONE-VERIFIED (messages.test.ts)
- [~] T031 Crew feature S12–S13 (iOS) — A5 on 2026-09-09: strip pinned on top, solo explainer, crew-of-one invite card, composer from two members, auto-invite after create, report/block from the card, summary lines — WRITTEN-UNVERIFIED (CI: journey ② sees the crew-mate's reaction; Crew screenshot reviewed R-053)
- [x] T032 engine crew rules + comeback — DONE-VERIFIED (V37–V40 both engines; crew-rules.ts stream banners in crews.test.ts)
- [~] T033 Notifications — PARTIAL: push-token route + apns2 lib + eligibility unit tests + cron sender DONE-VERIFIED (cron-notifications.test.ts, notification-eligibility.test.ts); a push to a device is BLOCKED-CREDENTIALS (APNs key + a phone); the beta cron is daily (Hobby, debt)
- [x] T034 Moderation — DONE-VERIFIED (moderation.test.ts: report → email queue, blocks both ways, EULA gate)
- [~] T035 🛑 Journey ② + security matrix (Phase 3 gate) — PARTIAL: web journey ② DONE-VERIFIED (e2e, three viewports); iOS journey ② green on the CI simulator only; 8.7 items runnable here green (standing 403s, Keychain static check, HttpOnly, EXIF, cascade crawl, rate limits, `npm audit` 0); device-side items open

Phase 4 — web parity
- [x] T036 Web onboarding + plan builder — DONE-VERIFIED (build; e2e journey ① on 768 and 1280 today; 375 flaked once, passed alone)
- [x] T037 Web session logging + posting — DONE-VERIFIED (e2e journey ④ on all three viewports)
- [x] T038 Web crew/chat/progress + invite landing W1 — DONE-VERIFIED (e2e journey ③ on all three viewports)
- [~] T039 🛑 Playwright ①②③④ + Lighthouse + token parity (Phase 4 gate) — PARTIAL: token-parity.test.ts green; `npm run e2e` = 23 passed · 1 skipped (keyboard check on the phone descriptor, by design) · 0 failed after the Q02 helper fix (the first run of the evening had journey ① phone-375 flaking on a pre-hydration fill); Lighthouse budgets not enforced (`@lhci/cli` not on the allowlist — debt, BLOCKED on the owner approving the dependency)

Phase 5 — hardening
- [~] T040 Progress + Journal (S15–S16) — A6 on 2026-09-09 (day labels, summary lines, Sending ↻, empty state, cardio/mobility minutes) on both platforms — PARTIAL: web DONE-VERIFIED (build + e2e a11y sweep incl. /journal); iOS WRITTEN-UNVERIFIED
- [~] T041 Settings (S17): pause, export, delete cascade — A7 on 2026-09-09 (profile name + photo, notification toggles on server prefs, mute from the server, blocked people, legal pages, version, real log out) on both platforms — PARTIAL: routes DONE-VERIFIED (account.test.ts: export completeness, cascade crawl, pause) + web settings page (e2e sweep); iOS WRITTEN-UNVERIFIED
- [~] T042 Edge screens — PARTIAL: web DONE-VERIFIED (welcome-back.test.ts + lapsed-user.test.ts; stale-session and failed-upload components in the build); iOS WRITTEN-UNVERIFIED (CI: LapsedUserTests, ServerHydrateTests green)
- [~] T043 A11y + offline matrix + perf — PARTIAL: the web substitute audit DONE-VERIFIED (a11y.spec.ts: landmarks, names, labels, overflow at 375/768/1280); two 8.4 simulator probes WRITTEN-UNVERIFIED (Q09: CameraDeniedTests, OfflineSessionTests — first CI run pending); NOT done: Xcode a11y audit, VoiceOver, Dynamic Type XXL, Reduce Motion, the 8.6 offline matrix, launch signposts on device (all need a phone or a Mac), axe-core and Lighthouse (dependencies not on the allowlist)
- [~] T044 🛑 Security sweep + zero P0/P1 (Phase 5 gate) — PARTIAL: everything runnable here green today (standing checks, `npm audit` 0, EXIF, cascade, rate limits); one hygiene finding fixed by Q01 (a local `.env` with real vendor keys could reach the e2e harness); device items and the owner's ratification open

Phases 6–7 — beta & release
- [~] T045 TestFlight + web beta + metrics — PARTIAL: `npm run metrics` DONE-VERIFIED (metrics.test.ts); `.github/workflows/testflight.yml` RAN for the first time 2026-09-08 21:36Z (run 34281494452, workflow_dispatch build 1) with real credentials — App ID `com.maxwellcuenca.crew` on a NEW App Store Connect record "Crew: Train. Track. Show up." (SKU crew-2; the old rejected record is not reused), Team PZ56UL99NM, Admin API key AXVB98H4DM; the secrets/variables were set from this machine with `gh secret set` / `gh variable set` (the key from the downloaded .p8, never printed): xcodegen + ARCHIVE SUCCEEDED — cloud signing issued the certificate and profile, so the Admin-role finding held — then App Store Connect refused the upload: ITMS 90022/90713/90023, no app icon. FIXED the same hour: `ios/Crew/Assets.xcassets/AppIcon.appiconset` (first the owner's sloth icon from the earlier product — REJECTED by the owner once it showed in TestFlight; since F17 the Ember flame on the bone canvas, source `shared/brand/app-icon.svg`, rendered with sharp to an opaque 1024 px PNG; single-size catalog, Xcode derives every size and writes CFBundleIconName) + `ASSETCATALOG_COMPILER_APPICON_NAME` in project.yml (F15). UPLOADED 2026-09-08 ~21:58Z: run 34282978517 (build 2, commit 344791a, `gh workflow run testflight.yml -f build_number=2`) — every step green including "Export and upload"; the first build of the native app reached App Store Connect from a Windows machine (App Store Connect numbered it 0.1.0 (1) — `manageAppVersionAndBuildNumber` picks the next free number regardless of the input). The owner rejected the sloth icon on sight; run 34285838041 (commit 3854845, F17, 2026-09-08 22:29Z) uploaded the build with the Ember flame icon — every step green, "Upload succeeded" — PROCESSED by 2026-09-08 22:39Z: TestFlight lists 0.1.0 (1) sloth and 0.1.0 (2) flame, both "Ready to Test" (no export-compliance hold), Invites/Installs still "–" because NO internal group exists yet; the iPhone's TestFlight app therefore shows only the OLD record ("Crew — Train. Track. Show up.", em dash, sloth, "Build Removed") under Previously Tested — TestFlight has no catalog, an app appears only after an invite. DONE 22:55Z: the owner created the Internal Testing group `beta-test` (group id 76ab034e-0273-4d57-b99b-1587e678d227) with both builds attached and themselves as the single tester — status "Invited", i.e. Apple's invitation email is out and not yet accepted, which is why the phone still shows nothing (internal testers must accept from the email's "View in TestFlight" button or the Accept row in the TestFlight app, signed in with the same Apple ID as the App Store Connect user). NEXT: the owner accepts the invite on the phone and installs build 2; then the APNs key → Vercel (APNS_KEY_ID/TEAM_ID/PRIVATE_KEY/BUNDLE_ID, APNS_ENVIRONMENT=production, APPLE_BUNDLE_ID)
- [~] T046 Production env, monitoring, backups, rotation — PARTIAL / BLOCKED-CREDENTIALS: Atlas M0, Resend, Blob values exist in the owner's local `web/.env` (never printed, never committed); Vercel project `crew` (team `maxs-projects-4a767c36`) is DEPLOYED from master `e9fe41f` at **https://crew-eta-one.vercel.app** — `/` → 200 "Crew", `/api/v1/users/me` → 401 (2026-09-08 ~18:50Z); the first two builds failed because Root Directory was `.` (log: "No Next.js version detected"), now `web`; variables on the project: APP_BASE_URL, COOKIE_SECURE, RESEND_FROM, MONGODB_DB, RESEND_API_KEY; the secret ones went in through `vercel env add` typed by the owner (the browser form never landed them); the first MONGODB_URI failed with `MongoServerError: bad auth`, the regenerated one still 500'd because `MONGODB_DB` no longer held `crew` (`MongoInvalidArgumentError: Database names cannot contain the character '.'` — the value had been edited in the dashboard); reset through the CLI, redeployed, and `POST auth/register` → 201 against Atlas at 2026-09-08 22:03Z (the smoke account was deleted through `DELETE users/me` right after); STILL MISSING: BLOB_READ_WRITE_TOKEN (Blob store `crew-photos` not connected to the project — photo posts fail until the owner clicks Connect to Project); the Vercel CLI is logged in on this machine (`npx --yes vercel@59.11.7 <cmd> --scope maxs-projects-4a767c36`; a scratch-folder link OUTSIDE the repo gives `env ls` / `redeploy` / `inspect --logs`); the agent may not read secret values or the CLI token (auto-mode classifier blocks it) — the owner enters secrets in the UI, the agent adds only public values; monitoring/backups/rotation deferred to launch (debt)
- [ ] T047 🛑 App Store submission — NOT STARTED beyond the registry audit (R-040) and the launch checklist (OWNER-REVIEW §8); needs a TestFlight build first

## Gap-closure queue (strict dependency order — work top to bottom, one at a time, verify by command, commit per item)

- [x] Q01 (done 2026-09-08: `grep RESEND_API_KEY dev-server.mjs` → pinned ""; `ios/.env` absent; journey ③ 3/3 green on the isolated harness) Harness isolation + env hygiene — `web/tests/e2e/dev-server.mjs` blanks `RESEND_API_KEY`, `BLOB_READ_WRITE_TOKEN`, `APNS_*`, `MODERATION_INBOX` so a local `web/.env` with real keys can never reach the Playwright harness (rule 3b; today it reaches `next dev`); delete the stray `ios/.env` (a byte-for-byte duplicate of `web/.env` that nothing under ios/ reads); add `APP_STORE_URL` to `.env.example`. Verify: `grep -n "RESEND_API_KEY" web/tests/e2e/dev-server.mjs`; `ls ios/.env` → absent; `npm run e2e -- journey3` green. [SPEC: rule 3b; Part IV; 8.7]
- [x] Q02 (done: full `npm run e2e` 23 passed · 1 skipped · 0 failed) Journey ① phone-375 flake — `fillWhenHydrated` clears the field before each fill (a fill that lands before hydration seeds React's value tracker, so a later identical fill never fires onChange). Verify: `npx playwright test journey1 --project=phone-375 --repeat-each=3` green, then the full `npm run e2e` green. [SPEC: 8.4; 8.9; XI T039]
- [x] Q03 (done: events.test.ts 4 green; standing checks 139 green incl. `events:POST`; typecheck + lint clean) SERVER: `POST /api/v1/events` (docs/api.md, R-004; 1C/1D funnel instrumentation "measured, funnel-instrumented") — canonical 5.6.4 shape, `clientEventsSchema` (already in validate.ts), source "web"/"ios"; integration test (`tests/api/events.test.ts`: inserts with the caller's userId, rejects a malformed body, standing checks discover it); the web client posts the funnel steps (hero shown · plan built · plan saved · bridge → first post). Verify: `npm test tests/api/events tests/api/standing-checks`. [SPEC: 1C; 1D; Part IV analytics; docs/api.md]
- [x] Q04 (done: crews.test.ts 7 green) SERVER: `PATCH crews/[id]/mute` dedicated test — mute round-trips through `GET users/me` (`crew.muted`), unmute clears it, a non-member is 404. Verify: `npm test tests/api/crews`. [SPEC: E2; S17; 8.2]
- [x] Q05 (done: validators.test.ts 7 green) 8.3 validators unit test — `tests/engine/validators.test.ts`: every input limit constant at the limit and one over (caption 280, crew name 30, exercise name 60, chat 1000, display name, password min, plan ceilings, reps/weight/hold, emoji, report reason, timezone rule). Verify: `npm test tests/engine/validators`. [SPEC: 8.3; E20; Flow 8; C7]
- [x] Q06 (done: day-key.test.ts 9 green; docker swift test 25/25) 8.3 DayKey unit tests on both engines — `tests/engine/day-key.test.ts` (3 AM boundary, Monday weeks incl. Sunday, DST both ways, daysBetween across a DST change, east/west travel) and `ios/CrewTests/DayKeyTests.swift` added to `Package.swift` test sources so the Linux job runs it. Verify: `npm test tests/engine/day-key`; docker swift test. [SPEC: 8.3; 5.2; E8; E20]
- [x] Q07 (done: `git status` shows `D codemagic.yaml`; check-drift + doctrine-lint clean; R-055 written) Tree hygiene + ratification R-055 — delete `codemagic.yaml` (never run; Actions unlocked and green; a second CI that must not drift; carries the owner's email in a public repo) and its Stage-1 section in docs/testing-without-a-mac.md; move its debt line to Repaid; R-055 logs the full 5.2 tree diff (every extra kept with its justification, every spec path absent and why). Verify: `git status` shows the deletion; check-drift + doctrine-lint green. [SPEC: 5.2; XI T008; debt 2026-09-08]
- [~] Q08 (WRITTEN — doctrine-lint clean on 132 files; compiles on the next CI ios job) iOS C10 file split — `MessageRow` out of StreamList.swift and `CreateCrewScreen` out of InviteScreen.swift into their own files per the 5.6 map ("one screen per file"). WRITTEN-UNVERIFIED; CI compiles it. Verify: doctrine-lint; the next CI ios job. [SPEC: C9; C10; 5.2]
- [~] Q09 (FIRST CI RUN 34282955601, push 344791a, 2026-09-08 22:07Z: the unit scheme green; in the UI scheme everything else passed but `OfflineSessionTests.testACheckedSetSurvivesAKillAndHomeOffersResume` FAILED at OfflineSessionTests.swift:52 — after "Start your first workout" no button whose label contains "set 1 of" appeared within 5 s; the xcresult with screenshots is in that run's `ios-test-results` artifact; the `ios` CI job is RED until this is fixed or the probe is adjusted) 8.4 state probes (XCUITest) — `CrewUITests/CameraDeniedTests.swift` (no camera → text-first posting completes) and `OfflineSessionTests.swift` (Resume-after-kill: start a session, terminate, relaunch, the Resume banner and the checked set survive; airplane mode is device-only and stays a manual 8.6 item). WRITTEN-UNVERIFIED; the CI ios job runs the scheme. Verify: next CI run. [SPEC: 8.4; S07; S09; E6]
- [x] Q10 (done: docs/OWNER-REVIEW.md rewritten 2026-09-08 evening) docs/OWNER-REVIEW.md regenerated — the four-state matrix (✅ DONE-VERIFIED / 📝 WRITTEN-UNVERIFIED / 🔌 BLOCKED-CREDENTIALS / ❌ NOT DONE) for T001–T047 and the ordered ship path. [SPEC: Appendix A continuous build (5)]
- [x] Q11 Deploy check — host = `crew-eta-one.vercel.app`; DONE 2026-09-08: `/api/v1/users/me` → 401 and `/` → 200 (18:50Z, after the Root Directory fix); `POST auth/register` → 201 against Atlas (22:03Z, after MONGODB_DB was reset to `crew`); **journey ① PASSED against production** at 22:08Z (`BASE_URL=https://crew-eta-one.vercel.app npx playwright test journey1 --project=desktop-1280`, 19.6 s: fresh visitor → questions → plan → save → first post → flame lit). Left in the beta database: that run's `j1-…@example.com` user, plan and post — drop the `crew` database from Atlas Data Explorer before real testers. The smoke account was deleted through `DELETE users/me` (see Q12). Never run the whole matrix against production: Vercel overwrites x-forwarded-for, so the G11 auth limit (10/min) counts every test from one address.
- [ ] Q12 SERVER: `DELETE users/me` reports a completed cascade as a failure when the "account deleted" email cannot be sent — seen on production 2026-09-08 22:10Z: the smoke account was gone (`users/me` → 404) but the response was 500, because `lib/account-delete.ts` awaits `sendAccountDeletedEmail` after the irreversible cascade and Resend's sandbox sender refuses any address but the account owner's. Fix: the email is best-effort after the cascade (try/catch + one log line; the response stays 200 with the cascade done — E9 promises the confirmation "states the cascade is done", not that the deletion waits on it); test: `account.test.ts` with a throwing transport (`RESEND_API_KEY` set to a junk key makes `deliver` throw) expects 200 and the cascade. Verify: `npm test tests/api/account`. [SPEC: E9; 8.2 Account; Part IV email touchpoints] [SPEC: XI T046; OWNER-REVIEW §5 step 6]

## Blockers

- OPERATING MODE (Appendix A, 2026-09-04): CONTINUOUS BUILD — no 🛑 stops the line; former checkpoints are self-reviews in docs/ratification.md; gaps get the most conservative in-spec call tagged `// GAP:`; iOS is WRITTEN-UNVERIFIED (no Xcode here; GitHub's macOS job is the compiler); no real credentials in the repo or the chat.
- BLOCKED-CREDENTIALS (owner steps, docs/testing-without-a-mac.md Stage 2): the Atlas password (production `MONGODB_URI` fails with "bad auth" — the owner is regenerating the `crew` user's password and replacing the variable; the Blob store `crew-photos` is still not connected) (T046) · the APNs key → Vercel (T033; the Team ID and bundle id are known) · a Services ID for web Sign in with Apple (T012) · an iPhone for the device pass (T028/T035/T043).
- OPEN OWNER DECISION (non-blocking): Firebase Auth ⏳ (Appendix B) — custom auth proceeds by default (12.5); nothing built against Firebase.
- Git is hook-blocked for the agent: commits are queued in `docs/commit-queue.sh` (FIX QUEUE section); the owner runs `& "C:\Program Files\Git\bin\bash.exe" C:/Users/princ/CREW_2.0/docs/commit-queue.sh` then `git push`.

## Notes for next session

- CI run 34351357853 (push 5374a2f, 2026-09-09 12:30Z): contracts ✓ · web ✓ · ios engine ✓ · ios ✗ with ONE diagnostic across the ~95 rewritten Swift files — `ShellStatesTests.swift:11: type 'PlanLoadState' has no member 'offline'` (the editor rewrite dropped the case); F23 restores it. The unit + UI test outcome is unknown until the next run. The web e2e job also failed on ONE check: the phone-375 a11y sweep measured 11 px of sideways scroll on a signed-in page under the Linux runner's fallback fonts (green here on Windows fonts). Reproduced locally by forcing a wide font: the Settings profile `<input type=file>` and the session exercise header (name · chip · Swap · Skip) overflowed; F23 makes the file input span the column and lets that header wrap, and the assertion now names the page.
- NEXT (2026-09-09): the owner runs the commit queue (F23) and pushes; the agent reads the CI run — the ~95 rewritten Swift files meet a compiler for the first time on the macOS job (expect a round of type fixes; the XCUITest journeys' selectors were kept but re-read them against the new Home/Plan copy), then `gh workflow run testflight.yml -f build_number=3` so the owner reinstalls the beta (the SwiftData schema changed — delete the old app first). Q09 (OfflineSessionTests) stays red until that run shows the new screens. Then the owner's Stage 2 steps: connect the Blob store (photo posts), the APNs key, the beta DB drop. Web is complete and green for A1–A8 (`npm test` 340 · e2e 23/1 skipped).
- Plan notes (5.6 map / 5.2 tree additions, all logged in R-055): shared/scripts holds generate · check-drift · render-spec-constants · render-ember · render-seed · check-vectors · vector-shapes · vector-invariants · check-seeds · doctrine-lint; Generated/ gains EmberTokens.swift; Api/ gains JSONValue.swift, HttpStatus.swift, KeychainStore.swift and per-resource Api*.swift files (C9); Storage/ gains SyncDriver, ServerHydrate, PlanLocal, GamificationLocal, AchievementFacts, PostPayloadPhotoStripper, SyncTransport, ModelsSocial; ios/ gains Package.swift + ExportOptions.plist + scripts/doctrine-lint.sh; `.github/workflows/testflight.yml`; web gains `api/cron/notifications`, `photos` routes, `crews/[id]/{stream,mute}`, `vercel.json`, `scripts/metrics.mjs`, `/journal`, `/onboarding` outside the (app) group (pre-auth by design, Flow 1); web/AGENTS.md + web/CLAUDE.md are written by `next dev`.
