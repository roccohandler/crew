// SPEC: E1 — name + one profile picture; until set, initials on warm gray (a fallback, not a second system).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct AvatarView: View {
    let displayName: String
    let image: UIImage?
    var size: CGFloat = EmberTokens.Size.avatar

    private var initials: String {
        let parts = displayName.split(separator: " ").prefix(SpecConstants.initialsMaxLetters)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle().fill(EmberColors.hairline)
                Text(initials).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(displayName)
    }
}
