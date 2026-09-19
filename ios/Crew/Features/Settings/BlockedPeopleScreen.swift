// SPEC: A7 (owner-directed 2026-09-08) — Blocked people: the list, Unblock with "Unblock {name}?" — Unblock / Keep blocked;
// empty "No one blocked." · E9 (silent both ways) · 6.3 targets ≥ 44 pt. Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct BlockedPeopleScreen: View {
    @State private var model = BlockedPeopleModel()
    @State private var pendingUnblock: BlockedUserDTO?

    var body: some View {
        List {
            if model.isLoaded && model.people.isEmpty {
                Text("No one blocked.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary).listRowBackground(EmberColors.card)
            }
            ForEach(model.people, id: \.userId) { person in
                HStack {
                    Text(person.displayName).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    Spacer()
                    TextActionButton(title: "Unblock", horizontalPadding: 0, accessibilityLabel: "Unblock \(person.displayName)", role: EmberTokens.Typography.textButton) { pendingUnblock = person }.buttonStyle(.borderless)
                }
                .frame(minHeight: EmberTokens.Focus.rowButton)
                .listRowBackground(EmberColors.card)
            }
            if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink).listRowBackground(EmberColors.canvas) } // A28 (a): red only in a destructive confirm
        }
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Blocked people")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.refresh() }
        .confirmationDialog(Text("Unblock \(pendingUnblock?.displayName ?? "")?"), isPresented: Binding(get: { pendingUnblock != nil }, set: { if !$0 { pendingUnblock = nil } }), titleVisibility: .visible) {
            Button("Unblock") { if let person = pendingUnblock { Task { await model.unblock(userId: person.userId) } } }
            Button("Keep blocked", role: .cancel) { pendingUnblock = nil }
        }
    }
}
