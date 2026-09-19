# Crew — owner review (rewritten 2026-09-18, at the end of "continue to full completion")

Read this first. It replaces the 2026-09-08 review in full. It lists what only you can do, in the order that unblocks the most,
with the exact step for each. Nothing here was waited on: everything a builder could do without you is built, tested and pushed.
`docs/progress.md` is the ledger (its top line carries the latest TestFlight build number), `docs/ratification.md` R-068 … R-078
holds every reading made without you, `docs/debt.md` every compromise.

## 1. Where things stand

| Area | State |
|---|---|
| Server + web (Vercel, **`trycrew.fit`** — `crew-eta-one.vercel.app` still answers and is still what the phone calls) | Live and current: training, crews, invites by code or link, nutrition (18+), the education layer, the drafted privacy and terms pages. Checked 2026-09-19: `www.trycrew.fit/` 200 · `/privacy` 200 · `/api/v1/users/me` 401 · **the app-site-association route answers 200** with `PZ56UL99NM.com.maxwellcuenca.crew`. The apex `trycrew.fit` 308-redirects every path to `www` (a Vercel domain setting, not the repo) — see §2.1 |
| iPhone app | Everything above is written and compiled and tested on GitHub's macOS simulator. No Mac exists here, so nothing is proven on a phone until you run the checklist in §4 |
| Tests | 84 vectors on both engines · the web suite and the Playwright journeys ①–⑤ at 375 / 768 / 1280 · the iPhone unit tests and journeys · the launch audit (the seven no-grade clauses + the Not Building list) runs in CI on every push |
| Not built, by your rulings | A21.13's list: feed, chat, leaderboards, comments, DMs, food search / barcode / recognition, supersets, A15, exercise media, web push, Android, Google sign-in (v1.1) |

## 2. Your tasks, in order (each is independent unless it says otherwise)

1. **Domain (W7) — DONE 2026-09-19, with one thing left.** `trycrew.fit` is attached, `APP_BASE_URL` is `https://trycrew.fit`, and
   the association file, the API and the pages all answer. **The one thing left is yours and takes a minute:** Vercel → the `crew`
   project → Settings → Domains currently makes **`www.trycrew.fit` the primary**, so every request to the bare `trycrew.fit`
   answers `308 → www`, including the invite links the server mints from `APP_BASE_URL`. Set **`trycrew.fit`** as the primary
   (`www` then redirects to it) so the link a friend taps is the host that serves it. Not urgent — Apple already followed the
   redirect and holds a valid association for the apex (checked below) — but the two should agree.
   `CREW_API_HOST` is deliberately still `crew-eta-one.vercel.app`: it is what the phone calls, a POST to the apex would take a
   redirect hop mid-login, and it is the same deployment and the same database. Move it after the primary is flipped:
   ```powershell
   gh variable set CREW_API_HOST --body "trycrew.fit"
   ```
2. **Universal links (W7) — DONE 2026-09-19.** (a) Associated Domains is ticked on `com.maxwellcuenca.crew`. (b) Vercel holds
   `APPLE_TEAM_ID` and `APPLE_BUNDLE_ID` — proven, not assumed: the live file reads `PZ56UL99NM.com.maxwellcuenca.crew`. (c) The
   variable is set and the build carries the entitlement:
   ```powershell
   gh variable set CREW_APPLINKS_HOST --body "trycrew.fit"   # already run
   ```
   Apple's own cache confirms it end to end — `https://app-site-association.cdn-apple.com/a/v1/trycrew.fit` answers 200 with the
   right appID, and its `Apple-From` header names both `trycrew.fit` and `www.trycrew.fit`. Test it with §4.5. If a future build
   ever fails at the export step, Associated Domains has come off the App ID; `gh variable delete CREW_APPLINKS_HOST` returns the
   build to green. **Only the apex is claimed** — a link someone shares as `www.trycrew.fit/join/…` opens the web page, not the
   app (`docs/debt.md`, 2026-09-19).
