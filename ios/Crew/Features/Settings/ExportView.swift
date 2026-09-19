// SPEC: E9 — JSON data export in MVP: one tap builds the file, the share sheet hands it over; a second tap fetches it again
// (A7: re-exportable — D13 fix). WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct ExportView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            Button { Task { await model.exportJSON() } } label: {
                Text("Export my data (JSON)").typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            if let url = model.exportedFileURL {
                ShareLink(item: url) { Text("Share crew-export.json").typeRole(EmberTokens.Typography.textButton).foregroundStyle(EmberColors.ink) }.buttonStyle(.borderless)
            }
            if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
        }
    }
}
