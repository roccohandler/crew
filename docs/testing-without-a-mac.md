# Testing Crew without a Mac

The owner's build machine is Windows. The iPhone app is native Swift (SwiftUI + SwiftData — Appendix A, Part IV: zero
third-party Swift dependencies), so Expo and EAS do not apply to it: they are React Native tooling and this repo has no
React Native layer. What replaces them is GitHub's macOS runners for the build and TestFlight for delivery.

This file is the step list. Three stages, each usable on its own; each one needs more than the last.

---

## Stage 0 — today, on this Windows machine, no accounts

**The whole product, in a browser, including on the iPhone.** The web app is full parity (Part IV) and runs against a
local harness: an in-memory MongoDB plus `next dev`, no credentials.

```
cd C:\Users\princ\CREW_2.0\web
node tests/e2e/dev-server.mjs
```

Open `http://localhost:3000` on the PC. For the phone, put it on the same Wi-Fi and open the "Network" address the server
prints (`http://192.168.x.x:3000`); Safari's Share → "Add to Home Screen" makes it an icon. If it does not load, allow
Node through the Windows firewall for private networks. Everything resets when the server stops. Sign in with Apple and
push need credentials; email signup does not. An invite link is printed with `localhost` in it — swap that word for the
PC's address when opening it on the phone.

**The Swift engine, compiled and tested, with no Mac and no Xcode.** `ios/Package.swift` builds the engine half of the
app — `Crew/Engine/`, the generated constants and seed data, the API DTOs — on the open-source Swift toolchain, and runs
the vector runners against `shared/vectors`. This is the 8.1 gate ("a red vector on EITHER engine blocks every merge")
without a Mac in the room.

```
docker run --rm -v "C:\Users\princ\CREW_2.0:/repo" -w /repo/ios swift:5.10 swift test
```

18 tests, including all 51 shared vectors on the Swift twin. What it cannot cover: SwiftUI, SwiftData, the screens, the
sync queue's storage — those need Xcode. That is Stage 1.

---

> **2026-09-08 — GitHub Actions is unavailable on this account.** Every job, including the free Linux ones, is refused with
> "your account is locked due to a billing issue", although a valid card is on file and nothing is owed. Only GitHub support
> can lift that. Until they do, Stage 1 runs on **Codemagic** instead: `codemagic.yaml` in the repo root describes the same
> jobs, and the sign-up is in a browser. The GitHub workflow files stay as they are and become the home again the moment the
> lock is gone (`docs/debt.md`).
>
> **Later the same day — lifted.** The lock was a past-due charge declined on an expired card; re-saving the card on
> Settings → Billing & Licensing → Payment information paid it, and Actions started within minutes. GitHub Actions is the
> main path below; Codemagic stays as the backup and has never been run.

## Stage 1 — free macOS CI: compile the iPhone app and watch it run on a simulator

### Stage 1 on Codemagic (the backup — never run yet)

1. Go to `codemagic.io`, sign up **with GitHub**, and authorise it for `roccohandler/crew`.
2. Add the application when it lists your repositories; choose **"Use codemagic.yaml"** rather than the visual editor.
3. Pick the `ios-test` workflow and press **Start new build**.
4. It installs XcodeGen, generates the project, runs the doctrine lint and the Swift engine tests, starts the local web
   harness, then runs the unit suite, the 51 vectors, and journeys ① and ② on the newest iPhone simulator the image ships.
5. The build page lists artifacts. `UITestResults.xcresult` holds the journeys' screenshots — that is how you look at the
   app. The free tier gives 500 macOS minutes a month, which is plenty for the compile-fix loop.

### Stage 1 on GitHub Actions (use this — the lock is lifted)

GitHub's `macos-latest` runners have Xcode. The `ios` job in `.github/workflows/ci.yml` generates the project with
XcodeGen, compiles the whole app, runs the unit suite and the 51 vectors, then runs journeys ① and ② on the newest iPhone
simulator the runner image ships (picked at run time — the image, not the workflow, decides which devices exist) against
the same local harness. **This is the compile-fix loop, and it needs no Mac of your own.**

1. Commit and push. Git is hook-blocked for the agent, so the commits are queued. In PowerShell, plain `bash` is WSL and
   cannot enter the repo, so call Git Bash by its path:

