// SPEC: S17 Settings — pause flow (≤ 21 days, no retro); per-crew mute; per-row notification toggles; units; reminder time (G12:
// no silent default, 7:30 suggested); JSON export; delete = two-step, "can't be undone" (E18); log out. WRITTEN — UNVERIFIED. T041

import SwiftUI

struct SettingsScreen: View {
    @State private var model = SettingsModel()
    @State private var units = AuthStore.shared.currentUser?.units ?? "lb"
    @State private var reminderOn = AuthStore.shared.currentUser?.reminderTime != nil
    @State private var reminderTime = Date()
    @State private var crewMuted = false
    @State private var confirmingDelete = false
    private let auth = AuthStore.shared
    private var crew: LocalCrewSnapshot? { try? Store.shared.crewSnapshot() }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: EmberTokens.Spacing.space12) {
                        AvatarView(displayName: auth.currentUser?.displayName ?? "You", image: nil)
                        Text(auth.currentUser?.displayName ?? "You").font(.headline).foregroundStyle(EmberColors.inkText)
                    }
                }
                Section("Plan") {
                    NavigationLink("Pause my plan") { PauseScreen(model: model) }
                    Picker("Units", selection: $units) { Text("lb").tag("lb"); Text("kg").tag("kg") }
                        .onChange(of: units) { _, value in Task { await model.setUnits(value) } }
                }
                Section("Notifications") {
                    Toggle("Workout reminder", isOn: $reminderOn).tint(EmberColors.inkText)
                    if reminderOn {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, value in Task { await model.setReminder(Self.clock(value)) } }
                    }
                }
                .onChange(of: reminderOn) { _, on in Task { await model.setReminder(on ? Self.clock(reminderTime) : nil) } }
                if let crew {
                    Section("Crew") {
                        Toggle("Mute \(crew.name)", isOn: $crewMuted).tint(EmberColors.inkText)
                            .onChange(of: crewMuted) { _, muted in Task { await model.muteCrew(crew.crewId, muted: muted) } }
                    }
                }
                Section("Account") {
                    ExportView(model: model)
                    Button("Log out") { auth.signOutLocally() }.foregroundStyle(EmberColors.inkText)
                    if confirmingDelete {
                        Text("This deletes your plan, workouts, posts and photos everywhere. It can't be undone.").font(.footnote).foregroundStyle(EmberColors.inkText)
                        Button("Delete my account") { Task { await model.deleteAccount() } }.foregroundStyle(EmberColors.danger)
                        Button("Keep it") { confirmingDelete = false }.foregroundStyle(EmberColors.inkText)
                    } else {
                        Button("Delete account") { confirmingDelete = true }.foregroundStyle(EmberColors.danger)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .onAppear { reminderTime = Self.suggestedReminder() }
        }
    }

    // G12: 7:30 AM pre-filled as the suggestion, never silently saved
    private static func suggestedReminder() -> Date {
        let minutes = SpecConstants.reminderSuggestedMinuteOfDay
        return Calendar.current.date(bySettingHour: minutes / TimeUnits.minutesPerHour, minute: minutes % TimeUnits.minutesPerHour, second: 0, of: Date()) ?? Date()
    }

    private static func clock(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