3. **Support address.** In Vercel set `SUPPORT_EMAIL` to the address people should write to, then redeploy (the two pages are built
   once per deploy). The privacy and terms pages print it; until then they say "Write to the support address on Crew's App Store page."
4. **Privacy and terms (W9).** Read `https://trycrew.fit/privacy` and `/terms` (source: `shared/copy/legal.json`). They
   are drafted from what the code does — what is stored, who sees it, the four providers, export and deletion, the 13+ and 18+ ages.
   Three things are yours to add, and a lawyer's eye is worth it: **the operator's legal name**, **a governing-law sentence**, and
   whether you want Apple's standard EULA or these terms as the App Store EULA. Send the changes; the builder edits the one file.
5. **The age questionnaire (A16.b / W070).** App Store Connect → your app → App Information → Age Rating → answer it again with
   what the app now does in mind: it gives adults calorie and macro targets and keeps one bodyweight, and posts are user-generated
   content inside invite-only groups. The answers are yours. Record the rating Apple returns in `docs/progress.md` (or tell the builder).
   **The App Store submission is gated on this and on nothing else in the code.**
6. **The education copy (A23).** Read `docs/education-copy-draft.md` line by line — twelve whispers and the How Crew works page —
   and **rewrite the note from Max in your own words**. On screen the note is labelled "Draft" until you do. Send the final text;
   the builder changes `shared/copy/education.json` (`page.note.draft` → false) and both apps follow.
7. **The canonical Push / Pull / Legs lists — DONE 2026-09-18 (A26).** Your lists are the templates at every experience (3×8 · 4×8 ·
   5×8), every named swap is always offered, and the phone draws a symbol beside each equipment tag. No vector moved (the templates
   are no gamification rule). Yours to look at on the phone: the names the rows took (`docs/ratification.md` R-079 (3)), the five
   symbols (R-079 (6) — each is a one-word change), and the one "no" in it: the WEB chip stays words, because a browser has no SF
   Symbols and you ruled out assets (R-079 (5)). An existing account keeps its plan until Rebuild my plan.
