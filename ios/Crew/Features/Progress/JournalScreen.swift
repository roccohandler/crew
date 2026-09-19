// SPEC: S16 History/Journal — every post forever; editing a past session never alters XP (copy says so); deleted posts absent,
// logs present. E3 (delete yours anytime; captions editable, photos not). A6 (owner-directed 2026-09-08): grouped by day with
// readable labels, one summary line per post, a Sending ↻ chip while undelivered. A19.4 / W6 (2026-09-17): the journal is the
// second SEGMENT of Progress; A28 (f) · R-086 (2026-09-19): the segment is not on the component list, so the Journal is a row button
// on Progress, one tap from the tab, pushed with its own title. Its empty state's CTA goes to today (Home). The system's colours and
// type: each day's rows in one card on the gutter (not the platform's inset-grouped list, ui-reviewer run 35444308817), day labels
// as eyebrows, every numeral Rounded Bold. WRITTEN — UNVERIFIED (needs Mac). T040 · R3

import SwiftUI

struct JournalDay: Identifiable {
    let dayKey: String
    let posts: [LocalPost]
    var id: String { dayKey }
}

struct JournalScreen: View {
    let posts: [LocalPost]
    let trainingDays: [TrainingDaysEntry] // A27 (a): the plan's training-days history
    let distanceUnit: String // A9: journal lines carry distances, never weights
    let onDelete: (LocalPost) -> Void
    let onGoHome: () -> Void // W6: the empty state's one CTA
    private let todayKey = DayKey.dayKey(for: Date(), tz: .current)

    // SPEC: A6 — sections per dayKey (the 3 AM day, E8), newest day first; rows inside a day in the order they happened
    private var days: [JournalDay] {
        let grouped = Dictionary(grouping: posts, by: \.dayKey)
        return grouped.keys.sorted(by: >).map { JournalDay(dayKey: $0, posts: grouped[$0, default: []].sorted { $0.createdAt < $1.createdAt }) }
    }

    // SPEC: A6 — "Rest day" when the day was not a training day (A1) and holds no workout; a plan without days labels nothing.
    // A27 (a): "a training day" is asked of the training days in effect ON that day, never of today's
    private func isRestDay(_ day: JournalDay) -> Bool {
        let weekdays = TrainingDays.weekdaysOn(trainingDays, day.dayKey)
        return !weekdays.isEmpty && !weekdays.contains(DayKey.isoWeekday(day.dayKey)) && !day.posts.contains { $0.type == "workout" }
    }

    var body: some View {
        Group {
            if posts.isEmpty {
                // SPEC: A6 · 6.1 Empty — an invitation with exactly one CTA; W6: the CTA is today (Home), where a first workout starts
                EmptyState(title: "Your first post lands here.", line: "Every workout you post stacks up here, day by day.", ctaTitle: "Go to today", action: onGoHome)
            } else {
                list
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                Text("Your journal keeps everything. Editing a past workout changes your stats, never your XP or streak.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(days) { day in
                    JournalDaySection(dayKey: day.dayKey, todayKey: todayKey, posts: day.posts, isRestDay: isRestDay(day), distanceUnit: distanceUnit, onDelete: onDelete)
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
    }
}
