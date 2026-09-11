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


Permanently rejected: barcode scanning · AI food recognition · healthiness ratings · any score, grade, colour, rank or label applied to a food, a meal or a day. The moment Crew grades a meal, honest posting dies. Self-entered macro planning and daily tracking is a separate, private, ungamified vector (A16); the plate journal stays numberless.
THE SEVEN NO-GRADE CLAUSES (A16, owner-ratified 2026-09-10). All seven or A16 is not ratified — they are never applied partially, and each names the mechanism that enforces it, because a rule with no mechanism is a rule that drifts:
① No food, meal, outline or day is ever scored, rated, ranked, colour-coded by quality, or labelled healthy / clean / junk — not in the UI, not in the seed data, not in a sort order. ENFORCED BY: a check-seeds.mjs assertion over shared/seed/meal-outlines.json (no quality tag, no healthiness word, and seed order is not a ranking).
② Over-target is never red, never a minus sign, never an alert, never a notification, never a modal. An overage is a measurement stated in ordinary ink on its own line, naming tomorrow in the same breath. ENFORCED BY: macro-palette.test.ts (no semantic token on a nutrition surface; a macro token is identity, never status) plus the daily-screen copy test.
③ A macro entry earns no XP, breaks no streak, consumes no shield and unlocks no achievement. ENFORCED BY: vector V63 on both engines — zero XP awarded and day.meals not incremented.
④ A macro number never appears in the crew feed, on a profile, or in Crew Pulse. Nutrition numbers are private to the person who typed them. ENFORCED BY: nutrition documents are a separate collection never joined into a feed or pulse query, with a route test that asserts it.
⑤ No plausibility check, no "that seems low", no anomaly flag, no under-reporting warning on an entered number. This is E15 verbatim, applied to food. ENFORCED BY: bounds validation and nothing else — there is no other validation to write, and the launch audit greps for one.
⑥ The plate journal stays numberless: JournalFacts.line keeps rendering "Dinner · 4:31 PM" and never a gram or a calorie. ENFORCED BY: a test on that existing pure function, on both engines.
⑦ Barcode scanning, AI food recognition and healthiness ratings stay permanently rejected, forever, and are never "prepared for". ENFORCED BY: the T047 launch audit, whose grep is rewritten from the old literal "calorie/macro entry" to these seven clauses (W067).
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
E1 Identity (AMENDED 2026-09-04, owner-final) — name + one profile picture, taken with the camera in-app or uploaded from the library. That is the entire identity system: the previously considered sloth avatar set is rejected — two identity systems (avatars + photos) proved too complicated in v1 of this product, and one is enough. Until a picture is set, the default state renders the user's initials on warm gray (a fallback, not a second system — there is nothing to choose). Profile photos get the same treatment as all photos: EXIF/GPS stripped on upload, changeable anytime in Settings. No bios, no body stats — with ONE BOUNDED EXCEPTION added 2026-09-10 by A16: a single CURRENT bodyweight, held only as the input to the nutrition target calculator. Never a history, never a trend, never a chart, never on a profile, never visible to a crew, and deleted in one tap together with the targets it produced. That is the entire exception; nothing else about a body is ever stored. Your streak and posts are your identity.

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
#211D19 text · primary buttons = #211D19 fill with #FAF8F5 label · secondary buttons = #938C83 controlOutline, ink label (A18.11, 2026-09-10 — was the #E9E4DD hairline, which measures 1.26:1 on a card and 1.19:1 on the canvas and so failed 6.5's 3:1 gate on the one mark that says a control IS a control; #938C83 measures 3.32:1 / 3.13:1. `hairline` keeps #E9E4DD for card edges and dividers: a boundary between two SURFACES is not a component) · #6F6860 secondary text · #A8A29A missed-gray
#F5F1EB text · primary buttons = #F5F1EB fill with #171412 label · #726A61 controlOutline (3.15:1 on the dark card, 3.45:1 on the dark canvas) · #A69E94 secondary
≤10% Ember
the reward layer ONLY: streak flame, XP count-ups, ring & heat-map fills, PR / comeback / celebration accents
#DF5908 shapes (A17.4, 2026-09-10 — was #FF6600, which measured 2.77:1 on the bone canvas and failed 6.5's 3:1 non-text gate; #DF5908 measures 3.56:1 at hue h23 against h24, the same orange one shade deeper) · #B84D00 for any orange words · #FFEFE3 tints & ring tracks
#FF7A1F lifted · #33241A tints


Semantics: success #3E8E5A · danger #D64550 (berry, never near orange) · missed = warm gray, never red.

