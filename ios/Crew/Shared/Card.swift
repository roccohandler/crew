// SPEC: Part III — cards are #FFFFFF on the bone canvas (dark: #211D19), hairline borders, warm neutrals only.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(EmberTokens.Spacing.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space16, style: .continuous).stroke(EmberColors.hairline, lineWidth: 1))
    }
}
