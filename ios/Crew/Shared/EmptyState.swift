// SPEC: 6.1 Empty — an invitation, never an apology ("Start your first crew", not "Nothing here yet"); exactly one CTA.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct EmptyState: View {
    let title: String
    let line: String
    let ctaTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space16) {
            Text(title).font(.title2.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            Text(line).font(.body).foregroundStyle(EmberColors.secondaryText).multilineTextAlignment(.center)
            PrimaryButton(title: ctaTitle, action: action)
        }
        .padding(EmberTokens.Spacing.space24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}