```
cd C:\Users\princ\CREW_2.0
& "C:\Program Files\Git\bin\bash.exe" C:/Users/princ/CREW_2.0/docs/commit-queue.sh
git push
```

2. Open the repository's **Actions** tab. Five jobs run: contracts, web, web e2e, ios engine (Linux), ios (macOS). **All
   five have been green since 2026-09-08 (run 34246649543):** the app compiles, 49 unit tests and the 51 vectors pass, and
   journeys ① and ② run end to end on an iPhone 17 simulator. Stage 1 is done; it now guards every push.
3. When the `ios` job fails, read the log, fix in the repo here, push again. Behaviour must not change — the tests are the
   contract. (Getting here took four one-line compile fixes, one wrong test expectation, one server rule the simulator's
   "GMT" timezone tripped, and one clipped layout: R-050 to R-053.) The agent reads the log itself:
   `gh api repos/roccohandler/crew/actions/runs/<run>/attempts/<n>/jobs` lists the job ids, and
   `gh api repos/roccohandler/crew/actions/jobs/<id>/logs` is the raw log — job ids differ per attempt.
4. **Look at the app.** The job uploads `ios-test-results` on every run, pass or fail. Download it, and inside the
   `.xcresult` bundle are the journeys' screenshots (`CrewUITests/Screenshots.swift` attaches one at every named moment:
   the hero, the three questions, the built week, Home's bridge, the session, the celebration, the crew card with its
   reaction). Opening the bundle needs a Mac; unzipping it does not — the PNGs sit under `Data/`.

**Cost.** Free for a public repository. For a private one, macOS minutes count ten-to-one against the free monthly
allowance, so a private repo gets roughly a dozen runs a month before it costs money. The Linux jobs are one-to-one.

---

## Stage 2 — the app on your own iPhone, still with no Mac

This is TestFlight. Where things stood on the evening of 2026-09-08: the paid Apple Developer Program is already active
(App Store Connect holds a "Crew — Train. Track. Show up." record with a rejected iOS 1.0 from the earlier codebase — the
record and its bundle id are reused; TestFlight does not care about that rejection), an Atlas free cluster `Crew2` exists
in project `Crew2`, and the Vercel account is on Hobby. Three vendor limits were checked against the vendors' own pages
before this list was written (R-054):

