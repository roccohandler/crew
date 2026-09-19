// SPEC: A28 (d), (e) — the ONE card of the Focus Card Home (design/targets 01–06): a weekday eyebrow, the title that names the
// state, one sub-line, a hairline, the day's rows or tomorrow, and at most ONE filled primary (none on rest and done — unless a
// session is open, when "Resume workout" is the card's one primary, R-083 (23)). The card's title names the state now that Home
// draws no nav title (supersedes A17.4 (c)); tomorrow sits inside the card (supersedes A18.3's block above it).
//
// Carried: A14 — the day's ACTUAL work, read-only rows, one action; A18.8 — the bridge's one CTA takes an open session with it;
// A18.9 — the all-done card reports the day in the journal's own sentence; A22 / R-070 — a rest-day bridge's one control is the
// bonus workout. Copy (A28 (e)): "Your season starts today" (mockup 01; where else it lives is GAP 5), "Rest is part of the season.
// Nothing to do today.", "Off-season until <date>. Reminders are off." and "End the pause" (mockup 06; the one label for the action,
// 6.6). Branches only on view state (5.6.6). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct TodayCard: View {
    let state: TodayState
    let weekday: String              // "Friday" — the eyebrow renders it uppercase
    let work: HomeCardWork?          // the day's rows: a workout day and the workout-day bridge
    let nextUp: NextUpFacts?         // tomorrow: rest, all-done and the rest-day bridge
    let todaySummaryLines: [String]  // A18.9
    let pausedUntil: String?         // "Friday 25 September"
    let resuming: Bool               // a session is open
    let onStart: () -> Void
    let onBonus: () -> Void
    let onEndPause: () -> Void

    var body: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                header
                if hasBody {
                    Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline)
                    if let work, showsWork { workRows(work) }
                    if let nextUp, showsNextUp { tomorrow(nextUp) }
                }
                if let primary { PrimaryButton(title: primary.title, height: EmberTokens.Focus.primaryHeightHome, action: primary.action).padding(.top, EmberTokens.Spacing.space8) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text(weekday).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
            Text(title).typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink)
                .fixedSize(horizontal: false, vertical: true) // 6.7: a long workout name wraps
            ForEach(Array(sublines.enumerated()), id: \.offset) { _, line in
                Text(line).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch state {
        case .bridge(.workout), .workout: return work?.name ?? "Today"
        case .bridge(.rest), .rest: return "Rest day"
        case .paused: return "Plan paused"
        case .allDone: return "Done for today"
        }
    }

    private var sublines: [String] {
        switch state {
        case .bridge: return ["Your season starts today"] // GAP: A28 GAP 5, R-084 (3) — first-day Home's card only; the reveal is untouched
        case .workout: return work.map { [$0.size] } ?? []
        case .rest: return ["Rest is part of the season. Nothing to do today."]
        case .paused: return ["Off-season until \(pausedUntil ?? ""). Reminders are off."]
        case .allDone: return todaySummaryLines
        }
    }

    private var showsWork: Bool { if case .bridge(.rest) = state { return false }; if case .rest = state { return false }; return state != .allDone }
    private var showsNextUp: Bool { !showsWork || work == nil }
    private var hasBody: Bool { if case .paused = state { return false }; return (showsWork && work != nil) || (showsNextUp && nextUp != nil) }

    // ONE filled primary where the state has one (A28 (f); 3.1)
    private var primary: (title: String, action: () -> Void)? {
        switch state {
        case .bridge(let kind):
            if resuming { return ("Resume your first workout", onStart) }
            return kind == .workout ? ("Start your first workout", onStart) : ("Start a bonus workout", onBonus)
        case .workout: return (resuming ? "Resume workout" : "Start workout", onStart)
        case .paused: return ("End the pause", onEndPause)
        case .rest, .allDone: return resuming ? ("Resume workout", onStart) : nil
        }
    }

    // SPEC: A14 · A28 (c) — the rows, then the mobility block as a COUNT of holds and the cardio block's entered target
    // GAP: A28 GAP 4, R-084 (2) — a cardio block's minutes are a target the user entered, not time spent training, so they stay
    private func workRows(_ work: HomeCardWork) -> some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
            ForEach(Array(work.lines.enumerated()), id: \.offset) { _, line in row(line.name, line.detail) }
            if work.holds > 0 { row("Mobility", "\(work.holds) \(work.holds == 1 ? "hold" : "holds")") }
            if let minutes = work.cardioMinutes { row("Cardio", "\(minutes) min") }
        }
        .accessibilityElement(children: .combine) // E20: the workout is one passage; the primary below is the one action
    }

    private func row(_ name: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
            Text(name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                .fixedSize(horizontal: false, vertical: true) // 6.7: a long name wraps, it never pushes the target past the edge
            Spacer(minLength: EmberTokens.Spacing.space8)
            Text(detail).typeRole(EmberTokens.Typography.bodySemibold, numeral: true).foregroundStyle(EmberColors.inkSecondary)
        }
    }

    // SPEC: A28 (d) — tomorrow inside the card: the eyebrow, the workout, its size (mockups 04, 05)
    private func tomorrow(_ facts: NextUpFacts) -> some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text(facts.when ?? facts.heading).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                Text(facts.name ?? facts.detail).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: EmberTokens.Spacing.space8)
                if let size = facts.size { Text(size).typeRole(EmberTokens.Typography.secondary, numeral: true).foregroundStyle(EmberColors.inkSecondary) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(facts.heading), \(facts.detail)")
    }
}

// SPEC: A28 (d) — no plan (mockup 02): the card is the hero at 44 pt, no reward block. The copy says TWO questions — the mockup's
// "Three" is its seeded text, and A21.1 asks two (DESIGN.md: where a mockup's copy contradicts the spec, the spec wins).
struct NoPlanCard: View {
    let weekday: String
    let onBuild: () -> Void

    var body: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                    Text(weekday).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
                    Text("Build your week").typeRole(EmberTokens.Typography.screenTitleBare).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Two questions and your plan is ready.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                PrimaryButton(title: "Build my week", height: EmberTokens.Focus.primaryHeightHome, action: onBuild).padding(.top, EmberTokens.Spacing.space8)
            }
        }
    }
}
