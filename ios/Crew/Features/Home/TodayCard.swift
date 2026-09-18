// SPEC: Flow 2 (today's card: "PUSH DAY · 5 exercises + mobility") · Flow 5 (rest day copy) · Flow 7 (paused 🧊) · 1D (the
// bridge CTA replaces the layout) · A3 (owner-directed 2026-09-08: every non-bridge state carries a what's-next line and a
// way to log cardio and — rest / all-done — start a bonus workout) · A8 (never a zero as a verdict, verb-first CTAs) · Part III
// law ① (one primary, every control ink). Branches only on view state (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T024
//
// A17.3 (2026-09-10) — the "Log cardio" / "Bonus workout" pair is GONE from this card. A3 requires *a way* to reach each,
// not a dedicated button each, and the log rows below are that way at a position that no longer moves between states.
//
// A18 (2026-09-10): A18.9 THE ALL-DONE CARD REPORTS THE DAY in the journal's own sentence and carries no button — the day is
// closed. A18.6c THE PAUSED CARD OFFERS THE WAY OUT ("End the pause now", the string Settings already uses, 6.6). A18.8 THE
// BRIDGE ABSORBS AN OPEN SESSION: its single button resumes instead of a second Resume banner appearing beside it (§1D).
//
// A22 G1 (a) (owner-approved 2026-09-18) — A REST DAY ASKS NOTHING. The rest card's premise line (A18.4: "Rest days count too —
// post anything…") is deleted with the daily requirement it explained; the card carries no control and no stake. The plate
// journal is gone, so the bridge's rest-day CTA ("Start your streak — post a meal") went with it — see R-070 below.

import SwiftUI

struct TodayCard: View {
    let state: TodayState
    let nextUpLine: String?  // A3 / §1D: the BRIDGE's one line. Every other state gets the NextUpBlock above the card (A18.3).
    let todaySummaryLines: [String] // A18.9: what today held, from the journal's own twin
    let resuming: Bool       // A18.8: a session is open, so the bridge's single CTA resumes it
    let onStart: () -> Void
    let onBonus: () -> Void  // A22 / R-070: the rest-day bridge's one control — the bonus workout A3 offers on every rest day
    let onEndPause: () -> Void

    var body: some View {
        switch state {
        case .bridge(let kind):
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text(bridgeLine(kind)).font(.headline).foregroundStyle(EmberColors.secondaryText)
                // A18.8 — one CTA, and it takes the open session with it rather than a second banner appearing above.
                PrimaryButton(title: bridgeTitle(kind), action: kind == .workout || resuming ? onStart : onBonus)
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
        case .rest:
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Rest day — recovery is part of the plan.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    // SPEC: Flow 5 · A22 G1 (a) — no control, no stake, no premise; the NextUpBlock above the card names the next workout
                    Text("Nothing to do here. A rest day asks nothing of your streak.").font(.body).foregroundStyle(EmberColors.secondaryText)
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

    // GAP: A22 G1 (a) — 1D's rest-day bridge lost its subject (the meal). The most conservative in-spec reading keeps §1D's ONE
    // control and gives it the bonus workout A3 already offers on every rest day; the copy stops promising a flame a rest day
    // cannot light (a bonus workout pays XP and leaves the streak, V70). R-070. A workout-day install, or ANY install with a
    // session already open, starts or resumes the first workout as before (A18.8).
    private func bridgeTitle(_ kind: BridgeKind) -> String {
        if resuming { return "Resume your first workout" }
        return kind == .workout ? "Start your first workout" : "Start a bonus workout"
    }

    private func bridgeLine(_ kind: BridgeKind) -> String {
        kind == .workout || resuming ? "Your first flame lights today." : "Your plan rests today. Your first flame lights on your first planned workout."
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
