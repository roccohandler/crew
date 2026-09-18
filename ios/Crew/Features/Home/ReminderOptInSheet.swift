// SPEC: A21.4 (owner-approved 2026-09-17) · 1D · G12 · A7 · E5 — after the FIRST completed workout's celebration, once: "Get a nudge
// on workout days?" with the time picker pre-filled at 7:30 (G12: a pre-fill, never saved by appearing); Remind me → the system
// permission prompt → the APNs token (PushRegistrar) → reminderTime saved (PATCH users/me); Not now → nothing saved, never asked
// again on this phone for this account (E5). workoutReminder defaults ON server-side (A7), so the saved time is all a reminder
// needs. Screens hold ZERO logic (5.6.6): ReminderOptInModel holds it. WRITTEN — UNVERIFIED (needs Mac).

import Observation
import SwiftUI

enum ReminderOptIn {
    // SPEC: A21.4 — ask once, after the first completed workout, and only while no reminder time is stored
    nonisolated static func shouldAsk(askedBefore: Bool, storedReminderTime: String?, completedWorkouts: Int) -> Bool {
        !askedBefore && storedReminderTime == nil && completedWorkouts >= 1
    }

    nonisolated static func askedKey(userId: String) -> String { "reminderOptInAsked.\(userId)" }
}

@Observable
@MainActor
final class ReminderOptInModel {
    var time: Date
    var isSaving = false
    var errorLine: String?
    private let userId: String

    init(userId: String, storedReminderTime: String?) {
        self.userId = userId
        self.time = SettingsModel.reminderDate(stored: storedReminderTime) // G12: 7:30 pre-fills when nothing is stored
    }

    // Remind me: the permission, the token, the time — in that order; a denial still saves the time (E5: in-app banners take over)
    func accept() async {
        isSaving = true
        defer { isSaving = false }
        _ = await PushRegistrar.requestPermissionAndRegister()
        do {
            AuthStore.shared.updateCurrentUser(try await Api.shared.updateMe(UpdateMeRequestDTO(reminderTime: SettingsModel.clock(time))))
        } catch let error as AppError {
            errorLine = error.userLine
        } catch {}
        markAsked()
    }

    func decline() { markAsked() }

    private func markAsked() { UserDefaults.standard.set(true, forKey: ReminderOptIn.askedKey(userId: userId)) }
}

struct ReminderOptInSheet: View {
    @State private var model: ReminderOptInModel
    let onDone: () -> Void

    init(userId: String, storedReminderTime: String?, onDone: @escaping () -> Void) {
        _model = State(initialValue: ReminderOptInModel(userId: userId, storedReminderTime: storedReminderTime))
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Spacer()
            Text("Get a nudge on workout days?").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            Text("One notification, on the days your plan trains. You can change the time in Settings.").font(.body).foregroundStyle(EmberColors.secondaryText)
            DatePicker("Remind me at", selection: $model.time, displayedComponents: .hourAndMinute)
                .tint(EmberColors.inkText)
                .foregroundStyle(EmberColors.inkText)
            if let line = model.errorLine { Text(line).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
            Spacer()
            PrimaryButton(title: model.isSaving ? "Saving…" : "Remind me") { Task { await model.accept(); onDone() } }
                .disabled(model.isSaving)
            Button("Not now") { model.decline(); onDone() }
                .font(.body)
                .foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}
