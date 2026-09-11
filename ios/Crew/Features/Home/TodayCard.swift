// SPEC: Flow 2 (today's card: "PUSH DAY · 5 exercises + mobility") · Flow 5 (rest day copy) · Flow 7 (paused 🧊) · 1D (the
// bridge CTA replaces the layout) · A3 (owner-directed 2026-09-08: every non-bridge state carries a what's-next line and a
// way to post a meal, log cardio and — rest / all-done — start a bonus workout) · A8 (never a zero as a verdict, verb-first
// CTAs) · Part III law ① (one primary, every control ink). Branches only on view state (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T024
//
// A17.3 (2026-09-10) — the "Log cardio" / "Bonus workout" pair is GONE from this card. A3 requires *a way* to reach each,
// not a dedicated button each, and the log rows below are that way at a position that no longer moves between states.
//
// A18 (2026-09-10), four changes, each answering something the owner asked about the shipped screen:
//
//   A18.4 THE REST CARD STATES ITS PREMISE. "Post anything today and your 1-day streak holds" states the reward and
//     never the rule, so the headline ("recovery is part of the plan") and the loudest control on the screen read as a
//     contradiction — which is exactly what the owner reported. Crew's streak is DAILY and has no training-day
//     exemption: streak.vectors.json V04 is titled "rest day, silence → streak 0 at 3 AM". The line says so now.
//     A17.1's hard limit bans the CONSEQUENCE (no countdown, no risk notification, no time-pressure line); a premise
//     is none of the three. NOTE FOR A FUTURE SESSION: this line exists ONLY because the streak is daily (A18.13).
//   A18.9 THE ALL-DONE CARD REPORTS THE DAY. It was the one state with no control and nothing to report, so the day
//     you did everything right looked least finished. It now prints today's work in the journal's own sentence and
//     carries no button — the day is closed. Its outline "Post a meal" is gone; the meal row and the camera remain.
//   A18.6c THE PAUSED CARD OFFERS THE WAY OUT. Flow 7 gave it zero controls, which left a paused user reading a return
//     date with no route off it that any word on the screen named. "End the pause now" is the string Settings already
//     uses for the same action (6.6: one action, one wording).
//   A18.8 THE BRIDGE ABSORBS AN OPEN SESSION. The bridge lasts until the first POST and starting a workout is not a
//     post, so an abandoned first workout used to put a Resume banner NEXT TO the bridge's CTA — two prompts on the
//     one screen §1D says carries none. The bridge's single button resumes instead.
//
// A CORRECTION, because the previous version of this comment will otherwise be quoted against the next decision: it
// claimed rest and all-done "still carry none [no ink-filled primary], deliberately" — twelve lines above a `case
// .rest` that renders `PrimaryButton`. The true rule, which the web twin stated correctly, is: the rest day carries a
// filled primary UNTIL it is posted, and after that nothing on the day is required so nothing is filled.

import SwiftUI

struct TodayCard: View {
    let state: TodayState
    let streak: Int          // A17.1: so the rest-day line can name what "it" is in "One post keeps it lit"
    let nextUpLine: String?  // A3 / §1D: the BRIDGE's one line. Every other state gets the NextUpBlock above the card (A18.3).
    let todaySummaryLines: [String] // A18.9: what today held, from the journal's own twin
    let resuming: Bool       // A18.8: a session is open, so the bridge's single CTA resumes it
    let onStart: () -> Void
    let onPost: () -> Void
    let onEndPause: () -> Void

