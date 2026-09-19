# Education layer — the RATIFIED copy (A23)

Status: **RATIFIED 2026-09-19 by the owner, with eight amendments** (Appendix A, the line under A23; `docs/ratification.md` R-081).
The amended lines are applied below. **`shared/copy/education.json` is the source of truth** — every whisper and every string of the
How Crew works page is read from it by both apps; this document is the record of how the copy was decided, and where the two ever
differ, the file wins. Written 2026-09-18 from the owner's ruling of the same night as the draft for W6's second session (the page
and the nine non-nutrition whispers) and W8's (the two nutrition whispers and the shake line) — `docs/mvp-definition.md`. The layer EXTENDS the whisper pattern the app already has ("Tap any exercise to swap it.", 1C) and never
becomes a tour, a carousel or a modal (1A: teach by doing, not touring). Docs only: no source, vector, constant or seed changed.

## A. Whisper rules — the contract

1. A whisper renders ONCE, the first time its moment arrives, and never returns.
2. It sits in secondaryText ink directly under the element it explains; no border, no card, no icon.
3. Never in a modal or a sheet, and never on the bridge state (1D: zero competing prompts on the one screen that must have none).
4. It disappears on the first tap anywhere on that screen. When two whispers share a screen (only the plan reveal — B1 and the
   existing swap whisper), each sits under its own element and the first tap clears both.
5. ≤ 12 words. Sentence case, contractions, no "please", no "!" (6.6). Never a zero as a verdict (A8), never guilt.
6. VoiceOver reads it once: the whisper is a static-text element announced on appearance and then removed from the tree with the
   first tap, exactly as it leaves the screen.
7. Seen-state persists SERVER-SIDE so iOS and web agree — PROPOSED, not built:
   - Part IX `User` gains `whispersSeen: [string]` — the ids below; append-only per user.
   - `PATCH users/me { whispersSeen: [id, …] }` UNIONS into the stored list (never removes); `GET users/me` returns it.
   - iOS: `WhisperState` (one @Observable holder, 5.6.2) keeps `seen: Set<String>` = the server's list ∪ a per-user local set in
     UserDefaults; `shouldShow(id)` is `!seen.contains(id)`; `markSeen(id)` writes the local set at once and PATCHes when online — a
     whisper seen offline is re-sent at the next foreground by PATCHing the whole local set (idempotent). No new sync op.
   - Web: the same field from the session's user, unioned with localStorage; the dismiss PATCHes.
   - Because the union never shrinks, a second device inherits what the first one saw, and an offline dismissal never shows twice.
   - The existing 1C swap whisper (`OnboardingModel.swapWhisperShown`, in-memory today) joins the system as `how.revealSwap`.

Whisper ids: `why.ppl` · `why.streak` · `why.crews` · `why.protein` · `why.freeDinner` · `how.overload` · `how.swapSkip` ·
`how.quickComplete` · `how.pause` · `how.shake` · `how.invite` · `how.revealSwap` (existing).

## B. The eleven whispers — line · trigger · screen (word counts in brackets; the cap is 12)

| # | id | Line (ratified) | Trigger — the FIRST time this is true | Screen · placement | Gate |
|---|---|---|---|---|---|
| WHY 1 | `why.ppl` | Push, pull, legs: three days, every muscle covered, no decisions. [10] | the plan reveal renders (signup or rebuild) | S04 reveal · under "Your week, built." | — |
| WHY 2 | `why.streak` | The flame counts days you showed up, not effort. [9] | Home renders a lit flame (streak ≥ 1) — never on the bridge | S07 Home · under the flame in the header | — |
| WHY 3 | `why.crews` | Your crew sees you show up. That's the whole system. [10] *(amendment 1)* | the Crew tab renders a crew (member strip present) | S12 Crew · under the member strip | — |
| WHY 4 | `why.protein` | Protein's planned first: the hardest number on a busy day. [10] | the first nutrition targets derive (W8) | Nutrition targets · under the protein row | 18+ (A16.c) |
| WHY 5 | `why.freeDinner` | Same breakfast and lunch every day. Dinner's yours. [8] *(amendment 2)* | the daily template renders for the first time (W8) | Saved meals & template · under the template list | 18+ (A16.c) |
| HOW 1 | `how.overload` | Add a rep before you add weight. [7] | a session row shows last time's numbers (A12 prefill) — the second-ever performance of any exercise | S09 Session · under that row's last-time line | — |
| HOW 2 | `how.swapSkip` | Machine's taken? Swap. Wrecked? Skip. Both are fine. [8] | the first session opens (the first exercise card is on screen) | S09 Session · under the first exercise's Swap · Skip controls | — |
| HOW 3 | `how.quickComplete` | Trained phone-free? Quick complete logs today at your targets. [9] | Home offers Quick complete for the first time | S07 Home · under the Quick complete button | — |
| HOW 4 | `how.pause` | Away a while? Pause the plan. The streak stays whole. [10] | Settings' Plan group is on screen for the first time | S17 Settings · under "Pause my plan" | — |
| HOW 5 | `how.shake` | Morning scoop? It's a template slot. One tap logs it. [10] | the template renders with its first slot (W8) | Nutrition Today · under the first template slot | 18+ (A16.c) |
| HOW 6 | `how.invite` | Send the link or the code straight into your group text. [11] | the Invite screen opens for the first time | S13 Invite · under "Send invite link" | — |

