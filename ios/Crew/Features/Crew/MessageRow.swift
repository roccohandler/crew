// SPEC: Flow 6 — a chat line in the unified stream (S12) · E20 (deleted messages are tombstones: "Message deleted", never a gap)
// · C10 one screen/view per file (split out of StreamList.swift, R-055). WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

struct MessageRow: View {
    let authorName: String
    let text: String // not `body`: a View's body is its own member
    let deleted: Bool
    let mine: Bool
    let at: Date

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text("\(mine ? "You" : authorName) · \(at.formatted(date: .omitted, time: .shortened))").font(.caption).foregroundStyle(EmberColors.secondaryText)
            Text(deleted ? "Message deleted" : text).font(.body).foregroundStyle(deleted ? EmberColors.missedGray : EmberColors.inkText).italic(deleted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
