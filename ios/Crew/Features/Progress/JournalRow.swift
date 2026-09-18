// SPEC: A6 (owner-directed 2026-09-08) — one journal row: the summary line ("Push day · 12/12 sets · 44 min" · "Walk · 25 min ·
// 2.1 km"), a "Sending ↻" chip while the post is counted but not yet delivered (E19), and the caption (A22 G2: the optional line a
// workout post carries; no photo — photos left the journal with the plate journal). Ink and secondary only — no ember here.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JournalRow: View {
    let post: LocalPost
    let distanceUnit: String // A9: a journal line carries a distance, never a weight

    // SPEC: A6 · E19 — counted on this phone, not yet delivered: no server id and no delivery stamp
    private var isSending: Bool { post.deliveredAt == nil && post.serverId == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                Text(JournalFacts.line(for: post, distanceUnit: distanceUnit)).font(.body).foregroundStyle(EmberColors.inkText)
                Spacer()
                if isSending {
                    Text("Sending ↻")
                        .font(.caption)
                        .foregroundStyle(EmberColors.secondaryText)
                        .padding(.horizontal, EmberTokens.Spacing.space8)
                        .padding(.vertical, EmberTokens.Spacing.space4)
                        .overlay(Capsule().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
                        .accessibilityLabel("Sending")
                }
            }
            if !post.caption.isEmpty { Text(post.caption).font(.subheadline).foregroundStyle(EmberColors.secondaryText) }
        }
        .padding(.vertical, EmberTokens.Spacing.space4)
    }
}
