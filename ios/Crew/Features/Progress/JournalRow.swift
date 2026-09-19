// SPEC: A6 (owner-directed 2026-09-08) as amended by A28 (c), (f) — one journal row: the summary line ("Push day · 12 of 12 sets" ·
// "Walk · 25 min · 2.1 km"; a stored line's old minutes are dropped at render, R-086), a quiet "Sending" while the post is counted
// but not yet delivered (E19), and the caption (A22 G2: the optional line a
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
                Text(numerals: JournalFacts.line(for: post, distanceUnit: distanceUnit)).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: EmberTokens.Spacing.space8)
                // E19 — counted here, not yet delivered: a quiet word, not a chip (A28 (f): chips are not on the component list)
                if isSending { Text("Sending").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary) }
            }
            if !post.caption.isEmpty { Text(post.caption).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary) }
        }
        .padding(.vertical, EmberTokens.Spacing.space8)
    }
}
