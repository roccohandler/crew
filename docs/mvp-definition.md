# Crew — MVP definition

Status: the owner's rulings of 2026-09-17, recorded as Appendix A amendment A21 (A21.1–A21.13). Companion to `docs/crew-mvp-spec.md`
(the law), `docs/MVP_STATE_REPORT.md` (the audit these rulings answer), `docs/GYM_ASSUMPTION_MAP.md` (W2's work order) and
`docs/nutrition-addendum.md` (W8's contract, RATIFIED 2026-09-18). Nothing below is built until the owner says go (ruling of
2026-09-17, carried); on that go, W2 is the next session.

## Positioning

Crew is the iPhone app for people who already train at a gym: one Push · Pull · Legs plan that repeats every week, a set-by-set
logger built for one hand between sets, and a small crew of friends who see you show up through posts and reactions — no chat, no
feed, no scores — and it works just as well with zero friends.

## The five flows that must be flawless on device

| # | Flow | Path on the phone | Spec |
|---|---|---|---|
| 1 | First ten minutes | hero → 2 questions → plan reveal (swap in 2 taps) → save (Apple / email) → Home bridge → first workout → celebration → "Share to crew" / "Keep it private" | Flow 1, 1A–1D, S02–S05, S07, S10, A21.1, A21.9 |
| 2 | The training day | reminder → Home names the day → session (one-tap sets, prefill, rest timer, holds; tab bar hidden, compact rows) → Complete → post → a reaction lands | Flow 2, Flow 3, S07, S09, A21.4, A21.11 |
| 3 | The crew loop | a post drops into the stream → the pulse counts you → 🔥💪👏😂❤️ → the comeback banner after 3+ quiet days; no chat anywhere | Flow 6, S12, V37–V40, A21.2 |
| 4 | Invite and join | Start a Crew → share the link or the code → a friend pastes the code on iOS (or opens the link on web) → crew preview → onboarding → lands in-crew | Flow 6, S13, W1, A21.3 |
| 5 | Rest day and plan care | rest-day Home asks nothing — G1 (a), 2026-09-18: the streak counts planned training days only; a rest day neither requires nor breaks it; a bonus or cardio day pays XP and leaves it unchanged · Pause my plan (≤ 3 weeks) · plan editor: swap / tune / rebuild, forward-only | Flows 5, 7, 8, S14, S17, A22 G1 |

## The A21 rulings (Appendix A, 2026-09-17, all owner-approved)

| # | Ruling | Supersedes | Lands in |
|---|---|---|---|
| A21.1 | Full commercial gym for every user; the equipment question and access tiers are removed; onboarding = 2 questions; organic decisions before Home = 4; A15 removed (Not Building) | Flow 1 ③, 1B, 1C, S03, 5.2, 5.6.1–5.6.2, 8.3, Appendix A "equipment asked in onboarding", A15 | W2 |
| A21.2 | Free-text chat removed from both clients; the stream is posts + system lines + reactions; message routes marked deprecated (deletion is W3's call); S12 copy "and chat" replaced | Flow 6, E6/E9/E20 (parts), Part IV, 5.2, 5.6.2–5.6.3, 6.5, S12, 8.2, 8.6, Part IX, Part X | W3 |
| A21.3 | iOS invite-code path — hero "I have an invite" → paste → preview → onboarding → join after auth; same entry on the empty Crew tab; the Invite screen shows the code; universal links stay in scope, deferred to production wiring | 1A (part), S02, S13, Appendix A "invite-link only" | W4 (code), W7 (links) |
| A21.4 | Notification permission asked after the first completed workout (1D); APNs token registered; workoutReminder defaults ON | — (confirms 1D, G12, A7) | W4 |
| A21.5 | Nutrition Stage 1 replaces A16's model (targets from body weight and goal, saved meals, daily template, one-tap log, quick-add grams, Today view) + a curated fast-food seed; 18+ gate; birth year required when Nutrition opens; the final block before launch. **A22 (ruled 2026-09-18, G1 (a)–G4): the plate journal is removed — nutrition is macro logging only, in the MyMacros+ shape; the addendum is RATIFIED (Q1 no goal · Q2 calories as a fourth line · Q3 the Home row is the action) and renamed `docs/nutrition-addendum.md`** | Flow 4 (part), the A16 model, the A16.c GAP; A22: Flow 4, Flow 5 (part), S11, E16, E19 (part) | W8 (+ W3b removal) |
| A21.6 | No new training mechanics — skip / swap / bonus / quick-complete / pause / carry-forward are the complete set | — | — |
| A21.7 | Firebase Auth rejected; custom auth is the standing decision | Appendix B ⏳ (closed) | — |
| A21.8 | Google Sign-In deferred to v1.1; if built: ASWebAuthenticationSession + server-side token verification, no SDK | — | v1.1 |
| A21.9 | A19.3 stands: two celebration buttons; no post exists until one is tapped | — (fixes the inert toggle) | W4 |
| A21.10 | Light mode is the primary; **amended 2026-09-18: Crew is light ALWAYS, on iOS and web, regardless of the device setting** (dark tokens kept, unreachable) | A21.10's dark half | W6 (+ 2026-09-18) |
| A21.11 | Session screen: tab bar hidden; non-active exercises as compact rows | S09 (amended) | W6 |
| A21.12 | A20 Build B preserved on `archive/a20-build-b`; rebuild-or-drop after the owner's device walkthrough | — | W6 |
| A21.13 | The Not Building list below | — | — |

## Not Building (MVP)

Public feed · dating · free-text chat · food search, barcode, food recognition, third-party nutrition API · leaderboards · comments ·
DMs · supersets · A15 (change today's workout) · exercise media (A13, lawyer-gated — post-MVP) · web push · Android. The standing
rejected lists (Flow 4, Part II, Part IV) and the seven no-grade clauses stay in force. "Preparing for" any item here is scope expansion.

## Worklist — ordered sessions

One session works like a Part XI task: plan visibly (files → tests → vectors), verify by command, commit per batch, progress.md
updated at the end. Sizes: S ≤ half a session · M = one session · L = a full session with a device check owed. Every session ends
with the local gate green — `swift-xref` · generate / drift / vectors / seeds / doctrine · web typecheck / lint / test / vectors /
build (e2e when web changed) · native `swift test` — before the push.

| W | Scope | Size | Exit criterion |
|---|---|---|---|
| W1 | A21 on paper: the Appendix A entry and markers, this definition, the nutrition addendum draft | S | DONE 2026-09-17 — this commit |
| W2 | Gym-only (A21.1): every row of `docs/GYM_ASSUMPTION_MAP.md` — `onboardingQuestionCount` 3→2, `decisionsBeforeHomeOrganic` 5→4, the 30 home-tier lists deleted, the equip parameter gone from both engines, the equipment screen gone on both clients, the tier inference gone from the editors and swaps, tests and journeys rewritten, mobility names checked gym-only | M | check-seeds reports 15 lists; the plan-generator property tests run over days × experience and are green on BOTH engines; `npm run e2e` and the CI ios journeys green with no "Full gym" tap; the onboarding whisper reads "1 of 2" |
| W3 | Crew surface (A21.2): composer, message rows, message models and `OpKind.sendMessage` removed on both clients; the message routes marked deprecated (deleted or kept — decided and recorded); S12 copy fixed; blocked members excluded from the pulse and the member strip; Captain rename / emoji from the Invite panel (`PATCH crews/[id]` exists) | M | no composer on either client (journeys ② ③ green); pulse and strip consult the block list, with a test; rename reachable from both Invite panels; a registry/debt note on the deprecated routes |
| W3b | **Plate-journal removal (A22 — RULED 2026-09-18; item 2 of the owner's order; EXECUTED 2026-09-18 in five commits — engines a70a401 · web 8695e1d · iOS 3eb3042 · constants/seeds/spec markers, this commit):** every row of `docs/MEAL_POST_REMOVAL_MAP.md` — meal posts, meal photos, meal tags, both post composers, the /post page and NutritionPostScreen, the "Log a meal" row, plates on Progress and in the journal, the meal-post tests, seeds and journeys; the engine's meal branch and `xpMealPost` / `mealXpDailyCap` stay vector-bound (21 vectors, never edited). Depends on **G1** (what a rest day asks for — the bridge CTA, TodayCard's premise, E16, the streak-risk push, every "postMeal" test seed), **G2** (photos on workout posts — E19, the photo route's `post` purpose, captions, CameraCapture), **G3** (under-18 users' nutrition surface — Progress meals/week, A16.c's fallback), **G4** (the third Home row and its gated-off state) | M | G1–G4 ruled 2026-09-18 (Appendix A); exit: no client can create a meal post (validator + tests), no meal UI on either client, the 21 meal-carrying vectors still green and unedited, G1's new vectors appended on both engines, W4's flow ④ seeds and W6's walkthrough list re-checked |
| W4 | Invite code (A21.3) + a "Copy code" button on the web landing page /join/[token] (owner, 2026-09-17) + the web hero passing a real token + push registration (A21.4) + two-button share (A21.9) + the profile-photo prompt at first crew join (1C) | L | iOS journey ③ via a pasted code lands in-crew; the landing page copies the code and the web hero routes to /join/[token]; permission asked once after the first completed workout and a push-token row exists; a test proves no post document exists before a celebration button is tapped; the photo prompt appears at first join |
| W5 | Photos auth-checked end to end (no public blob URL behind a 302), the Apple web callback (state/nonce bound; failure → /login?apple=failed), `COOKIE_SECURE` defaulting to true in production, a report-resolution script (sets `resolved`), deletion leftovers (reports, orphan reactions, outbox rows) | M | the photo GET streams behind auth with a cross-user 403 test; callback tests green; the cascade crawl finds nothing left; the script prints what it resolved |
| W6 | Walkthrough fixes: keyboard-aware Save screen · tappable "Log in instead" with prefill · Plan "Mon · —" copy · Progress background token · Progress CTA · Journal segment (A19.4) · Units label · version-number reconciliation · mobility names gym-only · session screen per A21.11 · light-mode pass and dark check on every screen (A21.10) · the Home decision on Build B (A21.12) · **second session (A23, after `docs/education-copy-draft.md` is ratified line by line — that document is the source of truth): the "How Crew works" page (S19, a Settings row under About) and the nine non-nutrition whispers (PPL · streak · crews · overload · swap/skip · quick complete · pause · invite, plus the existing reveal swap whisper joining the system), with `whispersSeen` on the user so iOS and web agree** | L (+ M) | every item ticked against the owner's walkthrough list; CI screenshots reviewed in light and dark; the Build B decision recorded in Appendix A; A23: each whisper fires once at its trigger and never again on either device (a test drives the seen-state round trip), the page reads every section verbatim from the ratified document |
| W7 | (CODE HALF BUILT 2026-09-18 — owner order item 3: the AASA route, the build-variable entitlement, onOpenURL → the A21.3 code path; the owner half stays: the domain, Associated Domains on the App ID, APPLE_TEAM_ID on the server) Owner accounts + universal links + AASA: the host decision, `APP_BASE_URL`, the AASA route at /.well-known/apple-app-site-association, `applinks:<host>` in project.yml, `onOpenURL` feeding the A21.3 code path; APNs, Blob, Resend domain and the Apple Services ID wired | L | a link tapped on the phone opens the app on the crew preview; a push arrives on the device; a photo post round-trips through Blob |
| W8 | Nutrition (A21.5) in three sessions — 8a (the addendum is ratified; the A16.b rating is the owner's and gates only the App Store submission): constants + tokens + the fast-food seed + the check-seeds assertion; 8b: data model, engine twins, vectors V57–V65, routes, export + delete cascade, the age gate; 8c: the Today and Saved meals / template screens on both platforms, journey ⑤, the A16.a methodology screen, the W067 audit grep · **A23: the two nutrition whispers (protein-first at the first targets, free dinner at the first template) and the shake line, behind the 18+ gate — `docs/education-copy-draft.md` is the source of truth** | L ×3 | `npm run vectors` 56 → 65 green on both engines; the clause ④ route test; the grayscale pass; the screens fully correct with every macro token forced to ink |
| W9 | Privacy and terms bodies, the SwiftData VersionedSchema migration, the App Store listing, T047 (registry audit: nothing rejected exists; doctrine lint clean; `TEST_EMAIL_ALLOWLIST` unset in production) | M | T047's checklist green; the store record complete; 🛑 SHIP |

The order is load-bearing: W2 before W4 (the invited onboarding has two questions) · W3 before W4 (the crew a joiner lands in has no
composer) · W5 before W7 (production wiring lands on a hardened server) · W8 last before W9 (owner ruling: the final block before launch).

## The owner's order of 2026-09-18 — "continue to full completion" (Appendix A, 2026-09-18)

1. Storyboard tooling (every XCUITest step a numbered screenshot + index in the run artifact; Playwright traces on) · 2. W3b, the A22
execution · 3. W7's code half on the vercel.app host (AASA, applinks by build variable, onOpenURL, Copy code) · 4. W8 in three sessions
under the ratified addendum · 5. the education layer mechanism with the draft copy in one file (A23) · 6. W9. Commit per batch, push per
item, the CI verdict read before the next. Owner tasks are never waited on; they live in `docs/OWNER-REVIEW.md`.
composer) · W5 before W7 (production wiring lands on a hardened server) · W8 last before W9 (owner ruling: the final block before launch).
