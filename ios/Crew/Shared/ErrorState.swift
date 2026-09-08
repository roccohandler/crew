// SPEC: 6.1 Error — what happened + what to do, one sentence, no codes, always a retry path; never a dead end.
// Offline (iPhone): core loop unaffected; social shows last-synced + one thin banner. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct ErrorState: View {
    let line: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space16) {
            Text(line).font(.body).foregroundStyle(EmberColors.inkText).multilineTextAlignment(.center)
            SecondaryButton(title: "Try again", action: retry)
        }
        .padding(EmberTokens.Spacing.space24)
        .frame(maxWidth: .infinity)
    }
}

struct OfflineBanner: View {
    let lastSyncedLine: String

    var body: some View {
        Text(lastSyncedLine)
            .font(.footnote)
            .foregroundStyle(EmberColors.secondaryText)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Spacing.space32)
            .background(EmberColors.card)
            .overlay(Rectangle().frame(height: 1).foregroundStyle(EmberColors.hairline), alignment: .bottom)
            .accessibilityLabel("Offline. \(lastSyncedLine)")
    }
}
