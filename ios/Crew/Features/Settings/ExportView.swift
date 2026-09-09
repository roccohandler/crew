// SPEC: E9 — JSON data export in MVP: one tap builds the file, the share sheet hands it over; a second tap fetches it again
// (A7: re-exportable — D13 fix). WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct ExportView: View {
    @Bindable var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            Button("Export my data (JSON)") { Task { await model.exportJSON() } }.foregroundStyle(EmberColors.inkText).buttonStyle(.borderless)
            if let url = model.exportedFileURL {
                ShareLink(item: url) { Text("Share crew-export.json").font(.body).foregroundStyle(EmberColors.inkText) }.buttonStyle(.borderless)
            }
            if let error = model.errorLine { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
        }
    }
}
