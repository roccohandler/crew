# Crew — App Store listing copy (DRAFT for the owner, W9)

Written 2026-09-18 from what the app does today (`docs/mvp-definition.md`, Appendix A through A25). Every field is the owner's to
change in App Store Connect; character limits are Apple's. Nothing here promises a feature on the Not Building list (A21.13): no
feed, no chat, no leaderboards, no food search, no barcode, no coaching.

## Identity

| Field | Limit | Draft |
|---|---|---|
| Name | 30 | Crew: Train With Your People |
| Subtitle | 30 | One plan. A crew that shows up. |
| Primary category | — | Health & Fitness |
| Secondary category | — | Social Networking |
| Bundle ID | — | com.maxwellcuenca.crew |
| Price | — | Free |

If "Crew" alone is taken as a name, the subtitle carries the rest; the name must stay ≤ 30 characters.

## Promotional text (170, editable without a new build)

One push · pull · legs plan that repeats every week, a logger you can run with one thumb, and a small crew who see you show up.

## Description (4000)

Crew is the training app for people who already go to the gym and want two things: a plan they do not have to think about, and a
few friends who notice when they show up.

YOUR WEEK, BUILT IN TWO QUESTIONS
Pick your days and your experience. Crew builds a push · pull · legs plan that repeats every week, with sets, reps and a short
mobility block at the end. Swap any exercise. Edit any day. The plan rotates, so a missed Monday never scrambles your week.

LOG A WORKOUT WITH ONE THUMB
Every set opens at what you did last time. Tap to check it off, nudge the weight, skip what is taken, and finish. Trained without
your phone? Quick complete logs the day at your targets.

A CREW, NOT A FEED
Start a crew of two to ten people with one link or code. When you finish a workout your crew sees it and can react. That is all:
no public feed, no chat, no leaderboards, no strangers.

A STREAK THAT IS FAIR
The flame counts the days you planned to train and did. Rest days ask nothing. A perfect week earns a shield that covers one
missed day, and you can pause your plan for a trip or an injury without losing anything.

MACROS, KEPT PRIVATE (18+)
Set protein, carbs and fat targets from your bodyweight, save the meals you actually eat, build your usual day once, and log it
with one tap. Nothing about your food is ever shown to your crew, scored or judged.

YOURS TO TAKE BACK
Export everything as one file or delete your account from Settings at any time.

Crew is not medical advice. Talk to a doctor before starting a training program or changing how you eat.

## Keywords (100, comma-separated, no spaces after commas)

workout,gym,push pull legs,PPL,strength,training log,lifting,accountability,streak,friends,macros

## URLs

| Field | Value |
|---|---|
| Support URL | the owner's — a page or a mailto that reaches `SUPPORT_EMAIL` |
| Marketing URL (optional) | `APP_BASE_URL` (today https://trycrew.fit) |
| Privacy Policy URL | `APP_BASE_URL`/privacy |
| Terms (EULA) | `APP_BASE_URL`/terms — or Apple's standard EULA; the owner chooses |

## What's New (first public version)

The first public version of Crew.

## App Review notes (draft)

- Sign in: email + password, or Sign in with Apple. A demo account is the owner's to create and paste here (App Review needs one
  because crews are invite-only): the account should have a plan, a few workouts and a crew with a second member.
- User-generated content: workout posts with an optional caption, visible only inside an invite-only crew of at most ten. Report
  and Block are on every post and member; reports reach a person (the `MODERATION_INBOX` address); the EULA is accepted at signup.
- Age: the app asks a birth year at signup (13+). Nutrition features exist only for accounts 18 and over; under 18 the entry
  points are absent. The A16.b age-rating questionnaire is the owner's to answer in App Store Connect.
- Health claims: none. Nutrition targets are estimates with a methodology screen (Settings → How targets are estimated) that
  names every source and says to consult a clinician (guideline 1.4.1).
- Push notifications: a workout reminder at the user's chosen time, a streak reminder on a planned day that is still open, and crew
  activity. All optional, each with its own toggle.
- Account deletion: Settings → Delete account (two steps), which removes everything immediately (guideline 5.1.1(v)).

## Privacy "nutrition label" answers (draft — the owner confirms in App Store Connect)

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| Email address | yes | yes | no | App functionality (account) |
| Name | yes | yes | no | App functionality |
| Photos (profile picture) | optional | yes | no | App functionality |
| Fitness (workouts, sets, streak) | yes | yes | no | App functionality |
| Health (bodyweight, macro logs — 18+, optional) | optional | yes | no | App functionality |
| User content (captions, reactions) | yes | yes | no | App functionality |
| Device ID (push token) | optional | yes | no | App functionality |
| Product interaction (first-party events) | yes | yes | no | Analytics |
| Other data (birth year) | yes | yes | no | App functionality (age gates) |

No data is used for tracking, none is shared with data brokers, and there are no third-party SDKs in the app.

## Screenshots

Run the `store screenshots` workflow (Actions → store screenshots → Run workflow). It produces two artifacts, one per display class,
each with `SIZES.md`. Suggested order: Home (a training day) · the workout logger · the celebration · the Crew tab · Progress ·
Today (macros). No device frames and no marketing text are added by the workflow; that is the owner's choice.
