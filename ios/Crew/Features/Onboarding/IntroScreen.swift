// SPEC: S02 hero (AMENDED v1.9) — ONE screen, three CTAs (Build my week · I have an invite · Log in); pure ink-on-bone
// (Part III onboarding rule: no orange anywhere); invite token renders crew name/emoji · T013 shell (T021 wires the
// flows). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct IntroScreen: View {
    var invitedCrewLine: String? = nil
    var onBuildMyWeek: () -> Void = {}
    var onHaveInvite: () -> Void = {}
    var onLogIn: () -> Void = {}

    var body: some View {
        // SPEC: A19.5 / R10 · 6.7 ("content that can grow lives in ScrollViews") — the overflow valve. A largeTitle
        // headline, an optional invite line and three stacked controls do not fit an SE at accessibility-XXL, and
        // without a scroll view the bottom control is clipped with no way to reach it. The two Spacers stay exactly
        // where they are: they centre the headline and hold the CTAs at the floor while the screen FITS (6.7), and
        // the minHeight below is what gives them a floor to push against once it is inside a scroll view.
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                    Spacer()
                    if let invitedCrewLine {
                        Text(invitedCrewLine)
                            .font(.headline)
                            .foregroundStyle(EmberColors.secondaryText)
                    }
                    Text("One plan. Every week. Your crew sees you show up.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(EmberColors.inkText)
                    Spacer()
                    PrimaryButton(title: "Build my week", action: onBuildMyWeek)
                    SecondaryButton(title: "I have an invite", action: onHaveInvite)
                    Button("Log in", action: onLogIn)
                        .font(.body)
                        .foregroundStyle(EmberColors.inkText)
                        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                }
                .padding(EmberTokens.Spacing.space24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}