**The merge question (HOW 2 vs. the existing reveal whisper) — ratified as written (amendment 8).** They do NOT merge. The reveal's "Tap any exercise to swap it." teaches
the reveal's own affordance while the plan is still a draft — swapping there costs nothing, and 1C names that moment. HOW 2 teaches
the two in-session exceptions on the day they happen, where Swap and Skip are on screen for the first time; folding it into the
reveal would put a lesson about a live workout on a screen with no workout. Both stay; rule A4 covers their one shared screen (the
reveal carries WHY 1 and the swap whisper, each under its own element). This is also how the owner's count works: the NINE
non-nutrition whispers are the eight new ones above plus the existing reveal swap whisper.

## C. The "How Crew works" page — S19 (new screen, both platforms), reached from a Settings row

Placement (ratified as written, amendment 8): S17 Settings → About → "How Crew works" (a row above Version). One scrolling page; nothing interactive but links (every
source opens in the in-app browser the legal pages use). Same page on web at /how-crew-works, linked from Settings (parity noted, not
built). The page renders for every age; §D says what changes under 18.

### 1. A note from Max — the owner's, ratified (amendment 6; `draft: false`)

I work a full-time job and I still want to train well. This is how I actually train: three days, push, pull, legs, the same
breakfast and lunch, a dinner I look forward to. Crew is the plan I follow — everything in here is what I do myself. If it gets you
through one full week, that's the whole point.

### 2. Sections, in this order, leading with the owner's top-ranked reason

**Push, pull, legs.** It's simple: three days, one job each, no decisions at the rack. It's balanced — every major muscle gets its
day — and efficient — three sessions a week fits around a job. *(amendment 4)* Recovery is built in: one group rests while the
next day works another. A plan you'll follow beats a perfect one you won't; when you're ready, add a fourth day and every muscle
gets hit more often. Source: Schoenfeld, Ogborn & Krieger, "Effects of Resistance Training Frequency on Measures of Muscle
Hypertrophy", Sports Medicine 2016 — https://doi.org/10.1007/s40279-016-0543-8

**Protein first.** Protein is planned first because it's the hardest number to hit on a busy day. It keeps you full, and muscle needs
it to repair and grow. If you track one number, track this one. A working range is 0.7–1 g per pound of bodyweight; 1 g per pound is
the easy target to remember. Source: Morton et al., "A systematic review, meta-analysis and meta-regression of the effect of protein
supplementation on resistance training-induced gains in muscle mass and strength in healthy adults", British Journal of Sports
Medicine 2018 — https://doi.org/10.1136/bjsports-2017-097608 *(the addendum's proposed 1.8 g/kg sits inside this range at ≈0.82 g/lb)*

**Same foods, free dinner.** Eating the same breakfast and lunch removes decisions from the busiest part of the day. Dinner is the
reward: it changes, you enjoy it, and you still know your numbers. Tracking stays honest because most of the day is already logged.
Prep is cheaper, too — the same groceries, fewer of them wasted.

**The streak.** Showing up is the whole game. The flame counts days, not effort — a light day and a big day light it the same.
Rest days are free: the flame counts your training days, and a rest day never breaks it. *(amendment 3 — A22 G1 (a))*