8. **Fast-food chains.** Six chains ship (Chick-fil-A, Chipotle, Panera Bread, Starbucks, Subway, Wendy's). McDonald's, Burger King,
   Five Guys and Taco Bell are held in `docs/fast-food-seed-sources.md` with the reason each could not be read from its own current
   publication. Release a chain by sending its published nutrition PDF or page; nothing else is needed.
9. **The test-account variable.** `TEST_EMAIL_ALLOWLIST` is read by no server code — only by `web/scripts/purge-test-accounts.ts`
   on this machine (confirmed by search 2026-09-18), so it cannot change how production behaves. Vercel's environment cannot be read
   from here: open Vercel → Settings → Environment Variables and delete the name if it is listed. Before public launch, purge the
   plus-addressed test accounts with that script (`docs/TEST_ACCOUNT_BYPASS.md`).
10. **Store screenshots.** When the app looks the way you want:
    ```powershell
    gh workflow run "store screenshots"
    ```
    Two artifacts appear on the run (6.9-inch and 6.5-inch classes), each with `SIZES.md`. Listing copy: `docs/app-store-listing.md`.
11. **Connectors.** The Google Calendar connector and the Stripe plugin are not authorized in this Claude session. Nothing in Crew
    needs them. If you want them: claude.ai → Settings → Connectors, or `/mcp` in an interactive Claude Code session.

## 3. Readings made without you — a "no" on any of them is a small change

| Reading | Where | What was chosen |
|---|---|---|
| A one-day plan whose one workout is done is a perfect week (+150 and a shield) | R-068 (3), A22 G1 (a) | The rule as written; the alternative is a minimum of two planned days for a perfect week |
| Plan history is not kept, so a plan edit re-judges unposted past days | R-068 (1), debt | The current plan judges the past |
| The comeback, the rest-day bridge and the streak nudge after A22 | R-069 · R-070 · R-071 | The smallest copy and rule that survive the removal of meal posts |
| Nutrition: ten readings (rounded energy, the typo bounds, the calorie line, idempotent saves, the one-route delete, the gate, six chains) | R-074 | Each the narrowest in-contract answer |
| Nutrition screens: what Today prints, the markers, optimistic logging | R-075 | Same |
| Education: `how.invite` shows on the Crew tab, not inside the Invite sheet (a whisper never sits in a sheet) | R-076 | Rule 3 of the whisper contract wins over the placement table |
| 6.9 density on Today: Quick add and "Logged today" became their own screens; How Crew works stays one scrolling page | R-077 | Nothing was removed; the second scroll-length moved one tap away. S19 is prose, read once |
| W9: the store's first versioned schema is build 150's; the legal pages leave three blanks for you | R-078 | See §2.4 |
| A26: a row may repeat an exercise, so rows are named by their order; named swaps are kept by swap-group size, not a new rule; six rows renamed to your words; the web chip stays words | R-079 | Each the narrowest reading of your ruling |

## 4. The phone checklist (TestFlight, latest build — the number is on the top line of `docs/progress.md`)

1. Update over your existing install: your plan, history and streak are all still there (the new store migration).
2. A rest day's Home asks nothing: no camera, no meal row, the streak unchanged the next morning.
3. Finish a workout: the celebration offers "Share to crew" and "Keep it private"; nothing posts before you tap one; the caption saves.
4. Paste an invite code on the hero or the Crew tab: the crew's name previews, and you land in the crew.
5. **The universal link (W7 — new in build 201).** Crew tab → Invite → copy the link (it is already `https://trycrew.fit/join/…`;
   the server mints it from `APP_BASE_URL`). Send it to yourself in Messages or Notes and **tap it there**. It must be a tap from
   another app: iOS never hands the app a link typed into Safari's address bar, nor one tapped inside a page on the same domain,
   so a test done that way proves nothing. Pass = Crew opens on the Crew tab with the join sheet up and the code already filled.
   Tapping Join then answers "You're already in a crew" — correct, not a failure; you are in the crew you invited yourself to.
   If it opens the web page instead, give it a minute on Wi-Fi and relaunch: iOS fetches the association shortly after install.
6. Home shows "Log macros" on an adult account (absent under 18): estimate targets from a bodyweight, then Today shows four lines.
7. Save a meal, add one from a chain, build the template, log a slot with one tap, undo it; Quick add: one tap on + adds 5 g and a hold repeats (the same fix is on reps and weight in the logger); "Logged today" lists both.
8. Airplane mode: log a meal and a quick add, then reconnect: both reach the web app's Today without a duplicate.
9. Whispers: each appears once, the first tap anywhere clears it, and it stays gone after a reinstall once you sign in; Settings → About → How Crew works opens.
10. Settings → Accessibility → Colour Filters → Grayscale: the macro lines still read correctly (W066); then Settings → Delete my nutrition data.

## 5. What blocks the App Store submission (T047)

| Gate | Owner | State |
|---|---|---|
| Age questionnaire re-answered (A16.b) | you | open — §2.5 |
| Privacy and terms reviewed; legal name and governing law added | you | open — §2.4 |
| Education copy ratified; the note rewritten | you | open — §2.6 |
| A demo account for App Review with a plan, workouts and a two-person crew | you | open — notes drafted in `docs/app-store-listing.md` |
| The phone checklist in §4 | you | open |
| Listing copy, privacy label answers, review notes | builder | drafted — `docs/app-store-listing.md` |
| Launch audit (seven no-grade clauses + Not Building) | builder | clean, and in CI |
| Store migration for existing installs | builder | built and unit-tested in CI (`StoreMigrationTests`); proven on a phone by §4.1 |
| Exercise media (A13) | lawyer | not shipping; gated on W053, unchanged |

## 6. Production notes that still stand

Atlas continuous backup and a restore drill before launch · a Vercel log drain with a 5xx alert · `JWT_SECRET` rotation expires access
tokens within 15 minutes while refresh tokens survive · `CRON_SECRET` rotates in Vercel and `vercel.json` together · APNs, Resend and
Blob keys rotate at the provider, redeploy, one smoke test each · Vercel Pro returns the reminder cron to every minute when a second
tester exists (debt).
