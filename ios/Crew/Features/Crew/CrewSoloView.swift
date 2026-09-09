// SPEC: A5 (owner-directed 2026-09-08) — the solo tab explains the loop in three lines then one CTA · Flow 10 (solo is a full
// experience; the Crew tab is one warm invitation) · 6.1 Empty (an invitation, never an apology) · A8 (sentence case, verb-first
// CTA, no orange: nothing here is a reward). Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct CrewSoloView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Spacer()
            Text("Start a crew").font(.title2.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            LoopLine(symbol: "camera", text: "Post a workout or a meal photo.")
            LoopLine(symbol: "arrow.down.to.line", text: "It lands here for your crew.")
            LoopLine(symbol: "bubble.left.and.bubble.right", text: "They react 🔥💪👏😂❤️ and chat.")
            Text("Two to ten friends. A link, a name, an emoji.").font(.body).foregroundStyle(EmberColors.secondaryText)
            PrimaryButton(title: "Start a crew", action: onStart)
            Spacer()
        }
        .padding(EmberTokens.Spacing.space24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

// One ink glyph + one line: the preview of what will happen here, plain text in the layout (never an overlay)
private struct LoopLine: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
            Image(systemName: symbol).font(.body).foregroundStyle(EmberColors.inkText).frame(width: EmberTokens.Spacing.space24)
            Text(text).font(.body).foregroundStyle(EmberColors.inkText)
        }
        .accessibilityElement(children: .combine)
    }
}
