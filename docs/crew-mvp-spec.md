Crew — The Complete MVP Specification
Version 2.0 — Implementation-Ready Edition · APPROVED 2026-09-04 · Owner: [You] · Builder: Claude Code Status: every decision in this document is ✅ owner-approved. This single file is the entire build authority.

Crew is a fitness app built on one daily habit: post your progress. You set a weekly workout plan once (Push · Pull · Legs), it repeats every week, and each day you log your workout or snap your meals — which posts to your small Crew of friends, who react and keep you accountable. A streak system makes showing up feel like winning. It works just as well with zero friends.

Contents

Part I · The Experience — Flows 1–10
Part II · The Edges — every resolved edge case
Part III · The Color System ("Ember") and Voice
Part IV · The Build — architecture, integrations, platforms
Part V · The Code — concrete doctrine, repository structure, Claude Code operations
Part VI · UX Quality Standards — measurable, pass/fail
Part VII · Screen-by-Screen Acceptance Criteria
Part VIII · The Test Catalog — incl. gamification vectors V01–V40
Part IX · Data Model — final shape and invariants
Part X · Phases with Quality Gates
Part XI · The Build Playbook — the Claude Code task ledger and operating loop
Part XII · The Implementation Plan — session schedule, ordering logic, and kickoff
Appendices · A Decision Registry · B Remaining Deliverables · C Builder's Rules


PART I — THE EXPERIENCE
Flow 1 — Your First 10 Minutes (new user)
The plan comes BEFORE the account — you experience the value, then sign up to keep it.

1. Open Crew → ONE hero screen: "One plan. Every week. Your crew

   sees you show up."

   [Build my week]  ·  I have an invite  ·  Log in

   (arrived via an invite link? the hero already shows the crew:

    "Dawn Patrol 🌅 is waiting for you")

2. Three questions — all easy, all tappable:

   ① "Which days do you train?"  [M T W T F S S — Mon/Wed/Fri pre-selected]

   ② "How experienced are you?"        [Brand new / Some / Experienced]

   ③ "What do you have access to?"     [Full gym / Dumbbells / Bodyweight]

3. → Crew instantly builds your week: full Push·Pull·Legs on your days

   (Full-Body A/B if you chose ≤2 days), every exercise with equipment

   tag + sets×reps, and a short MOBILITY BLOCK closing each workout

   (2–3 holds, ~5–10 min — see Flow 3).

   Brand new = 4 simple exercises at 3×10 · Experienced = 6 incl. barbell lifts.

4. Don't like an exercise? Tap → Swap → 3–5 alternatives that do the

   same job. Two taps. No questions asked, ever.

5. "Looks good" → "Save your plan" → Sign in with Apple (one tap) or email

   (the plan is the hook; the account is how you keep it)

6. → Invited? You land INSIDE your crew, already a member.

   Organic? → Home, bridge state, first flame waiting. No choice screen.

   (Crew creation lives in the Crew tab, one tap away, whenever.)
UX Detail Layer — Phase 1: Onboarding & First-Run (added v1.7, research-driven, normative)
Sources of truth: Apple HIG onboarding guidance (fast, fun, optional; teach by doing, not touring), Robinhood's one-input-per-screen momentum model, and fintech onboarding drop-off research (the "Bridge" problem — see 1D).

1A — Launch & the hero screen (S01–S02) — AMENDED v1.9 (onboarding review)

The launch screen is a bone-colored frame matching Home's skeleton — no logo splash, no brand moment. HIG: onboarding is not part of launch; the fastest-feeling app is one whose first frame looks like its second.
The intro carousel is CUT. Carousels get skipped and cost swipes; the 3 questions ARE the onboarding (teach by doing). S02 is now ONE hero screen, Robinhood's three-CTA pattern: the promise ("One plan. Every week. Your crew sees you show up.") + primary [Build my week] + secondary [I have an invite] + tertiary "Log in". Every arrival type has its path on screen one.
Invite-aware fast path (fixes a structural gap — invites are the growth loop): arriving via an invite link (universal link or [I have an invite]) carries the crew token through onboarding: the hero shows the crew's name/emoji ("Dawn Patrol 🌅 is waiting for you"), the user answers the 3 questions, authenticates — and lands INSIDE the crew with a system line ("Jordan joined the crew"), never seeing a solo/crew choice. Invited onboarding target: ≤ 60 s median.
The solo/crew choice screen (old S06) is CUT for organic users — one less decision before value. After auth → straight to Home's bridge state; crew creation lives where it always lives, the Crew tab, plus the existing first-perfect-week prompt. Defer everything non-essential.

1B — The three questions (S03): momentum mechanics

