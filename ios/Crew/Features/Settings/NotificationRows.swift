// SPEC: A7 (owner-directed 2026-09-08) — Notifications: Workout reminder + Time (G12: initialised from the STORED reminder,
// 7:30 only when nothing is stored, nothing saved on appear — D1 fix), Streak reminder, Crew activity, Mute {crew} (E2, state
// from the server — D2 fix); footer: the only emails. A28 (f) · R6: the settings are the system's checks (CheckToggleStyle, set by
// the screen) in one card — the ink-tinted switch left its knob on a cream track in dark; the time is the platform's picker
// (R-083 (11)). Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T041 · R6

import SwiftUI

struct NotificationRows: View {
    let model: SettingsModel
    @State private var reminderTime: Date

    init(model: SettingsModel) {
        self.model = model
        _reminderTime = State(initialValue: SettingsModel.reminderDate(stored: AuthStore.shared.currentUser?.reminderTime))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    Toggle("Workout reminder", isOn: Binding(get: { model.reminderOn }, set: { on in Task { await model.setReminder(on: on, time: reminderTime) } }))
                        .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    if model.reminderOn {
                        cardSeam()
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .typeRole(EmberTokens.Typography.bodySemibold)
                            .foregroundStyle(EmberColors.ink)
                            .tint(EmberColors.ink)
                            .frame(minHeight: EmberTokens.Focus.rowButton)
                            .padding(.horizontal, EmberTokens.Focus.setCardInset)
                            .onChange(of: reminderTime) { _, value in Task { await model.setReminderTime(value) } }
                    }
                    cardSeam()
                    Toggle("Streak reminder", isOn: Binding(get: { model.streakRiskOn }, set: { on in Task { await model.setStreakRisk(on) } }))
                        .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    cardSeam()
                    Toggle("Crew activity", isOn: Binding(get: { model.crewActivityOn }, set: { on in Task { await model.setCrewActivity(on) } }))
                        .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    if let name = model.crewName {
                        cardSeam()
                        Toggle("Mute \(name)", isOn: Binding(get: { model.crewMuted }, set: { muted in Task { await model.setMuted(muted) } }))
                            .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    }
                }
            }
            Text("We only email you for password resets and account deletion.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
