// SPEC: Part III law ① — ink acts: primary buttons are #211D19 fill with #FAF8F5 label (dark: inverted ink), never
// orange; 6.3 targets ≥ 44 pt; 6.6 verb-first labels. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(EmberColors.primaryButtonLabel) }
            }
            .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
            .foregroundStyle(EmberColors.primaryButtonLabel)
            .background(EmberColors.primaryButtonFill, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .foregroundStyle(EmberColors.secondaryButtonLabel)
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space16, style: .continuous).stroke(EmberColors.secondaryButtonOutline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
