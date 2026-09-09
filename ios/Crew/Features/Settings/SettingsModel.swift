// SPEC: 5.6.2 SettingsModel — actions: setReminder · muteCrew · pause(until) (≤ 21 d, no retro) · exportJSON · deleteAccount ·
// logout. Flow 7 pause · E9 export/delete · G12 reminder chosen by the user · A7 (owner-directed 2026-09-08): toggles backed by
// server fields, correct reminder and mute state, a real log out, version. The notification/mute half lives in
// SettingsModel+Notifications.swift (C9 file cap). WRITTEN — UNVERIFIED (needs Mac). T041

import Foundation
import Observation

@Observable
@MainActor
final class SettingsModel {
    var pause: PauseDTO?
    var errorLine: String?
    var exportedFileURL: URL?
    var deleted = false
    // A7: server-backed toggles — seeded from the Keychain copy of the user, re-read by refresh(), flipped at once on a tap
    var reminderOn = AuthStore.shared.currentUser?.reminderTime != nil
    var streakRiskOn = AuthStore.shared.currentUser?.prefs.streakRisk ?? true
    var crewActivityOn = AuthStore.shared.currentUser?.prefs.crewActivity ?? true
    var crewId: String?
    var crewName: String?
    var crewMuted = false

    let store: Store

    init(store: Store = .shared) {
        self.store = store
    }

    // SPEC: A7 — one trip (GET users/me) seeds the pause, the crew's mute state (D2 fix: never fabricated) and the toggles
    func refresh() async {
        guard let me = try? await Api.shared.me() else { return }
        AuthStore.shared.updateCurrentUser(me.user)
        pause = me.pause
        crewId = me.crew?.id
        crewName = me.crew?.name
        crewMuted = me.crew?.muted ?? false
        syncToggles(from: me.user)
    }

    // SPEC: Flow 7 / A3 — the return day reads through dayLabel, never as raw ISO ("Until Mon Sep 21")
    var pauseUntilLabel: String? {
        pause.map { DayLabel.dayLabel($0.endDay, todayKey: DayKey.dayKey(for: Date(), tz: .current)) }
    }

    var pauseDetail: String { pauseUntilLabel.map { "Until \($0)" } ?? "Off" }

    // SPEC: A7 — About row: Version {CFBundleShortVersionString} ({CFBundleVersion})
    var versionLine: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "beta"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }

    // SPEC: A7 — privacy policy and terms live at {APP_BASE_URL}/privacy and /terms; the API base is {APP_BASE_URL}/api/v1
    func legalURL(_ page: LegalPage) -> URL {
        URL(string: "/\(page.rawValue)", relativeTo: Api.shared.baseURL)?.absoluteURL ?? Api.shared.baseURL
    }

    func setUnits(_ units: String) async {
        await update(UpdateMeRequestDTO(units: units))
    }

    func update(_ body: UpdateMeRequestDTO) async {
        do { AuthStore.shared.updateCurrentUser(try await Api.shared.updateMe(body)) } catch let error as AppError { errorLine = error.userLine } catch {}
    }

    // SPEC: Flow 7 — pick a return date (max 3 weeks); validated locally by the same rule the server runs (V22/V23/V44)
    func pause(until returnDay: String, timeZone: TimeZone = .current, now: Date = Date()) async {
        let today = DayKey.dayKey(for: now, tz: timeZone)
        let userId = AuthStore.shared.currentUser?.id ?? "local"
        let existing = (try? GamificationLocal.pauses(for: userId, store: store)) ?? []
        let verdict = PauseValidation.validatePauseRequest(today: today, startDay: today, endDay: returnDay, existingPauses: existing)
        guard verdict.accepted else { errorLine = Self.line(for: verdict.reason); return }
        do {
            let reply = try await Api.shared.createPause(startDay: today, endDay: returnDay, timezone: timeZone.identifier)
            pause = reply.pause
            store.context.insert(LocalPause(userId: userId, startDay: today, endDay: returnDay, createdAt: now))
            try store.save()
        } catch let error as AppError { errorLine = error.userLine } catch {}
    }

    func endPause() async {
        do { _ = try await Api.shared.endPause(); pause = nil } catch let error as AppError { errorLine = error.userLine } catch {}
    }

    // SPEC: E9 — JSON data export in MVP; saved to a temporary file for the share sheet; every tap fetches afresh (re-exportable)
    func exportJSON() async {
        do {
            let data = try await Api.shared.exportJSON()
            let url = FileManager.default.temporaryDirectory.appending(path: "crew-export.json")
            try data.write(to: url, options: .atomic)
            exportedFileURL = url
            errorLine = nil
        } catch let error as AppError { errorLine = error.userLine } catch { errorLine = AppError.invalidResponse.userLine }
    }

    // SPEC: A7 — a real log out: the refresh token is revoked server-side, then everything local goes — the op queue and
    // pauses included (D7 fix) — through the one reset the fresh-install journey uses
    func logout() async {
        if let token = AuthStore.shared.refreshToken { _ = try? await Api.shared.logout(refreshToken: token) }
        CrewApp.resetState()
    }

    // SPEC: E18 — delete is real and says so; the local store is wiped after the server confirms (OpRecord and LocalPause too)
    func deleteAccount() async {
        do {
            _ = try await Api.shared.deleteAccount()
            CrewApp.resetState()
            deleted = true
        } catch let error as AppError { errorLine = error.userLine } catch {}
    }

    private static func line(for reason: PauseRejection?) -> String {
        switch reason {
        case .retroactive: return "A pause can start today or later, never in the past."
        case .tooLong: return "Pauses last three weeks at most."
        case .alreadyPaused: return "One pause at a time — end this one first."
        case .none: return ""
        }
    }
}
