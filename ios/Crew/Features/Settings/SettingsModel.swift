// SPEC: 5.6.2 SettingsModel — actions: setReminder · muteCrew · pause(until) (≤ 21 d, no retro) · exportJSON · deleteAccount.
// Flow 7 pause · E9 export/delete · G12 reminder chosen by the user. WRITTEN — UNVERIFIED (needs Mac). T041

import Foundation
import Observation

@Observable
@MainActor
final class SettingsModel {
    var pause: PauseDTO?
    var errorLine: String?
    var exportedFileURL: URL?
    var deleted = false

    private let store: Store

    init(store: Store = .shared) {
        self.store = store
    }

    func refresh() async {
        pause = (try? await Api.shared.currentPause())?.pause
    }

    // G12: nil = the user turned the reminder off (an explicit null on the wire); a time = the user's own choice
    func setReminder(_ time: String?) async {
        await update(UpdateMeRequestDTO(reminderTime: time, clearsReminder: time == nil))
    }

    func setUnits(_ units: String) async {
        await update(UpdateMeRequestDTO(units: units))
    }

    private func update(_ body: UpdateMeRequestDTO) async {
        do { AuthStore.shared.updateCurrentUser(try await Api.shared.updateMe(body)) } catch let error as AppError { errorLine = error.userLine } catch {}
    }

    func muteCrew(_ crewId: String, muted: Bool) async {
        do { _ = try await Api.shared.muteCrew(crewId: crewId, muted: muted) } catch let error as AppError { errorLine = error.userLine } catch {}
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

    // SPEC: E9 — JSON data export in MVP; saved to a temporary file for the share sheet
    func exportJSON() async {
        do {
            let data = try await Api.shared.exportJSON()
            let url = FileManager.default.temporaryDirectory.appending(path: "crew-export.json")
            try data.write(to: url, options: .atomic)
            exportedFileURL = url
        } catch let error as AppError { errorLine = error.userLine } catch { errorLine = AppError.invalidResponse.userLine }
    }

    // SPEC: E18 — delete is real and says so; the local store is wiped after the server confirms
    func deleteAccount() async {
        do {
            _ = try await Api.shared.deleteAccount()
            try store.context.delete(model: LocalPost.self)
            try store.context.delete(model: LocalSession.self)
            try store.context.delete(model: LocalPlan.self)
            try store.context.delete(model: LocalGamificationState.self)
            try store.context.delete(model: LocalCrewSnapshot.self)
            try store.save()
            AuthStore.shared.signOutLocally()
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
