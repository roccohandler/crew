// SPEC: A7 (owner-directed 2026-09-08) — Blocked people: the list, Unblock with "Unblock {name}?" — Unblock / Keep blocked;
// empty "No one blocked." · E9 (silent both ways) · 6.3 targets ≥ 44 pt. Screens hold ZERO logic (5.6.6). A28 (f) · R-091: the
// people are rows of one card on the gutter, not the platform's inset-grouped list. WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct BlockedPeopleScreen: View {
    @State private var model = BlockedPeopleModel()
    @State private var pendingUnblock: BlockedUserDTO?

    var body: some View {
        SettingsGroupScreen(title: "Blocked people") {
            if model.isLoaded && model.people.isEmpty {
                Text("No one blocked.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            }
            if !model.people.isEmpty {
                FocusCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(model.people.enumerated()), id: \.element.userId) { index, person in
                            if index > 0 { cardSeam() }
                            HStack(spacing: EmberTokens.Spacing.space12) {
                                Text(person.displayName).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                                Spacer(minLength: EmberTokens.Spacing.space8)
                                TextActionButton(title: "Unblock", horizontalPadding: 0, accessibilityLabel: "Unblock \(person.displayName)", role: EmberTokens.Typography.textButton) { pendingUnblock = person }
                            }
                            .padding(.horizontal, EmberTokens.Focus.setCardInset)
                            .frame(minHeight: EmberTokens.Focus.rowButton)
                        }
                    }
                }
            }
            if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
        }
        .task { await model.refresh() }
        .confirmationDialog(Text("Unblock \(pendingUnblock?.displayName ?? "")?"), isPresented: Binding(get: { pendingUnblock != nil }, set: { if !$0 { pendingUnblock = nil } }), titleVisibility: .visible) {
            Button("Unblock") { if let person = pendingUnblock { Task { await model.unblock(userId: person.userId) } } }
            Button("Keep blocked", role: .cancel) { pendingUnblock = nil }
        }
    }
}
