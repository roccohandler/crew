// SPEC: E19 — failed sends: counted-vs-delivered are separate facts; a send failure never retro-breaks a streak; after ~24 h the
// user chooses [Retry] [Delete]. A22 G2 (owner-approved 2026-09-18): "Post without photo" left with the plate journal — no queued
// op carries a photo. Plain private helper of the Home feature (5.6.6); the choices go straight to SyncQueue.resolve. A28 (a), (f) ·
// R-091: the system's sheet — `card`, the title in the content, each held send a row with Retry and Delete as ink text buttons; the
// red lives only in Delete's confirm (it was a bordered red button on the row). WRITTEN — UNVERIFIED (needs Mac). T042

import SwiftUI

struct FailedUploadSheet: View {
    let records: [OpRecord]
    let onChoose: (OpRecord, UserChoice) -> Void
    @State private var deleting: OpRecord?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Still sending").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                Text("It counted the moment you logged it. It just hasn't reached your crew yet.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 0) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        if index > 0 { cardSeam(inset: 0) }
                        HStack(spacing: EmberTokens.Spacing.space12) {
                            Text(Self.title(for: record)).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: EmberTokens.Spacing.space8)
                            TextActionButton(title: "Retry", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { onChoose(record, .retry) }
                            TextActionButton(title: "Delete", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { deleting = record }
                        }
                        .frame(minHeight: EmberTokens.Focus.rowButton)
                    }
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space32)
            .padding(.bottom, EmberTokens.Spacing.space24)
        }
        .background(EmberColors.card.ignoresSafeArea())
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
        .tint(EmberColors.ink)
        .confirmationDialog("Delete this unsent change?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let deleting { onChoose(deleting, .delete) }; deleting = nil }
        }
    }

    // A `createPost` record can only come from a build older than A22: the server refuses it (postsRetired) and the user deletes it here
    private static func title(for record: OpRecord) -> String {
        switch OpKind(rawValue: record.kind) {
        case .createPost: return "A post from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        case .createSession, .patchSession: return "A workout log from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        default: return "A change from \(record.createdAt.formatted(date: .abbreviated, time: .shortened))"
        }
    }
}
