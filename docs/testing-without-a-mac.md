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

2. Open the repository's **Actions** tab. Five jobs run: contracts, web, web e2e, ios engine (Linux), ios (macOS). The
   first run (2026-09-08, run 34224403865) had the four non-Xcode jobs green, Playwright included.
3. The `ios` job will fail the first time. 127 Swift files have never met the Xcode compiler; two desk-check passes and
   the Linux build removed what could be found without one. Read the log, fix the errors in the repo here, push again.
   Behaviour must not change — the tests are the contract. The agent reads the log itself:
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

This is TestFlight, and it needs two things Stage 1 does not.

**The Apple Developer Program, $99 a year.** There is no free path to a phone without a Mac: a free Apple ID can install
directly from Xcode on a Mac you own, and nothing else. TestFlight requires the paid program.

**A deployed server.** A TestFlight build cannot reach a dev server on your desk, so the API must be live first: a
MongoDB Atlas cluster and a Vercel deployment of `web/`, with the variables in `web/.env.example`. Section 5 of
`docs/OWNER-REVIEW.md` is the step list.

Then, once per build:

1. In App Store Connect, create the app record with a bundle id you own, for example `com.yourname.crew`.
2. Under Users and Access → Integrations → App Store Connect API, create a key with the **App Manager** role. Download
   the `.p8` — it downloads exactly once.
3. In the GitHub repository, Settings → Secrets and variables → Actions, add four **secrets**:
   `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY` (paste the whole `.p8`),
   `APPLE_TEAM_ID`; and two **variables**: `CREW_BUNDLE_ID` and `CREW_API_HOST` (your deployed host, no scheme —
   e.g. `crew-yourname.vercel.app`).
4. Actions → **testflight** → Run workflow, with a build number higher than the last one.
   `.github/workflows/testflight.yml` archives, signs (the API key lets Xcode issue the certificate and profile itself —
   no `.p12` to export from a Mac you do not have) and uploads straight to App Store Connect.
5. On App Store Connect → TestFlight, add yourself as an internal tester. Install the TestFlight app on the iPhone and
   the build appears there.

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
