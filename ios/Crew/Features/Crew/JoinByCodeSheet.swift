// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — the same entry on the EMPTY Crew tab for a signed-in user: paste → preview →
// "Join the crew" → the crew appears on the tab behind the sheet (S13 states explicit: dead code, full crew, already in a crew).
// Screens hold ZERO logic (5.6.6): CrewModel looks the code up and joins. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct JoinByCodeSheet: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                InviteCodeEntry(code: $model.inviteCode, preview: model.invitePreview, errorLine: model.inviteCodeError, isLookingUp: model.isLookingUpInvite, continueTitle: "Join the crew",
                                onLookUp: { Task { await model.lookUpInvite() } },
                                onContinue: { Task { await model.joinByCode(); if model.crew != nil { dismiss() } } })
                    .padding(EmberTokens.Spacing.space24)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("I have an invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