    var body: some View {
        switch state {
        case .bridge(let kind):
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Your first flame lights today.").font(.headline).foregroundStyle(EmberColors.secondaryText)
                // A18.8 — one CTA, and it takes the open session with it rather than a second banner appearing above.
                PrimaryButton(title: bridgeTitle(kind), action: kind == .workout || resuming ? onStart : onPost)
                nextUp // A3: the one line a rest-day install gets; nothing else competes (1D)
            }
        case .workout(let name, let exerciseCount, let hasCardio, let lines, let tail):
            Card {
                // A14 — three groups, not five evenly spaced elements: identity, the work, the action. sectionGap separates
                // the groups and rowGap the rows inside one, which is the whole reason two role tokens exist (G5 scale).
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                        // A14 — the identity line now OUTRANKS the count line. It was .caption secondary while "5 exercises
                        // + mobility" was .title3 ink: the size of the workout was typographically louder than which
                        // workout it was. Typography carries the hierarchy; no colour is added to say it (law ⑥).
                        Text(name.uppercased()).font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                        Text(NextUp.sizeLine(exerciseCount: exerciseCount, hasCardio: hasCardio)).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    }
                    workRows(lines, tail: tail)
                    PrimaryButton(title: resuming ? "Resume workout" : "Start workout", action: onStart)
                }
            }
        case .rest(let posted):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Rest day — recovery is part of the plan.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text(stakeLine(posted: posted)).font(.body).foregroundStyle(EmberColors.secondaryText)
                    // A18.3 — the what's-next line is no longer here on either branch, so it can no longer sit ABOVE the
                    // control when posted and BELOW it when not (the moving-element defect A14 was written to remove).
                    if posted {
                        SecondaryButton(title: "Post another", action: onPost)
                    } else {
                        PrimaryButton(title: "Post a meal", action: onPost)
                    }
                }
            }
        case .paused(let until):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Plan paused").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text("Your streak is frozen until \(until). Reminders are off.").font(.body).foregroundStyle(EmberColors.secondaryText)
                    SecondaryButton(title: "End the pause now", action: onEndPause) // A18.6c
                }
            }
        case .allDone:
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Done for today.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    // A18.9 — the day, reported. `todaySummaryLines` is the journal's own sentence (JournalFacts
                    // .summaryLine), so this adds no copy and cannot drift from what Progress and the journal print.
                    ForEach(Array(todaySummaryLines.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.body).foregroundStyle(EmberColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // A18.8 — the bridge's single label. A rest-day install with no session still offers the meal; a workout-day
    // install, or ANY install with a session already open, resumes.
    private func bridgeTitle(_ kind: BridgeKind) -> String {
        if resuming { return "Resume your first workout" }
        return kind == .workout ? "Start your first workout" : "Start your streak — post a meal"
    }

    // SPEC: A17.1 · A18.4 · A8 · spec:452 — what today is worth AND why a rest day is a day that asks for anything.
    // No countdown, no notification, no time pressure: it states a fact about today and stops there. At streak 0 it
    // never says "0-day streak" — the first flame is the thing on offer instead.
    private func stakeLine(posted: Bool) -> String {
        if posted { return "Today counts." }
        return streak > 0
            ? "Rest days count too — post anything and your \(streak)-day streak holds."
            : "Rest days count too — one post lights your first flame."
    }

    @ViewBuilder
    private var nextUp: some View {
        if let nextUpLine { NextUpLine(line: nextUpLine) }
    }

    // SPEC: A14 — the day's ACTUAL work: "Bench Press  3×8". The owner's report was that it is not visually clear what the
    // work should be; the rows were always available (the plan editor two taps away lists them) and Home showed a count
    // instead. Read-only lines, not controls — the card still has exactly one action (6.1 · §1B · S07).
    @ViewBuilder
    private func workRows(_ lines: [HomeLine], tail: String?) -> some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                    Text(line.name).font(.subheadline).foregroundStyle(EmberColors.inkText)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true) // 6.7: a long name wraps, it never pushes the target past the edge
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    Text(line.detail).font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                }
            }
            if let tail { Text(tail).font(.caption).foregroundStyle(EmberColors.secondaryText) }
        }
        // E20 — VoiceOver reads the workout as one passage; seven separate stops on a read-only list is noise, and the
        // Start button below is the only thing here anyone can act on
        .accessibilityElement(children: .combine)
    }
}
