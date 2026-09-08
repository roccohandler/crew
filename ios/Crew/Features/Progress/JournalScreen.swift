// SPEC: S16 History/Journal — every post forever; editing a past session never alters XP (copy says so); deleted posts absent,
// logs present. E3 (delete yours anytime; captions editable, photos not). WRITTEN — UNVERIFIED (needs Mac). T040

import SwiftUI

struct JournalScreen: View {
    let posts: [LocalPost]
    let onDelete: (LocalPost) -> Void

    var body: some View {
        List {
            Section {
                Text("Your journal keeps everything. Editing a past workout changes your stats, never your XP or streak.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
            }
            ForEach(posts, id: \.clientId) { post in
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                    Text(post.dayKey).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    if let path = post.localPhotoPath, let image = UIImage(contentsOfFile: path) {
                        Image(uiImage: image).resizable().scaledToFill().frame(maxHeight: EmberTokens.Size.skeletonHero).clipped().clipShape(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                    } else if let key = post.photoKey {
                        PostPhoto(photoKey: key) // posted from another device, or hydrated on a fresh phone: the photo lives on the server only
                    }
                    Text(post.type == "workout" ? "Workout ✓" : (post.caption.isEmpty ? (MealTag(rawValue: post.mealTag ?? "")?.emoji ?? "") : post.caption)).foregroundStyle(EmberColors.inkText)
                }
                .swipeActions { Button("Delete", role: .destructive) { onDelete(post) } }
                .listRowBackground(EmberColors.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas)
        .navigationTitle("Journal")
    }
}
