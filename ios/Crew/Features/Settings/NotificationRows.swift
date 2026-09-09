// SPEC: A7 (owner-directed 2026-09-08) — Notifications: Workout reminder + Time (G12: initialised from the STORED reminder,
// 7:30 only when nothing is stored, nothing saved on appear — D1 fix), Streak reminder, Crew activity, Mute {crew} (E2, state
// from the server — D2 fix); footer: the only emails. Toggles tinted ink (Part III law ①). Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct NotificationRows: View {
    let model: SettingsModel
    @State private var reminderTime: Date

    init(model: SettingsModel) {
        self.model = model
        _reminderTime = State(initialValue: SettingsModel.reminderDate(stored: AuthStore.shared.currentUser?.reminderTime))
    }

    var body: some View {
        Section {
            Toggle("Workout reminder", isOn: Binding(get: { model.reminderOn }, set: { on in Task { await model.setReminder(on: on, time: reminderTime) } }))
                .tint(EmberColors.inkText)
            if model.reminderOn {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .tint(EmberColors.inkText)
                    .onChange(of: reminderTime) { _, value in Task { await model.setReminderTime(value) } }
            }
            Toggle("Streak reminder", isOn: Binding(get: { model.streakRiskOn }, set: { on in Task { await model.setStreakRisk(on) } }))
                .tint(EmberColors.inkText)
            Toggle("Crew activity", isOn: Binding(get: { model.crewActivityOn }, set: { on in Task { await model.setCrewActivity(on) } }))
                .tint(EmberColors.inkText)
            if let name = model.crewName {
                Toggle("Mute \(name)", isOn: Binding(get: { model.crewMuted }, set: { muted in Task { await model.setMuted(muted) } }))
                    .tint(EmberColors.inkText)
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("We only email you for password resets and account deletion.")
        }
    }
}
