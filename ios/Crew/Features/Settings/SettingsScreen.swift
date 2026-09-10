// SPEC: S17 Settings — profile (E1, name + photo) · pause flow (≤ 21 days, no retro) · units · per-row notification toggles + per-crew
// mute · privacy & safety (E9: blocked people, privacy policy, terms) · JSON export · log out · delete = two-step, "can't be
// undone" (E18) · version. A7 (owner-directed 2026-09-08). Screens hold ZERO logic (5.6.6): SettingsModel holds it.
// WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct SettingsScreen: View {
    @State private var model = SettingsModel()
    @State private var weightUnit = AuthStore.shared.weightUnit     // A9: the two preferences are separate rows
    @State private var distanceUnit = AuthStore.shared.distanceUnit
    @State private var legalPage: LegalPage?
    private let auth = AuthStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { EditProfileScreen() } label: {
                        HStack(spacing: EmberTokens.Spacing.space12) {
                            AvatarView(displayName: auth.currentUser?.displayName ?? "You", image: nil, photoKey: auth.currentUser?.profilePhotoKey)
                            Text(auth.currentUser?.displayName ?? "You").font(.headline).foregroundStyle(EmberColors.inkText)
                        }
                    }
                }
                Section("Plan") {
                    NavigationLink { PauseScreen(model: model) } label: { LabeledContent("Pause my plan", value: model.pauseDetail) }
                    // SPEC: A9 — weight and distance are chosen separately: a UK lifter loads kilos and runs in miles,
                    // which the single field this replaces could never express
                    Picker("Weight", selection: $weightUnit) { Text("lb").tag("lb"); Text("kg").tag("kg") }
                        .onChange(of: weightUnit) { _, value in Task { await model.setWeightUnit(value) } }
                    Picker("Distance", selection: $distanceUnit) { Text("mi").tag("mi"); Text("km").tag("km") }
                        .onChange(of: distanceUnit) { _, value in Task { await model.setDistanceUnit(value) } }
                }
                NotificationRows(model: model)
                Section("Privacy & safety") {
                    NavigationLink("Blocked people") { BlockedPeopleScreen() }
                    Button("Privacy policy") { legalPage = .privacy }.foregroundStyle(EmberColors.inkText)
                    Button("Terms") { legalPage = .terms }.foregroundStyle(EmberColors.inkText)
                }
                AccountRows(model: model)
                Section("About") {
                    LabeledContent("Version", value: model.versionLine)
                }
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .task { await model.refresh() }
            .sheet(item: $legalPage) { page in SafariView(url: model.legalURL(page)).ignoresSafeArea() }
        }
    }
}
