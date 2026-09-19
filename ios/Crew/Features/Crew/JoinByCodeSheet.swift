// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — the same entry on the EMPTY Crew tab for a signed-in user: paste → preview →
// "Join the crew" → the crew appears on the tab behind the sheet (S13 states explicit: dead code, full crew, already in a crew).
// Screens hold ZERO logic (5.6.6): CrewModel looks the code up and joins. A28 (f) · R-092: the system's sheet — the title in the
// content at `sheetTitle` with Cancel beside it (not the navigation bar's inline title), sized to the medium detent so the one
// filled button sits in the thumb zone. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JoinByCodeSheet: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                    Text("I have an invite").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { dismiss() } // 6.3: the pull has a visible twin
                }
                InviteCodeEntry(code: $model.inviteCode, preview: model.invitePreview, errorLine: model.inviteCodeError, isLookingUp: model.isLookingUpInvite, continueTitle: "Join the crew",
                                onLookUp: { Task { await model.lookUpInvite() } },
                                onContinue: { Task { await model.joinByCode(); if model.crew != nil { dismiss() } } })
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space32)
            .padding(.bottom, EmberTokens.Spacing.space16)
        }
        .background(EmberColors.card.ignoresSafeArea()) // A28 (f): the sheet surface
        .tint(EmberColors.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