- **Vercel Hobby runs a cron at most once a day** and refuses to deploy anything more frequent ("Hobby accounts are limited
  to daily cron jobs"), so `web/vercel.json` schedules `/api/cron/notifications` at `0 12 * * *` for the beta. The reminder
  rule is minute-exact, so reminders and streak-risk nudges need Pro ($20/month) and the one-line return to `* * * * *`
  (`docs/debt.md`). Everything else in the beta is unaffected.
- **Resend without a verified domain** sends from `onboarding@resend.dev` and delivers only to the Resend account's own
  address — enough for your own password reset and the moderation inbox, not for other testers.
- **Xcode's cloud signing needs an App Store Connect API key with the Admin role** to issue the Distribution certificate;
  an App Manager key fails with "Cloud signing permission error".

The order, one step per message from the agent. Real values go straight into the vendor's form — never into the repo or
the chat.

1. **Atlas** — Database & Network Access → Database Users → Add: password authentication, user `crew`, "Autogenerate
   Secure Password" (copy it), built-in role "Read and write to any database". Network Access → Add IP Address → "Allow
   access from anywhere" (Vercel's functions have no fixed address on Hobby). Cluster card → Connect → Drivers → copy the
   `mongodb+srv://crew:<db_password>@crew2….mongodb.net/…` string and put the password in. That is `MONGODB_URI`;
   `MONGODB_DB` is `crew`.
2. **Resend** — resend.com → API Keys → Create ("Sending access") → `RESEND_API_KEY`. `RESEND_FROM` is
   `Crew <onboarding@resend.dev>` until a domain is verified; `MODERATION_INBOX` is the Resend account's own email.
3. **Vercel** — Add New → Project → Import `roccohandler/crew` (grant the GitHub app access to the repo if it is not
   listed) → Root Directory `web` → Framework Next.js → Environment Variables: `MONGODB_URI`, `MONGODB_DB`, `JWT_SECRET`
   (32 random bytes, base64), `CRON_SECRET` (a long random string), `RESEND_API_KEY`, `RESEND_FROM`, `MODERATION_INBOX`,
   `COOKIE_SECURE=true` → Deploy. Then Settings → Environment Variables → `APP_BASE_URL=https://<the project's domain>` and
   Redeploy. Storage → Create Database → Blob → connect it to the project: Vercel adds `BLOB_READ_WRITE_TOKEN` itself;
   redeploy once more. The agent checks the deployment from here (`/api/v1/users/me` answers 401, the home page 200).
4. **Apple, on developer.apple.com/account** — first accept the updated Program License Agreement (the Account Holder;
   until then the App Store Connect API answers 403 to everything, cloud signing included). Membership details → the
   10-character Team ID. Certificates, Identifiers & Profiles → Keys → a key with "Apple Push Notifications service (APNs)"
   → download the `.p8` (exactly once) → into Vercel: `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY` (the file's whole
   text; a multi-line value is fine), `APNS_BUNDLE_ID` and `APPLE_BUNDLE_ID` (the record's bundle id), and
   `APNS_ENVIRONMENT=production` — a TestFlight build is App Store-signed, so its push tokens are production tokens
   (`sandbox` is only for a Debug build installed from a Mac). Redeploy. The web Sign in with Apple button also needs a
   Services ID (`APPLE_SERVICES_ID`) whose return URL is `https://<host>/api/v1/auth/apple/callback` — after the phone
   works; the iOS button needs only the bundle id.
5. **App Store Connect** — Users and Access → Integrations → App Store Connect API → Team Keys → Generate API Key, role
   **Admin**. Download the `.p8` (exactly once); note the Key ID and the Issuer ID shown above the table.
6. **GitHub** — `github.com/roccohandler/crew` → Settings → Secrets and variables → Actions: secrets
   `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY` (the whole `.p8`),
   `APPLE_TEAM_ID`; variables `CREW_BUNDLE_ID` (the record's bundle id) and `CREW_API_HOST` (the Vercel host — no
   scheme, no trailing slash).
7. Actions → **testflight** → Run workflow, build number higher than the last upload (1 for this codebase;
   `manageAppVersionAndBuildNumber` in `ios/ExportOptions.plist` lets Xcode raise it if App Store Connect already holds a
   higher one). `.github/workflows/testflight.yml` archives, signs (the API key lets Xcode issue the certificate and
   profile itself — no `.p12` to export from a Mac you do not have; the App ID's capabilities — Sign in with Apple, Push,
   Associated Domains — are registered the same way) and uploads straight to App Store Connect.
8. App Store Connect → TestFlight → Internal Testing → a group with yourself in it. Install the TestFlight app on the
   iPhone; the build appears there once processing finishes (usually minutes).

The build talks to whatever `CREW_API_HOST` names, because `Api.configuredBaseURL()` reads two Info.plist keys that
`ios/project.yml` fills per configuration: `http` + `localhost:3000` in Debug, `https` + your host in Release.

---

## If you later get a Mac (or rent one)

Everything above still applies; a Mac only makes the loop faster and adds what a simulator cannot do: VoiceOver, Dynamic
Type XXL, Reduce Motion, the 8.6 offline matrix, and the launch signposts on real hardware (8.5, 8.6, 8.8 — all still
deferred). A rented cloud Mac by the hour is enough for those passes. From a Mac the sequence is:

```
brew install xcodegen
cd web && node tests/e2e/dev-server.mjs &
cd ios && xcodegen generate && xcodebuild test -scheme Crew
```

For a phone plugged into that Mac, pass your machine's address so the app does not look for the server on the phone
itself: `xcodebuild ... CREW_API_HOST=192.168.1.30:3000`.

---

## What each stage proves

| Stage | Proves | Cannot prove |
|---|---|---|
| 0 — Windows | every product rule through the web app; the Swift engine and all 51 vectors compile and pass | anything about SwiftUI, SwiftData, or the phone |
| 1 — GitHub macOS | the whole Swift app compiles; unit tests, vectors and journeys ①② pass on a simulator; screenshots of every key screen | real hardware: gestures, haptics, camera, push, offline, accessibility |
| 2 — TestFlight | the app on your iPhone, against the real server | nothing further — this is the beta |
