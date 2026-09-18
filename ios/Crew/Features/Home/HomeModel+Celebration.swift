// SPEC: 5.6.2 HomeModel — the celebration's answer (A21.9 / W4, owner-approved 2026-09-17): the tapped button posts with the
// visibility it names; a celebration the app died under posts privately at the next cold start; the reminder opt-in follows the
// FIRST completed workout once (A21.4 · 1D). Plain extension of HomeModel — no new layer; split from HomeModel.swift for C9 (the
// file cap). WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension HomeModel {
    // SPEC: A21.9 — the celebration's tapped button: the post with the visibility it names, the engine for real, then Home
    // re-reads the day (the bridge falls, Quick complete hides, the ring fills)
    func answerCelebration(_ outcome: CelebrationOutcome, shareToCrew: Bool, now: Date = Date()) {
        do { try SessionActions.post(outcome, shareToCrew: shareToCrew, now: now, store: store) } catch { loadError = AppError.storage("post").userLine }
        refresh(now: now)
    }

    // SPEC: A21.9 — a celebration the app died under (no button tapped) posts PRIVATELY at the next cold start
    func postUnanswered(now: Date = Date()) {
        try? SessionActions.postUnanswered(userId: userId, now: now, store: store)
    }

    // SPEC: A21.4 · 1D — the reminder opt-in follows the celebration of the FIRST completed workout, once per account on this
    // phone, and only while no reminder time is stored (ReminderOptIn.shouldAsk)
    func shouldOfferReminder() -> Bool {
        let asked = UserDefaults.standard.bool(forKey: ReminderOptIn.askedKey(userId: userId))
        let completed = (try? store.completedSessions(for: userId).count) ?? 0
        return ReminderOptIn.shouldAsk(askedBefore: asked, storedReminderTime: AuthStore.shared.currentUser?.reminderTime, completedWorkouts: completed)
    }
}
