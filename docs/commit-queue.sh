#!/usr/bin/env bash
# Crew — commit queue. The owner's user-locked hook blocks every state-changing git command for the agent,
# so the agent appends one block per completed task here (CLAUDE.md rule 6 / XI 11.1 step 6: one
# conventional commit per task with its [SPEC:] tag) and the owner runs the file from the repo root:
#     bash docs/commit-queue.sh
# Blocks are idempotent: a task whose files are already committed produces an empty commit attempt that
# git skips ("nothing to commit"). Run it whenever you like; the queue is append-only.
#
# Ordering rule (learned 2026-09-08, block S38): a block stages every listed path that has changes, so a later
# EDIT to a file lands in the FIRST block that names it — S38's CI fix was committed under older messages. Fix
# blocks go in the FIX QUEUE section right under commit_task, newest LAST, ahead of the history. Since F07 a block
# whose message is already in `git log` is skipped outright (it stages nothing), so only never-committed blocks
# can claim a file; among those the first one naming it wins — the shared ledgers (progress, ratification, this
# file) ride with the oldest uncommitted block.
set -u
cd "$(dirname "$0")/.."

commit_task() {
  local message="$1"; shift
  if [ -n "$(git log --fixed-strings --grep="$message" --format=%H -n 1)" ]; then echo "skip   (in history) $message"; return 0; fi
  git add -- "$@" 2>/dev/null
  if git diff --cached --quiet; then echo "skip   (nothing to commit) $message"; else git commit -q -m "$message" && echo "commit $message"; fi
}

# ===== FIX QUEUE — runs before the history; append new fix blocks at the END of this section =====

# --- F01 (the first Xcode compile, run 34226861952: one parse error, the module stopped there) ---
commit_task "fix(ios): MobilityHoldRow — a stored property named 'set' reads as a setter accessor inside a computed property; renamed setLog. First Xcode diagnostic; fix blocks now run ahead of the history [SPEC: S09; Flow 3; XI T025/T008]" \
  ios/Crew/Features/Session/MobilityHoldRow.swift ios/Crew/Features/Session/SessionScreen.swift docs/commit-queue.sh docs/debt.md docs/progress.md

# --- F02 (run 34227696962: one type error; CI now asks swiftc to keep going after the first failing batch) ---
commit_task "fix(ios): AuthStore compares the token's remaining seconds as TimeInterval; CI passes -continue-building-after-errors so one run reports every type error [SPEC: G11; C7; XI T012/T008]" \
  ios/Crew/Api/AuthStore.swift .github/workflows/ci.yml codemagic.yaml docs/commit-queue.sh docs/debt.md docs/progress.md

# --- F03 (run 34228245648: the whole module type-checks except one line) ---
commit_task "fix(ios): ProgressModel — the plan is optional to the heat map (a user without a plan still sees their days); the guard no longer unwraps it [SPEC: Flow 9; S15; XI T040]" \
  ios/Crew/Features/Progress/ProgressModel.swift docs/commit-queue.sh docs/progress.md

