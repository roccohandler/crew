// SPEC: E19 — failed uploads: counted-vs-delivered are separate facts; a send failure never retro-breaks a streak; after ~24 h the
// user chooses [Retry] [Post without photo] [Delete]. Plain private helper of the Home feature (5.6.6); the choices go straight
// to SyncQueue.resolve. WRITTEN — UNVERIFIED (needs Mac). T042

import SwiftUI

struct FailedUploadSheet: View {
    let records: [OpRecord]
    let onChoose: (OpRecord, UserChoice) -> Void

    var body: some View {
        NavigationStack {
            List(records, id: \.id) { record in
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                    Text(Self.title(for: record)).font(.headline).foregroundStyle(EmberColors.inkText)
                    Text("It counted the moment you posted it. It just hasn't reached your crew yet.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                    HStack(spacing: EmberTokens.Spacing.space8) {
                        Button("Retry") { onChoose(record, .retry) }
                        if record.kind == OpKind.createPost.rawValue { Button("Post without photo") { onChoose(record, .postWithoutPhoto) } }
                        Button("Delete", role: .destructive) { onChoose(record, .delete) }
                    }
                    .buttonStyle(.bordered)
                    .tint(EmberColors.inkText)
                }
                .listRowBackground(EmberColors.card)
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas)
            .navigationTitle("Still sending")
        }
    }

    private static func title(for record: OpRecord) -> String {
        switch OpKind(rawValue: record.kind) {
        case .createPost: return "A post from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        case .createSession, .patchSession: return "A workout log from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        case .sendMessage: return "A crew message"
        default: return "A change from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        }
    }
}
