// SPEC: Flow 6 — posts drop into the chat as cards ("SAM · PULL DAY ✓ · 15/15 sets · 🔥 day 4"); long-press → the five
// reactions; the COMEBACK 🎉 banner (V39); Part III law ④ (ember only where progress is the message) · A6 (the summary line
// under the author) · A5 + E9 (Report post · Block {name} one long-press away, never on your own post).
// WRITTEN — UNVERIFIED. T031

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
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                if item.comeback == true {
                    Text("Comeback 🎉").font(.caption.weight(.semibold)).foregroundStyle(EmberColors.emberText)
                }
                HStack {
                    Text(authorName.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(EmberColors.secondaryText)
                    Spacer()
                    Text(item.post?.type == "workout" ? "Workout ✓" : (item.post?.mealTag.map { MealTag(rawValue: $0)?.emoji ?? "" } ?? "")).font(.caption).foregroundStyle(EmberColors.secondaryText)
                }
                if let summary = item.post?.summary, !summary.isEmpty { Text(summary).font(.subheadline).foregroundStyle(EmberColors.inkText) }
                if let key = item.post?.photoKey { PostPhoto(photoKey: key) }
                if let caption = item.post?.caption, !caption.isEmpty { Text(caption).font(.body).foregroundStyle(EmberColors.inkText) }
                if let reactions = item.reactions, !reactions.isEmpty {
                    HStack(spacing: EmberTokens.Spacing.space8) {
                        ForEach(Dictionary(grouping: reactions, by: \.emoji).sorted { $0.key < $1.key }, id: \.key) { emoji, who in
                            Text("\(emoji) \(who.count)").font(.caption)
                                .padding(.horizontal, EmberTokens.Spacing.space8).padding(.vertical, EmberTokens.Spacing.space4)
                                .background(who.contains { $0.userId == myUserId } ? EmberColors.hairline : EmberColors.canvas, in: Capsule())
                        }
                    }
                }
                // 6.7: every gesture has a visible button · 6.3: at caption size that button was ~40×16 pt
                TextActionButton(title: "React", font: .caption, color: EmberColors.secondaryText, horizontalPadding: 0, accessibilityLabel: "React to \(authorName)'s post") { showsReactions = true }
            }
        }
        .onLongPressGesture { showsReactions = true }
        .confirmationDialog("React", isPresented: $showsReactions) {
            ForEach(SpecConstants.reactionEmojis, id: \.self) { emoji in Button(emoji) { onReact(emoji) } }
            if !isMine {
                Button("Report post") { onReport() }
                Button("Block \(authorName)", role: .destructive) { onBlock() }
            }
        }
        // SPEC: 6.5 — "session, posting, reacting, chat fully completable non-visually" is a RELEASE-BLOCKING gate, and
        // reacting was not completable. `children: .combine` merges the card into one element, which is right for reading a
        // post as a single passage — but it also swallows the inner `React` button, so the only non-visual route to a
        // reaction was a long-press gesture VoiceOver never delivers. The reactions become accessibility ACTIONS on the
        // merged element: reachable from the rotor in one gesture, no extra stop while reading the stream, and the
        // gesture/button pair above is untouched for sighted users (6.3).
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

struct PostPhoto: View {
    let photoKey: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image { Image(uiImage: image).resizable().scaledToFill() } else { SkeletonBlock(height: EmberTokens.Size.skeletonHero) }
        }
        .frame(maxWidth: .infinity, maxHeight: EmberTokens.Size.skeletonHero + EmberTokens.Size.skeletonHero)
        .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
        .task { image = try? await Api.shared.photo(key: photoKey) }
    }
}