# --- F04 (run 34228816686: the app compiles, 49 unit tests ran, 51 vectors green under Xcode; one wrong expectation) ---
commit_task "test(ios): HomeModelTests — Friday of a Mon/Wed/Fri plan is Leg day (PPL cycles over the sorted days), the model was right; ios job gets a 45-minute timeout; ratification R-051 [SPEC: Flow 1 step 3; S07; 8.1; XI T024/T008]" \
  ios/CrewTests/HomeModelTests.swift .github/workflows/ci.yml docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- F05 (run 34243884907: the app runs on a simulator; journeys ①② fail on the server's timezone rule; S03 clipped) ---
commit_task "fix: a phone's timezone is whatever Intl can format with (Foundation says GMT on a UTC device — the seed and the app both got 400); S03 day toggles fit the screen (GAP, R-052); CI warms the API routes and keeps the dev-server log [SPEC: E8; S03; 1B; 6.3; 8.4; XI T021/T028/T035/T008]" \
  ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift ios/Crew/Features/Onboarding/SaveAuthScreen.swift ios/CrewUITests/Journey1_NewUserTests.swift ios/CrewUITests/SeedClient.swift web/src/lib/validate.ts web/tests/api/auth.test.ts .github/workflows/ci.yml codemagic.yaml docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- F06 (run 34246649543: every job green — journeys ①② pass on the simulator; two nits from the nine screenshots) ---
commit_task "fix(ui): S03 day circles inscribed in a column-wide 56 pt tap area (the F05 sizing collapsed to the letter); Home says '1 exercise' on both platforms; journeys ①② green on a simulator recorded (R-053) [SPEC: S03; 1B; Flow 2; 8.4; XI T021/T024/T028/T035]" \
  ios/Crew/Features/Home/TodayCard.swift ios/Crew/Features/Onboarding/PlanQuestionsScreen.swift "web/src/app/(app)/home/page.tsx" docs/ratification.md docs/progress.md docs/commit-queue.sh docs/OWNER-REVIEW.md docs/testing-without-a-mac.md

# --- F07 (Stage 2 begins: the accounts exist — a paid Apple program holding a Crew record, an Atlas M0 cluster, Vercel Hobby; three vendor limits checked against their own pages) ---
commit_task "chore(deploy): beta tier — Vercel Hobby runs the notifications cron daily (per-minute needs Pro); the TestFlight key must be Admin for cloud signing and TestFlight push is the production APNs; Stage 2 step list rewritten around the accounts that exist; the queue skips blocks already in git log; debt for M0 + open allowlist, the sandbox sender, the applinks placeholder; R-054 [SPEC: Part IV; XI T045/T046/T008]" \
  web/vercel.json .github/workflows/testflight.yml docs/testing-without-a-mac.md docs/debt.md docs/ratification.md docs/progress.md docs/OWNER-REVIEW.md docs/commit-queue.sh

# --- F08 (cold-start audit, R-055: the Playwright harness never reaches a real vendor; the stray ios/.env; APP_STORE_URL documented) ---
commit_task "fix(test): the e2e harness pins every vendor variable to empty so a local .env with real keys never mails or uploads; .env.example gains APP_STORE_URL [SPEC: rule 3b; Part IV; 8.7; XI T039/T046]" \
  web/tests/e2e/dev-server.mjs web/.env.example

# --- F09 (journey ① at phone-375 flaked under three workers: a pre-hydration fill seeds the React value tracker) ---
commit_task "fix(e2e): fillWhenHydrated waits on the labelled field and clears before every fill [SPEC: 8.4; 8.9; XI T039]" \
  web/tests/e2e/helpers.ts

# --- F10 (SERVER: the events route api.md promised since R-004, and the web funnel that feeds it) ---
commit_task "feat(api): POST events — client funnel events with their own timestamps, receivedAt from the server clock; the web queues hero → days → experience → plan built → saved and flushes after sign-up [SPEC: 1C; 1D; Part IV analytics; docs/api.md; 8.2; XI T006/T045]" \
  web/src/app/api/v1/events/route.ts web/src/lib/events.ts web/src/lib/funnel.ts web/src/lib/api-client.ts web/src/lib/documents-auth.ts web/src/components/FunnelStep.tsx web/src/components/onboarding/OnboardingFlow.tsx web/src/app/page.tsx web/tests/api/events.test.ts web/tests/api/standing-registry.ts docs/api.md

# --- F11 (SERVER: the one route with only standing checks; 8.3 validators; 8.3 DayKey unit tests on both engines) ---
commit_task "test: crews/[id]/mute round-trips per member and 404s outsiders; every input limit at the limit and one over; DayKey unit tests on both engines (3 AM boundary, DST both ways, date line, Monday weeks) [SPEC: E2; S17; 8.3; E8; E20; XI T016/T029]" \
  web/tests/api/crews.test.ts web/tests/engine/validators.test.ts web/tests/engine/day-key.test.ts ios/CrewTests/DayKeyTests.swift ios/Package.swift

# --- F12 (tree hygiene: the never-run Codemagic CI goes; C10 one screen per file in Crew/) ---
commit_task "chore: delete codemagic.yaml (Actions green on every job, Codemagic never ran, the owner's email was in a public file — debt repaid); MessageRow and CreateCrewScreen in their own files [SPEC: 5.2; C10; XI T008/T031]" \
  codemagic.yaml docs/testing-without-a-mac.md docs/debt.md ios/Crew/Features/Crew/MessageRow.swift ios/Crew/Features/Crew/CreateCrewScreen.swift ios/Crew/Features/Crew/StreamList.swift ios/Crew/Features/Crew/InviteScreen.swift

# --- F13 (8.4 state probes on the simulator; the audit's ledger, ratification and owner review) ---
commit_task "test(ios-ui): camera-denied → text-first post counts; a checked set survives a kill and Home offers Resume (WRITTEN — UNVERIFIED); docs: progress.md rewritten from the audit, R-055, OWNER-REVIEW four-state matrix [SPEC: 8.4; E5; S07; S09; S11; XI 11.3; T043]" \
  ios/CrewUITests/CameraDeniedTests.swift ios/CrewUITests/OfflineSessionTests.swift docs/progress.md docs/ratification.md docs/OWNER-REVIEW.md docs/commit-queue.sh

# --- F14 (the server is live at crew-eta-one.vercel.app after the Root Directory fix; the journeys can run against a deployment) ---
commit_task "test(e2e): BASE_URL runs the Playwright journeys against a deployment (no local server, no warm-up; one journey at one viewport under the G11 limit); the live host, the Root Directory fix and the variables still owed recorded [SPEC: 8.4; 8.7; XI T039/T046; OWNER-REVIEW §5 step 6]" \
  web/playwright.config.ts docs/progress.md docs/testing-without-a-mac.md docs/commit-queue.sh

# --- F15 (first TestFlight run 34281494452: the archive signed itself in the cloud; App Store Connect refused the upload for want of an icon) ---
commit_task "feat(ios): app icon — the 1024 px single-size asset catalog and ASSETCATALOG_COMPILER_APPICON_NAME, so App Store Connect accepts the archive (ITMS 90022/90713/90023); first TestFlight run and the live server recorded (R-056) [SPEC: Part IV; XI T045/T046]" \
  ios/Crew/Assets.xcassets ios/project.yml docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F16 (run 34282978517: build 2 uploaded — the native app reaches App Store Connect from Windows) ---
commit_task "docs: TestFlight build 2 uploaded (run 34282978517, every step green); journey ① green against the live server once MONGODB_DB was reset to crew; the delete-cascade-then-email finding queued as Q12; progress and R-056 record it, the phone install is the next owner step [SPEC: XI T045/T046; Part X Phase 6; E9]" \
  docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F17 (TestFlight showed the earlier product's sloth; the owner wants nothing of that app involved) ---
commit_task "feat(ios): the app icon is the Ember flame on the bone canvas (shared/brand/app-icon.svg → opaque 1024 px PNG), replacing the earlier product's mark [SPEC: Part III (Ember: flame = streak; bone canvas; launch frame); XI T045]" \
  ios/Crew/Assets.xcassets/AppIcon.appiconset/AppIcon.png shared/brand/app-icon.svg docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F18 (run 34285838041: the flame build uploaded; the first CI run of the audit's UI probes) ---
commit_task "docs: the flame build uploaded (run 34285838041); the first CI run of the 8.4 probes — OfflineSessionTests fails at the set button (Q09 notes it); Q12 delete-then-email finding [SPEC: XI T045; 8.4; E9]" \
  docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F19 (the owner's smoke test became Appendix A amendments A1–A8; the contracts: constants, cardio seed, V51, the engine twins on both engines) ---
commit_task "feat(shared): A1 PPL rotation + A2 cardio contracts — trainingWeekdays plans that always carry Push · Pull · Legs, PlanRotation/DayLabel/SessionSummaryLine twins, nine cardio activities, cardio/journal constants, V51; the improvement plan and Appendix A 2026-09-08 [SPEC: A1; A2; A6; 8.1; 8.3; XI T001/T004/T020]"   shared/spec-constants.json shared/seed/exercises.json shared/seed/plan-templates.json shared/scripts/check-seeds.mjs shared/scripts/render-seed.mjs shared/vectors/completion.vectors.json   ios/Crew/Generated/SpecConstants.swift ios/Crew/Generated/SeedData.swift web/src/generated/spec-constants.ts web/src/generated/seed.ts   ios/Crew/Engine/PlanGenerator.swift ios/Crew/Engine/PlanRotation.swift ios/Crew/Engine/DayLabel.swift ios/Crew/Engine/SessionSummaryLine.swift ios/Package.swift   ios/CrewTests/PlanGeneratorTests.swift ios/CrewTests/PlanRotationTests.swift ios/CrewTests/DayLabelTests.swift ios/CrewTests/SessionSummaryLineTests.swift   web/src/lib/engine/plan-generator.ts web/src/lib/engine/plan-rotation.ts web/src/lib/engine/day-label.ts web/src/lib/engine/session-summary-line.ts   web/tests/engine/plan-generator.test.ts web/tests/engine/plan-rotation.test.ts web/tests/engine/day-label.test.ts web/tests/engine/session-summary-line.test.ts   docs/improvement-plan-2026-09-08.md docs/crew-mvp-spec.md docs/debt.md docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- F20 (the server and the web client behind the amendments) ---
commit_task "feat(api): plans carry trainingWeekdays + an ordered rotation (legacy documents normalised on read); sessions carry workoutKind, distanceMeters and a summary line; today-state, the reminder cron and progress facts read the rotation; notificationPrefs, GET blocks, profilePhotoKey ownership; api.md [SPEC: A1; A2; A3; A6; A7; 8.2; XI T023/T029/T033/T041]"   docs/api.md web/src/app/api/cron/notifications/route.ts web/src/app/api/v1/blocks/route.ts web/src/app/api/v1/plans/route.ts web/src/app/api/v1/users/me/route.ts   web/src/lib/api-client-crew.ts web/src/lib/api-client.ts web/src/lib/blocks.ts web/src/lib/documents-social.ts web/src/lib/documents.ts web/src/lib/export.ts   web/src/lib/notification-eligibility.ts web/src/lib/notification-facts.ts web/src/lib/plans.ts web/src/lib/posts.ts web/src/lib/progress-facts.ts web/src/lib/sessions.ts   web/src/lib/today-state.ts web/src/lib/users.ts web/src/lib/validate-plans.ts web/src/lib/validate-sessions.ts web/src/lib/validate.ts   web/tests/api/account.test.ts web/tests/api/cron-notifications.test.ts web/tests/api/db.test.ts web/tests/api/moderation.test.ts web/tests/api/plans-sessions.ts   web/tests/api/plans.test.ts web/tests/api/sessions.test.ts web/tests/api/standing-registry.ts web/tests/api/sync.test.ts web/tests/e2e/helpers.ts   web/tests/engine/notification-eligibility.test.ts web/tests/engine/validators.test.ts

# --- F21 (the iPhone app: every screen the owner reviewed, rebuilt to the amendments — WRITTEN-UNVERIFIED until the macOS job compiles it) ---
commit_task "feat(ios): A1–A8 — rotation-driven Home with next-up, bonus workout and cardio log; the week map → workout editor → exercise sheet; CardioRow; journal day labels and summary lines; the crew strip on top, the crew-of-one card, report/block; profile photo, notification toggles, blocked people, legal pages, a real log out; sync keeps a counted-but-undelivered post's streak (E19) [SPEC: A1–A8; S07; S09; S12; S14–S17; XI T024/T025/T031/T040/T041]"   ios/Crew/Api/Api.swift ios/Crew/Api/ApiCrews.swift ios/Crew/Api/ApiModels.swift ios/Crew/Api/ApiPhotos.swift ios/Crew/Api/ApiPlans.swift ios/Crew/Api/ApiSessions.swift ios/Crew/Api/ApiSettings.swift   ios/Crew/CrewApp.swift ios/Crew/Shared/AvatarView.swift   ios/Crew/Features/Crew ios/Crew/Features/Home ios/Crew/Features/Onboarding ios/Crew/Features/Plan ios/Crew/Features/Post ios/Crew/Features/Progress ios/Crew/Features/Session ios/Crew/Features/Settings   ios/Crew/Storage/Models.swift ios/Crew/Storage/ModelsSocial.swift ios/Crew/Storage/PlanLocal.swift ios/Crew/Storage/ServerHydrate.swift ios/Crew/Storage/Store.swift ios/Crew/Storage/SyncDelivery.swift ios/Crew/Storage/SyncDriver.swift ios/Crew/Storage/SyncQueue.swift ios/Crew/Storage/SyncTransport.swift   ios/CrewTests/AchievementsLocalTests.swift ios/CrewTests/HomeModelEdgeTests.swift ios/CrewTests/HomeModelTests.swift ios/CrewTests/OnboardingModelTests.swift ios/CrewTests/ServerHydrateTests.swift ios/CrewTests/SessionModelTests.swift ios/CrewTests/SyncDeliveryTests.swift ios/CrewTests/SyncQueueTests.swift ios/CrewUITests/SeedClient.swift

# --- F22 (the web app, full parity, green on typecheck · lint · 340 tests · build · 23 e2e) ---
commit_task "feat(web): A1–A8 parity — Home next-up/bonus/cardio, /log-cardio, CardioRow, the /plan week map and /plan/[kind] editor with the exercise sheet, onboarding projection, crew solo explainer + crew-of-one invite card + report/block, journal day groups and summary lines, progress minutes, Settings profile photo / notification toggles / blocked people / legal links, /privacy and /terms drafts [SPEC: A1–A8; Part IV parity; 8.4; 8.5; XI T036–T040]"   "web/src/app/(app)/home" "web/src/app/(app)/journal" "web/src/app/(app)/log-cardio" "web/src/app/(app)/plan" "web/src/app/(app)/post/page.tsx" "web/src/app/(app)/progress/page.tsx" "web/src/app/(app)/session"   web/src/app/privacy web/src/app/terms web/src/app/app.css web/src/lib/plan-draft.ts web/src/components   web/tests/e2e/a11y.spec.ts web/tests/e2e/journey1.spec.ts web/tests/e2e/journey4-web-parity.spec.ts web/tests/e2e/warm-up.ts


# --- F23 (run 34351357853: the whole rewritten app compiled first time; one test named the offline state the editor dropped; the phone-375 a11y sweep found 11 px of sideways scroll under the runner's fonts) ---
commit_task "fix: PlanLoadState keeps its offline case (6.1 five states); the settings file input and the session exercise header stay inside a 375-wide column under wide fallback fonts; the overflow assertion names its page [SPEC: 6.1; 6.7; 8.9; S14; XI T013/T039]" \
  ios/Crew/Features/Plan/PlanScreen.swift web/src/app/app.css web/src/components/SessionLogger.tsx web/tests/e2e/helpers.ts web/tests/e2e/a11y.spec.ts docs/commit-queue.sh docs/progress.md

# --- F24 (run 34354352786: 89 unit tests ran, two SyncDeliveryTests cases were wrong about their own clock and about JSON slash escaping; the owner asked for local checks before the next GitHub failure) ---
commit_task "fix(ios): SyncDeliveryTests enqueue and step the queue on one clock (an op is not due before nextAttemptAt); attachPhotoKey and the photo stripper re-serialise without escaping slashes, so the stored payload reads as the encoder wrote it [SPEC: 5.6.3; E19; A3; A6; XI T014]" \
  ios/CrewTests/SyncDeliveryTests.swift ios/Crew/Storage/SyncDelivery.swift ios/Crew/Storage/PostPayloadPhotoStripper.swift
commit_task "feat(ci): swift-xref — a compiler-free Swift cross-reference check that reproduces every compile error the macOS job has reported (first step of the contracts job, and the local pre-push command); the ios job runs unit + journeys even when unit fails and writes a verdict summary; the e2e overflow check measures again under a wide fallback font and names the element — it caught the crew header pushing the pulse 9 px past a 375 edge, which now wraps [SPEC: 5.3; 6.7; 8.1; 8.4; 8.9; XI T008/T043]" \
  shared/scripts/swift-xref.mjs .github/workflows/ci.yml web/tests/e2e/helpers.ts web/src/components/CrewHeader.tsx docs/testing-without-a-mac.md docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F25 (run 34360394481: unit 89/0; journeys 3/5 — journey ① and Q09 both failed at the set row, read from the xcresult's accessibility dump: the row was not a button and the card was 484 pt wide on a 402 pt window) ---
commit_task "fix(ios): a set row is a button to VoiceOver and XCUITest and wraps its steppers under the label so no session card passes a 375-pt edge; exercise names wrap; journey ① trains every day and the journeys measure that the row, Skip and Complete sit inside the window (the iOS twin of the web overflow check); the day-toggle step shared on its third use [SPEC: 6.7; E20; S09; 8.4; 8.9; XI T025/T028/T043]" \
  ios/Crew/Features/Session/SetRow.swift ios/Crew/Features/Session/SessionScreen.swift ios/CrewUITests/JourneySteps.swift ios/CrewUITests/Journey1_NewUserTests.swift ios/CrewUITests/OfflineSessionTests.swift ios/CrewUITests/CameraDeniedTests.swift docs/testing-without-a-mac.md docs/progress.md docs/ratification.md docs/commit-queue.sh

# --- F26 (run 34364030257: the set row is a button and fits — and its centre is the weight stepper's minus, so the journeys' tap set the weight to 0 instead of checking the set) ---
commit_task "fix(ios): the check button is the set row to VoiceOver and XCUITest — it carries the row's full label and hint, the container holds its children, and every stepper button names what it changes (Decrease reps, Increase weight, Decrease minutes, Increase sets) [SPEC: E20; Flow 3; S09; 6.7; 8.4; XI T025/T028/T043]" \
  ios/Crew/Features/Session/SetRow.swift ios/Crew/Features/Session/CardioRow.swift ios/Crew/Features/Plan/ExerciseSheet.swift docs/progress.md docs/ratification.md docs/commit-queue.sh

# ===== HISTORY — kept for the record only; it never runs. 49 of the 62 blocks below are in git log (the guard would skip
# them), the other 13 — S38 and twelve docs/test blocks — found nothing left to stage when their turn came, because an
# earlier block naming the same files had already swept their changes in (the S38 class). Left live, those 13 would still
# stage any future edit to a ledger they name, so the queue stops here. =====

exit 0


# --- S03 ---
commit_task "feat(shared): seed exercises.json (101, swap-covered) + check-seeds; continuous-build amendment + T003 ratification logged [SPEC: Appendix B; Part IX seed; XI T004]" \
  docs/crew-mvp-spec.md docs/ratification.md docs/progress.md docs/commit-queue.sh shared/seed/exercises.json shared/scripts/check-seeds.mjs
commit_task "feat(shared): plan-templates.json — PPL × experience × equipment + Full-Body A/B + mobility blocks [SPEC: Flow 1 step 3; G7; XI T005]" \
  shared/seed/plan-templates.json

# --- S04 ---
commit_task "feat(shared): achievements.json (15) + docs/api.md contract; generate emits SeedData.swift + seed.ts [SPEC: Appendix B; 5.6.4; 8.2; XI T006]" \
  shared/seed/achievements.json docs/api.md shared/scripts/render-seed.mjs shared/scripts/generate.mjs ios/Crew/Generated/SeedData.swift web/src/generated/seed.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S05 ---
commit_task "chore(scaffold): monorepo — Next.js 16 TS-strict web app, XcodeGen iOS project spec, .env.example, layout constants in ember.css [SPEC: Part V 5.2; XI T007]" \
  .gitignore web/package.json web/package-lock.json web/tsconfig.json web/next.config.ts web/vitest.config.ts web/playwright.config.ts web/.prettierrc web/.env.example web/src/app/layout.tsx web/src/app/app.css web/src/app/page.tsx web/src/generated shared/scripts/render-ember.mjs shared/scripts/render-seed.mjs shared/scripts/generate.mjs ios/project.yml ios/Crew/CrewApp.swift ios/Crew/RootView.swift ios/CrewTests/SpecConstantsTests.swift ios/CrewUITests/LaunchTests.swift docs/crew-mvp-spec.md docs/ratification.md docs/progress.md docs/commit-queue.sh
commit_task "chore(ci): pipeline + doctrine lint (ESLint rules, Swift/CSS scanner) [SPEC: Part V 5.3; Part X Phase 1; XI T008]" \
  .github/workflows/ci.yml web/eslint.config.mjs shared/scripts/doctrine-lint.mjs ios/scripts/doctrine-lint.sh web/src/lib/http-status.ts web/src/lib/crypto-params.ts web/src/lib/time-units.ts

# --- S06 ---
commit_task "feat(web): lib/db.ts — Mongo client, typed collections, Part IX unique indexes + real-db test [SPEC: Part IX; C4; XI T009]" \
  web/src/lib/db.ts web/src/lib/documents.ts web/src/lib/documents-social.ts web/src/lib/documents-auth.ts web/tests/setup/mongo-global.ts web/tests/setup/env.ts web/tests/api/db.test.ts web/vitest.config.ts
commit_task "feat(web): server auth — register/login/refresh/logout with scrypt, jose JWTs, rotating refresh, cookies, rate limit [SPEC: Part IV; G11; E9; XI T010]" \
  web/src/lib/api-error.ts web/src/lib/password.ts web/src/lib/auth.ts web/src/lib/refresh-tokens.ts web/src/lib/rate-limit.ts web/src/lib/validate.ts web/src/lib/events.ts web/src/lib/users.ts web/src/lib/auth-response.ts web/src/app/api/v1/auth/register/route.ts web/src/app/api/v1/auth/login/route.ts web/src/app/api/v1/auth/refresh/route.ts web/src/app/api/v1/auth/logout/route.ts web/tests/api/http.ts web/tests/api/auth.test.ts shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts

# --- S07 ---
commit_task "feat(web): lib/email.ts (Resend, three touchpoints, outbox substitute) + password reset flow [SPEC: Part IV email; 8.2 Auth; XI T011]" \
  web/src/lib/email.ts web/src/lib/password-resets.ts web/src/app/api/v1/auth/reset/route.ts web/src/app/api/v1/auth/reset/confirm/route.ts web/tests/api/auth-reset.test.ts
commit_task "feat(auth): Sign in with Apple — server verification (jose JWKS), web callback + button, iOS AuthStore/Keychain [SPEC: Part IV; 1C; XI T012]" \
  web/src/lib/apple-auth.ts web/src/lib/apple-sign-in.ts web/src/app/api/v1/auth/apple/route.ts web/src/app/api/v1/auth/apple/callback/route.ts web/src/components/SignInWithAppleButton.tsx web/tests/api/apple-jwks.ts web/tests/api/auth-apple.test.ts ios/Crew/Api/AuthStore.swift ios/Crew/Api/KeychainStore.swift web/package.json shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S08 / S09 ---
commit_task "feat(ios): shells — RootView tabs, Api transport + DTOs, SwiftData Store + models, Shared five-state components (WRITTEN — UNVERIFIED) [SPEC: 5.2; 6.1; XI T013]" \
  ios/Crew/AppError.swift ios/Crew/TimeUnits.swift ios/Crew/RootView.swift ios/Crew/Api/Api.swift ios/Crew/Api/ApiModels.swift ios/Crew/Api/HttpStatus.swift ios/Crew/Storage/Store.swift ios/Crew/Storage/Models.swift ios/Crew/Storage/ModelsSocial.swift ios/Crew/Shared ios/Crew/Features ios/CrewTests/ShellStatesTests.swift shared/design-tokens.json shared/spec-constants.json shared/scripts/render-ember.mjs shared/scripts/generate.mjs shared/scripts/doctrine-lint.mjs ios/Crew/Generated web/src/generated
commit_task "feat(ios): SyncQueue — OpRecord, FIFO backoff, poison handling, reconcile, E19 choices + in-memory tests (WRITTEN — UNVERIFIED) [SPEC: 5.6.3; E6; E19; XI T014]" \
  ios/Crew/Storage/SyncQueue.swift ios/Crew/Storage/PostPayloadPhotoStripper.swift ios/Crew/Api/ApiSync.swift ios/CrewTests/SyncQueueTests.swift
commit_task "test(web): standing-checks generator ①–④ over every route + registry [SPEC: 8.2; XI T015]" \
  web/tests/api/standing-checks.gen.test.ts web/tests/api/standing-registry.ts web/tests/api/fixtures.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S10 / S11 ---
commit_task "feat(engine): DayKey twin — 3 AM boundary, Monday weeks, DST in the user's favor; TS vectors V05–V10 green [SPEC: E8; E20; XI T016]" \
  web/src/lib/engine/day-key.ts ios/Crew/Engine/DayKey.swift web/tests/vectors.test.ts ios/CrewTests/VectorRunnerTests.swift ios/CrewTests/VectorFiles.swift web/eslint.config.mjs
commit_task "feat(engine): gamification twin — streak, XP, shields, pause, undo, recompute, completion, pause validation, crew rules; all 45 vectors green on TS [SPEC: Part VIII; 5.6.1; XI T017–T019 (+T032 engine)]" \
  web/src/lib/engine ios/Crew/Engine ios/CrewTests/VectorRunnerCrewTests.swift shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S12 ---
commit_task "feat(engine): PlanGenerator + SwapFinder twins + property tests (1143 plans; 3–5 swaps everywhere) [SPEC: Flow 1 steps 3–4; 8.3; XI T020]" \
  web/src/lib/engine/plan-generator.ts web/src/lib/engine/swap-finder.ts web/tests/engine ios/Crew/Engine/SeedCatalog.swift ios/Crew/Engine/PlanGenerator.swift ios/Crew/Engine/SwapFinder.swift ios/CrewTests/PlanGeneratorTests.swift ios/CrewTests/SwapFinderTests.swift docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S13 / S14 ---
commit_task "feat(ios): onboarding — questions, reveal, swap sheet, save/auth, login, draft persistence (WRITTEN — UNVERIFIED) [SPEC: S02–S05; 1A–1C; XI T021–T022]" \
  ios/Crew/Features/Onboarding ios/Crew/Api/ApiPlans.swift ios/Crew/RootView.swift ios/CrewTests/OnboardingModelTests.swift shared/design-tokens.json shared/scripts/render-ember.mjs ios/Crew/Generated web/src/generated
commit_task "feat(api): plans, sessions, sync routes — snapshots, idempotency, warm-up exclusion, holds, completion → post, recompute [SPEC: docs/api.md; 8.2; XI T023]" \
  web/src/lib/server-clock.ts web/src/lib/validate-plans.ts web/src/lib/validate-sessions.ts web/src/lib/validate-posts.ts web/src/lib/gamification-store.ts web/src/lib/plans.ts web/src/lib/posts.ts web/src/lib/sessions.ts web/src/lib/sync-ops.ts web/src/app/api/v1/plans web/src/app/api/v1/sessions web/src/app/api/v1/sync web/tests/api/plans-sessions.ts web/tests/api/plans.test.ts web/tests/api/sessions.test.ts web/tests/api/sync.test.ts web/tests/api/standing-registry.ts web/tests/api/standing-checks.gen.test.ts shared/spec-constants.json docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S17 (web halves, pulled forward) ---
commit_task "feat(api): posts routes — create/journal/caption/delete (post ≠ log), reactions crew-gated, 3-meal cap [SPEC: docs/api.md posts; E3; V26; XI T026]" \
  web/src/lib/reactions.ts web/src/app/api/v1/posts web/tests/api/posts.test.ts
commit_task "feat(api): photos — sharp EXIF/GPS strip + resize ≤ 300 KB, unguessable keys, auth-checked read, local blob substitute [SPEC: E3; 8.7; 8.8; XI T027]" \
  web/src/lib/blob.ts web/src/lib/photos.ts web/src/app/api/v1/photos web/tests/api/photos.test.ts web/tests/api/standing-registry.ts shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S15 / S16 / S17 (iOS halves) ---
commit_task "feat(ios): Home — today-state machine, bridge, quick complete, resume, ring, crew strip; local engine persistence (WRITTEN — UNVERIFIED) [SPEC: S07; 1D; XI T024]" \
  ios/Crew/Features/Home ios/Crew/Storage/GamificationLocal.swift ios/Crew/Storage/ModelsSocial.swift ios/Crew/Api/ApiSessions.swift ios/Crew/Features/Session/SessionActions.swift ios/CrewTests/HomeModelTests.swift
commit_task "feat(ios): Session — set rows, ghost row, warm-ups, holds, rest timer, plate math, celebration (WRITTEN — UNVERIFIED) [SPEC: S09; S10; Flow 3; XI T025–T026]" \
  ios/Crew/Features/Session ios/Crew/Engine/PlateMath.swift ios/Crew/Engine/MealTag.swift web/src/lib/engine/plate-math.ts web/src/lib/engine/meal-tag.ts web/tests/engine/plate-math.test.ts web/tests/engine/meal-tag.test.ts ios/CrewTests/SessionModelTests.swift
commit_task "feat(ios): nutrition posting — camera-first, library, time-smart tags, same-as-yesterday, outbox photo upload (WRITTEN — UNVERIFIED) [SPEC: S11; Flow 4; E19; XI T027]" \
  ios/Crew/Features/Post ios/Crew/Api/ApiPhotos.swift ios/Crew/Storage/SyncTransport.swift ios/Crew/Storage/SyncQueue.swift shared/spec-constants.json ios/Crew/Generated web/src/generated docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S18 / S19 ---
commit_task "test(ios): journey ① XCUITest — fresh install → first post → celebration (WRITTEN — UNVERIFIED) [SPEC: 8.4; XI T028]" \
  ios/CrewUITests/Journey1_NewUserTests.swift
commit_task "feat(api): crews — create/join/invite/members/rename/mute, Captain rules, auto-pass, archive, unified stream [SPEC: Flow 6; E2; docs/api.md; XI T029]" \
  web/src/lib/validate-crews.ts web/src/lib/crews.ts web/src/lib/crew-stream.ts web/src/app/api/v1/crews web/tests/api/crews.test.ts
commit_task "feat(api): messages + reactions + blocks — limits, tombstones, Captain delete, un-react, both-way filtering, sync ops [SPEC: E9; E20; V27; docs/api.md; XI T030 (+T034 blocks)]" \
  web/src/lib/crew-messages.ts web/src/lib/blocks.ts web/src/app/api/v1/blocks web/src/lib/sync-ops.ts web/tests/api/messages.test.ts web/tests/api/fixtures.ts web/tests/api/standing-registry.ts docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S20 / S21 / S22 ---
commit_task "feat(ios): Crew — model with polling + snapshot, stream, post cards, reactions, member strip, invite/create (WRITTEN — UNVERIFIED) [SPEC: S12–S13; Flow 6; XI T031–T032]" \
  ios/Crew/Features/Crew ios/Crew/Api/ApiCrews.swift ios/Crew/Api/ApiPhotos.swift
commit_task "feat(notifications): push-token route, apns2 lib + outbox substitute, eligibility rules + tests, cron sender [SPEC: Flow 2; Flow 4; E5; XI T033]" \
  web/src/lib/push.ts web/src/lib/notification-eligibility.ts web/src/lib/notification-facts.ts web/src/app/api/v1/push-token web/src/app/api/cron web/vercel.json web/.env.example web/tests/engine/notification-eligibility.test.ts web/tests/api/cron-notifications.test.ts shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts
commit_task "feat(moderation): reports → Resend queue email; Keychain-only static check in the doctrine scan [SPEC: E9; 8.7; XI T034]" \
  web/src/app/api/v1/reports web/tests/api/moderation.test.ts web/tests/api/standing-registry.ts web/tests/api/standing-checks.gen.test.ts shared/scripts/doctrine-lint.mjs ios/CrewUITests/Journey2_FastLogTests.swift docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S24 / S25 ---
commit_task "feat(web): onboarding + hero + login + reset + invite landing + home, app shell with silent refresh [SPEC: S02–S07; W1; 1A–1D; XI T036]" \
  web/src/lib/session.ts web/src/lib/api-client.ts web/src/lib/api-client-crew.ts web/src/lib/today-state.ts web/src/lib/geometry.ts web/src/app/page.tsx web/src/app/onboarding web/src/app/login web/src/app/reset web/src/app/join web/src/app/\(app\)/layout.tsx web/src/app/\(app\)/home web/src/app/app.css web/src/components/SessionKeeper.tsx web/src/components/EmptyState.tsx web/src/components/StreakFlame.tsx web/src/components/WeeklyRing.tsx web/src/components/onboarding web/src/components/LoginForm.tsx web/src/components/ResetForm.tsx web/src/components/JoinButton.tsx web/src/components/DraftFlusher.tsx web/src/components/QuickCompleteButton.tsx web/eslint.config.mjs web/tsconfig.json
commit_task "feat(web): session logging (set/hold rows, plate math, complete → celebration) + nutrition posting [SPEC: S09–S11; Flow 3–4; XI T037]" \
  web/src/lib/last-time.ts web/src/app/\(app\)/session web/src/app/\(app\)/post web/src/components/SetRow.tsx web/src/components/HoldRow.tsx web/src/components/SessionLogger.tsx web/src/components/PostComposer.tsx docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S26 / S29 (web halves) ---
commit_task "feat(api): users/me (profile, delete cascade), export, pause routes + account suite [SPEC: E9; E18; Flow 7; 8.2 Account/Pause; XI T041]" \
  web/src/lib/pauses.ts web/src/lib/account-delete.ts web/src/lib/export.ts web/src/app/api/v1/users web/src/app/api/v1/pause web/src/lib/sync-ops.ts web/tests/api/account.test.ts web/tests/api/standing-registry.ts
commit_task "feat(web): crew stream/chat, plan editor, progress, settings pages + Playwright harness and journeys [SPEC: S12–S17; Flow 6–9; 8.4; XI T038, T040, T041 web]" \
  web/src/app/\(app\)/crew web/src/app/\(app\)/plan web/src/app/\(app\)/progress web/src/app/\(app\)/settings web/src/components/CrewView.tsx web/src/components/CrewHeader.tsx web/src/components/StreamList.tsx web/src/components/CrewInvitePanel.tsx web/src/components/PlanEditor.tsx web/src/components/HeatMap.tsx web/src/components/SettingsView.tsx web/src/lib/progress-facts.ts web/tests/e2e web/tests/token-parity.test.ts web/playwright.config.ts web/eslint.config.mjs docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S27 (T039) / S26 / S29 (iOS halves) / S30 (T042) ---
commit_task "test(web): Playwright matrix green ①③④ × 375/768/1280 — WebKit hydration wait, per-context client IPs, 375 layout fixes [SPEC: 8.4; 8.9; XI T039]" \
  web/playwright.config.ts web/tests/e2e/helpers.ts web/tests/e2e/journey1.spec.ts web/tests/e2e/journey3-invite.spec.ts web/tests/e2e/journey4-web-parity.spec.ts web/src/app/app.css web/src/components/PlanEditor.tsx
commit_task "feat(ios): Progress + Journal (heat map, rings history, layer-3 charts) and Settings (pause, export, delete) — WRITTEN — UNVERIFIED [SPEC: S15–S17; Flow 7; Flow 9; E9; XI T040–T041]" \
  ios/Crew/Features/Progress ios/Crew/Features/Settings/SettingsModel.swift ios/Crew/Features/Settings/SettingsScreen.swift ios/Crew/Features/Settings/PauseScreen.swift ios/Crew/Features/Settings/ExportView.swift ios/Crew/Api/ApiSettings.swift shared/spec-constants.json web/src/generated/spec-constants.ts ios/Crew/Generated/SpecConstants.swift web/src/lib/progress-facts.ts
commit_task "feat(edge): welcome back (E4), stale-session prompt (S01), failed-upload choice (E19) on both platforms; signed-in Rebuild; PlanLocal writer; iOS S14 plan editor; launch signposts [SPEC: E4; S18; S01; E19; Flow 8; XI T042]" \
  web/src/lib/lapsed-user.ts web/tests/engine/lapsed-user.test.ts web/src/components/WelcomeBack.tsx web/src/components/StaleSessionPrompt.tsx web/src/lib/today-state.ts web/src/app/\(app\)/home/page.tsx web/src/lib/documents.ts web/src/lib/users.ts web/src/lib/validate.ts web/src/lib/api-client-crew.ts web/tests/api/welcome-back.test.ts web/src/app/onboarding/page.tsx web/src/components/onboarding/OnboardingClient.tsx web/src/components/onboarding/OnboardingFlow.tsx docs/api.md \
  ios/Crew/Engine/LapsedUser.swift ios/CrewTests/LapsedUserTests.swift ios/CrewTests/HomeModelEdgeTests.swift ios/Crew/Features/Home ios/Crew/Features/Settings/WelcomeBackScreen.swift ios/Crew/Features/Onboarding/OnboardingFlow.swift ios/Crew/Features/Onboarding/OnboardingModel.swift ios/Crew/Storage/PlanLocal.swift ios/Crew/Features/Plan ios/Crew/Api/ApiModels.swift ios/Crew/Api/AuthStore.swift ios/Crew/Shared/Signposts.swift ios/Crew/CrewApp.swift docs/ratification.md docs/progress.md docs/commit-queue.sh

# --- S31 (T043 / T044) ---
commit_task "test(web): a11y substitute audit + responsiveness sweep + keyboard check; empty states are the page heading; settings timezone list from the server [SPEC: 8.5; 8.9; 6.5; XI T043]" \
  web/tests/e2e/a11y.spec.ts web/src/components/EmptyState.tsx web/src/components/SettingsView.tsx web/src/app/\(app\)/settings/page.tsx .github/workflows/ci.yml
commit_task "test(api): posting rate limit 60/hour/user proven; security sweep recorded [SPEC: G11; 8.7; XI T044]" \
  web/tests/api/rate-limit-posts.test.ts docs/ratification.md docs/progress.md docs/debt.md docs/commit-queue.sh

# --- END OF THE CONTINUOUS BUILD: the owner review + the files next dev keeps re-adding ---
commit_task "docs: OWNER-REVIEW — everything ratifiable, everything deferred, the ordered steps to ship [SPEC: XI 11.3; Appendix A continuous build]" \
  docs/OWNER-REVIEW.md docs/progress.md docs/ratification.md docs/debt.md docs/commit-queue.sh web/CLAUDE.md web/AGENTS.md

# --- S32 (achievements awarding pass; T006 debt repaid) ---
commit_task "feat(engine): achievements awarding pass — README kind achievements, vectors V45–V50, tallies, personal records, crew full pulse; server pass + newAchievementIds; web celebration; Swift twins (WRITTEN — UNVERIFIED) [SPEC: Appendix B achievements; V35; E8; 8.1 V45–V50; Appendix A 2026-09-04]" \
  shared/vectors/README.md shared/vectors/achievements.vectors.json shared/scripts/vector-shapes.mjs shared/scripts/check-vectors.mjs \
  web/src/lib/engine/achievements.ts web/src/lib/engine/personal-records.ts web/src/lib/engine/crew-rules.ts web/src/lib/engine/gamification.ts web/src/lib/engine/gamification-post.ts web/src/lib/engine/gamification-day.ts web/src/lib/achievement-facts.ts web/src/lib/gamification-store.ts web/src/lib/api-client.ts web/src/components/EarnedAchievements.tsx web/src/components/SessionLogger.tsx web/src/components/QuickCompleteButton.tsx web/src/components/PostComposer.tsx web/src/app/\(app\)/session/\[id\]/done/page.tsx web/src/app/\(app\)/home/page.tsx web/tests/vectors.test.ts web/tests/engine/achievements.test.ts web/tests/api/achievements.test.ts \
  ios/Crew/Engine/Achievements.swift ios/Crew/Engine/PersonalRecords.swift ios/Crew/Engine/CrewRules.swift ios/Crew/Engine/GamificationEngine.swift ios/Crew/Engine/GamificationPost.swift ios/Crew/Engine/GamificationDay.swift ios/Crew/Storage/AchievementFacts.swift ios/Crew/Storage/GamificationLocal.swift ios/Crew/Features/Session/SessionActions.swift ios/CrewTests/VectorRunnerTests.swift ios/CrewTests/AchievementsTests.swift \
  docs/api.md docs/crew-mvp-spec.md docs/ratification.md docs/debt.md docs/progress.md docs/commit-queue.sh

commit_task "test(api): crew fixtures live in UTC like their posts (the 3 AM rule made the suite clock-dependent between midnight and 3 AM Pacific) [SPEC: E8 day boundary; 8.2]" \
  web/tests/api/crews.test.ts web/tests/api/messages.test.ts web/tests/api/moderation.test.ts docs/OWNER-REVIEW.md

# --- S33 (E7 swap + G9 rest timer both platforms; web journal; metrics report; registry audit) ---
commit_task "feat(session): mid-workout swap (Just today · Update my plan) and an adjustable rest timer on web and iOS (iOS WRITTEN — UNVERIFIED) [SPEC: E7; G9; Flow 3; Flow 8]" \
  web/src/components/SessionSwap.tsx web/src/components/RestTimer.tsx web/src/components/SessionLogger.tsx shared/spec-constants.json web/src/generated/spec-constants.ts ios/Crew/Generated/SpecConstants.swift ios/Crew/Features/Session/SessionSwap.swift ios/Crew/Features/Session/SessionModel.swift ios/Crew/Features/Session/SessionScreen.swift ios/Crew/Features/Session/RestTimerView.swift
commit_task "feat(web): journal page — every post forever, delete yours, never alters XP [SPEC: S16; E3; Flow 6; XI T040]" \
  web/src/app/\(app\)/journal web/src/components/DeletePostButton.tsx web/src/app/\(app\)/progress/page.tsx web/tests/e2e/a11y.spec.ts
commit_task "feat(metrics): npm run metrics — the Part IV readings from first-party facts, with a seeded test [SPEC: Part IV success targets; XI T045]" \
  web/scripts/metrics.mjs web/tests/api/metrics.test.ts web/package.json
commit_task "docs: registry audit (nothing rejected exists), launch checklist, ratification R-038–R-040, ledger [SPEC: XI T047; Appendix A]" \
  docs/ratification.md docs/progress.md docs/commit-queue.sh docs/OWNER-REVIEW.md

commit_task "test(e2e): journeys assert the unlocked achievements on the celebration and Home; Complete waits for the last save [SPEC: E8; 8.4]" \
  web/tests/e2e/journey1.spec.ts web/tests/e2e/journey4-web-parity.spec.ts web/src/components/SessionLogger.tsx

# --- S34 (journey ② on web; the sync contract; the Swift desk-check; constant hygiene) ---
commit_task "test(e2e): journey ② on web — returning → fast-log → crew reaction received; Quick complete uses the 3 AM day; journey ④ runs on any weekday; a warm-up before the first test [SPEC: 8.4; S07; E8; XI T035/T039]" \
  web/tests/e2e/journey2.spec.ts web/tests/e2e/journey4-web-parity.spec.ts web/tests/e2e/helpers.ts web/tests/e2e/warm-up.ts web/playwright.config.ts web/src/components/QuickCompleteButton.tsx
commit_task "fix(sync): the phone's replay contract — payload as a JSON object (JSONValue), session by clientId, absent nil fields, deletePost by clientId; an iPhone batch replay test [SPEC: 5.6.3; docs/api.md sync; XI T014/T023]" \
  ios/Crew/Api/JSONValue.swift ios/Crew/Api/ApiSync.swift ios/Crew/Storage/SyncQueue.swift ios/Crew/Storage/SyncTransport.swift web/src/lib/sessions.ts web/src/lib/sync-ops.ts web/src/lib/posts.ts web/src/lib/validate-posts.ts web/src/lib/validate-sessions.ts web/tests/api/sync.test.ts docs/api.md
commit_task "fix(ios): blind desk-check — imports, main-actor isolation, inits, autoclosure awaits, if-case syntax, View body clash, partial counters decode, -resetState hook (WRITTEN — UNVERIFIED) [SPEC: 5.6; 8.1; 8.4; XI T013–T043]" \
  ios/Crew/CrewApp.swift ios/Crew/Storage/GamificationLocal.swift ios/Crew/Storage/PlanLocal.swift ios/Crew/Features/Session/SessionModel.swift ios/Crew/Features/Progress/ProgressModel.swift ios/Crew/Features/Progress/ExerciseChartView.swift ios/Crew/Features/Onboarding/OnboardingModel.swift ios/Crew/Features/Onboarding/SaveAuthScreen.swift ios/Crew/Features/Onboarding/LoginScreen.swift ios/Crew/Features/Crew/StreamList.swift ios/Crew/Features/Crew/InviteScreen.swift ios/Crew/Features/Home/HomeScreen.swift ios/Crew/Engine/Achievements.swift ios/CrewTests/SyncQueueTests.swift ios/CrewTests/OnboardingModelTests.swift ios/CrewTests/AchievementsTests.swift ios/CrewTests/VectorFiles.swift
commit_task "chore(ci): ios job without xcpretty, unsigned simulator build, xcresult on failure; commit-queue line continuations [SPEC: Part X Phase 1; XI T008]" \
  .github/workflows/ci.yml docs/commit-queue.sh
commit_task "refactor(constants): every smuggled number named for its rule — GAP ceilings and layout counts on both platforms [SPEC: C7; 5.3]" \
  shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts web/src/generated/seed.ts web/src/lib/validate-plans.ts web/src/lib/validate-sessions.ts web/src/lib/validate-crews.ts web/src/components/SettingsView.tsx ios/Crew/Engine/DayKey.swift ios/Crew/Engine/PlateMath.swift ios/Crew/Features/Session/MobilityHoldRow.swift ios/Crew/Features/Settings/PauseScreen.swift ios/Crew/Features/Plan/PlanScreen.swift ios/Crew/Shared/Skeleton.swift ios/Crew/Features/Crew/CrewScreen.swift ios/Crew/Features/Post/PostComposer.swift
commit_task "docs: ratification R-041–R-044, ledger, debt, owner review refreshed [SPEC: XI 11.3; Appendix A]" \
  docs/ratification.md docs/progress.md docs/debt.md docs/commit-queue.sh docs/OWNER-REVIEW.md

# --- S35 (the sync-queue driver; fresh-phone hydration; the journey ② seed) ---
commit_task "fix(ios): the sync queue runs — drain after every enqueue, foreground and network return; strict FIFO under backoff; offline is not an attempt; in-flight recovery; Home re-judges on foreground (WRITTEN — UNVERIFIED) [SPEC: 5.6.3; E6; 8.3; 8.6; XI T014/T024]" \
  ios/Crew/Storage/SyncQueue.swift ios/Crew/Storage/SyncDriver.swift ios/Crew/Api/HttpStatus.swift ios/Crew/CrewApp.swift ios/Crew/RootView.swift ios/Crew/Features/Home/HomeScreen.swift ios/CrewTests/SyncQueueTests.swift
commit_task "feat(ios): a signed-in phone with an empty Store hydrates first — plan, journal, sessions, gamification, crew; login pulls the same; the journal renders server photos; posts carry clientId (iOS WRITTEN — UNVERIFIED; web tested) [SPEC: 1C; 1D; E6; 5.6.3; XI T024/T042]" \
  ios/Crew/Storage/ServerHydrate.swift ios/Crew/Storage/Store.swift ios/Crew/Api/ApiSettings.swift ios/Crew/Api/ApiSessions.swift ios/Crew/Features/Onboarding/OnboardingModel.swift ios/Crew/Features/Progress/JournalScreen.swift ios/CrewTests/ServerHydrateTests.swift shared/spec-constants.json ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts web/src/lib/posts.ts web/tests/api/posts.test.ts docs/api.md
commit_task "test(ios-ui): journey ② seeds itself — SeedClient through the real API, CREW_SEED_SESSION, the crew-mate reacts mid-test; LaunchTests resets state; local networking for the simulator (WRITTEN — UNVERIFIED) [SPEC: 8.4; S07; Flow 6; XI T035]" \
  ios/CrewUITests/SeedClient.swift ios/CrewUITests/Journey2_FastLogTests.swift ios/CrewUITests/Journey1_NewUserTests.swift ios/CrewUITests/LaunchTests.swift ios/project.yml
commit_task "docs: ratification R-045–R-046, ledger, debt, owner review refreshed [SPEC: XI 11.3; Appendix A]" \
  docs/ratification.md docs/progress.md docs/debt.md docs/commit-queue.sh docs/OWNER-REVIEW.md
commit_task "test(e2e): the warm-up opens every page in a browser so client bundles compile before the first test; three workers, one per viewport [SPEC: 8.4; 8.9; XI T039]" \
  web/tests/e2e/warm-up.ts web/playwright.config.ts

# --- S36 (the Swift engine on the open-source toolchain; the no-Mac path to a phone) ---
commit_task "feat(ios): ios/Package.swift — the engine half builds and its 51 vectors pass on the open-source toolchain (Docker/Linux); array constants typed from every element [SPEC: 8.1; C7; XI T016–T020]" \
  ios/Package.swift shared/scripts/render-spec-constants.mjs shared/scripts/doctrine-lint.mjs ios/Crew/Generated/SpecConstants.swift web/src/generated/spec-constants.ts ios/CrewTests/VectorFiles.swift ios/CrewTests/VectorRunnerTests.swift ios/CrewTests/VectorRunnerCrewTests.swift ios/CrewTests/AchievementsTests.swift ios/CrewTests/AchievementsLocalTests.swift .gitignore
commit_task "feat(ci): an engine-swift job on Linux, the ios job runs journeys ①② against the web harness, screenshots kept from every run [SPEC: 8.1; 8.4; XI T008]" \
  .github/workflows/ci.yml ios/CrewUITests/Screenshots.swift ios/CrewUITests/Journey1_NewUserTests.swift ios/CrewUITests/Journey2_FastLogTests.swift
commit_task "feat(ios): the API host is a build setting, not a hard-coded localhost; a TestFlight workflow that archives, signs and uploads from GitHub's macOS runners [SPEC: Part IV; XI T045]" \
  ios/Crew/Api/Api.swift ios/project.yml ios/ExportOptions.plist .github/workflows/testflight.yml
commit_task "docs: testing without a Mac (three stages), ratification R-048–R-049, ledger, owner review [SPEC: XI 11.3; T045; Appendix A]" \
  docs/testing-without-a-mac.md docs/ratification.md docs/progress.md docs/debt.md docs/commit-queue.sh docs/OWNER-REVIEW.md

# --- S37 (a second macOS CI, because GitHub Actions is locked) ---
commit_task "feat(ci): codemagic.yaml — compile, unit + vectors and journeys ①② on a macOS instance, plus a TestFlight workflow; GitHub Actions is unavailable while the account carries a billing lock [SPEC: 8.1; 8.4; XI T008/T045]" \
  codemagic.yaml docs/testing-without-a-mac.md docs/debt.md docs/ratification.md docs/progress.md docs/commit-queue.sh .gitignore

# --- S38 (first run on GitHub's macOS runner: the image decides the simulator) ---
commit_task "fix(ci): pick the newest plain iPhone simulator at run time — Xcode 26.6 ships no 'iPhone 16'; Actions unlocked, four jobs green, the first Xcode compile is next [SPEC: 8.1; 8.4; XI T008]" \
  .github/workflows/ci.yml codemagic.yaml docs/testing-without-a-mac.md docs/debt.md docs/progress.md docs/ratification.md docs/commit-queue.sh docs/OWNER-REVIEW.md
