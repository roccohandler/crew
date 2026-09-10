// SPEC: Flow 2 (today's card: "PUSH DAY · 5 exercises + mobility") · Flow 5 (rest day copy) · Flow 7 (paused 🧊) · 1D (the
// bridge CTA replaces the layout) · A3 (owner-directed 2026-09-08: every non-bridge state carries a what's-next line, a way
// to post a meal, Log cardio, and — rest / all-done — Bonus workout; the bridge on a rest-day install gets ONE ink line under
// its CTA) · A8 (never a zero as a verdict, verb-first CTAs) · Part III law ① (one primary, every control ink; HIG: one
// prominent action per view). Branches only on view state (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T024

import SwiftUI

struct TodayCard: View {
    let state: TodayState
    let nextUpLine: String?
    let onStart: () -> Void
    let onPost: () -> Void
    let onLogCardio: () -> Void
    let onBonus: () -> Void

    var body: some View {
        switch state {
        case .bridge(let kind):
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Your first flame lights today.").font(.headline).foregroundStyle(EmberColors.secondaryText)
                PrimaryButton(title: kind == .workout ? "Start your first workout" : "Start your streak — post a meal", action: kind == .workout ? onStart : onPost)
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
                    PrimaryButton(title: "Start workout", action: onStart)
                }
            }
        case .rest(let posted):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Rest day — recovery is part of the plan.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text(posted ? "Today counts." : "One post keeps it lit.").font(.body).foregroundStyle(EmberColors.secondaryText)
                    if posted {
                        nextUp
                        SecondaryButton(title: "Post another", action: onPost)
                    } else {
                        PrimaryButton(title: "Post a meal", action: onPost)
                    }
                    extras
                    if !posted { nextUp }
                }
            }
        case .paused(let until):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Plan paused").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text("Your streak is frozen until \(until). Reminders are off.").font(.body).foregroundStyle(EmberColors.secondaryText)
                }
            }
        case .allDone:
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Done for today.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    nextUp
                    SecondaryButton(title: "Post a meal", action: onPost)
                    extras
                }
            }
        }
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

    // A3: Log cardio · Bonus workout side by side — ink outlines, never a second primary
    private var extras: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            SecondaryButton(title: "Log cardio", action: onLogCardio)
            SecondaryButton(title: "Bonus workout", action: onBonus)
        }
    }
}
