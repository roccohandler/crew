// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — hero "I have an invite" → THIS screen: paste → the crew's preview line → Continue
// into the two questions; the token rides through onboarding (1A) and the join happens after auth (OnboardingModelAuth.finishSignup),
// landing INSIDE the crew. Dead code and full crew are explicit states (S13). Pure ink-on-bone (Part III onboarding rule). 6.7: a
// ScrollView is the overflow valve. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct InviteCodeScreen: View {
    @Bindable var model: OnboardingModel
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                    Text("Your invite").font(.largeTitle.weight(.bold)).foregroundStyle(EmberColors.inkText)
                    InviteCodeEntry(code: $model.inviteCode, preview: model.invitedCrew, errorLine: model.inviteError, isLookingUp: model.isLookingUpInvite, continueTitle: "Continue",
                                    onLookUp: { Task { await model.lookUpInvite() } },
                                    onContinue: onContinue)
                    Spacer()
                }
                .padding(EmberTokens.Spacing.space24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}