**Crews.** Being seen is the whole system. Your crew sees you show up and reacts; that's it — no feed, no chat, no scores. Two to
ten people, one link or code. *(amendment 5; the first sentence is the builder's wording, R-081 (2))*

**Mobility.** Five to ten minutes of holds at the end of a workout keeps you moving without a separate session. They're part of the
plan, so they get done.

**Rest days.** Growth happens between workouts. Rest is part of the plan, not a gap in it.

### 3. What the whispers said — verbatim, in trigger order (regenerated from the amended lines, amendment 7)

Both apps build this list from `education.json`'s whisper list, so the page follows the file; this copy is for reading.

1. Push, pull, legs: three days, every muscle covered, no decisions. *(the plan reveal)*
2. Tap any exercise to swap it. *(the plan reveal — the existing 1C whisper)*
3. Machine's taken? Swap. Wrecked? Skip. Both are fine. *(the first workout)*
4. The flame counts days you showed up, not effort. *(the first lit flame)*
5. Send the link or the code straight into your group text. *(the first Invite screen)*
6. Your crew sees you show up. That's the whole system. *(the first crew on the Crew tab)*
7. Trained phone-free? Quick complete logs today at your targets. *(the first Quick complete offer)*
8. Away a while? Pause the plan. The streak stays whole. *(the first Settings Plan group)*
9. Add a rep before you add weight. *(the first row that remembers last time)*
10. Protein's planned first: the hardest number on a busy day. *(the first nutrition targets — 18+)*
11. Same breakfast and lunch every day. Dinner's yours. *(the first daily template — 18+)*
12. Morning scoop? It's a template slot. One tap logs it. *(the first template slot — 18+)*

### 4. The A16.a line, reused

These are estimates and rules of thumb, not medical advice. Talk to a clinician before acting on them. Every source above is a link.

## D. Copy checks the draft passes (and how the page handles under-18 users)

| Check | Result |
|---|---|
| Ember law ③ — orange is a shape colour, never a text colour | every whisper is secondaryText ink; the page is ink and secondary ink; no orange text anywhere |
| 6.6 — sentence case · contractions · no "please" / "successfully" / "!" | all twelve whisper lines and every section sentence pass, the eight amendments included (`check-copy`, 2026-09-19) |
| A8 — never a zero as a verdict; never red for a miss | no whisper or section names a zero or a miss; the streak lines describe what counts, not what didn't |
| No guilt framing | no "should", no "missed", no "only"; rest days are "part of the plan" and "never break" the flame; the streak "counts days, not effort" |
| ≤ 12 words per whisper | longest is still HOW 6 at 11; the two amended lines are 10 (WHY 3) and 8 (WHY 5) |
| Under-18 (A16.c) — never the two nutrition whispers | `why.protein`, `why.freeDinner` and `how.shake` live behind the 18+ gate: their surfaces do not exist under 18, so they cannot fire |
| Under-18 — never the protein / template numbers | the page renders for every age; under 18, or with no birth year on file (an Apple account that has not opened Nutrition), the Protein section drops its numeric sentence and its source link, and §3 omits lines 10–12. No copy explains the omission (A16.c: no upsell, no "unlock at 18"). The Same-foods section carries no numbers at any age |
| Web parity (Part IV) | noted, not built: /how-crew-works and the whispers on the matching web screens, reading the same ids and the same server field |

## Ratified 2026-09-19 — the eight amendments, and nothing left open

1. `why.crews` → "Your crew sees you show up. That's the whole system."
2. `why.freeDinner` → "Same breakfast and lunch every day. Dinner's yours."
3. The streak section gains one sentence after its two: "Rest days are free: the flame counts your training days, and a rest day
   never breaks it." This reconciles the page with A22 G1 (a) and closes the draft's open question on rest days.
4. The PPL section's efficiency clause → "and efficient — three sessions a week fits around a job." The recovery sentence after it is
   unchanged.
5. The crews section: "Two to ten friends" → "Two to ten people"; its first sentence is reworded off the old algorithm line to match
   the new whisper — "Being seen is the whole system." (the builder's wording, R-081 (2)).
6. The note from Max: "nothing in here I don't do myself" → "everything in here is what I do myself". The rest verbatim; `draft: false`.
7. §3 "What the whispers said" regenerated from the amended lines, still in trigger order.
8. Ratified as written: WHY 1's wording ("every muscle covered"), the no-merge decision on the swap whisper (§B), and the Settings →
   About placement (§C).

Previously open and now closed: the note (amendment 6) · WHY 1, the merge, the placement (amendment 8) · rest days in the streak
lines (amendment 3).
