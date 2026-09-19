// SPEC: A6 (owner-directed 2026-09-08) — one day of the journal: the header reads "Today" · "Yesterday" · "Mon" · "Mon Sep 8"
// (the DayLabel twin) plus " · Rest day" when the day was not a training day (A1) and holds no workout; rows in the order they
// happened. Swipe to delete (E3: delete yours anytime). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JournalDaySection: View {
    let dayKey: String
    let todayKey: String
    let posts: [LocalPost] // chronological
    let isRestDay: Bool
    let distanceUnit: String // A9: journal lines carry distances, never weights
    let onDelete: (LocalPost) -> Void
    @State private var deleting: LocalPost?

    private var header: String {
        let label = DayLabel.dayLabel(dayKey, todayKey: todayKey)
        return isRestDay ? "\(label) · Rest day" : label
    }

    var body: some View {
        Section {
            ForEach(posts, id: \.clientId) { post in
                JournalRow(post: post, distanceUnit: distanceUnit)
                    // A28 (a): red lives only inside the destructive confirm, so the swipe is ink and the confirm asks (E3: delete yours anytime)
                    .swipeActions { Button("Delete") { deleting = post }.tint(EmberColors.ink) }
                    .listRowBackground(EmberColors.card)
                    .confirmationDialog("Delete this post?", isPresented: Binding(get: { deleting?.clientId == post.clientId }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                        Button("Delete", role: .destructive) { onDelete(post); deleting = nil }
                    }
            }
        } header: {
            Text(numerals: header).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary) // the role renders it uppercase
        }
    }
}
