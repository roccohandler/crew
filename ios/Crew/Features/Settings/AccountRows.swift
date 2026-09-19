// SPEC: S17 Account — Export my data (JSON) (E9, re-exportable) · Log out (A7: a real log out — the token is revoked, the phone
// is wiped) · Delete account = two-step, "can't be undone" (E18). A28 (a) · R6: the row that starts the delete is ink; the red lives
// in its confirm, which carries the "can't be undone" sentence (step two of two). Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED. T041 · R6

import SwiftUI

struct AccountRows: View {
    let model: SettingsModel
    @State private var confirmingDelete = false

    var body: some View {
        Section {
            ExportView(model: model).listRowBackground(EmberColors.card)
            Button { Task { await model.logout() } } label: { row("Log out") }.listRowBackground(EmberColors.card)
            Button { confirmingDelete = true } label: { row("Delete account") }.listRowBackground(EmberColors.card)
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete my account", role: .destructive) { Task { await model.deleteAccount() } }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This deletes your plan, workouts, posts and photos everywhere. It can't be undone.")
        }
    }

    private func row(_ title: String) -> some View {
        Text(title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
            .contentShape(Rectangle())
    }
}
