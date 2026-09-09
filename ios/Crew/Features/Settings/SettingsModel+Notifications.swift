// SPEC: A7 (owner-directed 2026-09-08) — Notifications rows: Workout reminder + Time (G12: the STORED time is what the picker
// shows; 7:30 only pre-fills when nothing is stored; nothing is saved by appearing — the D1 defect), Streak reminder and Crew
// activity (partial notificationPrefs PATCH, merged server-side), Mute {crew} (E2, state from GET users/me). Plain extension of
// SettingsModel — no new layer (C9 file cap). WRITTEN — UNVERIFIED (needs Mac). T041

import Foundation

extension SettingsModel {
    // SPEC: G12 — parse "HH:MM" from the stored reminder; when nothing is stored, the 7:30 suggestion pre-fills the picker
    // (never saved until the user acts). nonisolated: a View's init seeds its picker state from it.
    nonisolated static func reminderDate(stored: String?, now: Date = Date()) -> Date {
        let parts = (stored ?? "").split(separator: ":").compactMap { Int($0) }
        let hour = parts.first ?? SpecConstants.reminderSuggestedMinuteOfDay / TimeUnits.minutesPerHour
        let minute = parts.dropFirst().first ?? SpecConstants.reminderSuggestedMinuteOfDay % TimeUnits.minutesPerHour
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }

    nonisolated static func clock(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    func syncToggles(from user: UserDTO) {
        reminderOn = user.reminderTime != nil
        streakRiskOn = user.prefs.streakRisk
        crewActivityOn = user.prefs.crewActivity
    }

    // SPEC: G12 — off = an explicit null on the wire; on = the time the picker shows, chosen (or accepted) by the user
    func setReminder(on: Bool, time: Date) async {
        reminderOn = on
        await update(UpdateMeRequestDTO(reminderTime: on ? Self.clock(time) : nil, clearsReminder: !on))
    }

    func setReminderTime(_ time: Date) async {
        guard reminderOn else { return }
        await update(UpdateMeRequestDTO(reminderTime: Self.clock(time)))
    }

    // SPEC: A7 — one toggle, one key on the wire
    func setStreakRisk(_ on: Bool) async {
        streakRiskOn = on
        await update(UpdateMeRequestDTO(notificationPrefs: NotificationPrefsPatchDTO(streakRisk: on)))
    }

    func setCrewActivity(_ on: Bool) async {
        crewActivityOn = on
        await update(UpdateMeRequestDTO(notificationPrefs: NotificationPrefsPatchDTO(crewActivity: on)))
    }

    // SPEC: E2 — mute per crew; the toggle flips at once and the server confirms (a failure reads under the row's error line)
    func setMuted(_ muted: Bool) async {
        guard let crewId else { return }
        crewMuted = muted
        do { crewMuted = try await Api.shared.muteCrew(crewId: crewId, muted: muted).muted } catch let error as AppError { errorLine = error.userLine; crewMuted = !muted } catch {}
    }
}
