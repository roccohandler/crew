// SPEC: S16 History/Journal — every post forever; editing a past session never alters XP (copy says so); deleted posts absent,
// logs present. E3 (delete yours anytime; captions editable, photos not). A6 (owner-directed 2026-09-08): grouped by day with
// readable labels, one summary line per post, an empty state whose CTA posts, a Sending ↻ chip while undelivered.
// WRITTEN — UNVERIFIED (needs Mac). T040

import SwiftUI

struct JournalDay: Identifiable {
    let dayKey: String
    let posts: [LocalPost]
    var id: String { dayKey }
}

struct JournalScreen: View {
    let posts: [LocalPost]
    let trainingWeekdays: [Int]
    let distanceUnit: String // A9: journal lines carry distances, never weights
    let onDelete: (LocalPost) -> Void
    let onPosted: () -> Void
    @State private var posting = false
    private let todayKey = DayKey.dayKey(for: Date(), tz: .current)

    // SPEC: A6 — sections per dayKey (the 3 AM day, E8), newest day first; rows inside a day in the order they happened
    private var days: [JournalDay] {
        let grouped = Dictionary(grouping: posts, by: \.dayKey)
        return grouped.keys.sorted(by: >).map { JournalDay(dayKey: $0, posts: grouped[$0, default: []].sorted { $0.createdAt < $1.createdAt }) }
    }

    // SPEC: A6 — "Rest day" when the day was not a training day (A1) and holds no workout; a plan without days labels nothing
    private func isRestDay(_ day: JournalDay) -> Bool {
        !trainingWeekdays.isEmpty && !trainingWeekdays.contains(DayKey.isoWeekday(day.dayKey)) && !day.posts.contains { $0.type == "workout" }
    }

    var body: some View {
        Group {
            if posts.isEmpty {
                // SPEC: A6 · 6.1 Empty — an invitation with exactly one CTA, and the CTA posts
                EmptyState(title: "Your first post lands here.", line: "Workouts and meals stack up day by day.", ctaTitle: "Post something") { posting = true }
            } else {
                list
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Journal")
        .sheet(isPresented: $posting) { NutritionPostScreen { posting = false; onPosted() } }
    }

    private var list: some View {
        List {
            Section {
                Text("Your journal keeps everything. Editing a past workout changes your stats, never your XP or streak.").font(.footnote).foregroundStyle(EmberColors.secondaryText).listRowBackground(EmberColors.canvas)
            }
            ForEach(days) { day in
                JournalDaySection(dayKey: day.dayKey, todayKey: todayKey, posts: day.posts, isRestDay: isRestDay(day), distanceUnit: distanceUnit, onDelete: onDelete)
            }
        }
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas)
    }
}
