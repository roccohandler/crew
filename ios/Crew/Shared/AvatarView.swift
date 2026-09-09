// SPEC: E1 — name + one profile picture; until set, initials on warm gray (a fallback, not a second system) · A7
// (owner-directed 2026-09-08): when a photoKey is given the picture loads through GET photos/[key] (own or a crew-mate's);
// an in-memory image (a freshly chosen one) wins over the key. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct AvatarView: View {
    let displayName: String
    let image: UIImage?
    var photoKey: String? = nil
    var size: CGFloat = EmberTokens.Size.avatar
    @State private var loaded: UIImage?

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(SpecConstants.initialsMaxLetters)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    private var shown: UIImage? { image ?? loaded }

    var body: some View {
        ZStack {
            if let shown {
                Image(uiImage: shown).resizable().scaledToFill()
            } else {
                Circle().fill(EmberColors.hairline)
                Text(initials).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(displayName)
        .task(id: photoKey) {
            loaded = nil
            guard let photoKey else { return }
            loaded = try? await Api.shared.photo(key: photoKey)
        }
    }
}
