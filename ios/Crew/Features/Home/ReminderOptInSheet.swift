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

    // A28 (f) · R-094: the system's sheet — `card`, the grabber, the title in the content at `sheetTitle`, the 20 pt gutter, the one
    // filled button at its foot and "Not now" as the kit's text button (it was a canvas page with a 20 pt title). The time is the
    // platform's compact picker: its grey chip is recorded residue (docs/debt.md), as on Settings → Notifications.
    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Text("Get a nudge on workout days?").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("One notification, on the days your plan trains. You can change the time in Settings.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            DatePicker("Remind me at", selection: $model.time, displayedComponents: .hourAndMinute)
                .typeRole(EmberTokens.Typography.bodySemibold)
                .tint(EmberColors.ink)
                .foregroundStyle(EmberColors.ink)
            if let line = model.errorLine { Text(line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
            Spacer(minLength: 0)
            PrimaryButton(title: model.isSaving ? "Saving…" : "Remind me") { Task { await model.accept(); onDone() } }
                .disabled(model.isSaving)
            TextActionButton(title: "Not now", role: EmberTokens.Typography.textButton) { model.decline(); onDone() }
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.top, EmberTokens.Spacing.space32)
        .padding(.bottom, EmberTokens.Spacing.space12)
        .background(EmberColors.card.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
