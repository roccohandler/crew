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

// SPEC: 6.1 Offline ("core loop unaffected; social shows last-synced + one thin banner") · A18.12 (the state became
// reachable) · A20.9 (2026-09-11 — it became LEGIBLE, and it started saying something true).
//
// What was wrong with it. It rendered `EmberColors.card` on `EmberColors.canvas` — #FFFFFF on #FAF8F5, which measures
// **1.06:1** — behind a `hairline` edge at 1.19:1, with no glyph and a hard-coded sentence that named no time. So the
// one element in the entire app whose job is to explain why the screen is behind was, in practice, invisible; and even
// when it was seen it could not answer "behind by how much". The owner's second complaint — "things don't look like
// they're syncing" — is about exactly this surface, and the mockup that prompted this pass deleted it altogether.
//
// What it does now: states the two facts SyncQueue publishes — when the server last took something, and how much is still
// waiting — beside an SF Symbol. `lastSyncedLine` stays the caller's sentence. A28 (f) · R5 (2026-09-19): the system has no
// banner, and offline is "a quiet line" (R-083 (13)), so the tinted, outlined surface is gone: an ink glyph and an inkSecondary
// line, on whatever the screen draws. Home, Plan and Crew read it, so all three moved together (docs/debt.md).
struct OfflineBanner: View {
    let lastSyncedLine: String
    var pending: Int = 0
    var lastSyncedAt: Date?

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(EmberColors.ink)
            Text(numerals: line)
                .typeRole(EmberTokens.Typography.secondary)
                .foregroundStyle(EmberColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps, it never widens the column
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: EmberTokens.Spacing.space32, alignment: .leading)
        // E20 — one stop, the whole sentence, with the word "Offline" leading so a screen reader states the condition first
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Offline. \(line)")
    }

    // A8 — never a zero as a verdict: with nothing waiting the banner reports the condition and the time, and says
    // nothing about a queue that is empty.
    private var line: String {
        let waiting = pending > 0 ? " \(pending) waiting to send." : ""
        guard let lastSyncedAt else { return lastSyncedLine + waiting }
        return "Offline — last synced \(Self.clock.string(from: lastSyncedAt))." + waiting
    }

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
