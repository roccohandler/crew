// SPEC: S17 · A7 · A9 · E9 as grouped by A27's hand-off (R6) — the destinations Settings' rows open. Each is a page of the system's
// cards on the canvas, the gutter and the 28 pt radius (the platform's inset-grouped List drew a 16 pt gutter and a ~10 pt radius —
// ui-reviewer, run 35445082374 · R-091); a group's header is an eyebrow; an on/off setting is the system's check (CheckToggleStyle).
// Units: lb/kg lives here only (A28 (d)), each choice a row with a check — the kit's radio, not a segmented picker (§11). Privacy &
// safety: Blocked people and the two legal pages. WRITTEN — UNVERIFIED (needs Mac). R6

import SwiftUI

struct SettingsGroupScreen<Rows: View>: View {
    let title: String
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        ScrollView {
            // full width, so a short page (Blocked people's one line) still fills the canvas edge to edge — a hugging column left
            // the stack's white showing on both sides (ui-reviewer, run 35448570159 · R-095)
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) { rows() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.vertical, EmberTokens.Spacing.space16)
        }
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
        SettingsGroupScreen(title: "Units") {
            group("Weight") {
                choice("Pounds (lb)", selected: weightUnit == "lb") { weightUnit = "lb" }
                cardSeam()
                choice("Kilograms (kg)", selected: weightUnit == "kg") { weightUnit = "kg" }
            }
            group("Distance") {
                choice("Miles (mi)", selected: distanceUnit == "mi") { distanceUnit = "mi" }
                cardSeam()
                choice("Kilometres (km)", selected: distanceUnit == "km") { distanceUnit = "km" }
            }
        }
        .onChange(of: weightUnit) { _, value in Task { await model.setWeightUnit(value) } }
        .onChange(of: distanceUnit) { _, value in Task { await model.setDistanceUnit(value) } }
    }

    private func group<Rows: View>(_ title: String, @ViewBuilder rows: () -> Rows) -> some View {
        let built = rows() // built here: FocusCard's content closure escapes, and a non-escaping builder cannot go with it
        return VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            Text(title).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary).accessibilityAddTraits(.isHeader)
            FocusCard(padding: 0) { VStack(spacing: 0) { built } }
        }
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(get: { selected }, set: { if $0 { action() } }))
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// SPEC: A7 · E9 — Blocked people and the two legal pages (in the in-app browser)
struct PrivacyScreen: View {
    let model: SettingsModel
    @State private var legalPage: LegalPage?
    @State private var showsBlocked = false

    var body: some View {
        SettingsGroupScreen(title: "Privacy & safety") {
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    RowButton(title: "Blocked people") { showsBlocked = true }
                    cardSeam()
                    RowButton(title: "Privacy policy") { legalPage = .privacy }
                    cardSeam()
                    RowButton(title: "Terms") { legalPage = .terms }
                }
            }
        }
        .navigationDestination(isPresented: $showsBlocked) { BlockedPeopleScreen() }
        .sheet(item: $legalPage) { page in SafariView(url: model.legalURL(page)).ignoresSafeArea() }
    }
}
