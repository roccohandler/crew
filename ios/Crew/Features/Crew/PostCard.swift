// SPEC: Flow 6 — posts are the stream's cards (A21.2: there is no chat); long-press → the five reactions; the comeback (V39) · A6
// (the summary line under the author) · A5 + E9 (Report post · Block {name} one long-press away, never on your own post). A28 (b),
// (c), (f) · R5: the system's card; the comeback is stated in ink and in words (no 🎉 — every PR and comeback accent went); the
// summary reads without a stored line's old minutes (R-086); the reaction counts are words, not chips (the five emoji are user
// content, R-083 (12)); React is an ink text button. WRITTEN — UNVERIFIED. T031 · R5

import SwiftUI

struct PostCard: View {
    let item: StreamItemDTO
    let authorName: String
    let myUserId: String
    let onReact: (String) -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    @State private var showsReactions = false

    private var isMine: Bool { item.userId == myUserId }

    var body: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(authorName).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary) // uppercase by its role
                    Spacer()
                    if item.comeback == true { Text("Comeback").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                }
                if let summary = item.post?.summary, !summary.isEmpty {
                    Text(numerals: SessionSummaryLine.withoutWorkoutMinutes(summary)).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let caption = item.post?.caption, !caption.isEmpty {
                    Text(caption).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink).fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                    if let reactions = item.reactions, !reactions.isEmpty {
                        ForEach(Dictionary(grouping: reactions, by: \.emoji).sorted { $0.key < $1.key }, id: \.key) { emoji, who in
                            // the reader's own reaction reads in ink, the others' in inkSecondary: weight, not a chip, says "yours"
                            Text(numerals: "\(emoji) \(who.count)").typeRole(EmberTokens.Typography.caption)
                                .foregroundStyle(who.contains { $0.userId == myUserId } ? EmberColors.ink : EmberColors.inkSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                    // 6.7: every gesture has a visible button · 6.3: its target is 44 pt
                    TextActionButton(title: "React", horizontalPadding: 0, accessibilityLabel: "React to \(authorName)'s post", role: EmberTokens.Typography.textButton) { showsReactions = true }
                }
            }
        }
        .onLongPressGesture { showsReactions = true }
        .confirmationDialog("React", isPresented: $showsReactions) {
            ForEach(SpecConstants.reactionEmojis, id: \.self) { emoji in Button(emoji) { onReact(emoji) } }
            if !isMine {
                Button("Report post") { onReport() }
                Button("Block \(authorName)", role: .destructive) { onBlock() } // the confirm surface: the one place red appears
            }
        }
        // SPEC: 6.5 — reacting is completable non-visually: the card reads as one passage and the reactions are its actions
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            ForEach(SpecConstants.reactionEmojis, id: \.self) { emoji in
                Button(emoji) { onReact(emoji) }
            }
            if !isMine {
                Button("Report post") { onReport() }
                Button("Block \(authorName)") { onBlock() }
            }
        }
        .accessibilityHint("Actions available for reactions")
    }
}
