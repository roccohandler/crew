// SPEC: S17 Settings · A7 (owner-directed 2026-09-08) as grouped by A27's hand-off and drawn by A28 (f) (R6) — one short page of
// row buttons in cards, each opening the screen that holds its rows, instead of one ~20-row list (DESIGN.md 3.2: secondary
// information one tap away behind a labelled control): the profile (E1, name + photo) · Pause my plan (its state as the value;
// A23's whisper under it) · Units (A9: lb/kg lives here only) · Notifications · Nutrition (absent under 18, A16.c) · Privacy &
// safety (E9) · Account (export, log out, delete — two-step, E18) · How Crew works (S19) · the version, a quiet line. Screens hold
// ZERO logic (5.6.6): SettingsModel holds it. WRITTEN — UNVERIFIED (needs Mac). T041 · R6

import SwiftUI

enum SettingsDestination: Hashable {
    case profile, pause, units, notifications, nutrition, privacy, account, howCrewWorks
}

struct SettingsRow {
    let title: String
    var value: String? = nil
    let destination: SettingsDestination
}

struct SettingsScreen: View {
    @State private var model = SettingsModel()
    @State private var path: [SettingsDestination] = []
    private let auth = AuthStore.shared

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    FocusCard(padding: 0) { profileRow }
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                        FocusCard(padding: 0) { RowButton(title: "Pause my plan", value: model.pauseDetail) { path = [.pause] } }
                        Whisper(.howPause) // A23: under Pause my plan
                    }
                    card(preferenceRows)
                    card([SettingsRow(title: "Privacy & safety", destination: .privacy), SettingsRow(title: "Account", destination: .account)])
                    card([SettingsRow(title: "How Crew works", destination: .howCrewWorks)]) // A23 · S19: the page behind the whispers
                    Text(numerals: model.versionLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.vertical, EmberTokens.Spacing.space16)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsDestination.self) { destination(for: $0) }
            .task { await model.refresh() }
        }
        .tint(EmberColors.ink)
    }

    // E1 — the member's own picture and name; it opens the Profile screen
    private var profileRow: some View {
        Button { path = [.profile] } label: {
            HStack(spacing: EmberTokens.Spacing.space12) {
                AvatarView(displayName: auth.currentUser?.displayName ?? "You", image: nil, photoKey: auth.currentUser?.profilePhotoKey)
                Text(auth.currentUser?.displayName ?? "You").typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Spacer(minLength: EmberTokens.Spacing.space8)
                Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
            }
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(auth.currentUser?.displayName ?? "You")
        .accessibilityHint("Opens your profile")
    }

    // Units · Notifications · Nutrition — A16.c: under 18 the Nutrition row is absent, with no copy
    private var preferenceRows: [SettingsRow] {
        var rows = [SettingsRow(title: "Units", value: "\(auth.weightUnit) · \(auth.distanceUnit)", destination: .units), SettingsRow(title: "Notifications", destination: .notifications)]
        if auth.nutrition != .absent { rows.append(SettingsRow(title: "Nutrition", destination: .nutrition)) }
        return rows
    }

    private func card(_ rows: [SettingsRow]) -> some View {
        FocusCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 { Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.setCardInset) }
                    RowButton(title: row.title, value: row.value) { path = [row.destination] }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for destination: SettingsDestination) -> some View {
        switch destination {
        case .profile: EditProfileScreen()
        case .pause: PauseScreen(model: model)
        case .units: UnitsScreen(model: model)
        case .notifications: SettingsGroupScreen(title: "Notifications") { NotificationRows(model: model) }
        case .nutrition: SettingsGroupScreen(title: "Nutrition") { NutritionSettingsRows(availability: auth.nutrition) }
        case .privacy: PrivacyScreen(model: model)
        case .account: SettingsGroupScreen(title: "Account") { AccountRows(model: model) }
        case .howCrewWorks: HowCrewWorksScreen()
        }
    }
}