One input per screen, one obvious action — the Robinhood rhythm. Single-select answers (experience, equipment) AUTO-ADVANCE on tap: selection haptic → 250 ms beat → next screen. No redundant Continue button when one tap fully answers the question.
Day picker: seven circular toggles ≥ 56 pt, multi-select — Mon/Wed/Fri arrive PRE-SELECTED with the encouragement line already reading "3 days a week — solid." The modal new user confirms in one tap; everyone else adjusts. (Smart defaults beat empty inputs.) Continue requires ≥ 1 day.
Interactive back-swipe works everywhere and preserves every answer; a subtle "1 of 3" progress whisper sits under the title (never a heavy progress bar — three questions shouldn't look like paperwork).
Question cards use SF Symbols (dumbbell, figure.strengthtraining, house) at consistent weight; all copy survives Dynamic Type XXL without truncation.

1C — The reveal, the save, the choice (S04–S06)

Generated-plan reveal is the onboarding's peak: day cards stagger in over ~0.5 s ("Your week, built.") — instant under Reduce Motion. One inline whisper appears once, then never again: "Tap any exercise to swap it."
Save screen: the native Sign in with Apple button (black — it IS the ink system) sits primary per App Store guideline prominence; email path beneath. Email fields declare .textContentType (username/newPassword) so iCloud Keychain autofills and stores — zero-typing signup for most users. Validation fires on field-exit, never per keystroke; errors are one inline line under the field.
Sessions persist in Keychain indefinitely — a Crew user is asked to authenticate ONCE per device, ever (the login screen is a failure state, not a feature).
Speed targets (measured, funnel-instrumented): organic hero→Home median ≤ 90 s · invited ≤ 60 s · total decisions before Home: organic 5 (hero, days-confirm, experience, equipment, auth) · invited 5.
Profile photo is NOT requested during onboarding — it's prompted contextually the first time identity matters (first crew join or first share). Defer everything non-essential; only the 3 plan questions are essential.

1D — THE BRIDGE (the research finding that matters most) Drop-off research across onboarding-famous apps shows the biggest loss happens AFTER the "finish line" — Robinhood's own data: ~40% of users went inactive immediately after first funding, because the product treated setup-complete as done while the user stood in an entrance with no next step. For Crew, plan-created is NOT the finish line — the first post is. So Home has a designed first-day bridge state:

The streak flame renders unlit at 0 with one line: "Your first flame lights today."
One oversized bridge CTA replaces the normal layout: workout day → "Start your first workout" · rest day → "Start your streak — post a meal" (camera-first).
The bridge state persists until the first post exists, then never returns. The onboarding→first-post gap is instrumented as its own funnel step (feeds the ≥50% same-day target).
Nothing else competes: no crew prompts, no settings nudges, no notification permission ask until the first workout completes (existing law).
Flow 2 — A Normal Training Day (the core loop)
7:00 AM   Notification: "Push day is ready 💪"

6:00 PM   Open Crew walking into the gym

          → HOME: today's card ("PUSH DAY · 5 exercises + mobility ·

            ~45 min · last done Tue"), streak flame 🔥12, weekly ring

            2/4, crew strip showing who's posted today.

          Tap the card → WORKOUT PREVIEW: every exercise, equipment

          tag, targets, last time's numbers. Swap available right here.

          [Start Workout] → Flow 3

7:10 PM   [Complete Workout]

          → THE MOMENT: 18/18 sets · 44 min · +125 XP counts in ·

            streak ticks 12 → 13 🔥 (haptics only — no sounds)

          → Your workout is now a POST (selfie/caption optional)

          → [Share to Crew] · one tap · back on Home, ring 3/4

7:15 PM   Buzz: 💪 from Alex · 🔥 from Jordan

8:30 PM   Dinner → tap [+] → camera (or photo library) → snap

          → 🍽 pre-tagged → posted. 15 seconds.
Flow 3 — Tracking at the Gym, Set by Set
┌──────────────────────────────────┐

│ PUSH DAY                 ⏱ 12:41 │

├──────────────────────────────────┤

│ ▼ Bench Press          [Barbell] │  ← current, auto-expanded

│    last: 8 · 8 · 7 @ 135         │  ← yesterday's truth, tiny & gray

│    Set 1   8 reps            ✓   │

│    Set 2   8 reps            ✓   │

│    Set 3  [ 8 ] [ 135 lb ]   ○   │

│    + set · + warm-up   rest 1:12 │

├──────────────────────────────────┤

│ ▷ Incline DB Press  [Dumbbells]  │

│ ▷ Overhead Press      [Barbell]  │

├──────────────────────────────────┤

│ ▷ MOBILITY · 3 holds · ~6 min    │  ← the closing block

│    couch stretch      90s each   │     duration-based, one tap

│    thoracic opener    60s        │     per hold; timer runs it

├──────────────────────────────────┤

│        [ Complete Workout ]      │  ← always visible

└──────────────────────────────────┘

The base loop: tap a set → ✓ done at pre-filled numbers · haptic tick · rest timer starts → last set checks → next exercise auto-opens → mobility block runs on hold-timers → [Complete Workout] whenever (partial always counts).

The approved bag of tricks:

Trick
How it works
Management by exception
The master rule: pre-filled everything; you only input the difference between plan and reality
Pre-fill from reality
Rows load your last ACTUAL performance, not theoretical targets. Drift is data, not failure
Log without looking
Haptic language: tick = set · double = exercise · thump = workout. Eyes on the mirror
"Same again" ghost row
Next set pre-cloned — straight sets become tap · rest · tap
Smart steppers
Reps ±1 · weight ±5 lb/±2.5 kg · long-press fast-scroll · invalid values impossible
Plate math
Tap-hold a barbell weight → "45 + 25 + 2.5 per side"
Warm-up sets
"+ warm-up" rows excluded from targets — 2 warm-ups + 3 work sets still reads 3/3
Mobility holds
Duration-based: tap a hold → countdown runs → auto-check. No reps, no weight, ever
Screen stays awake
No auto-lock mid-session
Rest timer
Auto-start on check · quiet inline countdown · chime+haptic through a locked phone · per-workout length · off-able
Out-of-order reality
Bench taken? Tap any exercise. The plan is a checklist, not a sequence
Neutral skips
Swipe → gray. No reasons, no red, no guilt
Setup cues
Tap a name → one line: "Seated chest press — grips at chest height, press forward"
Weight invisible until invited
"—" is a complete set forever. Something > nothing is law: below-target reps still = done; "done" and "as planned" recorded separately
Crash-proof
Every tap saves; "Resume workout" survives anything
Quick complete
Trained phone-free? One tap logs the planned workout. Hidden once today already counts
PR celebrations
Where weights ARE logged: new best → small confetti + badge on the post ("Bench: 155 🎉")

Flow 4 — Tracking Nutrition, Snap by Snap
Philosophy: no calories, no barcodes, no scores, no judgment — the photo IS the accountability. Proper tracking = consistent, honest, frictionless capture.

Tap [+] → camera ALREADY OPEN → snap (or pick from library)

→ meal tag pre-guessed by time of day → [Post] → done. Under 15 seconds.

Trick
How it works
Camera-first, zero preamble
The [+] button IS the camera
Time-smart tags
7 AM → 🍳 · 12:30 → 🥗 · 7 PM → 🍽 · odd hours → 🥤. One tap only if wrong
"Same as yesterday" chip
Meal-preppers repost yesterday's meal in one tap, marked ↻
Text-only is legit
"protein shake post-gym" → posted. A text meal beats an unlogged meal
No filters, no editing
Real plates, real Tupperware. Nothing to be self-conscious about
Same-day backfill
Forgot lunch? Log it tonight, labeled "earlier today." Yesterday is closed
XP cap
First 3 meals earn +15 each; post more freely, it's your journal
The plate journal
Heat map → tap a day → that day's plates. The most honest diet review, zero numbers
Rhythm reminder
One gentle nudge at YOUR usual time, only when the streak's at risk


Permanently rejected: calorie/macro entry · barcode scanning · AI food recognition · healthiness ratings. The moment Crew grades a meal, honest posting dies.
Flow 5 — A Rest Day
Home: "Rest day — recovery is part of the plan." No workout, no guilt.

Streak stays safe IF you post something today — most people drop a

15-second meal photo. Feeling froggy? Bonus workout = +25 XP, never expected.
Flow 6 — Crews (the accountability layer)
STARTING: Crew tab → [Start a Crew] → name + emoji → invite link →

straight into iMessage → friends tap → in. No usernames, no requests.

2–10 people, sweet spot 3–6. One crew per user in MVP.

┌──────────────────────────────────┐

│ DAWN PATROL 🌅        4/5 today  │  ← CREW PULSE: posted-today

├──────────────────────────────────┤    counter + weekly crew ring

│ (You🔥13) (Alex🔥21) (Sam🔥4)... │  ← member strip: streak + today-dot

├──────────────────────────────────┤

│  ONE UNIFIED STREAM:             │

│  Alex: "who's in at 6am"         │

│  ┌────────────────────────┐      │

│  │ SAM · PULL DAY ✓       │      │  ← posts drop into the chat

│  │ 15/15 sets · 🔥 day 4  │      │

│  └────────────────────────┘      │

│  You reacted 💪                  │

│  Jordan: "ok ok I'm going"       │

└──────────────────────────────────┘

Reactions: 🔥 💪 👏 😂 ❤️ (long-press a post). No comments — the chat IS the comment section. No nudge pings — the empty today-dot does the talking. Feed shows 7 days; your own journal keeps everything forever.

The comeback: quiet for 3+ days → your next post gets the COMEBACK 🎉 banner → the crew piles on. The first check-in after a bad stretch gets the loudest applause. Rule, not vibe.
Flow 7 — The Day You Miss (and the days you plan to)
PLANNED ABSENCE — Plan Pause:

Settings → "Pause my plan" → pick return date (max 3 weeks)

→ streak freezes 🧊 · reminders stop · crew dot shows ⏸ · no XP accrues

→ one active pause at a time · never retroactive · resumes automatically.

Vacations and injuries are life, not failure.

UNPLANNED MISS (3 AM local passes with nothing posted):

Shield held? → absorbed automatically: "🛡 Shield used — your 23-day

  streak lives." (Earned per PERFECT week · hold max 2 · never sold.)

No shield? → streak → 0, stated once, in gray, no drama. History intact,

  longest-streak record stands, tomorrow says "New streak starts today,"

  and your return post gets the comeback celebration.
Flow 8 — Changing Your Plan
Plan tab → Mon–Sun at a glance.

Small: tap day → swap / adjust sets·reps / reorder / add / remove (undo always).

Big:   [Rebuild my week] → the 3 questions again → fresh plan, confirm diff.

No gates for anyone — input limits (≤15 exercises/day, ≤20 sets) are the

guardrails. Everything applies FORWARD. History never rewrites.
Flow 9 — Checking Your Progress
LAYER 1 · DID I SHOW UP?    heat map (tap a day → workout + plates) ·

                            rings history · streaks · totals · meals/week

LAYER 2 · HOW MUCH WORK?    sets/week trend · Push/Pull/Legs balance

LAYER 3 · AM I STRONGER?    only where weights were logged: per-exercise

                            charts · last-vs-today · PR moments 🎉

                            Never logged weight? Politely doesn't exist.
Flow 10 — Riding Solo
Everything works identically with zero friends — posts go to your

private journal, Home never shows empty social panels, the Crew tab is

one warm invitation, one prompt after your first perfect week, then

silence. Solo is a full experience, not a waiting room.


PART II — THE EDGES (all resolved)
E1 Identity (AMENDED 2026-09-04, owner-final) — name + one profile picture, taken with the camera in-app or uploaded from the library. That is the entire identity system: the previously considered sloth avatar set is rejected — two identity systems (avatars + photos) proved too complicated in v1 of this product, and one is enough. Until a picture is set, the default state renders the user's initials on warm gray (a fallback, not a second system — there is nothing to choose). Profile photos get the same treatment as all photos: EXIF/GPS stripped on upload, changeable anytime in Settings. No bios, no body stats. Your streak and posts are your identity.

E2 Crew lifecycle — creator = Captain (rename, remove members, regenerate link; captaincy auto-passes to longest-tenured on exit). Leavers' past posts remain; joiners see the stream from join-forward; full crew = "crew full"; per-crew mute; last-one-out archives silently.

E3 Posts after posting — delete yours anytime; post ≠ log: deleting a post never deletes sets, never retro-breaks a streak. Captions editable, photos not. EXIF/GPS always stripped. Privacy model = "your group chat," not "your feed."

E4 The lapsed user — 14+ quiet days → one warm screen: "Your record still stands" → [Keep my plan] [Rebuild] → Home. No guilt recap, ever.

E5 Permissions denied — camera denied → text-first posting; notifications denied → in-app banners; nothing dead-ends, nothing re-prompts uninvited.

E6 Offline — the entire solo loop is offline-first on iPhone; posts queue with "will share ↻"; chat holds drafts. Built like it knows gyms are concrete basements.

E7 Session edges — mid-workout Swap asks [Just today] [Update my plan] · two-a-days: first counts (+100), extras +25 · bodyweight = no weight chip · supersets excluded (parking lot) · running sessions are snapshots.

E8 Gamification edges — first partial week can't earn a shield · level-ups fold into the completion celebration · timezones follow the device, edge cases resolve in the user's favor · the day ends 3 AM local.

E9 Safety & App Store — report any post/message/crew-name · block any user · Captain removes content · EULA at signup · age floor 13+ · photos crew-only · delete-account cascades everywhere · JSON data export in MVP · manual human review of reports (no AI scanning).

E15 Anti-cheat doctrine (permanent) — Crew does NOT police effort; four humans who know you beat any algorithm. Integrity = hard caps + server clock wins + no backdating. No effort scoring, no anomaly flags, ever.

E16 All-rest plans — allowed; streak runs on meal posts; one gentle "add a training day whenever" — once.

E17 Devices — everything syncs; an in-progress workout finishes on the device it started on.

E18 Accounts — standard resets; delete is real and says so; re-signup = genuine fresh start.

E19 Failed uploads — counted-vs-delivered are separate facts; a send failure never retro-breaks a streak; after ~24h the user chooses [Retry] [Post without photo] [Delete].

E20 Housekeeping — un-react by tapping again · delete own messages (tombstone) · limits: captions 280, crew names 30, exercise names 60, chat 1,000 · Monday week-start worldwide · VoiceOver-complete session screen ("Bench press, set 3 of 3… double-tap to complete").


PART III — THE COLOR SYSTEM ("Ember") AND VOICE
70 / 20 / 10 with Robinhood-grade restraint (owner-directed amendment): INK ACTS, EMBER REWARDS.

The reference is Robinhood's onboarding: a green-brand app whose CTAs are black-and-white, with the accent nearly absent — and the interface is clearer and easier to read because of it. Crew adopts the same discipline app-wide: every interactive element is monochrome; #FF6600 is reserved exclusively for the reward layer, so in practice it occupies far less than its 10% budget — and lands far harder when it appears.

Share
Job
Light
Dark
70% Canvas
every background
Bone #FAF8F5 page · #FFFFFF cards · #E9E4DD hairlines
#171412 · #211D19 cards · #2E2822
20% Ink
ALL text, structure, and ALL buttons/CTAs/controls
#211D19 text · primary buttons = #211D19 fill with #FAF8F5 label · secondary buttons = hairline outline, ink label · #6F6860 secondary text · #A8A29A missed-gray
#F5F1EB text · primary buttons = #F5F1EB fill with #171412 label · #A69E94 secondary
≤10% Ember
the reward layer ONLY: streak flame, XP count-ups, ring & heat-map fills, PR / comeback / celebration accents
#FF6600 shapes · #B84D00 for any orange words · #FFEFE3 tints & ring tracks
#FF7A1F lifted · #33241A tints


Semantics: success #3E8E5A · danger #D64550 (berry, never near orange) · missed = warm gray, never red.

The six laws (amended): ① Ink acts, Ember rewards — no button, CTA, link, toggle, tab, or any interactive control ever wears orange; navigation and chrome are monochrome forever. ② Warm neutrals only. ③ Orange is a shape color, not a text color (#B84D00 for orange words; #FF6600 fails WCAG on light). ④ Ember appears only when progress is the message — flame, XP, ring fills, PR/comeback/celebration. Most screens show ZERO ember at rest; the scarcity is why the flame hits. ⑤ Dark mode lifts (#FF7A1F), never inverts. ⑥ The 20% stays neutral; no second hue — semantics keep green/red/gray for their meanings.

Why this reads better (the Robinhood mechanics): ink-on-bone buttons run ≈15:1 contrast — the strongest possible CTA legibility; with zero color competition, reading order is carried by typography and spacing instead of hue; and because orange is never furniture, every appearance is information ("progress happened here"). The accent stops decorating and starts meaning.

Onboarding, specifically (per the owner's reference): Flow 1 is pure ink-on-bone — black "Continue" and "Save your plan" buttons, generous whitespace, one question per screen, no orange anywhere. The ember flame appears for the FIRST time on Home at streak zero — so the very first orange the user ever sees is already the thing the whole app is about.

Voice: warm gym buddy — casual, lightly funny, zero drill-sergeant, zero corporate wellness. "Push day is ready 💪". Feedback = haptics only, no sound effects.


PART IV — THE BUILD
Governing rule: SIMPLICITY IS THE ARCHITECTURE. Complexity must be earned by a requirement in this document.

┌─────────────────┐         ┌──────────────────────────────┐

│  iPHONE APP      │  REST   │  ONE NEXT.JS APP ON VERCEL   │

│  Swift/SwiftUI   │ ──────▶ │  · /api/v1 (the backend)     │

│  iOS 17+         │  JSON   │  · the FULL web app          │

│  iPhone-only     │         │  · invite landing pages      │

│  SwiftData local │         └──────────┬───────────────────┘

│  offline-first   │                    │

└─────────────────┘         ┌──────────┼────────────┐

                            ▼          ▼            ▼

                       MongoDB Atlas  Vercel Blob  APNs

The web app is FULL PARITY (owner-directed): every feature — onboarding + plan builder, workout sessions, nutrition posting (browser camera + file upload), crews, stream, chat, progress, settings — works on web. Same Ember tokens, same flows, same server-computed truth. Honest platform limits (physics, not scope): no push notifications on web in MVP (in-app indicators instead), no offline guarantee (offline-first is iPhone's), camera via the browser's native input. The invite landing page is the growth loop's front door.

Swift contract: ZERO third-party dependencies, hard rule — SwiftUI + @Observable · SwiftData · URLSession · Keychain · AVFoundation · APNs cover everything.

Third-party inventory (complete; nothing else without a logged decision): MongoDB Atlas · Vercel Blob (photos, presigned) · APNs direct · Resend (transactional email — see touchpoints below) · auth = Sign in with Apple + email, JWT in Keychain / httpOnly cookie · chat = polling 5–10s (upgrade path documented, not built) · analytics = first-party events to our DB · crashes = Xcode Organizer, Sentry named post-MVP · payments/AI/moderation vendors = none.

Email touchpoints (Resend — the complete list; email is transactional only, NEVER marketing/engagement): | Email | Trigger | Notes | |---|---|---| | Password reset | User requests it | Single-use token, 30-min expiry, gym-buddy voice, one link | | Report received | A report is filed | Sent to the owner's moderation inbox with target + reporter context (this IS the manual moderation queue) | | Account deleted | Deletion completes | One confirmation, states the cascade is done | No streak reminders, no digests, no re-engagement, no newsletters — those channels are push (iPhone) and in-app only. Password hashing uses Node's built-in crypto.scrypt — no extra dependency.

Success targets: ≥50% install→first post same day · ≥30% D7 retention · ≥4 posts/user/week · crew retention ≥1.5× solo · streak health watched, not targeted.
The Rules Behind the Feeling
You experience...
Because the rule is...
Tracking takes seconds
Management by exception — only deviations need input
Streak survives any day you post anything
Any post sustains it; day ends 3 AM; shields (max 2) absorb; Pause exists for real life
Perfect weeks feel special
+150 XP + a Streak Shield 🛡, earned never sold
Numbers going up
25 XP first post · +100 workout · +15 meals ×3 · +50 comeback · +25 bonus
No shame, ever
Gray misses · no guilt copy · comebacks celebrated loudest · pauses without penalty
No comparison anxiety
No leaderboards, no followers, no public anything — one small crew
Weights & calories never pressure you
Something > nothing: done = sets & reps · food = photos, never numbers



PART V — THE CODE: CONCRETE DOCTRINE, REPOSITORY STRUCTURE, CLAUDE CODE OPERATIONS
5.1 The Concrete Code Doctrine ✅ (owner-directed: the exact opposite of abstraction)
The prime rule: every piece of code does one concrete thing, is named for exactly that thing, and can be read top-to-bottom like a story. Indirection is a defect until proven otherwise.

#
Law
Meaning in practice
C1
No abstraction without two concrete users
A protocol/interface may exist ONLY when two concrete conformers already exist in the codebase. No protocol StorageProviding with one implementation. No <T> generics in app code (standard library generics excepted). Extraction happens on the THIRD occurrence, and extracts to a plain function — never to a type hierarchy.
C2
No architecture frameworks or patterns-as-religion
No repository pattern, no use-case/interactor layer, no clean-architecture rings, no DI containers, no service locators, no Combine/Rx, no custom pub-sub. iOS shape is exactly: View → @Observable model → plain functions (Engine / ApiClient / LocalStore). Server shape is exactly: route handler: validate → authorize → do → respond, top to bottom, inline.
C3
Concrete types, passed plainly
Dependencies arrive as init parameters of their CONCRETE type, or are the well-known singletons (Api.shared, Store.shared) — never protocols created to enable mocking.
C4
Test against real things, not mocks
No mocking frameworks, no protocol seams cut "for testability." The engine is pure functions (trivially testable). LocalStore/SyncQueue test against an in-memory SwiftData container. API routes test against a real test MongoDB. UI journeys run against a seeded server. If code is hard to test without a mock, the code is wrong — usually a pure function is hiding inside it.
C5
Duplication before abstraction
Writing similar code twice is correct. Extracting on the second occurrence is premature. Slightly-duplicated concrete code that a reader (or Claude Code) can see in full ALWAYS beats a clever shared helper that must be traced.
C6
No clever code
No custom property wrappers, result builders, operator overloads, reflection, metaprogramming, dynamic dispatch tricks, or middleware chains. If a junior couldn't predict what a line does, rewrite the line.
C7
Every spec number lives in one file
SpecConstants.swift / spec-constants.ts (both generated from shared/spec-constants.json) hold EVERY tunable from this document, named for their rule: xpPlannedWorkout = 100, dayBoundaryHour = 3, maxShields = 2, crewMaxMembers = 10, mealXpDailyCap = 3. A magic number anywhere else is a build failure (lint rule).
C8
Spec-traceable code
Any function implementing a rule from this document carries a tag comment: // SPEC: Flow 7 — shield auto-consumption or // SPEC: V15. Grep the spec, find the code; grep the code, find the spec.
C9
Small, single-purpose files
Targets: Swift ≤ 200 lines, TS ≤ 150 lines. One screen per file, one model per file, one route per file. Functions ≤ ~40 lines; a function reads as a paragraph.
C10
Names are sentences, files are their names
markSetDone(), computeStreakAfterPost(), dayKeyFor(date:timezone:). HomeScreen.swift contains HomeScreen and nothing else. No Utils.swift, no Helpers.ts, no Manager, no Handler, no Base*.
C11
Comments explain WHY, never WHAT
Code says what. Comments carry spec tags (C8), non-obvious reasons, and warnings ("server recompute overrides this — see /api/v1/sync").
C12
No barrel files, no re-exports, no path aliases beyond @/
Imports point at the real file. Where a thing lives is never hidden.
C13
Errors are boring
Throw early with the standard error shape; one AppError enum (iOS) / one apiError(code, message, status) function (server). No custom error class hierarchies.
C14
Explicit state, plain data
@Observable classes with plain vars on iOS; plain objects + React useState/server data on web. State lives where it's used; no global stores beyond Store.shared (SwiftData) and AuthStore.shared.

5.2 Repository Structure — one monorepo, file-level concrete
crew/                                  ← ONE repo. One clone = everything.

├── CLAUDE.md                          ← the builder's standing orders (5.4)

├── docs/

│   ├── crew-mvp-spec.md               ← THIS document

│   ├── progress.md                    ← the agent's cross-session memory: ledger state, next task, blockers

│   └── debt.md                        ← every compromise, same commit that creates it

├── shared/                            ← single source of truth, generated outward

│   ├── spec-constants.json            ← every number in this spec, named

│   ├── design-tokens.json             ← Ember palette + spacing + haptic names

│   ├── vectors/                       ← V01–V40 (append-only)

│   │   ├── streak.vectors.json        (V01–V12)

│   │   ├── shields.vectors.json       (V13–V18)

│   │   ├── pause.vectors.json         (V19–V23)

│   │   ├── xp.vectors.json            (V24–V31)

│   │   ├── completion.vectors.json    (V32–V36)

│   │   └── crew.vectors.json          (V37–V40)

│   ├── seed/

│   │   ├── exercises.json             (~80: name, pattern, equipment, level, type, cueLine, swapGroup, holdSeconds?)

│   │   ├── plan-templates.json        (PPL × experience × equipment + Full-Body A/B)

│   │   └── achievements.json

│   └── scripts/

│       ├── generate.mjs               → writes ios/Crew/Generated/* and web/src/generated/*

│       └── check-drift.mjs            → CI fails if generated files were hand-edited

│

├── ios/

│   ├── Crew.xcodeproj

│   ├── Crew/

│   │   ├── CrewApp.swift              (entry; auth routing; tab bar)

│   │   ├── Generated/                 ← DO NOT EDIT (from shared/)

│   │   │   ├── SpecConstants.swift

│   │   │   ├── EmberColors.swift

│   │   │   └── SeedData.swift         (bundles the three seed JSONs)

│   │   ├── Engine/                    ← pure functions only, zero imports beyond Foundation

│   │   │   ├── GamificationEngine.swift   (// SPEC: Part VIII vectors)

│   │   │   ├── DayKey.swift               (3 AM boundary, Monday weeks, DST)

│   │   │   ├── PlanGenerator.swift        (questions → plan)

│   │   │   └── SwapFinder.swift           (pattern+equipment candidates)

│   │   ├── Api/

│   │   │   ├── Api.swift              (one func per endpoint: `func createSession(_:) async throws -> SessionDTO`)

│   │   │   ├── ApiModels.swift        (Codable DTOs, mirror server zod schemas)

│   │   │   └── AuthStore.swift        (Keychain, refresh, Sign in with Apple)

│   │   ├── Storage/

│   │   │   ├── Store.swift            (SwiftData container + typed fetch functions)

│   │   │   ├── Models.swift           (@Model classes — mirrors Part IX)

│   │   │   └── SyncQueue.swift        (offline queue, retry/backoff, reconcile)

│   │   ├── Features/                  ← one folder = one feature = one context load

│   │   │   ├── Onboarding/  IntroScreen · PlanQuestionsScreen · GeneratedPlanScreen · SaveAuthScreen · SoloOrCrewScreen · OnboardingModel

│   │   │   ├── Home/        HomeScreen · TodayCard · CrewStrip · HomeModel

│   │   │   ├── Session/     SessionScreen · SetRow · MobilityHoldRow · RestTimerView · CelebrationScreen · SessionModel

│   │   │   ├── Post/        NutritionPostScreen · CameraCapture · PostComposer · PostModel

│   │   │   ├── Crew/        CrewScreen · StreamList · PostCard · MessageRow · MemberStrip · InviteScreen · CreateCrewScreen · CrewModel

│   │   │   ├── Plan/        PlanScreen · WorkoutEditorScreen · SwapSheet · RebuildFlow · PlanModel

│   │   │   ├── Progress/    ProgressScreen · HeatMapView · ExerciseChartView · JournalScreen · ProgressModel

│   │   │   └── Settings/    SettingsScreen · PauseScreen · ExportView · WelcomeBackScreen · SettingsModel

│   │   └── Shared/          PrimaryButton · Card · EmptyState · ErrorState · Skeleton · WeeklyRing · StreakFlame · AvatarView · Haptics.swift

│   ├── CrewTests/

│   │   ├── VectorRunnerTests.swift    ← loads shared/vectors/*, asserts engine matches EVERY case

│   │   ├── DayKeyTests.swift · PlanGeneratorTests.swift · SwapFinderTests.swift

│   │   └── SyncQueueTests.swift       (in-memory SwiftData, no mocks — C4)

│   └── CrewUITests/

│       ├── Journey1_NewUserTests.swift · Journey2_FastLogTests.swift

│       └── OfflineSessionTests.swift · CameraDeniedTests.swift

│

└── web/

    ├── package.json                   scripts: dev · test · vectors · e2e · lint · typecheck · generate

    ├── src/

    │   ├── generated/                 ← DO NOT EDIT (from shared/): spec-constants.ts · ember.css · seed.ts

    │   ├── lib/                       ← plain functions only

    │   │   ├── engine/                gamification.ts · day-key.ts · plan-generator.ts · swap-finder.ts  (mirrors ios/Engine 1:1, same file names)

    │   │   ├── db.ts                  (Mongo client + typed collection getters)

    │   │   ├── auth.ts                (jwt sign/verify/refresh, cookie helpers, requireUser(req) → userId | 401)

    │   │   ├── blob.ts                (presigned upload, EXIF strip + resize via sharp)

    │   │   ├── push.ts                (APNs http/2)

    │   │   ├── email.ts               (Resend: reset, report, delete-confirm — the only three)

    │   │   ├── validate.ts            (zod schemas, one per DTO — mirror ApiModels.swift)

    │   │   └── events.ts              (first-party analytics insert)

    │   ├── app/

    │   │   ├── join/[token]/page.tsx  (invite landing — no auth, the growth front door)

    │   │   ├── (app)/                 home · onboarding · session · plan · crew · progress · settings  (full parity screens)

    │   │   └── api/v1/                ← one route.ts per resource+verb, each reads top-to-bottom:

    │   │       auth/{register,login,apple,refresh,logout}/route.ts

    │   │       users/me/route.ts · users/me/export/route.ts

    │   │       plans/route.ts · sessions/route.ts · sessions/[id]/route.ts

    │   │       posts/route.ts · posts/[id]/route.ts · posts/[id]/reactions/route.ts

    │   │       crews/route.ts · crews/join/route.ts · crews/[id]/{members,invite,messages}/route.ts

    │   │       sync/route.ts · pause/route.ts · reports/route.ts · blocks/route.ts · push-token/route.ts

    │   └── components/                PostCard.tsx · StreamList.tsx · SetRow.tsx · HeatMap.tsx · WeeklyRing.tsx · EmptyState.tsx …(mirror iOS Shared/ names)

    └── tests/

        ├── vectors.test.ts            ← same shared vectors, TS engine, must match Swift exactly

        ├── api/                       one file per group + standing-checks.gen.test.ts (auto-generates ①–④ for every route)

        └── e2e/                       journey1.spec.ts · journey2.spec.ts · journey3-invite.spec.ts · journey4-web-parity.spec.ts

Allowed npm dependencies (complete list — adding one requires a Decision Registry entry): next react react-dom mongodb zod sharp @vercel/blob jose apns2 resend, dev: typescript vitest playwright eslint prettier. That's the whole supply chain. iOS: zero.

Naming symmetry rule: the Swift and TS engines use identical file names and identical function names (computeStreakAfterPost exists in both, byte-for-byte signatures adjusted per language). When Claude Code fixes a rule in one engine, the twin is found by name in seconds.
5.3 Clean-Code Working Practices
Read order for any feature: its *Model first (all state + actions live there), then its Screen (pure rendering of the model), then the Engine/Api functions it calls. Nothing else is involved — that's the point of C2.
Adding a screen = one folder touch: Screen file + Model file + (if new rule) Engine function + spec tag + Part VII test. If a change touches more than one feature folder plus Shared/, stop and check the design.
Optimistic-write pattern (the only "pattern" allowed), written concretely every time: mutate SwiftData → update model state → enqueue SyncQueue op → server reconciles → silent overwrite if divergent. No wrapper abstracts this; it is ~8 visible lines wherever it happens (C5: duplication is fine, readability wins).
Formatting is machine-owned: swift-format + Prettier, CI-enforced, never discussed.
Lint rules that enforce doctrine (CI-blocking): no protocol with single conformer (danger-swift script) · no numeric literal outside Generated/SpecConstants (allowlist: 0, 1) · file length caps · no TODO without a debt-log entry · no hand edits in Generated/ (check-drift.mjs).
5.4 CLAUDE.md — the exact standing orders (paste verbatim at repo root)
# Claude Code — standing orders for the Crew repo

1. READ docs/crew-mvp-spec.md before any work. Appendix C is your contract.

   Re-read Appendix A (Decision Registry) + Appendix C at the start of EVERY session.

2. This codebase is CONCRETE BY LAW (spec Part V 5.1, C1–C14). Never introduce a

   protocol/interface with one implementation, a generic, a repository/DI/use-case

   layer, a mock, a middleware chain, or a barrel file. Extraction only on the

   third occurrence, and only into a plain function.

3. Every number comes from shared/spec-constants.json via the Generated files.

   Never type a spec number inline. Never edit anything under Generated/.

4. Every function implementing a spec rule carries a `// SPEC:` tag.

5. Work one feature folder at a time. Before coding, state the plan as:

   files touched → tests added → vectors affected. If a needed behavior is

   undefined in the spec: STOP and output `SPECIFICATION GAP: [description]`.

6. Definition of done: Part VII screen criteria pass + Part VI standards hold +

   Part VIII tests green + `npm run vectors` AND the Swift VectorRunner both green.

   A red vector on either engine blocks everything.

7. Vectors are append-only. Changing behavior = new Decision Registry entry +

   new vector. Never edit an existing vector.

8. Commands: web → `npm run dev|test|vectors|e2e|lint|typecheck|generate`

   ios → `xcodebuild test -scheme Crew` (unit+vectors) · UI tests scheme CrewUITests

9. Record every compromise in docs/debt.md in the same commit that creates it.

10. Never build toward anything on the rejected lists (Flows 4, Part II, Part IV).

    "Preparing for" a rejected feature is scope expansion.

11. docs/progress.md is your cross-session memory. Read it at session start,

    update it at session end (task states, blockers, next task). Never rely on

    chat history for state.

12. Work the Part XI task ledger STRICTLY in order, one task at a time. A task

    is done only when its Verify command has been RUN and its output shown.

    Too big for one session? Split it in progress.md first, then start.
5.5 Why this is optimized for Claude Code (the reasoning, so it survives)
Concrete code is context-cheap code: with no indirection, reading ONE feature folder + the Engine gives complete truth about a behavior — no hunting through protocol conformances or DI graphs across files that don't fit in a context window. Identical twin-engine file/function names make cross-language fixes greppable. Spec tags make every rule bidirectionally traceable. SpecConstants makes every tunable findable and un-driftable. Small files make edits cheap and diffs reviewable. Real-thing tests mean a green suite proves behavior, not mock choreography. The doctrine isn't aesthetic — it is the anti-drift architecture.
5.6 The Feature Code Map (added v1.8 — the concrete design, signature level)
Every feature requirement resolved to actual types and functions. Claude Code implements these names; deviations require a plan note. All engine functions are pure (no I/O, no clocks — time and randomness enter as parameters). Twin rule: identical names in Swift and TS.
5.6.1 The Engines (shared logic — the heart)
DayKey.swift ⇄ day-key.ts                                  // SPEC: E8, E20

  dayKey(for: Date, tz: TimeZone) -> String                // "2026-09-04", 3 AM boundary

  weekKey(for dayKey: String) -> String                    // Monday-start week id

  daysBetween(_ a: String, _ b: String) -> Int

GamificationEngine.swift ⇄ gamification.ts                 // SPEC: Part VIII V01–V40

  // Inputs are plain values; state in, state out. One event type:

  enum GameEvent { postCreated(kind, dayKey, workoutCompleted, isPlannedDay)

                   postUndone(dayKey) · dayRolledOver(dayKey, hadRequirement)

                   reactionGiven(dayKey) }

  enum Award { xp(Int, reason: String) · streakTo(Int) · shieldEarned

               shieldConsumed · comeback · perfectWeek · levelUp(Int)

               achievement(id: String) · prBadge(exercise: String) }

  apply(_ e: GameEvent, to: GamificationState, pauses: [Pause]) -> (GamificationState, [Award])

  recompute(sessions: [SessionFacts], posts: [PostFacts],

            pauses: [Pause], tz: TimeZone) -> GamificationState   // server truth; must equal folded apply()

PlanGenerator.swift ⇄ plan-generator.ts                    // SPEC: Flow 1, 2.10 rules

  generatePlan(days: Set<Weekday>, exp: Experience, equip: Equipment,

               seed: SeedCatalog) -> PlanDraft              // incl. mobility block per workout

SwapFinder.swift ⇄ swap-finder.ts

  swapCandidates(for: ExerciseRef, equip: Equipment,

                 seed: SeedCatalog) -> [SeedExercise]       // same pattern, ≤5, never incumbent
5.6.2 iOS feature models — state shape + actions (the complete surface)
OnboardingModel   state: step, selectedDays, experience?, equipment?, draft: PlanDraft?, authError?

                  actions: toggleDay · choose(experience) /*auto-advance*/ · choose(equipment)

                           regenerate() · swap(exerciseId, with:) · saveWithApple() · saveWithEmail(_:_:)

                           pickPath(.solo|.create|.join)      // draft persists locally pre-auth (SPEC: S05)

HomeModel         state: today: TodayState, streak, shields, weeklyRing: [DayRingState], crewStrip: [MemberDot]?

                  enum TodayState { bridge(kind) · workout(template, done: Bool) · rest(posted: Bool)

                                    · paused(until: String) · allDone }        // SPEC: S07 + 1D Bridge

                  actions: refresh() /*Store-only, <500ms*/ · startWorkout() · quickComplete() · openDay(_)

SessionModel      state: session: LiveSession, focusIndex, restTimer: RestTimer?, celebration: CelebrationOutcome?

                  actions: checkSet(_) /*pre-fill→done, ghost row, haptic, rest start*/ · adjust(reps|weight, at:)

                           addSet(after:) · addWarmup(at:) · skip(set|exercise) · startHold(_) /*countdown→auto-check*/

                           jumpTo(exercise) · complete() /*engine.apply → CelebrationOutcome*/ · saveForLater() · discard()

                  struct CelebrationOutcome { setsDone/planned, duration, awards: [Award], postDraft: PostDraft }

PostModel         state: mode(.camera|.library|.text), photo?, caption, mealTag /*time-guessed*/, shareToCrew: Bool

                  actions: capture() · pick() · repeatYesterday() · submit() /*optimistic: Store insert + queue op*/

CrewModel         state: crew?, stream: [StreamItem] /*post|message|system, time-merged, 7-day window*/,

                         members: [MemberDot], pulse: (posted: Int, total: Int), draft: String

                  actions: poll() /*foreground 5–10s*/ · send() · react(target, emoji) · unreact(target)

                           create(name, emoji) · join(token) · leave() · captainRemove(member|content) · regenerateLink()

PlanModel         state: week: [DaySlot], editing?: WorkoutDraft

                  actions: swap(_, scope: .today|.plan) · adjust · reorder · add · remove /*undo snackbar*/ · rebuild()

ProgressModel     state: heatMap: [DayCell], weeks: [RingRecord], totals, strength: [ExerciseTrend] /*only where weight logged*/

                  actions: select(dayKey) -> DayDetail /*workout + plates*/

SettingsModel     actions: setReminder · muteCrew · pause(until) /*≤21d, no retro*/ · exportJSON() · deleteAccount()
5.6.3 SyncQueue — the one concrete mechanism
SyncQueue.swift          // SPEC: E6, E19, Part IV offline rules

  @Model OpRecord { id, kind: OpKind, payload: Data, createdAt, attempts, state: .pending|.inFlight|.held }

  enum OpKind { createSession · patchSession · createPost · deletePost · sendMessage

              · react · unreact · putPlan · pause · pushToken }

  enqueue(_ op) · processNext() /*FIFO, backoff 1s·2s·4s·8s·16s then .held*/ 

  reconcile(_ server: SyncResponse)   // gamification: server state REPLACES local, silently

  heldOver24h → UserChoice(.retry|.postWithoutPhoto|.delete)          // SPEC: E19
5.6.4 Server — one canonical route, then the map
Every route is this exact shape (POST /api/v1/posts shown; ~40 lines each, top-to-bottom):

export async function POST(req: Request) {

  const userId = await requireUser(req);                       // 401 inside

  const body = createPostSchema.parse(await req.json());       // 400 inside (zod)

  const dayKey = dayKeyFor(new Date(), body.timezone);         // server clock — SPEC: E15

  const existing = await posts().findOne({ clientId: body.clientId });

  if (existing) return json(existing);                         // idempotent — SPEC: 8.2 ④

  const post = await posts().insertOne({ ...shape... });

  const state = await recomputeAndStore(userId);               // engine truth — SPEC: 12.4

  await logEvent(userId, "post_created", { kind: body.kind });

  return json({ post, gamification: state });

}

Route → lib map: auth/* → auth.ts + email.ts · posts/* → blob.ts (EXIF strip) + engine · crews/* → plain collection ops + captain checks inline · sync → SyncQueue mirror + recompute · reports → email.ts · export → streamed JSON assembly · every mutation ends with recomputeAndStore + logEvent.
5.6.5 Web client — mirrors, not inventions
lib/api-client.ts: one typed function per endpoint, names identical to Api.swift (createSession, createPost…). Pages consume these + the same engine for optimistic rendering. Components mirror iOS Shared/ names (SetRow, PostCard, WeeklyRing, HeatMap) so a fix in one is findable in the other by name.
5.6.6 What the map forbids (doctrine applied)
No SessionManager, no PostService classes, no observer buses between models — models talk to Store/Api/engine directly. Screens hold ZERO logic: every if about business rules lives in a model or engine (screens may branch only on view-state enums). Any function not in this map that a task seems to need = either a plain private helper inside the feature, or a plan-note proposing the map change.


PART VI — UX QUALITY STANDARDS (normative, all platforms, pass/fail)
6.1 The Five States Law
Every screen ships with all applicable states DESIGNED, not defaulted: Loading → Success → Empty → Error → Offline

Loading: skeleton/spinner within 100 ms; skeletons mirror final layout (zero layout shift).
Empty: an invitation, never an apology ("Start your first crew" not "Nothing here yet"); exactly one CTA.
Error: what happened + what to do, one sentence, no codes, always a retry path. Never a dead end.
Offline (iPhone): core loop unaffected; social shows last-synced + one thin banner.
A PR that adds a screen without its states is incomplete by definition.
6.2 Perceived Performance Budgets
Moment
Budget
Measured by
Warm launch → Home interactive
< 1.0 s
signposts
Cold launch → Home
< 2.5 s
signposts
Any tap → visible feedback
< 100 ms
manual + UI test
Set-check → haptic + UI update
< 50 ms (no network in path)
trace
Session/History scroll
60 fps, no hangs > 250 ms
Instruments
Photo post: shutter → optimistic "posted"
< 500 ms (upload continues in background)
trace
Web LCP (Home, Crew)
< 2.5 s on 4G
Lighthouse CI
Web INP
< 200 ms
Lighthouse CI
Rule: nothing user-visible ever waits on the network — every write is optimistic, reconciled silently (server wins).





6.3 Touch & Ergonomics (iPhone)
Targets ≥ 44×44 pt · primaries in the thumb zone · destructive never adjacent to primary · session screen fully one-handed · every swipe gesture has a visible-button equivalent.
6.4 Motion & Feedback
One spring curve app-wide (defined once in Shared/) · celebrations ≤ 2.5 s non-interactive, skippable on first tap · fixed haptic language (tick/double/thump/soft-tap, named in design-tokens.json) · Reduce Motion: static equivalents with identical information · no meaning conveyed by motion alone.
6.5 Accessibility Gate (release-blocking)
Check
Standard
Dynamic Type
Usable at accessibility XXL; no critical action truncated
VoiceOver
100% labeled; session, posting, reacting, chat fully completable non-visually
Contrast
Text ≥ 4.5:1 · components ≥ 3:1 · primary CTAs are ink-fill (≈15:1) per Ember law ① · orange text always #B84D00 on light
Reduce Motion/Transparency
honored everywhere
Web
keyboard-complete, visible focus rings, semantic landmarks, same contrast

6.6 Copy Standards
Sentence case · contractions · verb-first CTAs (1–3 words) · no "please"/"successfully"/"!" on system copy · never guilt framing or red for missed · every notification names its subject.
6.7 Responsiveness & Size Classes (added v1.9 — pass/fail during testing)
iPhone device matrix (iOS 17+ reality): smallest = iPhone SE 3rd gen (375×667 pt) · compact-tall = 13 mini (375×812) · standard = 6.1–6.3" · largest = Pro Max (440×956). Every screen must pass on the SMALLEST and LARGEST, at default AND accessibility-XXL Dynamic Type.

Portrait-only for MVP — the gym context is one-handed portrait; locking orientation removes an entire test dimension.
Layout rules: safe-area–relative everything, zero hardcoded frames; content that can grow (Dynamic Type, long exercise names) lives in ScrollViews; bottom CTAs sit above the home indicator, never behind it; keyboard never covers the focused field or the primary action.
Reachability holds at Pro Max: primary actions stay bottom-anchored regardless of how much canvas exists above.
Non-negotiables on the SE at XXL type: session Complete button visible without scrolling; hero CTAs all on screen; celebration screen fits or scrolls gracefully; no truncated CTA labels anywhere (Part VI 6.5 already forbids it — this names the device it fails on first).

Web breakpoints (full parity): app screens render as a centered single column, max-width ~640 px, from 360 px up; Progress may widen to ~960 px for charts. ≥44 px touch targets below 768 px; hover is never the only affordance (long-press reactions get a visible button on web); no horizontal scroll at any width from 360–1920 px.
6.8 Cross-Platform Consistency
Ember tokens generated from shared/design-tokens.json → Swift + CSS (drift-proof, snapshot-tested) · same flow order and rule outcomes everywhere (server computes truth; both clients run the same vector-tested logic optimistically) · platform-native controls on each platform — parity of capability, not pixel-cloning.


PART VII — SCREEN-BY-SCREEN ACCEPTANCE CRITERIA
(iOS + web unless marked; every screen also inherits Part VI wholesale)

#
Screen
Must-have states
Top acceptance criteria
S01
Launch
loading
Warm start bypasses splash < 1 s; auth restored silently; stale (>day) in-progress session triggers the stale-session prompt
S02
Hero (AMENDED v1.9)
—
ONE screen, three CTAs (Build my week · I have an invite · Log in); invite token renders crew name/emoji on the hero; launch screen matches Home skeleton (no splash)
S03
Plan questions
—
3 questions, all tappable, no keyboard; back-swipe preserves answers; single-selects auto-advance w/ selection haptic; day toggles ≥56 pt, Mon/Wed/Fri pre-selected, live encouragement line; "1 of 3" whisper
S04
Generated plan
loading, error
Renders < 500 ms; every exercise shows equipment chip + targets + mobility block; Swap in 2 taps; Full-Body A/B at ≤2 days
S05
Save your plan (auth)
loading, error
Plan survives auth failure/abandon (resumes here next launch); native Apple button primary; email autofill via textContentType; validate on field-exit; authenticate once per device ever
S06
(REMOVED v1.9)
—
The solo/crew choice screen is cut: invited users auto-join via carried token and land in-crew; organic users go straight to Home's bridge. Crew creation = Crew tab
S07
Home
all five
First-day BRIDGE state until first post exists (oversized single CTA, unlit flame, zero competing prompts); correct today-state (workout/rest/paused/done) < 500 ms warm; ≤3 taps launch→fast-logged; Quick Complete hidden once today counts; crew strip absent (not empty) for solo; Resume banner when session open
S08
Workout preview
loading, empty
Last-time values per exercise; Swap offers [Just today]/[Update plan]; single CTA
S09
Session
offline, error (non-blocking)
One-tap set logging at pre-fill; ghost row after every set; warm-ups excluded from x/y; mobility holds countdown + auto-check; survives kill; Complete always visible; skips gray; out-of-order works; VoiceOver-complete
S10
Complete → Post
—
Numbers match engine exactly; celebration ≤2.5 s, skippable, haptic-only; share-default remembered; solo skips share; PR badge only where weights logged
S11
Nutrition post
permission-denied, error
[+] → live camera < 1 s; library available; time-smart tag pre-selected; text-only ≤ 3 taps; "same as yesterday" chip when applicable; optimistic post < 500 ms
S12
Crew screen
loading, empty (new crew), offline
Pulse correct vs. distinct members posted (3 AM day); unified stream time-ordered; posts as in-stream cards; long-press reactions; comeback banner per rules; 7-day window enforced
S13
Crew create/join/invite
error (full, dead link)
Link → landing (web) → join ≤ 2 taps with app; "crew full" and revoked-link states explicit; Captain tools visible only to Captain
S14
Plan editor
error, undo
Tiered editing (swap/tune/full); limits enforced by input constraints (invalid states unreachable); Rebuild shows diff first; forward-only stated in copy
S15
Progress
empty (new user)
Layer 3 only for weight-logged exercises; heat-map day-tap opens workout + plates; meals/week stat; empty states invite
S16
History/Journal
empty
Every post forever; editing a past session never alters XP (copy says so); deleted posts absent, logs present
S17
Settings
—
Pause flow (≤ 21 days, no retro); per-crew mute; per-row notification toggles; units; JSON export; delete = two-step, "can't be undone"
S18
Welcome back
—
Triggers at 14+ quiet days; one screen, two choices, zero guilt
W1
Web invite landing (web-only)
—
Renders crew name/emoji without auth; App Store + Continue-on-web; joining via web ≤ 3 interactions post-auth



PART VIII — THE TEST CATALOG
8.1 Gamification Vector Suite (shared JSON; Swift & TS engines must match EXACTLY)
Streak & day boundary (V01–V12) V01 first-ever post starts streak at 1 · V02 planned-workout day completed → +1 · V03 rest day + meal post → +1 · V04 rest day, silence → streak 0 at 3 AM · V05 post at 2:59 AM counts prior day · V06 post at 3:01 AM counts new day · V07 workout started 23:00, completed 01:10 → counts completion day · V08 DST spring-forward night resolves in user's favor · V09 timezone travel west (27 h day) → one increment, no double-count · V10 timezone travel east (21 h day) → never retro-missed · V11 two qualifying posts same day → one increment · V12 all-rest plan: meal posts alone sustain indefinitely

Shields (V13–V18) V13 perfect week → +1 shield · V14 cap at 2 (third perfect week → no gain) · V15 miss with shield → consumed, streak intact · V16 two consecutive misses with 2 shields → both consumed, streak intact · V17 first partial week → no shield possible, no penalty · V18 imperfect week (daily posts, one workout missed) → no shield

Plan Pause (V19–V23) V19 pause freezes streak across elapsed days · V20 posts during pause → 0 XP, no increments · V21 pause ends → next day's requirement resumes · V22 retroactive pause → rejected · V23 pause > 21 days → rejected

XP (V24–V31) V24 first post of day = 25 · V25 planned workout = +100 (day-one total 125) · V26 4th+ meal of day = 0 XP · V27 6th+ reaction of day = 0 XP · V28 perfect week bonus = +150 on final completion · V29 comeback (first post after 3+ missed) = +50 · V30 bonus/unplanned workout = +25 · V31 second workout same day = +25, not +100

Completion, undo, edits (V32–V36) V32 ≥1 set done = workout complete · V33 below-target reps: done=true, asPlanned=false, still counts · V34 same-day undo reverses XP+streak atomically · V35 earned achievements survive undo · V36 editing yesterday's reps changes stats, never XP/streak

Crew & pulse (V37–V40) V37 pulse = distinct members posted this (3 AM) day · V38 weekly crew ring resets Monday · V39 comeback banner fires at exactly 3+ missed days, once · V40 mid-week joiner counts in pulse from join day, never breaks prior days

CI rules: a vector failing on either engine blocks every merge. Vectors are append-only — behavior changes require a Decision Registry entry + a NEW vector; old vectors are never edited.
8.2 API Test Matrix (integration, real test MongoDB — no mocks, doctrine C4)
Standing checks auto-generated for EVERY route: ① cross-user access → 403 (server-side userId scoping) ② expired JWT → 401 + refresh works ③ malformed body → 400 with standard error shape ④ idempotent retries where a client UUID exists → no duplicates.

Group
Specific cases
Auth
register/login/apple/refresh rotation/logout; duplicate email; deleted-account re-signup = fresh identity; password reset: token single-use, 30-min expiry, old token dead after use, reset invalidates existing refresh tokens
Plans
one-per-user invariant; PUT replace forward-only; limits rejected server-side; mobility holds persist
Sessions/Sets
client-UUID idempotency; snapshot immunity to later plan edits; warm-up exclusion; duration holds; partial completion
Posts
fitness/meal/text-only creation; delete keeps log + streak; caption edit; EXIF stripped (GPS-tagged fixture asserts clean stored object); 3-meal XP cap server-enforced
Crews
create; join via link; full-crew rejection; regenerated link kills old; leave keeps past posts; Captain removes member; captaincy auto-pass; last-out archive; 1-crew invariant
Messages/Reactions
1,000-char limit; own-delete tombstone; Captain delete; un-react; reaction XP cap; blocked-user filtering both directions
Sync
offline queue replays in order; last-write-wins on plan; server gamification recompute overrides client divergence; device-clock skew reconciled to server time
Moderation/Safety
report post/message/crew-name lands in queue; block hides both ways without notification; EULA gate on register
Account
JSON export completeness; delete cascade — posts vanish from streams, blobs deleted, 404s everywhere after
Pause
create/end; overlap rejected; XP suppression server-enforced

8.3 Unit Test Areas (Swift + TS, real things only)
Plan generator property test: every days × experience × equipment combo yields a valid plan (limits respected, mobility block present, Full-Body at ≤2 days) · SwapFinder: candidates share pattern + equipment, never return the incumbent · SyncQueue: retry/backoff, poison-message handling, ordering — against in-memory SwiftData · DayKey: 3 AM boundary, Monday weeks, DST, timezone shifts · Validators: all input limits · Notification eligibility: reminder / streak-risk / digest conditions.
8.4 UI Journeys (kept green forever)
iOS (XCUITest): ① fresh install → questions → plan → save/auth → first workout incl. mobility hold → post → celebration · ② returning → fast-log → crew reaction received. State probes: camera-denied path; airplane-mode full session; Resume-after-kill. Web (Playwright, seeded backend in CI): the same two, plus ③ invite link → landing → join → react · ④ full plan build + workout log on web (parity proof).
8.5 Accessibility Pass (per release)
Automated: Xcode a11y audit + axe-core on web, zero criticals. Manual scripted: VoiceOver full session + posting + reacting; Dynamic Type XXL on S07/S09/S12; Reduce Motion celebration; keyboard-only web run of journey ④.
8.6 Offline Matrix (manual, pre-TestFlight, iPhone)
Airplane mode: view plan ✓ · full session ✓ · complete + celebration ✓ (local engine) · post queued with chip ✓ · reconnect → auto-send, silent reconcile ✓ · chat draft held ✓ · kill mid-queue → nothing lost ✓ · 24 h failed upload → the Retry/Post-without-photo/Delete choice ✓.
8.7 Security & Privacy Tests
Auto-generated cross-user 403 per route · Keychain-only tokens (static check, no UserDefaults) · httpOnly/secure cookies on web · EXIF fixture test · blob URLs unguessable + auth-checked · post-delete cascade crawl · rate limits on auth + posting · npm audit in CI against the fixed dependency list (Swift has zero deps by law).
8.8 Performance Tests
Launch signposts asserted on device-farm CI · scroll instrumentation on a 500-session History seed · image pipeline: 12 MP → ≤ ~300 KB upload · polling load: 10k users at 5–10 s within Vercel/Atlas budgets · Lighthouse CI budgets enforced on web PRs.
8.9 Responsiveness Tests (added v1.9)
iOS snapshot matrix (automated): S02 hero, S07 Home (bridge + normal), S09 Session, S10 Celebration, S12 Crew rendered at {SE 375×667, Pro Max 440×956} × {default, accessibility-XXL} — 4 snapshots per screen, diffed in CI. Failure = layout break, truncated CTA, or Complete button off-screen.
iOS runtime probes (XCUITest on SE simulator): journey ① completes end-to-end at XXL type; keyboard never obscures the auth fields; portrait lock verified.
Web viewport matrix (Playwright): journeys run at 375, 768, and 1280 px; assertions: no horizontal scroll, all CTAs in-viewport or reachable, reactions operable without hover, single-column max-width respected.
Gate: 8.9 joins the Phase 5 exit criteria alongside 8.5–8.8.


PART IX — DATA MODEL (final shape and invariants)
User (id, email, authProvider, displayName, profilePhotoKey?, units, timezone, reminderTime, createdAt) — profilePhotoKey nullable; unset renders initials Plan (id, userId UNIQUE, updatedAt) → 7 day slots → WorkoutTemplate (day, name, order) → ExerciseTemplate (name, pattern, equipment, type: strength|mobility, targetSets, targetReps, targetWeight?, holdSeconds?, order) Session (id client-UUID, userId, date [3 AM-adjusted dayKey], status, startedAt, completedAt, snapshots…) → SessionExercise → SetLog (targetReps, actualReps, weight?, holdSeconds?, isWarmup, done, asPlanned) Post (id, userId, type: workout|meal|text, sessionId?, photoKey?, caption≤280, mealTag?, createdAt, dayKey) — invariant: deleting a Post never touches Session/SetLog or GamificationState Crew (id, name≤30, emoji, captainId, inviteToken, archivedAt?) · CrewMembership (crewId, userId UNIQUE-per-user, joinedAt, mutedAt?) · Message (id, crewId, userId, body≤1000, deletedAt?) · Reaction (postId|messageId, userId, emoji ∈ {🔥💪👏😂❤️}, UNIQUE per user-target) GamificationState (userId, currentStreak, longestStreak, totalXP, level, shields ≤2, lastCountedDayKey) — server-derived truth, recomputable from Sessions + Posts alone (tested) Pause (userId, startDay, endDay ≤ start+21, one active) · Report (targetType, targetId, reporterId, status) · Block (blockerId, blockedId) Seed data (static, shipped from shared/seed/): ~80 exercises (pattern, equipment, level, type, cueLine, swapGroup, holdSeconds?) · plan templates · achievement definitions.


PART X — PHASES WITH QUALITY GATES (no gate, no next phase)
Phase
Builds
Exit gate
0 Contracts
shared/ populated: spec-constants, tokens, vectors V01–V40, seed drafts; API contracts; Part IX as schemas
Owner signs contracts + content drafts; vectors reviewed
1 Foundation
Monorepo, CI, generate pipeline, auth, app shells, sync queue, lint doctrine rules
CI green incl. vector harness on both engines; standing API checks auto-generated; check-drift green
2 Core loop (iOS)
Questions→plan→session→post→celebration + engine
V01–V36 green on both engines; UI journey ① green; five-states audit S01–S11
3 Crews & social
Crews, stream, chat (polling), reactions, moderation surfaces
V37–V40 green; journey ② green; security matrix green; safety checklist complete
4 Web parity
Full web app + landing
Playwright ③④ green; Lighthouse budgets met; token-parity snapshot test
5 Hardening
Offline matrix, a11y pass, perf, Pause, export, edge screens (welcome-back, stale-session, failed-upload)
8.5–8.9 all pass (incl. responsiveness matrix); zero P0/P1
6 Beta
TestFlight + web beta
Success metrics instrumented and reporting; crash-free ≥ 99.5%
7 Release
Prod env, monitoring, backups, App Store
Launch checklist; Decision Registry audit: nothing rejected exists in code; doctrine lint clean



PART XI — THE BUILD PLAYBOOK (Claude Code task ledger + operating loop)
11.1 The Operating Loop (every session, every task)
SESSION START

  1. Read CLAUDE.md → Appendix A + C → docs/progress.md

  2. Take the NEXT unchecked task in the ledger. Never skip ahead,

     never cherry-pick, never parallelize.

PER TASK

  3. PLAN FIRST, visibly: "Files touched → tests added → vectors/criteria

     affected." A task with no test in its plan is an invalid plan

     (exceptions: pure scaffolding tasks, marked ⚙).

  4. TEST-FIRST where a vector or acceptance criterion exists: write the

     failing test, then the concrete implementation that passes it.

  5. VERIFY BY COMMAND. Run the task's Verify command; only its real output

     proves done. "It should work" is not a state.

  6. CLOSE: update docs/progress.md (state + next task), docs/debt.md if

     anything was compromised, then one conventional commit:

     `feat(scope): description [SPEC: tag]` — commits are task-sized, never larger.

SESSION END

  7. progress.md reflects reality. The next session could be run by a

     different agent with zero chat history and lose nothing.

BLOCKED

  → `SPECIFICATION GAP: [description]` in the response AND in progress.md.

     Stop that task; the owner unblocks. Never guess through a gap.

Ledger rules: tasks are ordered by dependency — the order IS the architecture (contracts → engines → APIs → clients → journeys). Owner checkpoints are marked 🛑 (work stops until the owner reviews). Verify commands: web: runs in web/, ios: runs xcodebuild test -scheme Crew (unit + vectors) or -scheme CrewUITests.
11.2 The Task Ledger
PHASE 0 — CONTRACTS (nothing else starts until 🛑 clears)

T001 shared/spec-constants.json — every number in this spec, named per its rule. Verify: manual diff against Appendix A + Flows. ⚙
T002 shared/design-tokens.json + scripts/generate.mjs + check-drift.mjs → emits Generated/ for both platforms. Verify: node shared/scripts/generate.mjs && node shared/scripts/check-drift.mjs. ⚙
T003 Vector fixtures V01–V40 across the six JSON files (inputs + expected outputs per Part VIII). Verify: JSON schema check. 🛑 owner reviews vectors
T004 shared/seed/exercises.json (~80 w/ pattern, equipment, level, type, cueLine, swapGroup, holdSeconds?). 🛑 owner approves
T005 shared/seed/plan-templates.json (PPL × experience × equipment + Full-Body A/B). 🛑 owner approves
T006 shared/seed/achievements.json + docs/api.md (every route: method, zod schema names, auth, errors). 🛑 owner signs → Phase 1

PHASE 1 — FOUNDATION

T007 ⚙ Monorepo scaffold per Part V 5.2 (Next.js TS-strict; Xcode project; folder tree exact). Verify: web: npm run typecheck + ios builds.
T008 ⚙ CI: lint/typecheck/test (web), build/test (ios), check-drift, doctrine lint (single-conformer protocol ban, magic-number ban, file caps). Verify: green pipeline on empty suites.
T009 lib/db.ts + collections + unique indexes from Part IX (one-plan-per-user, one-crew-per-user, reaction uniqueness). Verify: web: npm test tests/api/db.
T010 Server auth: register/login/refresh/logout — crypto.scrypt, jose JWTs, httpOnly cookies. Verify: web: npm test tests/api/auth.
T011 lib/email.ts (Resend) + password-reset flow (single-use, 30-min, invalidates refresh tokens). Verify: auth suite incl. reset rows.
T012 Sign in with Apple: server verification + iOS AuthStore + web button. Verify: auth suite + manual device check.
T013 ⚙ iOS shells: CrewApp, RootView tabs, Api.swift + ApiModels.swift skeletons, Store.swift container, Shared/ components with five-state scaffolds. Verify: ios builds, empty screens render all states.
T014 SyncQueue + tests against in-memory SwiftData (retry/backoff, ordering, poison). Verify: ios unit suite.
T015 standing-checks.gen.test.ts — auto-generates checks ①–④ for every route file found. Verify: web: npm test (fails on any uncovered route forever after).

PHASE 2 — THE CORE LOOP

T016 DayKey twin (identical names both engines): 3 AM boundary, Monday weeks, DST, timezone shifts. Verify: V05–V10 green BOTH: web: npm run vectors + ios.
T017 GamificationEngine streak + XP core. Verify: V01–V04, V11–V12, V24–V31 green both.
T018 Shields + Pause in engine. Verify: V13–V23 green both.
T019 Completion/undo/edit rules. Verify: V32–V36 green both. Gate: V01–V36 all green on both engines.
T020 PlanGenerator + SwapFinder twins + property test (every days × experience × equipment → valid plan; swap candidates share pattern+equipment). Verify: both unit suites.
T021 Onboarding: PlanQuestionsScreen → GeneratedPlanScreen → SwapSheet (S02–S04 criteria). Verify: ios tests + S02–S04 manual criteria pass.
T022 SaveAuthScreen + SoloOrCrewScreen (S05–S06; plan survives auth abandon). Verify: ios tests.
T023 Plans/Sessions/Sync API routes (snapshot immunity, idempotency, warm-up exclusion, holds). Verify: web: npm test tests/api/{plans,sessions,sync}.
T024 Home (S07): today-state machine (workout/rest/paused/done), Quick Complete visibility, Resume banner, crew-strip-absent-for-solo. Verify: ios tests + S07 criteria.
T025 Session feature (S09): SetRow one-tap + ghost row, warm-ups, MobilityHoldRow timers, RestTimerView, out-of-order, kill-survival. Verify: ios tests + S09 criteria incl. VoiceOver labels.
T026 CelebrationScreen + workout-post creation + share flow (S10) + Posts API (post≠log invariant). Verify: web: npm test tests/api/posts + S10 criteria.
T027 Nutrition posting (S11): CameraCapture, library, time-smart tags, text-only, same-as-yesterday + lib/blob.ts (EXIF fixture test). Verify: posts suite + S11 criteria.
T028 🛑 Journey ① green: ios: CrewUITests Journey1 fresh-install → first post. Phase 2 gate review.

PHASE 3 — CREWS & SOCIAL

T029 Crews API: create/join/invite/members, Captain rules, auto-pass, archive, 1-crew invariant. Verify: crews suite.
T030 Messages + Reactions API: limits, tombstones, un-react, caps, Captain delete. Verify: messages suite.
T031 Crew feature (S12–S13): StreamList unified, PostCard, MemberStrip + pulse, InviteScreen, polling. Verify: ios tests + S12–S13 criteria.
T032 Engine crew rules + comeback. Verify: V37–V40 green both.
T033 Notifications: push-token route, APNs lib/push.ts, eligibility unit tests (reminder/streak-risk/digest/smart-mute). Verify: unit + manual push on device.
T034 Moderation: reports (→ Resend email) + blocks + two-way filtering + EULA gate. Verify: moderation suite.
T035 🛑 Journey ② green (fast-log → reaction received) + security matrix green. Phase 3 gate review.

PHASE 4 — WEB PARITY

T036 Web onboarding + plan builder pages (S02–S06 web). Verify: web: npm run e2e journey1.
T037 Web session logging + posting (S07–S11 web, keyboard-first). Verify: web: npm run e2e journey4.
T038 Web crew stream/chat/progress + invite landing join/[token] (W1). Verify: web: npm run e2e journey3.
T039 🛑 Playwright ③④ green + Lighthouse budgets met + token-parity snapshot. Phase 4 gate review.

PHASE 5 — HARDENING

T040 Progress + Journal both platforms (S15–S16): HeatMap, layer-3 conditional rendering, plate journal. Verify: criteria pass.
T041 Settings (S17): PauseScreen, JSON export route + completeness test, delete + cascade-crawl test. Verify: account suite.
T042 Edge screens: WelcomeBackScreen (14-day trigger), stale-session prompt, failed-upload choice. Verify: unit + manual.
T043 A11y pass (8.5) + offline matrix (8.6) + perf signposts asserted (8.8). Verify: audits zero-critical, matrix checklist.
T044 🛑 Security sweep (8.7) + zero P0/P1. Phase 5 gate review.

PHASES 6–7 — BETA & RELEASE

T045 TestFlight + web beta; E10 metrics dashboards live from first-party events. 🛑 owner reviews metrics weekly.
T046 Production env, monitoring, backups, secrets rotation.
T047 🛑 App Store submission + launch checklist + final Decision Registry audit (nothing rejected exists; doctrine lint clean). Ship.
11.3 docs/progress.md — the required format (agent maintains it)
# Crew build progress

Updated: <date> · Current phase: 2

## Ledger

- [x] T001 spec-constants — done <date>

- [x] T002 generate pipeline — done <date>

- [ ] T016 DayKey twin ← NEXT

## Blockers

- (none) | SPECIFICATION GAP: <description> (T0xx, waiting on owner)

## Notes for next session

- <one or two lines max>
PART XII — THE IMPLEMENTATION PLAN (session schedule, ordering logic, kickoff)
Part X defines the phases and gates; Part XI defines the tasks and the loop. This part is the runbook: how the 47 tasks become ~34 Claude Code working sessions in a logical, dependency-true order, what the owner does and when, and the exact prompt that starts the build.
12.1 Why this order (the logic, so it's never re-argued)
CONTRACTS FIRST      Changing a JSON contract costs minutes; changing shipped

(Phase 0)            code costs days. Every number, color, vector, and seed

                     item is agreed before any code references it.

ENGINES BEFORE UI    The gamification engine is the product's truth. Built

(early Phase 2)      pure and vector-proven first, every later screen renders

                     verified math instead of hopeful math.

SERVER WITH CLIENT   Each API group lands one task before the screen that

                     consumes it — UI is never built against an undefined

                     contract (Builder's Rule 4).

iOS BEFORE WEB       One client proves the API end-to-end; the second client

(Phase 2–3 → 4)      then mirrors a proven system instead of debating it.

HARDENING LAST,      Offline, a11y, responsiveness, and perf are verified

GATES ALWAYS         against the real, complete app — but their BUDGETS were

                     law from day one, so hardening is verification, not rescue.

SERIAL, NEVER        One task, one session-thread, no parallel agents. Serial

PARALLEL             work is what keeps progress.md a single source of truth.
12.2 The Session Schedule (each row = one Claude Code working session; 🛑 = owner reviews before the next session)
#
Tasks
Session goal
Exit proof
S01
T001–T002
spec-constants + tokens + generate/check-drift pipeline
generate + drift scripts run clean
S02
T003
all 40 vector fixtures written
schema-valid 🛑 owner reviews vectors
S03
T004–T005
seed exercises + plan templates drafted
🛑 owner approves content
S04
T006
achievements + full API contract doc
🛑 owner signs → build unlocked
S05
T007–T008
monorepo scaffold + CI with doctrine lint
pipeline green on empty suites
S06
T009–T010
db + indexes + server auth
auth suite green
S07
T011–T012
Resend reset flow + Sign in with Apple
auth suite incl. reset green
S08
T013
iOS shells: tabs, Api/Store skeletons, five-state scaffolds
app builds, states render
S09
T014–T015
SyncQueue + standing-checks generator
ios unit + web test green
S10
T016–T017
DayKey + engine core (twin)
V01–V12, V24–V31 green BOTH engines
S11
T018–T019
shields, pause, undo in engine
V01–V36 green both (mini-gate)
S12
T020
PlanGenerator + SwapFinder + property tests
both unit suites green
S13
T021–T022
onboarding screens: hero→questions→reveal→auth
S02–S05 criteria pass
S14
T023
plans/sessions/sync API
api suites green
S15
T024
Home incl. bridge state machine
S07 criteria pass
S16
T025
the Session screen, complete
S09 criteria incl. VoiceOver pass
S17
T026–T027
celebration→post + nutrition posting + blob
posts suite + S10–S11 pass
S18
T028
Journey ① green end-to-end
🛑 Phase 2 gate review
S19
T029–T030
crews + messages/reactions APIs
crew suites green
S20
T031
Crew screen: stream, pulse, invite
S12–S13 criteria pass
S21
T032–T033
crew engine rules + notifications
V37–V40 green; push on device
S22
T034
moderation: reports, blocks, EULA
moderation suite green
S23
T035
Journey ② + security matrix
🛑 Phase 3 gate review
S24
T036
web onboarding + plan builder
e2e journey1 green
S25
T037
web session + posting
e2e journey4 green
S26
T038
web crew + invite landing
e2e journey3 green
S27
T039
Lighthouse + token parity
🛑 Phase 4 gate review
S28
T040
Progress + Journal, both platforms
S15–S16 criteria pass
S29
T041–T042
Settings, pause, export, edge screens
account suite + criteria
S30
T043
a11y + offline + responsiveness + perf runs
8.5, 8.6, 8.8, 8.9 pass
S31
T044
security sweep, P0/P1 burn-down
🛑 Phase 5 gate review
S32
T045
TestFlight + web beta + metrics live
🛑 owner reviews metrics weekly
S33
T046
production env, monitoring, backups
prod checklist items green
S34
T047
App Store + registry/doctrine audit
🛑 SHIP


A session that doesn't reach its exit proof ends by recording exactly where it stopped in docs/progress.md; the next session resumes there — sessions are goals, tasks are the unit of truth.
12.3 The Owner's Cadence (your entire job during the build)
Phase 0 week: four review sittings (S02–S04 🛑) — vectors, exercises, templates, achievements + API doc. This is where your product taste enters the code forever; give it real attention.
Five gate reviews (S18, S23, S27, S31, S34): open the app, run the journey yourself, read docs/progress.md + docs/debt.md, say go/no-go.
Any SPECIFICATION GAP: answer it in a message; the answer gets logged to the Decision Registry before work resumes.
Beta (S32+): read the E10 metrics weekly; resist scope ideas — write them to the parking lot instead. That's it. Everything else is the agent's, governed by this document.
12.4 The Kickoff (paste this as your first message to Claude Code)
Read docs/crew-mvp-spec.md in full. Appendix C is your contract; Part V is

your code doctrine; Part XI is your loop; Part XII is your schedule.

Create docs/progress.md in the 11.3 format with the full T001–T047 ledger.

Then begin Session S01 (T001–T002): plan first — files touched, tests

added, vectors affected — then implement, verify by command, and close

per the operating loop. Stop at every 🛑 for my review.

Subsequent sessions start with exactly: Continue. Read docs/progress.md and run the next session per Part XII. — nothing more is ever needed; the repo carries all state.
12.5 Standing risks the schedule already answers
Firebase ⏳ (Appendix B) must be resolved before S06 or the approved custom auth proceeds by default · vector review (S02) is the highest-leverage hour of the entire project — wrong expected values there become "green" bugs everywhere · the S18 gate is intentionally the hardest: if Journey ① isn't genuinely smooth on a real phone, Phases 3–7 inherit the flaw, so this is the gate to be pickiest at.
APPENDIX A — THE DECISION REGISTRY ✅ (all owner-approved 2026-09-04)
Product: social accountability via daily posts + Crews · mobility = end-of-workout block, duration-based · no cardio workouts MVP · plan-before-account onboarding · web = full parity · identity = single profile picture (in-app camera or library), initials fallback when unset; sloth avatar set considered and REJECTED — one identity system only (owner-final 2026-09-04). Gamification: XP table as specced · 3 AM day boundary · Plan Pause (≤3 weeks) · 2 shields max, perfect-week-earned · below-target sets count as done · any post sustains the streak · first partial week earns no shield · anti-cheat doctrine permanent. Plan/tracking: PPL canonical + Full-Body ≤2-day fallback · equipment asked in onboarding · swap-don't-interrogate · management by exception · something > nothing · no goals system · rest timer + setup cues + PR celebrations + plate math + warm-ups + ghost rows · no gates on editing · supersets excluded. Crews: unified stream · 1 crew/user · Crew Pulse · no nudges · 7-day feed · reactions 🔥💪👏😂❤️, no comments/DMs · invite-link only · Captain model · comeback celebrations. Nutrition: photo/text only, never numbers · camera + library · time-smart tags · same-day backfill · 3-meal XP cap. Policy: 13+ · JSON export in MVP · Monday weeks · EXIF stripped · manual moderation · reportable everything · deletion cascades. Build: one Next.js repo on Vercel + Atlas + Blob · Resend for transactional email (reset, report queue, delete-confirm — never marketing) · polling chat · first-party analytics · zero Swift dependencies · fixed npm allowlist · iOS 17 · iPhone-only (web covers big screens) · haptics-only feedback · warm-gym-buddy voice · Ember color system + six laws — AMENDED 2026-09-04 (owner-directed, Robinhood-style restraint): ink-monochrome CTAs/controls everywhere; ember = reward layer only, never interactive · simplicity is the architecture. Code: the Concrete Doctrine C1–C14 (owner-directed: no abstraction) · monorepo with generated shared/ pipeline · twin-engine naming symmetry · real-thing testing, no mocks · spec-traceable tags · doctrine-enforcing lint · the Feature Code Map 5.6 as the signature-level design authority (v1.8). Quality: Five States Law · performance budgets (Part VI) · accessibility gate release-blocking · vectors append-only · phase quality gates mandatory · UX Detail Layers (research-driven, added per-phase): Phase 1 Onboarding & First-Run + the Bridge (v1.7); AMENDED v1.9 onboarding review — single hero (carousel cut), invite-aware fast path, Mon/Wed/Fri pre-selected, solo/crew choice screen removed, ≤90 s / ≤60 s targets · responsiveness standard 6.7 + test matrix 8.9, portrait-only MVP.
APPENDIX B — REMAINING DELIVERABLES (Phase 0 work, owner approves each)
⏳ PENDING OWNER DECISION — Firebase Auth: proposed by owner, conflicts with two approved registry entries (zero third-party Swift dependencies — the Firebase iOS SDK is a large multi-module dependency; and the no-second-backend-vendor reasoning that declined Supabase). Options: A (recommended) keep the approved custom auth — Sign in with Apple + email with jose JWTs and crypto.scrypt hashing, reset emails via Resend (~300 lines, fully in-spec) · B adopt Firebase Auth — amend both registry entries, accept the SDK on iOS, split user records across Firebase + Mongo, and handle two-system deletion cascades. Until decided, the approved custom auth stands; nothing may be built against Firebase.

Seed exercise list (~80, pattern + equipment + level + type + cue line + swap group, incl. mobility holds) → shared/seed/exercises.json.
Plan template contents (PPL variants × experience × equipment + Full-Body A/B) → shared/seed/plan-templates.json.
Final achievements list (~12–15, solo + crew, from approved mechanics) → shared/seed/achievements.json.
APPENDIX C — THE BUILDER'S RULES (Claude Code contract)
This document is law; the Decision Registry resolves all conflicts.
Undefined behavior → STOP, emit SPECIFICATION GAP: [description], wait for the owner.
Never adjust gamification numbers, the rejected-features lists, the five Ember laws, the performance/accessibility budgets, or the Concrete Doctrine.
Dependency order: contracts → data model → API → backend → clients → tests. Never build UI against an undefined contract.
No scope expansion — "preparing for" a rejected feature IS expansion. No abstraction expansion either — a protocol, generic, or layer without two live concrete users is scope expansion of the codebase (C1).
Simplest CONCRETE implementation that satisfies the spec; extraction only on the third occurrence, into a plain function.
"Done" = the screen's Part VII acceptance criteria pass + Part VI inherited standards + relevant Part VIII tests green + doctrine lint clean. The happy path rendering is not done.
Vectors are append-only; a red vector on either engine blocks every merge.
Every number from this spec enters code only through shared/spec-constants.json → Generated files. Never edit Generated/ by hand.
Record every compromise in docs/debt.md in the same commit that creates it.
Re-read this appendix + the Decision Registry at the start of every session (CLAUDE.md enforces this).
Execute strictly through the Part XI ledger: next unchecked task only, plan visibly, verify by command output, close by updating docs/progress.md. 🛑 tasks stop the line until the owner reviews.

