// SPEC: A6 (owner-directed 2026-09-08) — one day of the journal: the header reads "Today" · "Yesterday" · "Mon" · "Mon Sep 8"
// (the DayLabel twin) plus " · Rest day" when the day was not a training day (A1) and holds no workout; rows in the order they
// happened. Swipe to delete (E3: delete yours anytime). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JournalDaySection: View {
    let dayKey: String
    let todayKey: String
    let posts: [LocalPost] // chronological
    let isRestDay: Bool
    let units: String
    let onDelete: (LocalPost) -> Void

    private var header: String {
        let label = DayLabel.dayLabel(dayKey, todayKey: todayKey)
        return isRestDay ? "\(label) · Rest day" : label
    }

    var body: some View {
        Section {
            ForEach(posts, id: \.clientId) { post in
                JournalRow(post: post, units: units)
                    .swipeActions { Button("Delete", role: .destructive) { onDelete(post) } }
                    .listRowBackground(EmberColors.card)
            }
        } header: {
            Text(header).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText).textCase(nil)
        }
    }
}