The six laws (amended): ① Ink acts, Ember rewards — no button, CTA, link, toggle, tab, or any interactive control ever wears orange; navigation and chrome are monochrome forever. ② Warm neutrals only. ③ Orange is a shape color, not a text color (#B84D00 for orange words; #FF6600 fails WCAG on light). ④ Ember appears only when progress is the message — flame, XP, ring fills, PR/comeback/celebration. Most screens show ZERO ember at rest; the scarcity is why the flame hits. ⑤ Dark mode lifts (#FF7A1F), never inverts. ⑥ The 20% stays neutral; no second hue, with ONE BOUNDED EXCEPTION (A16, owner-ratified 2026-09-10): three categorical macro identity tokens — protein, carbs, fat — exist for nutrition surfaces only, bound by four hard rules: chroma never above C* 36; never inside CIELAB hue 20°–95° (the ember wedge, where #FF6600 sits at h52); identity only, never status, so a macro colour never changes with over / under / on-target; and no surface renders an ember element and a macro fill together. Semantics keep green/red/gray for their meanings, and no semantic token appears on a nutrition surface.

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
Something > nothing: done = sets & reps · food = photos, and optionally your own numbers — never ours



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
First-day BRIDGE state until first post exists (oversized single CTA, unlit flame, zero competing prompts — and that CTA absorbs an open session rather than a second banner appearing beside it, A18.8); correct today-state (workout/rest/paused/done) < 500 ms warm; ≤3 taps launch→fast-logged; Quick Complete hidden once today counts; crew strip absent (not empty) for solo AND below crewMinMembers (A17.1); Resume banner when session open on every NON-bridge state (A18.8); the nav title NAMES THE STATE (A17.4 — "Rest day" / "Push day" / "Done for today" / "Plan paused"); one ink summary sentence under the week strip, and the day's single ink-filled primary in the thumb zone on every state that HAS one (A17.1/A17.2). EVERY NUMERAL IS NAMED where it sits — "day streak" under the flame, "workouts this week" under the ring (A18.1); the ring renders only above zero done and never while paused (A18.2); the week strip marks EVERY planned day and never a miss inside a pause window (A18.6a/A18.7); the what's-next fact is its own block above the card on rest/all-done/paused (A18.3); the three logging vectors are full-width VERB rows (A18.5); the paused card carries "End the pause now" (A18.6c); the all-done card reports today and carries no control (A18.9); the toolbar camera is absent wherever the card already offers a meal CTA (A18.10); and the offline state is REACHABLE, not merely declared (A18.12)
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

Shields (V13–V18) V13 perfect week → +1 shield · V14 cap at 2 (third perfect week → no gain) · V15 miss with shield → consumed, streak intact · V16 two consecutive misses with 2 shields → both consumed, streak intact · V17 first partial week → no shield possible, no penalty · V18 imperfect week (daily posts, one workout missed) → no shield · V18b all-rest plan week (zero workout days) → sustains the streak, never earns a shield (Decision Registry gap resolution G6, 2026-09-04)

Plan Pause (V19–V23) V19 pause freezes streak across elapsed days · V20 posts during pause → 0 XP, no increments · V21 pause ends → next day's requirement resumes · V22 retroactive pause → rejected · V23 pause > 21 days → rejected

XP (V24–V31) V24 first post of day = 25 · V25 planned workout = +100 (day-one total 125) · V26 4th+ meal of day = 0 XP · V27 6th+ reaction of day = 0 XP · V28 perfect week bonus = +150 on final completion · V29 comeback (first post after 3+ missed) = +50 · V30 bonus/unplanned workout = +25 · V31 second workout same day = +25, not +100

Completion, undo, edits (V32–V36) V32 ≥1 set done = workout complete · V33 below-target reps: done=true, asPlanned=false, still counts · V34 same-day undo reverses XP+streak atomically · V35 earned achievements survive undo · V36 editing yesterday's reps changes stats, never XP/streak

Crew & pulse (V37–V40) V37 pulse = distinct members posted this (3 AM) day · V38 weekly crew ring resets Monday · V39 comeback banner fires at exactly 3+ missed days, once · V40 mid-week joiner counts in pulse from join day, never breaks prior days

Appended in S02 (2026-09-04, append-only): V41 level 2 at 500 XP emits levelUp(2) · V42 level 3 at 1500 XP — the G2 formula, not a table · V43 deleting a post from an already rolled-over day never retro-breaks streak or XP (E3) · V44 one active pause at a time — a second pause is rejected until the first has ended (Flow 7). The fixture contract lives in shared/vectors/README.md.
Appended 2026-09-04 (continuous build, append-only; kind `achievements` in the README): V45 the first workout post earns First flame + Showed up in seed order · V46 earned once — the same or higher counters award nothing again · V47 streak achievements fire exactly at 7 / 30 / 100 and catch up in seed order · V48 perfect weeks 1 and 5, a streak that falls afterwards removes nothing (V35) · V49 crew achievements (found your crew · hype · all in · perfect crew week), leaving removes nothing · V50 new best · saved by the shield · back in it · fifty workouts with thresholds met together, seed order kept.

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
Product: social accountability via daily posts + Crews · mobility = end-of-workout block, duration-based · no cardio workouts MVP · plan-before-account onboarding · web = full parity · identity = single profile picture (in-app camera or library), initials fallback when unset; sloth avatar set considered and REJECTED — one identity system only (owner-final 2026-09-04). Gamification: XP table as specced · 3 AM day boundary · Plan Pause (≤3 weeks) · 2 shields max, perfect-week-earned · below-target sets count as done · any post sustains the streak · first partial week earns no shield · anti-cheat doctrine permanent. Plan/tracking: PPL canonical + Full-Body ≤2-day fallback · equipment asked in onboarding · swap-don't-interrogate · management by exception · something > nothing · no goals system (NARROWED 2026-09-10 by A16 to TRAINING; nutrition targets are the single exception — user-owned, editable, maintenance-only estimates, never a prescribed deficit, never a weight goal) · rest timer + setup cues + PR celebrations + plate math + warm-ups + ghost rows · no gates on editing · supersets excluded. Crews: unified stream · 1 crew/user · Crew Pulse · no nudges · 7-day feed · reactions 🔥💪👏😂❤️, no comments/DMs · invite-link only · Captain model · comeback celebrations. Nutrition: the plate journal is photo/text only, never numbers (UNCHANGED) · self-entered macro planning and daily tracking is a separate, private, ungamified vector per A16 (2026-09-10) · camera + library · time-smart tags · same-day backfill · 3-meal XP cap. Policy: 13+ · JSON export in MVP · Monday weeks · EXIF stripped · manual moderation · reportable everything · deletion cascades. Build: one Next.js repo on Vercel + Atlas + Blob · Resend for transactional email (reset, report queue, delete-confirm — never marketing) · polling chat · first-party analytics · zero Swift dependencies · fixed npm allowlist · iOS 17 · iPhone-only (web covers big screens) · haptics-only feedback · warm-gym-buddy voice · Ember color system + six laws — AMENDED 2026-09-04 (owner-directed, Robinhood-style restraint): ink-monochrome CTAs/controls everywhere; ember = reward layer only, never interactive · simplicity is the architecture. Code: the Concrete Doctrine C1–C14 (owner-directed: no abstraction) · monorepo with generated shared/ pipeline · twin-engine naming symmetry · real-thing testing, no mocks · spec-traceable tags · doctrine-enforcing lint · the Feature Code Map 5.6 as the signature-level design authority (v1.8). Quality: Five States Law · performance budgets (Part VI) · accessibility gate release-blocking · vectors append-only · phase quality gates mandatory · UX Detail Layers (research-driven, added per-phase): Phase 1 Onboarding & First-Run + the Bridge (v1.7); AMENDED v1.9 onboarding review — single hero (carousel cut), invite-aware fast path, Mon/Wed/Fri pre-selected, solo/crew choice screen removed, ≤90 s / ≤60 s targets · responsiveness standard 6.7 + test matrix 8.9, portrait-only MVP.
Gamification/Build — gap resolutions 2026-09-04 (owner-approved; raised by the builder in S01, logged here before S02): G1 XP per reaction = 2 (xpReaction), capped at 5 counted reactions per day per V27 — max 10 XP/day from reactions; crumbs by design. G2 Levels — a user starts at level 1 with 0 XP; reaching level N (N ≥ 2) requires totalXP ≥ 500 × (N−1) × N / 2 (L2 = 500 · L3 = 1500 · L4 = 3000 · L5 = 5000 · L6 = 7500 · L7 = 10500 …); stored as the formula (levelBaseXp = 500), never as a table. G3 Flow 8 "≤20 sets" is per EXERCISE (planMaxSetsPerExercise), the original rule; 15 exercises × 20 sets is the day ceiling. G4 Dark-mode tokens — missedGray dark = #5E574F (quieter than secondary text: a missed day recedes on dark, never reads as content); emberText dark = #FF7A1F (clears 4.5:1 on #171412, so dark mode needs no deep-ember variant — one fewer token). G5 Spacing scale 4 / 8 / 12 / 16 / 24 / 32, nothing off-scale; the one app-wide spring curve (6.4) = response 0.35, dampingFraction 0.8. G6 Perfect week = a Mon–Sun week where EVERY planned workout day has a completed workout AND every day has ≥1 post AND the plan had ≥1 workout day that week; all-rest plans sustain streaks (V12) but can NEVER earn shields (vector V18b). G7 "Some experience" generation defaults = 5 exercises per workout at 3×8–10 (completing the Brand-new 4 / Experienced 6 progression). G8 softTap haptic = reaction received. G9 Rest timer default = 90 seconds, per-workout adjustable, off-able. G10 Meal-tag hours (local): breakfast 04:00–10:30 · lunch 10:30–15:30 · dinner 15:30–21:00 · snack otherwise. G11 JWT lifetimes: access 15 min · refresh 30 days, rotating; rate limits: auth endpoints 10 req/min/IP · post creation 60/hour/user · everything else unlimited in MVP. G12 Reminder time: no silent default — the user chooses it at the in-context opt-in moment after the first workout, with 7:30 AM pre-filled as the suggestion.
T003 vector review — APPROVED 2026-09-04 (owner): all 45 vectors (V01–V40, V18b, V41–V44) and every reviewNote interpretation as written — V08 (DST spring-forward night keeps a full 24 h; boundary at 04:00 that night) · V14 (+150 perfect-week XP still paid at the shield cap) · V24 (Part IX type `text` earns only the first-post XP; text-only meals are kind `meal`) · V32 (warm-up-only sessions are NOT complete — ≥1 work set required) · V38/V40 (the crew weekly ring = the week's daily pulses, membership as of each day) · V39 (paused days are never "missed" for the comeback rule) · V44 (no queued second pause while one is active) · shared/vectors/README.md (undo reverses the day's most recent post; a rollover event is the sole judge of a miss).
2026-09-04 — CONTINUOUS BUILD MODE (owner-directed operating amendment): owner converts all 🛑 checkpoints to recorded self-review + end ratification; agent runs continuously to maximum achievable completion. Terms: (1) at every former 🛑 the agent writes a self-review against the relevant spec sections into docs/ratification.md (checkpoint, what was checked, verdict, what the owner should look at) and continues; content tasks (T004–T006) are drafted to best spec-consistent judgment and proceed. (2) SPECIFICATION GAPs no longer stop the line: the most conservative interpretation consistent with the spec is adopted, tagged `// GAP:` in code, logged in ratification.md; never an interpretation that expands scope or touches a rejected feature. (3) Physical limits re-route, never stall, within true dependency order: no Xcode on this Windows machine — every iOS task's Swift sources and tests are WRITTEN per the 5.6 map and marked "WRITTEN — UNVERIFIED (needs Mac)", never claimed done; verifiable work (shared/, server routes + integration tests, the full web app, Playwright, the TS engine against all 45 vectors) is prioritized; no real credentials exist (Atlas, Vercel Blob, Resend, APNs, Apple) — local/test substitutes and dev-only test infrastructure (e.g. an in-memory MongoDB) may be added as devDependencies, each logged in ratification.md and debt.md; a complete .env.example ships; real-service wiring goes on the deferred list. (4) Truth discipline unchanged: verify by command for everything runnable here; one commit per task with [SPEC:] tags; progress.md current after every task. (5) Termination: stop only when nothing further is achievable in this environment; the final act is docs/OWNER-REVIEW.md — everything ratifiable, everything deferred, and the exact ordered steps to ship.
Gamification — achievements awarding pass 2026-09-04 (agent, continuous build; ratification R-037): the 15 seed achievements (Appendix B list, T006) are awarded by one pure pass — `Achievements.earned(counters, alreadyEarned)` — run after every server recompute and every local apply: an achievement is earned once, the first time its trigger counter reaches threshold, in seed order, appended after `levelUp` in the canonical award order, and never removed (V35). Counters are facts (posts, completed sessions, current streak, reactions given, crew membership, crew full-pulse days/weeks with membership as of each day and total ≥ crewMinMembers, personal records = a completed session beating every earlier logged best for an exercise) plus three engine tallies (perfect weeks, shields consumed, comebacks — engine memory, reverted with the day on undo, never asserted by apply vectors). The API's `gamification` reply gains `newAchievementIds` (what this mutation unlocked; E8) alongside the running `earnedAchievementIds`. Vectors V45–V50 (kind `achievements`) pin the rule on both engines.
Build — dev-only tooling additions 2026-09-04 (agent, under continuous-build rule 3b; ratification R-005): devDependencies beyond the fixed list, none shipped to production — `@types/node` `@types/react` `@types/react-dom` (TypeScript type packages the `typescript` entry implies), `eslint-config-next` (the ESLint config the `eslint` entry implies for a Next.js repo), `@playwright/test` (the runner package that IS Playwright), `mongodb-memory-server` (a local MongoDB for the real-database test suite until Atlas credentials exist — C4 real-thing testing, no mocks). iOS project generation: `ios/project.yml` (XcodeGen spec) generates `Crew.xcodeproj` on the owner's Mac — XcodeGen is a Mac dev tool, not a Swift dependency (the zero-dependency law is untouched).
2026-09-08 — OWNER-DIRECTED AMENDMENTS FROM THE FIRST TESTFLIGHT SMOKE TEST (logged by the agent under continuous build; the owner's review message is the direction, this entry is the record; ratify or strike each line). Full contract: docs/improvement-plan-2026-09-08.md. A1 Rotation — a plan is trainingWeekdays (ISO 1–7, ≥1) plus an ORDERED list of workouts; every generated plan is Push day · Pull day · Leg day at every frequency 1–7 (Full-Body A/B is no longer generated; the seed keeps the templates and legacy plans keep working); the next workout is the one after the LAST COMPLETED rotation workout and only a completed workout advances the pointer (never a missed day, a pause, or a plan edit); the pointer is derived from history, never stored; balance is automatic (over any 3k completed workouts each kind occurs k times). The agent's stated assumption: the evidence favours full-body at 1–2 days/week, the owner asked for PPL only, so PPL rotates at every frequency and the days picker shows one neutral line. A2 Cardio — "no cardio workouts MVP" is lifted: cardio is a third exercise type, duration-based (holdSeconds = seconds) with one optional distanceMeters; nine seeded activities (walk, run, bike, swim, row, elliptical, stairs, hike, other); two homes — a block inside a planned workout (part of the +100, never extra XP) and a standalone log from Home (a session of kind cardio, unplanned → +25 per V30/V31, sustains the streak, never advances the rotation); no pace, effort, calories, heart rate, goals or targets, ever; Progress shows cardio minutes/week and mobility minutes/week as facts; vector V51 (completion: a duration-only session with one done set is complete) appended. A3 Home — every non-bridge state carries a what's-next line, a way to post a meal, Log cardio, and (rest / all-done) Bonus workout; E19 takes precedence over 5.6.3: a counted-but-undelivered post never lowers the local streak (the server's gamification state replaces the local one only when no post op is pending, in flight or held), retryable sync failures retry, held ops younger than 24 h retry on foreground and network return. A4 Plan editor — two disclosure levels (week map with zero controls → one-workout editor with Cancel/Save → exercise sheet with 44 pt steppers, Swap, Move up/down, Remove + Undo); training days editable without a rebuild; forward-only stated in copy. A5 Crew — header pinned at the top; the solo tab explains the loop in three lines then one CTA; a crew of one shows an invite card and no composer until two members; the invite sheet opens right after creation; report and block one long-press away; the pulse never reads "0/n" (No posts yet today). A6 Journal — grouped by day with readable labels (Today · Yesterday · Mon · Mon Sep 8), one summary line per post (Push day · 12/12 sets · 44 min; Walk · 25 min · 2.1 km; Dinner · 4:31 PM), an empty state, a Sending ↻ chip while undelivered; sets/week counts strength work sets, mobility and cardio are minutes. A7 Settings — profile name + photo (camera or library), per-row notification toggles backed by User.notificationPrefs {workoutReminder, streakRisk, crewActivity} (absent = true), the stored reminder time shown and never silently rewritten, mute state from the server, blocked people (GET blocks + unblock), privacy policy and terms pages, version, log out that revokes the refresh token and clears the queue. A8 Copy — never a zero as a verdict, never red for a miss, orange only on rewards. New constants: cardioMinutesMin 1 · cardioMinutesMax 300 · cardioMinutesStep 5 · cardioDistanceMaxMeters 100000 · metersPerKilometer 1000 · metersPerMile 1609.344 · dayLabelWeekdayWithinDays 6 · distanceDecimalScale 10 (GAP, agent: a distance rounds half-up to tenths with integer arithmetic so both engines print the same digit — JS toFixed and printf %.1f disagree on an exact binary half; 2250 m → "2.3 km" on both). Server-side bounds decided in the build: a cardio row's holdSeconds ≤ cardioMinutesMax × 60, a mobility hold's ≤ holdSecondsMax. Map additions (5.6): PlanRotation.swift ⇄ plan-rotation.ts (nextWorkoutKind · workoutKindFromName · lastRotationKind · projectWeek · nextTrainingDayKey), DayLabel.swift ⇄ day-label.ts (dayLabel · weekHeader), SessionSummaryLine.swift ⇄ session-summary-line.ts; Plan/ gains WorkoutEditorScreen · ExerciseSheet · WeekRow · DaysSheet (PlanDayCard removed); Session/ gains CardioRow · CardioLogScreen · CardioLogModel; Home/ gains BonusWorkoutSheet · NextUpLine; Settings/ gains EditProfileScreen · BlockedPeopleScreen; web gains /plan/[kind], /log-cardio, /privacy, /terms. Gamification numbers, the rejected lists (Flows 4, Part II, Part IV), the six Ember laws and the doctrine are untouched.

2026-09-09 — OWNER-DIRECTED AMENDMENTS FROM THE SECOND PHONE REVIEW (build 0.1.0 (3); logged by the agent under continuous build; the owner's review message is the direction, this entry is the record). STATUS: RATIFIED IN FULL BY THE OWNER 2026-09-10 — A9–A15 as drafted here and as implemented through Stage 5; A16 RATIFIED MAINTENANCE-ONLY with the seven no-grade clauses (spec:240) and three owner additions (A16.a methodology screen, A16.b age-questionnaire entry gate, A16.c 18+ surface gate). See the 2026-09-10 entry below for the ratification and its terms. Full contract: docs/ux-plan-2026-09-09.md. Evidence: a 13-agent repo review (Home, Session, units, exercise data, design system, doctrine, web parity, nutrition) plus outside research on numeric entry, unit prompting, whitespace, exercise media licensing, macro tracking, the flex-budget pattern, macro colour and food data. A9 Units — `units` is replaced by TWO fields, `weightUnit` (lb|kg) and `distanceUnit` (mi|km), each defaulted at account creation from the device measurement system (.us → lb+mi, .uk → kg+mi, .metric → kg+km) and CONFIRMED ONCE in context on the first Session screen (one dismissible line, one tap to accept, one to flip); the unit label beside every weight is permanently tappable to switch; EVERY logged set stores the unit it was entered in, so a preference change is purely cosmetic and never reinterprets history; plate math, PR detection and strength trends compare on a normalised value. This closes a shipped data-integrity defect: today `units` is a display suffix with zero conversion code, so flipping it relabels a 135 lb bench as "135 kg", switches PlateMath from a 45 lb to a 20 kg bar, and fires a false "new best" in one direction while going blind in the other. New constants: kilogramsPerPound · poundsPerKilogram · per-unit rounding increments. New vectors V52 (conversion round-trip) · V53 (PR compares normalised). A10 Weight entry — Flow 3's "smart steppers … long-press fast-scroll" is replaced FOR WEIGHT ONLY by a horizontal snapping tape (large ink readout, ruler snapping to the unit's plate increment, haptic tick per notch, readout taps through to a decimal keypad, ± retained for single-notch nudges); reps keep the ± stepper; invalid values stay unreachable by clamping on commit; the tape carries an explicit accessibilityAdjustableAction or it is invisible to VoiceOver (a release-blocking 6.5 failure). A wheel picker was considered and REJECTED on evidence: it cannot resize for Dynamic Type, its unselected rows fail text contrast, and Voice Control cannot select an option — three direct 6.5/6.7 violations. New constants: tape range per unit · tick spacing · label cadence · points-per-notch. A11 Set removal — 5.6.2's SessionModel action surface gains removeSet: a swipe-left delete on any set row WITH the visible-button equivalent 6.3 requires and an Undo snackbar; removal renumbers the remainder and an exercise never drops below one set (server-guarded). New vectors V54 (renumber + recompute setsPlanned) · V55 (floor of one set). A12 Prefill — Flow 3's existing promise ("rows load your last ACTUAL performance") is implemented rather than merely displayed: at session creation each set seeds its weight and reps from the last completed session of that exercise, and a decrement from the floor returns to "—". Today every strength set opens at "—" while lastTimeLine computes the very numbers needed and renders them as grey text, so reaching 225 lb costs 45 taps or a 5.3 s hold. A13 Exercise media — each seed exercise gains an optional `mediaId` and a `muscles` array; line-art frames ship BUNDLED and tinted to ink at runtime (never edited on disk); tapping an exercise name opens a .medium detent sheet with start/end frames, a tinted muscle map, setup bullets, common mistakes and the last-time line. This is the SECOND occurrence of the sheet pattern alongside Plan/ExerciseSheet — C5 governs: duplicate it, do not extract. A Settings acknowledgements screen ships with the assets. BLOCKED until the CC BY-SA licence question is confirmed. A14 Home — A3's enumeration of Home's contents is extended: a seven-day strip rendering the per-day states HomeModel already computes and WeeklyRing already ignores (done · missed · rest · today · upcoming), the day's actual exercise rows inside the workout card (identity line outranking the count line), and a three-slot Workout · Cardio · Meals row giving the three vectors equal position while the plan's workout keeps the single ink-filled primary. Controls bottom-anchor into the thumb zone (6.7 already requires this at Pro Max). The BRIDGE STATE IS UNTOUCHED per §1D, and its ember "0/3" ring is REMOVED — it is simultaneously a competing prompt on the one screen that must have none, an orange element that is not a reward, and a zero used as a verdict (A8). A cardio log gets its own post type: today a standalone cardio session writes type "workout", so every count of workouts silently includes walks. A15 Change today's workout — one sheet with three escape hatches: what-do-you-have-today (Nothing · Dumbbells · Full gym → today's workout rebuilt at that equipmentAccess with the same movement patterns via the existing SwapFinder tiers), do-a-different-day (the existing bonus list), and build-my-own (the catalog picker). A custom session FILLS today's ring slot and earns full planned-day credit, and does NOT advance the rotation pointer — `custom` is not in the plan's cycle, so this falls out of A1's derived-pointer design rather than fighting it. On completion the celebration offers to save it as a reusable workout. New vector V56. A16 Nutrition — macro planning and daily tracking become a fourth surface (RATIFIED 2026-09-10, MAINTENANCE-ONLY), and it narrows FIVE rules that only the owner may touch: spec:240 Flow 4's permanent rejection is NARROWED not deleted (new text: "Permanently rejected: barcode scanning · AI food recognition · healthiness ratings · any score, grade, colour, rank or label applied to a food, a meal or a day. The moment Crew grades a meal, honest posting dies. Self-entered macro planning and daily tracking is a separate, private, ungamified vector (A16); the plate journal stays numberless."); spec:1490's "Nutrition: photo/text only, never numbers" keeps governing the PLATE JOURNAL unchanged while A16 is a separate vector earning no XP, sustaining no streak and never entering the crew feed; spec:1490's "no goals system" is narrowed to training, with nutrition targets the single exception — user-owned, editable, MAINTENANCE-ONLY estimates, never a prescribed deficit, never a weight goal; spec:340's E1 "No bios, no body stats" gains ONE BOUNDED EXCEPTION, a single CURRENT bodyweight held only as the target calculator's input (never a history, never a trend, never a chart, never on a profile, never visible to a crew, deleted in one tap with the targets it produced); and spec:453 becomes "food = photos, and optionally your own numbers — never ours". Ember law ⑥ is amended to: "The 20% stays neutral; no second hue, with one bounded exception. Three categorical macro identity tokens — protein, carbs, fat — exist for nutrition surfaces only, bound by four hard rules: chroma never above C* 36; never inside CIELAB hue 20°–95° (the ember wedge, where #FF6600 sits at h52); identity only, never status, so a macro colour never changes with over/under/on-target; and no surface renders an ember element and a macro fill together. Semantics keep green/red/gray for their meanings, and no semantic token appears on a nutrition surface." SURVIVING VERBATIM and governing the whole feature: spec:452 "Weights & calories never pressure you" (the rule the zero-floor, the no-red rule, the no-minus rule and the no-notification rule answer to), spec:358 E15 "No effort scoring, no anomaly flags, ever" (no plausibility check on an entered macro, no under-reporting flag), and Ember laws ① ③ ④ ⑤ inside the feature (no macro colour on any control; macro colours are shape colours only; every numeral and letter is ink). MODEL: "Your usual day" is a 1–6 slot fixed template of seeded meal outlines; "Flex" is the remainder (target − template), defined in place on first exposure; a SKIPPED template meal never becomes Flex (the day just comes in lower); Flex floors at zero and states an overage as a measurement on its own line, in ordinary ink, naming tomorrow in the same breath; each macro's framing flips from consumed to remaining at 50% with the fraction always visible; a photo post and a macro entry are TWO OBJECTS with separate lifecycles (E3's post≠log shape); targets are protein-first from bodyweight with a fat floor of max(20% of energy, 0.5 g/kg) and carbs as the remainder, every number editable, the whole flow skippable to manual. PALETTE (verified with CIEDE2000 and Machado et al. 2009 CVD simulation at full severity across normal/protanopia/deuteranopia/tritanopia, not picked by eye): macroProtein pine #2E4E28 light / #BDD9B9 dark (8.86:1 / 12.04:1) · macroCarbs slate #5A8EB4 / #3D7392 (3.32:1 / 3.55:1) · macroFat mulberry #6C315F / #DAADDB (8.84:1 / 9.59:1) · plus three warm-neutral tracks. Worst intra-palette separation ΔE00 23.5 light / 22.6 dark; minimum separation from the reward orange 24.8 / 44.5 / 30.0 (MyFitnessPal's carbs orange would score 7, Okabe-Ito's vermilion 3.7); chroma capped at C* ≤ 36 against the ember's C* 90, so the flame stays ~2.5–3× the most saturated object in the app — that ratio is the mechanism that keeps this reading as three inks with a tilt. FIVE REDUNDANT ENCODERS ARE MANDATORY (WCAG 1.4.1 is Level A and Apple surfaces "Differentiate Without Color Alone" as App Store metadata): fixed order Protein → Carbs → Fat forever · a P/C/F letter in INK on every coloured element · direct numeric labels, never a colour-only legend · fill treatment as a third channel (solid / solid+hairline / outline) · STATE IS NEVER COLOUR. The screen must be fully correct with every macro token forced to plain ink. TWO HAZARDS ON THE RECORD: macroCarbs sits only ΔE00 7.4 from the existing success token under deuteranopia, so they must never share a surface (the amended law already forbids it); and ember #FF6600 on bone measures 2.77:1, below the 3:1 graphical-object gate — a pre-existing defect logged in debt.md. New vectors V57–V64, of which V63 is load-bearing: a macro entry awards zero XP and does not increment day.meals, machine-checking the boundary between the graded and ungraded halves of the app forever. mealXpDailyCap stays 3, xpMealPost stays 15, V03/V12/V18b/V24/V26 are untouched. LAUNCH-GATE NOTE: T047's audit greps the source for the rejected list including "calorie/macro entry"; after A16 that grep stops being meaningful and must be replaced by the no-grade clauses, or the gate silently loses its teeth on the exact rule this amendment exists to preserve. Gamification numbers, Flow 4's remaining rejections, Part II, Part IV's supply-chain rules, Ember laws ① ② ③ ④ ⑤, the performance and accessibility budgets and the Concrete Doctrine are untouched.
2026-09-10 — OWNER RATIFICATION OF A9–A16, THREE ADDITIONS TO A16, AND THE EXERCISE-ART RULING (the owner's decision message is the direction, this entry is the record). A9–A15 ARE RATIFIED as drafted in the 2026-09-09 entry and as implemented through Stage 5 of docs/ux-plan-2026-09-09.md; ratification changed no code. A16 IS RATIFIED, MAINTENANCE-ONLY: nutrition targets are maintenance estimates and nothing else — NO DEFICIT, no deficit phase, no deficit constants, no sex field, and no body stat beyond the single current bodyweight E1 now excepts. A deficit, if it is ever wanted, is a SEPARATE amendment with its own phase and its own compliance checklist, and is not stubbed for (C1/Appendix C: preparing for it is scope expansion). The five overturns are applied in this document exactly as tabled: spec:240 narrowed, not deleted, and now carrying the seven no-grade clauses; spec:1490's "photo/text only, never numbers" unchanged for the PLATE JOURNAL; spec:1490's "no goals system" narrowed to training; spec:340's E1 gaining the bounded current-bodyweight exception; spec:396's Ember law ⑥ gaining the macro-token exception with its four hard rules; and spec:453 restated as "food = photos, and optionally your own numbers — never ours". THE SEVEN NO-GRADE CLAUSES ARE PART OF THE RATIFICATION, not commentary on it: without all seven and their named enforcement mechanisms A16 is not ratified, and it is never partially applied. W067 stands: T047's launch audit stops grepping the literal "calorie/macro entry" and checks the seven clauses instead, so the gate does not silently lose its teeth on the one rule A16 exists to preserve.
A16.a METHODOLOGY SCREEN — REQUIRED, NOT OPTIONAL. App Review 1.4.1's rejection language covers "calculations", and a TDEE estimate is a calculation. Stage 9 ships an in-app, easy-to-find methodology screen naming the formula used (Mifflin-St Jeor), the activity-multiplier source, and the line that this is an estimate and a clinician should be consulted before acting on it. Every source must be linkable.
A16.b AGE-RATING QUESTIONNAIRE — A STAGE 9 ENTRY GATE, AND AN OWNER TASK. Apple's 2025 questionnaire carries a mandatory medical/wellness section; adding calorie targets changes the honest answer, and Apple may raise the rating above 13+. Stage 9 does not begin until the owner has re-answered the App Store Connect questionnaire with A16 in mind and the resulting rating is recorded in docs/progress.md. The agent adds the gate; the agent does not perform the task.
A16.c 18+ GATE ON THE NUTRITION-TARGET SURFACE — RULED YES. The app stays 13+ (minimumAgeYears 13 is UNCHANGED). The macro-target vector and the bodyweight input are shown only to users whose age on file makes them 18+; under-18 users get the numberless plate journal exactly as today and never see the target surface, its Settings rows, or its onboarding questions. One constant plus one guard — no separate copy, no upsell, no "unlock at 18" messaging. New vector V65 asserts the surface is unreachable for a 17-year-old fixture on both engines. GAP (agent, 2026-09-10, conservative reading, open until the owner rules): the account holds a birth YEAR, not a birthdate (birthYearMin; requireSignupGates computes currentYear − birthYear), and birthYear is OPTIONAL on the Sign in with Apple path (LoginScreen passes nil), so an account can exist with NO age on file. The conservative interpretation adopted, and the one Stage 9 implements unless the owner rules otherwise: age is derived as currentYear − birthYear, the same arithmetic the signup gate already uses, and an ABSENT birth year is treated as under 18 — the surface is hidden, nothing is asked, and no existing account is re-prompted. This is recorded rather than resolved because it lands inside the same owner task as A16.b.
A13 EXERCISE ART — BUNDLE bryllim/workout-guide (artwork CC BY-SA 4.0, code MIT, derived from Everkinetic), VENDORED, BEHIND THE LAWYER GATE. Only the SVG frames for the 110 seeded exercises are copied into the repo, pinned to upstream release 1.0.0 with the upstream commit hash recorded, alongside the upstream LICENSES.md and ATTRIBUTION.md. NO npm dependency and NO CDN URL (jsDelivr or otherwise) anywhere in the app — vendor, do not depend. The files are NEVER edited on disk; tinting happens at render time only (.renderingMode(.template) / .foregroundStyle), because an unmodified bundle is a COLLECTION under CC and an edited file is Adapted Material. That ShareAlike boundary is MACHINE-CHECKED, not remembered: a test hashes every vendored SVG against a committed manifest, so an on-disk edit fails CI. A Settings attribution screen satisfies CC BY-SA 4.0 §3(a)(1) — Bryl Lim, Everkinetic (Greg Priday), the copyright notice, the licence name and URI, the warranty disclaimer, and a link upstream — built from the upstream plain-text attribution block. STAGE 8 REMAINS GATED on the owner's lawyer confirmation of the FairPlay / Effective Technological Measures question. The vendored assets, the hash test and the attribution screen MAY be prepared behind a feature flag; they MAY NOT ship to a TestFlight build until that gate clears. Fallback order if the answer is no: (1) RepDB free tier (CC attribution, no ShareAlike — exact terms to be verified), (2) exercisedb.io $199 Starter. Neither is pre-built.
UNTOUCHED BY THIS ENTRY: the gamification numbers, Flow 4's remaining rejections (barcode scanning, AI food recognition, healthiness ratings), Part II, Part IV's supply-chain rules, Ember laws ① ② ③ ④ ⑤, the performance and accessibility budgets, minimumAgeYears 13, and the Concrete Doctrine C1–C14.

2026-09-10 (evening) — A17, OWNER-DIRECTED FROM THE THIRD PHONE REVIEW OF HOME (the owner's message is the direction, this entry is the record; each of the four amendments below was authorised explicitly and separately). The complaint, verbatim: "I am looking at it and clearly don't know what to do next or what this screen is for or what the colors are for." Three questions; the screen answered none. Full contract: docs/home-plan-2026-09-10.md. Evidence: a 41-agent review across eight lenses with every finding adversarially verified against the source — 62 findings, 52 confirmed, 10 refuted — plus outside research on habit-app home screens, rest-day states, competing progress indicators, colour legends and empty-state placeholders. THE ROOT DIAGNOSIS: four elements on Home (the flame, the ring, the week strip, the crew strip) each build a complete English sentence and render it ONLY to VoiceOver, so a sighted user gets a glyph, two bare numerals and seven dots between the nav title and the card. Home explained itself to a screen reader and to nobody else.
A17.1 HOME CARRIES VISIBLE COPY. A3 (2026-09-08) and A14 (2026-09-09) are the ratified ENUMERATIONS of Home's contents and both are silent on captions, so the wordless header is an unexamined carry-over rather than a ratified silence — which is why this is an amendment and not a defect fix. Home gains: ONE ink summary sentence under the week strip, built from facts Home already computes ("This week: Wed done · Mon missed · next Sun"), which names the colours IN SITU so there is no legend to look up (a legend is a split-attention lookup, and A16 already ratified "direct numeric labels, never a colour-only legend"); a "Your crew" caption on the crew strip, which is otherwise a bare avatar with an unexplained dot and numeral; and the streak stake folded into the existing rest-day line ("Post anything today and your 1-day streak holds") so "One post keeps it lit" finally says what "it" is. THE HARD LIMITS ON ALL THREE: every one is secondaryText INK and never #B84D00 (law ③); none is ever tappable (law ①); and each is BRIDGE-GATED like the ring and the strip — on the bridge the streak is 0, so an ungated caption would put a noun beside a zero-as-verdict (A8) on the one screen §1D says carries nothing else. No countdown, no risk notification, no time-pressure line: spec:452 ("Weights & calories never pressure you") and the no-nudges doctrine govern this clause, and a streak countdown on Home is the shape of the thing this app was built not to do. The crew strip is additionally SUPPRESSED below crewMinMembers, exactly as the Crew tab already does (CrewModel.isCrewOfOne) — Home was the last surface showing a user their own face back to them and calling it a crew.
A17.2 THE STACK IS REORDERED. A14's flexible space moves from BELOW the day's card to ABOVE it. Consequence: the day's single ink-filled primary sits in the thumb zone on every state, and the leftover height becomes a section break under the header group rather than one contiguous hole. This is the first time 6.7's "primary actions stay bottom-anchored regardless of how much canvas exists above" is literally true on Home — under A14 the filled primary sat ABOVE the spacer on rest, all-done and paused, and on `.paused` (where the card renders zero controls) the slack reached roughly 29% of the screen. The space above the card is filled with facts Home already computes and renders nowhere: the miss named in words and the shield when one is held (HomeModel computes `shields` and `lastAwards`; iOS renders neither — the identical shape as the ring that ignored its `days:` parameter). The research finding this answers, recorded because it will be argued again: this was never too much whitespace, it was too few content elements to justify the whitespace.
A17.3 THE CARD'S EXTRAS ARE REMOVED ON REST AND ALL-DONE. A3 requires "a way to post a meal, Log cardio, and (rest / all-done) Bonus workout" — A WAY, not a dedicated button each. The three-slot vector row IS that way, at a position that no longer moves between states, and this is the same argument the code already makes for workout days. Measured before: seven controls reaching three destinations, with "Post a meal" offered THREE separate ways, and on rest(posted) and all-done the card's meal button is a SecondaryButton — so those seven-control screens carried ZERO ink-filled primaries and "one primary action per view" failed in the letter, not merely the spirit. Seven become five; the toolbar camera stays. THE ARGUMENT FOR THIS IS RANKING LEGIBILITY, NOT OPTION COUNT: choice overload does not survive meta-analysis (Scheibehenne, Greifeneder and Todd 2010, 63 conditions, N=5,036, effect near zero) and must not be cited here. This clause is written into the Registry specifically so no future session re-adds the buttons by reading A3 literally. FORWARD NOTE: A15's "Change today's workout" sheet routes "do a different day" to the same bonus list, which would become a FOURTH control for that destination — A15 does not ship until Home is settled.
A17.4 THREE TOKEN AND CONTRACT VALUES MOVE. (a) Part III's `ember` LIGHT value #FF6600 becomes #DF5908. #FF6600 measures 2.77:1 on the bone canvas, below 6.5's 3:1 graphical-object gate; #DF5908 measures 3.56:1 at hue h23 against h24 — a one-degree shift, the same orange one shade deeper. The dark value #FF7A1F (7.03:1), `emberText` #B84D00 (4.83:1, the text gate) and `emberTint` #FFEFE3 (the ring track, decorative — the fraction inside the ring is ink) are ALL UNCHANGED. This repays the ember entry in debt.md, which already prescribed exactly this route, and it matters now rather than later because A16's three macro tokens all pass their gate and would leave the flame as the only failing colour in the app. Every snapshot moves. (b) The week strip gains a FIFTH mark, for the NEXT training day only — not for all upcoming days. W040 specified four marks for five states, and `.rest` and `.upcoming` shipped byte-identical, so the plan's prose ("each state has its own SHAPE"), the code, and the code's own comment ("upcoming = the same tick, quieter") all disagreed with one another; this settles it in the one direction a rest day actually asks about — the owner's plan trains Mon/Wed/Sun and Sunday rendered identically to Friday while the card said "Next workout: Sun". (c) Home's nav title becomes PER-STATE, ending the only tab/title disagreement among the five screens. ALSO ON THE RECORD, NOT AMENDMENTS: six of the seven status marks on Home measured below the 3:1 non-text gate (missed 2.39:1, rest/upcoming 1.19:1, the unlogged vector dot 1.26:1, the crew not-posted dot 2.53:1), and the A14 pass certified them compliant BY ANSWERING THE WRONG RULE — arguing WCAG 1.4.1 (colour is not the only channel, which the shapes do satisfy) against a spec clause that states 1.4.11 (non-text contrast). They are repaired by pointing each at the existing secondaryText token, which needs no token change and no ratification. The crew posted-dot additionally gains a hollow ring for not-posted, which is what spec:290 already called "the EMPTY today-dot" — a spec deviation and a 1.4.1 gap closed together.
UNTOUCHED BY A17: the gamification numbers, every rejected list (Flows 4, Part II, Part IV), Ember laws ① ② ③ ④ ⑤ ⑥ (the VALUE of `ember` moves; no law changes and no second hue appears), the performance and accessibility budgets, minimumAgeYears 13, the Concrete Doctrine C1–C14, and every append-only vector. A17 ADDS NO VECTOR AND CHANGES NO ENGINE RULE — the count stays at 56 across the whole plan, and a task that appears to need a new vector has drifted outside A17.

2026-09-10 (night) — A18, OWNER-DIRECTED FROM THE FOURTH PHONE REVIEW OF HOME, ON THE SCREEN A17 PRODUCED (the owner's message is the direction, this entry is the record; the owner answered sixteen questions explicitly and each answer is carried below). The complaint, verbatim: "looking at this I have questions and the next action isn't clear like what is the 1/3? Why is their a big blank pace? Why does the card saying rest day have a post meal CTA? why are there three strange divs at the bottom with workout, cardio, and meals?" A17 answered "what are the colours for" and did not answer "what do I do now", and its reordered stack is the void the owner is now looking at. Evidence: a 45-agent review (7 repo lenses + 6 outside-research lenses, 124 findings, 10 load-bearing claims through 3 adversarial verifiers each, a synthesis and a completeness critic). Full contract: docs/home-plan-a18-2026-09-10.md.
A18.1 EVERY NUMERAL ON HOME IS NAMED WHERE IT SITS. A17.1 diagnosed the disease correctly — "the flame, the ring, the week strip and the crew strip each build a complete English sentence and render it ONLY to VoiceOver, so a sighted user gets a glyph, two bare numerals and seven dots" — and then treated the strip and the crew avatar only. THE TWO BARE NUMERALS WERE THE FLAME AND THE RING, and neither got a word. They sit on one row and both read "1" on the owner's screen while meaning unrelated things (consecutive days with any post; workouts done this ISO week), so the natural reading — "my 1 is 1 of 3" — is wrong. Home gains two captions: "day streak" under the flame and "workouts this week" under the ring. A17.1's three hard limits are carried verbatim: secondaryText INK and never #B84D00 (law 3), never tappable (law 1), bridge-gated. A8 branch: the flame's caption renders only above a streak of zero and reads "streak paused" while paused; the ring's caption cannot render below one done workout because A18.2 removes the ring there.
A18.2 THE RING IS A REWARD, SO IT APPEARS WHEN THERE IS ONE. The weekly ring renders only once the week holds at least one completed planned workout (and never while paused, A18.6). It was gated on `ringPlanned > 0, !isBridge`, so on every non-bridge MONDAY it printed "0/3" — the identical construction A14 removed from the bridge for being "a zero used as a verdict (A8)", one day in seven, for every user, for the life of the app; the other six states were never checked. The same removal is already ratified twice (the bridge ring; A5's crew pulse, which "never reads 0/n"). The week stays fully readable without it: A18.7 marks every planned day and the summary sentence still says "nothing logged yet".
A18.3 THE NEXT SESSION IS A BLOCK ON THE IDLE STATES, NOT A CARD FOOTNOTE. On rest, all-done and paused, the what's-next fact moves out of the card into its own group in the space above it — a caption heading and an ink detail line. A3's "what's-next line on every non-bridge state" is SATISFIED, NOT OVERTURNED: the line survives and moves. A17.2 recorded the correct diagnosis of the void ("this was never too much whitespace, it was too few content elements to justify the whitespace") and then shipped nothing that filled it — the two facts it named are the miss, which sits in the header group ABOVE the spacer, and the shield, which is perfect-week-earned and so is never held by the one-day streak in the screenshot. It renders ONLY on the idle states: on a workout day the card already IS what is next, and that state is the tallest (H009 measured it truncating at accessibility-XXL on an SE).
A18.4 THE REST-DAY CARD STATES THE PREMISE, NOT ONLY THE REWARD. "Post anything today and your 1-day streak holds" states what you get and never states why a rest day carries a requirement at all. Crew's streak is DAILY and has no training-day exemption — streak.vectors.json V04 is titled "rest day, silence -> streak 0 at 3 AM" — so the card's first line ("recovery is part of the plan") and its loudest control appear to contradict each other. The line becomes "Rest days count too — post anything and your N-day streak holds." A17.1's hard limit bans the CONSEQUENCE ("no countdown, no risk notification, no time-pressure line") and a statement of the premise is none of the three; spec:452 and spec:460 are untouched.
A18.5 THE THREE VECTORS BECOME THREE FULL-WIDTH VERB ROWS. A14's three equal-width bordered cells are, by Apple's own definition, the silhouette of a SEGMENTED CONTROL ("a linear set of two or more segments, each of which functions as a mutually exclusive button"; "within the control, all segments are equal in width") — and their grammar is a stat readout, a NOUN title over a value, while 6.6 requires verb-first control labels and the shipped VoiceOver name is literally "Workout, Done today" on a Button. The owner read them as "divs". The row becomes three full-width rows: an ink verb leading ("Log workout" - "Log cardio" - "Log a meal"), today's status trailing when there is one. A14'S RATIFIED CONTENT IS UNTOUCHED — the same three vectors, the same equal position, the same peer weight, the same single ink-filled primary elsewhere; only the geometry and the grammar move. It also retires the ViewThatFits fallback that existed solely because three-across truncates at accessibility sizes.
A18.6 THE PAUSED SCREEN STOPS CONTRADICTING ITSELF AND OFFERS THE WAY OUT. Four changes to one state. (a) The week marks become PAUSE-AWARE: a planned day inside an active pause window is never `missed`, because Flow 7 and spec:460 promise "pauses without penalty" and A17.1 turned those grey dots into the English sentence "This week: Mon missed" directly above a card reading "Your streak is frozen". (b) The ring does not render while paused. (c) The card gains "End the pause now" — the identical string PauseScreen.swift:22 and SettingsView.tsx:26 already use, so no third wording for one action enters the app (6.6) — which is the only candidate control on any Home card that is plan-level rather than a fourth route to a logging screen. (d) The WEB PAUSE GUARD lands at the model, mirroring HomeModel.swift:76: web computed today's workout with no pause term, so a frozen plan still offered "Quick complete" and sent the Workout route into a session stamped isPlannedDay:true. XP never leaked (V20 returns [] inside a pause window, which is also why a bonus workout while paused pays ZERO, not +25 — the comment claiming +25 is corrected in the same pass). Flow 7 and S07 gave the paused card zero controls; this entry is what changes that.
A18.7 EVERY PLANNED DAY GETS A MARK. A17.4(b) marked only the NEXT training day, so every planned day after it rendered byte-identically to a rest day and was named in no sentence: on a four-day plan the ring says "of 4" while the strip can account for at most three of them, so the strip cannot be used to read the ring. A18.1 puts the word "workouts" beside the ring and turns that mismatch into a visible contradiction. Every planned day now carries the planned mark and the NEXT one stays distinguishable (filled against hollow). A17.4(b) is OVERTURNED and this clause is the record. Consequence for the twin: the two engines disagreed about a bonus workout completed on a NON-training day (iOS guards on trainingWeekdays before reading any session and returns `rest`; web's projectWeek tested the completion first and emitted `done`), which produced two different sentences for one user; iOS's rule wins, because the ring counts planned days only and a strip that marks an unplanned completion cannot be read against it. The bonus stays visible in the journal and on Progress.
A18.8 THE BRIDGE CARRIES ONE CTA, INCLUDING WHEN A SESSION IS OPEN. The bridge survives until the first POST exists and starting a workout creates a session, not a post — so starting one and abandoning it put the bridge card's CTA and a "Resume workout" banner on screen together, on the one screen 1D says carries nothing else, and OfflineSessionTests asserted BOTH AT ONCE, so the rule was being broken by a passing test. The banner is suppressed on the bridge and the bridge's own single button reads "Resume your first workout" when a session is open. S07's "Resume banner when session open" and 1D's "zero competing prompts" are reconciled here in 1D's favour, ON THE BRIDGE ONLY; every other state keeps the banner.
A18.9 THE ALL-DONE CARD REPORTS THE DAY AND POINTS FORWARD. It was the one state with no filled control at all, so the day you did everything right was the day the screen looked least finished. It gains today's completed work as a summary line built by the existing SessionSummaryLine twin — the same sentence the journal prints, so no new copy and no new engine rule — and loses its outline "Post a meal"; the meal row and the toolbar camera both remain. No button: the day is closed.
A18.10 ONE DESTINATION, ONE ROUTE PER WEIGHT. The toolbar camera is dropped on any state whose CARD already offers a meal CTA. A3's "a camera toolbar button on every non-bridge state" is NARROWED, the same shape of carve-out A17.3 already made to A3's enumeration. On the screenshot the owner sent, posting was reachable three ways at three different weights (an unlabelled nav glyph, an ink-filled card primary, a slot), which Apple's own navigation guidance names as a cause of confusion ("the redundancy creates confusion... Home becomes the tab where every feature is fighting for real estate"), and the glyph was the screen's only unlabelled control. A17.3 claimed it had reduced posting to at most two routes; that arithmetic was wrong and is corrected in docs/home-plan-2026-09-10.md.
A18.11 `controlOutline` IS A TOKEN OF ITS OWN. Every outline control in the app drew its boundary with `secondaryButtonOutline` = `hairline` = #E9E4DD, which measures 1.26:1 on a card and 1.19:1 on the canvas against 6.5's 3:1 non-text gate — conceded in a source comment and exempted by name in the contrast test. On a control with no fill the outline IS "the visual information required to identify the component" that WCAG 1.4.11 governs, so at 1.26:1 the thing that says "this is a button" was invisible, which is precisely what the owner reported. Part III's table gains `controlOutline` #938C83 light (3.32:1 on a card, 3.13:1 on the canvas) / #726A61 dark (3.15:1 / 3.45:1), applied to every outline control on both engines, and the exemption is deleted and replaced by a source guard. `hairline` KEEPS ITS OWN VALUE: a boundary between two SURFACES (a card edge, a list divider) is not a UI component and 1.4.11 does not govern it. Ember laws 1 and 6 are untouched — this is a 70%-Canvas structure colour in the existing warm-gray family, not a control fill and not a second hue.
A18.12 HOME'S OFFLINE STATE IS REACHABLE. HomeScreen declared `.offline` and `load()` could only ever assign `.failed`, `.ready` or `.empty`, so its OfflineBanner had never rendered on any device — while 6.1's Five States Law was certified by a test that builds a five-element literal array and asserts it has five elements. CrewScreen does reach the state; Home does not. SyncQueue.processNext already distinguishes `.offline` from a failure (E6: "no network is not a failed attempt"), so the signal exists and was simply never published: it is published, Home reads it, and ShellStatesTests asserts REACHABILITY instead of counting a literal.
A18.13 THE STREAK'S CADENCE IS RECORDED, NOT CHANGED. Crew's streak is daily while its plan is weekly, which is the root reason a rest day must be bought with an unrelated post. The market went the other way (Hevy: "rest days do not break your weekly streak"; Nike Run Club counts consecutive weeks) and a ~60,000-post study (British Journal of Health Psychology, UCL + Loughborough) reports streak users describing "guilt, irritation and shame" and "greater discouragement over time". THE CADENCE STAYS DAILY. This clause exists so the argument is not re-derived, and to record that A18.4's premise line EXISTS ONLY BECAUSE THE STREAK IS DAILY: if the cadence ever moves to weeks, that line is deleted in the same commit. Logged as an open owner decision in docs/debt.md.
A18 ADDS NO VECTOR, AND THIS IS THE RULING, NOT AN OMISSION. The vector suite is the GAMIFICATION fixture contract — every file feeds initialState + events into the streak/XP/shield engine. A18 changes no rule that engine runs: the pause-aware week marks (A18.6a) are a REPORTING function, they award nothing, and V19-V23 already pin the pause behaviour they report on. Inventing a new fixture kind for one view-facts function would be a new abstraction with one caller, which C1-C5 forbid, so both engines get twin UNIT tests instead — the same ruling A17 made for a pure formatting twin. V57-V64 STAY RESERVED for A16 (nutrition) exactly as the 2026-09-09 entry names them; the next free id after this pass is still V57.
UNTOUCHED BY A18: the gamification numbers and every streak/XP/shield rule, every rejected list (Flows 4, Part II, Part IV), Ember laws 1 2 3 4 5 6 (no law changes, no second hue, every control stays ink), the performance and accessibility budgets, minimumAgeYears 13, the Concrete Doctrine C1-C14, and every append-only vector.

2026-09-11 — A19, OWNER RATIFICATION OF THE APP-WIDE INTERACTION-ERGONOMICS AUDIT (the owner's decision message is the direction, this entry is the record). A19 IS RATIFIED AS DRAFTED: docs/ios-ux-audit-2026-09-10.md, items R1-R23 with its Phase 10 rationale and Phase 11 sequence, becomes the contract. Where A17 and A18 were Home-only and content-shaped, A19 is app-wide and MECHANISM-shaped: it adds ONE component (`.crewBottomBar`) and ONE rename (`SetCountButton` -> `TextActionButton`), and no layer, protocol, generic, dependency or architectural change of any kind. The Concrete Doctrine C1-C14 is untouched, and the one extraction it makes is the doctrine's own third-occurrence rule applied to eight live call sites that each hand-roll a different wrong version of the same thing.
A19.1 THE BOTTOM ANCHOR BECOMES REAL (R1). `safeAreaInset` has ZERO uses in the app. Every "bottom-anchored" primary is either a `Spacer` inside scrolling content or a `VStack` sibling, and a Spacer inside a ScrollView COLLAPSES TO ZERO the moment content exceeds the viewport. So 6.7's "primary actions stay bottom-anchored regardless of how much canvas exists above" and "bottom CTAs sit above the home indicator" have never been mechanically true anywhere; they have been true only while each screen happened to fit. A18's own layout gate measured it on the rest-day Home: the largest inter-block gap is 212 px at 440x956, 108 px at 393x852, and 24 px at 375x667 — where it is small precisely BECAUSE the page already overflows and the anchor has already collapsed. At accessibility-XXL on an SE it is false on more screens still. A new `Shared/BottomBar.swift` provides `.crewBottomBar { }` over `safeAreaInset(edge: .bottom)`, using `EmberColors.controlOutline` (A18.11) for its top edge and `@ScaledMetric` for its metrics, and it is CONDITIONAL: absent on any state with no primary, because A17.3 and A18.9 both rule that a day asking nothing carries no filled primary and a permanent chrome strip that manufactures an ask is a regression. Adoption order is lowest-risk first — Generated plan, then Nutrition post, Cardio log, Session, Workout editor, and HOME LAST, because Home is the most recently changed surface and A17.2's placement reasoning must be PRESERVED, not re-argued: A19.1 replaces the mechanism that holds the placement, never the placement.
A19.2 THE DEAD ENDS CLOSE (R2, R3, R6). `.numberPad` and `.decimalPad` ship NO RETURN KEY, and no screen carries a keyboard toolbar, so a user who focuses the cardio distance field or the birth-year field can reach a state with no way to dismiss the keyboard and no way to reach the primary underneath it — `ToolbarItemGroup(placement: .keyboard)` with a Done item is the documented remedy and lands on every numeric field. Sign in with Apple handled only `.success`, so every failure was silent — and `.canceled` also means NO CREDENTIAL AVAILABLE, which strands that user permanently on the signup screen (R3, implemented). `PostCard`'s `.accessibilityElement(children: .combine)` made reacting impossible under VoiceOver, which is a release-blocking 6.5 gate, not polish (R6, implemented).
A19.3 THE CELEBRATION'S SHARE CONTROL BECOMES TWO BUTTONS (R4) — OWNER-RULED. The toggle is INERT: the post is queued with `shareToCrew: true` hardcoded before the celebration ever renders, so flipping it off still shares the workout, and the button beneath it reads "Share to crew" for a post that is already queued — a control that does nothing beside a label that misstates what it does (6.6: a CTA names what it does). Of the two honest shapes the audit tabled, the owner ruled SHAPE (b): the toggle is REMOVED and the celebration carries a primary "Share to crew" and a text "Keep it private", each writing the post's actual visibility. This removes a control rather than adding behaviour, and it keeps post visibility out of the completion inputs — so, unlike shape (a), it needs NO new append-only vector and no change to the gamification engine. S10's "share-default remembered" is satisfied by which button is offered first. Sequenced as Stage C, AFTER A15, per the ordering below.
A19.4 THE JOURNAL BECOMES A SEGMENT INSIDE PROGRESS (OWNER-RULED). S16 is a first-class screen reached through a small top-right toolbar button on another screen. The owner ruled: Progress carries a two-way segment (Charts / Journal) at the top, so both halves of Flow 9 are one tap from the tab and neither hides in chrome. The five-tab bar is UNCHANGED — a sixth tab was considered and rejected: Part VII's tab set is ratified at five and six segments do not fit a 375 pt bar at accessibility sizes.
A19.5 THE ERGONOMIC INVERSIONS (R9, R10, R5, R7). The onboarding question screens put their ONLY action at the top of the screen with the dead space beneath it — the exact defect A17.2 fixed on Home and never applied anywhere else, and the highest ergonomic return in the audit for a two-line change. The hero and question screens gain a `ScrollView` overflow valve, which 6.7 makes non-negotiable at accessibility-XXL. "Discard workout" moves out of the session's scroll tail, where it sits immediately above the Complete primary — 6.3 forbids a destructive control adjacent to a primary, and that adjacency occurs at the exact moment the user reaches for Complete. Eight sub-44 pt controls route through the renamed `TextActionButton` (R7, partly implemented).
A19.6 ORDERING (OWNER-RULED). Part XI's next unchecked task is Stage 7 (A15, "change today's workout"), and A17.3's forward note says "A15 does not ship until Home is settled". A18 settled Home's CONTENT; A19.1 settles its ANCHORING, and every element A18 added is what brings the collapse closer. The owner ruled the order: **A18 tail (complete) -> A19 Stage A (the bottom-bar mechanism) -> A19 Stages B and D -> A15 -> A19 Stages C, E and F.** A15's sheet is not built onto an anchoring mechanism that is known not to hold.
A19 ADDS NO VECTOR. Every clause is positional, mechanical or a correctness fix to an unreachable state; none changes a rule the streak/XP/shield engine runs. A19.3's ruled shape (b) is specifically the one that keeps post visibility OUT of the completion inputs, which is why it needs none — shape (a) would have needed one, and was not taken. V57-V64 stay reserved for A16 (nutrition); the next free id is still V57.
EVERY NEW CONTROL A19 CREATES DRAWS ITS BOUNDARY WITH `controlOutline` (A18.11), never `hairline` and never `secondaryButtonOutline`: `hairline` keeps #E9E4DD for card edges and dividers only, because a boundary between two SURFACES is not a UI component. `web/tests/contrast.test.ts` enforces this by source guard, so a new control that reaches for the old token fails the suite rather than shipping invisible.
UNTOUCHED BY A19: the gamification numbers and every streak/XP/shield rule, every rejected list (Flows 4, Part II, Part IV), Ember laws 1 2 3 4 5 6, the performance and accessibility budgets, minimumAgeYears 13, the five-tab set, the Concrete Doctrine C1-C14, every append-only vector, and every ratified A17 and A18 decision — including A18.10's ruling on Home's toolbar camera, which the audit listed as an open owner question and which is CLOSED.

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

