// SPEC: T042 · E4 (14 quiet days → Welcome back, S18) · S01 (a session in progress for more than a day) · E19 (an
// upload held past 24 h → the user chooses). The three edge prompts Home owns, and the only actions on this model
// that are not part of the daily loop.
//
// Split from HomeModel.swift for the C9 200-line cap, the way HomeModel+Facts.swift already splits the facts and
// SettingsModel+Notifications.swift splits Settings. Unlike +Facts these are INSTANCE methods — they mutate the
// model's published state — so the stored properties they touch are `internal` on HomeModel rather than `private`:
// Swift's `private` is file-scoped, and an extension in another file cannot reach it.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension HomeModel {
    // E4: the answer is stored on the account so no device asks twice this quiet spell; the phone remembers it even offline
    // GAP: a PATCH that fails offline is not queued (no such OpKind in the 5.6.3 map) — the web may ask once more; nothing is lost
    func acknowledgeWelcomeBack(now: Date = Date()) async {
        let today = DayKey.dayKey(for: now, tz: timeZone)
        welcomeBackAckDay = today
        welcomeBack = false
        if let user = try? await Api.shared.updateMe(UpdateMeRequestDTO(welcomeBackAckDay: today)) { AuthStore.shared.updateCurrentUser(user) }
    }

    // S01: "Keep going" hands the open session back to the normal Resume path
    func keepGoingWithStaleSession() -> LocalSession? {
        defer { staleSession = nil }
        return staleSession
    }

    // S01: a discard is the ordinary session discard — nothing was counted (V32), nothing is lost from XP
    func discardStaleSession(now: Date = Date()) {
        guard let session = staleSession else { return }
        session.status = "discarded"
        session.updatedAt = now
        try? store.save()
        try? (syncQueue ?? SyncQueue.shared).enqueue(.patchSession, payload: PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: nil, status: "discarded", completedAt: nil, post: nil))
        refresh(now: now)
    }

    // E19: Retry · Post without photo · Delete — straight to the queue's one resolve
    func resolveUpload(_ record: OpRecord, choice: UserChoice, now: Date = Date()) {
        try? (syncQueue ?? SyncQueue.shared).resolve(record, choice: choice, now: now)
        refresh(now: now)
    }
}
