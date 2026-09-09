// SPEC: A6 (owner-directed 2026-09-08) — one journal row: the summary line ("Push day · 12/12 sets · 44 min" · "Walk · 25 min ·
// 2.1 km" · "Dinner · 4:31 PM"), a "Sending ↻" chip while the post is counted but not yet delivered (E19), the caption, the
// photo (the outbox file first, then the server's). Ink and secondary only — no ember here. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JournalRow: View {
    let post: LocalPost
    let units: String

    // SPEC: A6 · E19 — counted on this phone, not yet delivered: no server id and no delivery stamp
    private var isSending: Bool { post.deliveredAt == nil && post.serverId == nil }
    private var photoLabel: String { post.caption.isEmpty ? "Your plate" : post.caption }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                Text(JournalFacts.line(for: post, units: units)).font(.body).foregroundStyle(EmberColors.inkText)
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
            if post.type != "workout", !post.caption.isEmpty { Text(post.caption).font(.subheadline).foregroundStyle(EmberColors.secondaryText) }
            if let path = post.localPhotoPath, let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image).resizable().scaledToFill().frame(maxHeight: EmberTokens.Size.skeletonHero).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                    .accessibilityLabel(photoLabel)
            } else if let key = post.photoKey {
                PostPhoto(photoKey: key).accessibilityLabel(photoLabel) // posted from another device, or hydrated on a fresh phone: the photo lives on the server only
            }
        }
        .padding(.vertical, EmberTokens.Spacing.space4)
    }
}
