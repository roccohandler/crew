// SPEC: A6 (owner-directed 2026-09-08) — one day of the journal: the header reads "Today" · "Yesterday" · "Mon" · "Mon Sep 8"
// (the DayLabel twin) plus " · Rest day" when the day was not a training day (A1) and holds no workout; rows in the order they
// happened, in one card. E3 (delete yours anytime): each row carries a visible Delete, and the confirm asks — a swipe with no
// visible twin broke 6.3, and the card is not a List, so there is no swipe (ui-reviewer, run 35444308817). WRITTEN — UNVERIFIED.

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
        // one day inside the Journal's one card (R-094): its eyebrow, then its rows with the seam between them
        VStack(alignment: .leading, spacing: 0) {
            Text(numerals: header).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary) // the role renders it uppercase
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, EmberTokens.Focus.setCardInset)
                .padding(.top, EmberTokens.Spacing.space16)
                .padding(.bottom, EmberTokens.Spacing.space4)
            ForEach(Array(posts.enumerated()), id: \.element.clientId) { index, post in
                if index > 0 { cardSeam() }
                row(post)
            }
        }
        // A28 (a): red lives only inside the destructive confirm; the button that opens it is ink
        .confirmationDialog("Delete this post?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let deleting { onDelete(deleting) }; deleting = nil }
        }
    }

    private func row(_ post: LocalPost) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
            JournalRow(post: post, distanceUnit: distanceUnit)
            Spacer(minLength: 0)
            TextActionButton(title: "Delete", accessibilityLabel: "Delete \(JournalFacts.line(for: post, distanceUnit: distanceUnit))", role: EmberTokens.Typography.textButton) { deleting = post }
        }
        .padding(.horizontal, EmberTokens.Focus.setCardInset)
        .padding(.vertical, EmberTokens.Spacing.space4)
    }
}
