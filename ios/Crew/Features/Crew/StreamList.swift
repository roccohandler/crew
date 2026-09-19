// SPEC: Flow 6 — ONE unified stream: post cards and system lines, time-ordered; feed shows 7 days (S12) · A21.2 (owner-approved
// 2026-09-17): no chat rows — a kind this list no longer knows (an old snapshot's chat line) renders nothing · E9 (report / block
// reach the model through the card). WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

struct StreamList: View {
    let items: [StreamItemDTO]
    let members: [MemberDot]
    let myUserId: String
    let onReact: (String, String) -> Void   // postId, emoji
    let onReport: (String) -> Void          // postId
    let onBlock: (String) -> Void           // the author's userId

    private func name(_ userId: String) -> String { members.first { $0.id == userId }?.displayName ?? "Someone" }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
            ForEach(items, id: \.itemId) { item in
                Group {
                switch item.kind {
                case "post":
                    PostCard(item: item, authorName: name(item.userId), myUserId: myUserId,
                             onReact: { emoji in if let id = item.post?.id { onReact(id, emoji) } },
                             onReport: { if let id = item.post?.id { onReport(id) } },
                             onBlock: { onBlock(item.userId) })
                case "system":
                    Text(numerals: item.body ?? "").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary).multilineTextAlignment(.center).frame(maxWidth: .infinity) // A28 (f): a quiet line
                default:
                    EmptyView()
                }
                }
                .id(item.itemId) // the Crew screen scrolls to the newest item by this id (ScrollViewReader, R-092)
            }
        }
    }
}
