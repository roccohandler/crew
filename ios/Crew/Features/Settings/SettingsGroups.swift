// SPEC: S17 · A7 · A9 · E9 as grouped by A27's hand-off (R6) — the destinations Settings' rows open. A group of rows is a List on the
// canvas with its rows on `card` (A28 (a): no platform gray, no white — the R0 review's "white list rows"); its section headers are
// eyebrows; an on/off setting is the system's check (CheckToggleStyle). Units: lb/kg lives here only (A28 (d)), each choice a row
// with a check — the kit's radio, not a segmented picker (§11). Privacy & safety: Blocked people and the two legal pages.
// WRITTEN — UNVERIFIED (needs Mac). R6

import SwiftUI

struct SettingsGroupScreen<Rows: View>: View {
    let title: String
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        List { rows().listRowBackground(EmberColors.card) }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas.ignoresSafeArea())
            .toggleStyle(CheckToggleStyle())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// SPEC: A9 — weight and distance are chosen separately (a UK lifter loads kilos and runs in miles); A28 (d): here only
struct UnitsScreen: View {
    let model: SettingsModel
    @State private var weightUnit = AuthStore.shared.weightUnit
    @State private var distanceUnit = AuthStore.shared.distanceUnit

    var body: some View {
        List {
            Section {
                choice("Pounds (lb)", selected: weightUnit == "lb") { weightUnit = "lb" }
                choice("Kilograms (kg)", selected: weightUnit == "kg") { weightUnit = "kg" }
            } header: { header("Weight") }
            Section {
                choice("Miles (mi)", selected: distanceUnit == "mi") { distanceUnit = "mi" }
                choice("Kilometres (km)", selected: distanceUnit == "km") { distanceUnit = "km" }
            } header: { header("Distance") }
        }
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: weightUnit) { _, value in Task { await model.setWeightUnit(value) } }
        .onChange(of: distanceUnit) { _, value in Task { await model.setDistanceUnit(value) } }
    }

    private func header(_ text: String) -> some View {
        Text(text).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(get: { selected }, set: { if $0 { action() } }))
            .toggleStyle(CheckToggleStyle())
            .listRowBackground(EmberColors.card)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// SPEC: A7 · E9 — Blocked people and the two legal pages (in the in-app browser)
struct PrivacyScreen: View {
    let model: SettingsModel
    @State private var legalPage: LegalPage?

    var body: some View {
        List {
            NavigationLink { BlockedPeopleScreen() } label: { row("Blocked people") }
            Button { legalPage = .privacy } label: { row("Privacy policy") }
            Button { legalPage = .terms } label: { row("Terms") }
        }
        .listRowBackground(EmberColors.card)
        .scrollContentBackground(.hidden)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Privacy & safety")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $legalPage) { page in SafariView(url: model.legalURL(page)).ignoresSafeArea() }
    }

    private func row(_ title: String) -> some View {
        Text(title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
            .contentShape(Rectangle())
    }
}
