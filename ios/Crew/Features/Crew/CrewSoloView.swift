// SPEC: A5 (owner-directed 2026-09-08) as drawn by A28 (f) — the solo tab explains the loop in three lines, then one CTA · Flow 10
// (solo is a full experience; the Crew tab is one warm invitation) · 6.1 Empty (an invitation, never an apology) · A21.3 / W4: the
// SAME entry as the hero — "I have an invite" — for a signed-in user with a code in hand (JoinByCodeSheet). One card, optically
// centred like Home's: the three lines and the size of a crew, the one filled "Start a crew", and "I have an invite" as text (the
// kit's text button, not an outline). No heading that repeats the button (ui-reviewer, run 35440565004). Screens hold ZERO logic
// (5.6.6). WRITTEN — UNVERIFIED (needs Mac). R5

import SwiftUI

struct CrewSoloView: View {
    let onStart: () -> Void
    var onHaveInvite: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: EmberTokens.Focus.gutter)
                    FocusCard {
                        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                            LoopLine(symbol: "dumbbell", text: "You finish a workout and post it.") // A28 (e): a statement, like the two lines under it (R-092)
                            LoopLine(symbol: "arrow.down.to.line", text: "It lands here for your crew.")
                            LoopLine(symbol: "hand.thumbsup", text: "They react 🔥💪👏😂❤️.") // A21.2: no chat; the five are user content (R-083 (12))
                            Text("Two to ten friends. A link, a name, an emoji.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            PrimaryButton(title: "Start a crew", action: onStart).padding(.top, EmberTokens.Spacing.space8)
                        }
                    }
                    TextActionButton(title: "I have an invite", role: EmberTokens.Typography.textButton, action: onHaveInvite) // A21.3: paste the code a friend sent
                        .padding(.top, EmberTokens.Spacing.space8)
                    Spacer(minLength: EmberTokens.Focus.gutter)
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .frame(minHeight: proxy.size.height)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// One ink glyph + one line: the preview of what will happen here, plain text in the layout (never an overlay)
private struct LoopLine: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
            Image(systemName: symbol).foregroundStyle(EmberColors.ink).frame(width: EmberTokens.Spacing.space24)
            Text(text).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
