// SPEC: Flow 6 — ONE unified stream: messages, post cards, system lines, time-ordered; feed shows 7 days (S12) · E20 (deleted
// messages are tombstones). WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

struct StreamList: View {
    let items: [StreamItemDTO]
    let members: [MemberDot]
    let myUserId: String
    let onReact: (String, String) -> Void

    private func name(_ userId: String) -> String { members.first { $0.id == userId }?.displayName ?? "Someone" }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
            ForEach(items, id: \.itemId) { item in
                switch item.kind {
                case "post":
                    PostCard(item: item, authorName: name(item.userId), myUserId: myUserId) { emoji in if let id = item.post?.id { onReact(id, emoji) } }
                case "system":
                    Text(item.body ?? "").font(.footnote).foregroundStyle(EmberColors.secondaryText).frame(maxWidth: .infinity)
                default:
                    MessageRow(authorName: name(item.userId), text: item.body ?? "", deleted: item.deleted ?? false, mine: item.userId == myUserId, at: item.at)
                }
            }
        }
    }
}

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
