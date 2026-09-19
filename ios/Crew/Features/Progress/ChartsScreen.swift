// SPEC: S15 / Flow 9 layers 2–3 as amended by A28 (c), (d), (f) and GAP 1 read by R-086 — the rest of the Charts job ("whether I'm
// getting stronger"), one tap below Progress's top (6.9 / DESIGN.md 3.2–3.3: a second scroll-length becomes a destination). The
// totals, how much work (sets per week, the Push / Pull / Legs balance, the cardio a user ENTERED this week — GAP 4, R-084 (2); the
// mobility minutes are gone with the hold timer, A28 (c)), and am I stronger (only where weights were logged). The weekly-ring
// history left: the heat map's rows are the weeks now (system §11: one fact, one rendering). Ink only (A28 (b): no accent on
// Progress). WRITTEN — UNVERIFIED (needs Mac). T040 · R3

import SwiftUI

struct ChartsScreen: View {
    let model: ProgressModel
    let units: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                FocusCard {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                        heading("Did I show up?")
                        fact("Streak \(model.totals.currentStreak) · longest \(model.totals.longestStreak)")
                        fact("\(model.totals.workouts) \(model.totals.workouts == 1 ? "workout" : "workouts") · \(model.totals.posts) \(model.totals.posts == 1 ? "post" : "posts")")
                    }
                }
                FocusCard {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                        heading("How much work?")
                        fact("Sets per week: \(model.weeks.map { String($0.sets) }.joined(separator: " · "))")
                        fact(balanceLine)
                        if let cardioLine { fact(cardioLine) }
                    }
                }
                if !model.strength.isEmpty {
                    heading("Am I stronger?").padding(.top, EmberTokens.Spacing.space8)
                    ForEach(model.strength) { ExerciseChartView(trend: $0, units: units) }
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func heading(_ text: String) -> some View {
        Text(text).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
    }

    private func fact(_ text: String) -> some View {
        Text(numerals: text).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // SPEC: Flow 9 layer 2 — "Push N · Pull N · Legs N" (+ " · Full body N" when legacy full-body sessions exist)
    private var balanceLine: String {
        let base = "Push \(model.balance.push) · Pull \(model.balance.pull) · Legs \(model.balance.legs)"
        return model.balance.fullBody > 0 ? "\(base) · Full body \(model.balance.fullBody)" : base
    }

    // SPEC: A2 · GAP 4 as R-084 (2) — "Cardio N min this week": the minutes the user entered, a fact, never a target; nothing at zero (A8)
    private var cardioLine: String? {
        guard let week = model.weeks.last, week.cardioMinutes > 0 else { return nil }
        return "Cardio \(week.cardioMinutes) min this week"
    }
}
