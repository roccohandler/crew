// SPEC: S17 Account — Export my data (JSON) (E9, re-exportable) · Log out (A7: a real log out — the token is revoked, the phone
// is wiped) · Delete account = two-step, "can't be undone" (E18). Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED. T041

import SwiftUI

struct AccountRows: View {
    let model: SettingsModel
    @State private var confirmingDelete = false

    var body: some View {
        Section("Account") {
            ExportView(model: model)
            Button("Log out") { Task { await model.logout() } }.foregroundStyle(EmberColors.inkText)
            if confirmingDelete {
                Text("This deletes your plan, workouts, posts and photos everywhere. It can't be undone.").font(.footnote).foregroundStyle(EmberColors.inkText)
                Button("Delete my account") { Task { await model.deleteAccount() } }.foregroundStyle(EmberColors.danger)
                Button("Keep it") { confirmingDelete = false }.foregroundStyle(EmberColors.inkText)
            } else {
                Button("Delete account") { confirmingDelete = true }.foregroundStyle(EmberColors.danger)
            }
        }
    }
}
