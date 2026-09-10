// SPEC: A2 (owner-directed 2026-09-08) — a standalone cardio log from Home: one of the nine seeded activities (last-used
// first), minutes in cardioMinutesStep steps between cardioMinutesMin and cardioMinutesMax (pre-filled with the last log
// for that activity or the seed default), an optional distance typed in the user's distanceUnit (A9: km or mi, chosen
// independently of the weight unit) and stored in
// meters (≤ cardioDistanceMaxMeters). One call creates and completes the session (SessionActions.logCardio): unplanned →
// +25 (V30/V31), it sustains the streak like any post, it never advances the rotation (A1). No pace, effort, calories,
// heart rate, goals or targets — ever. 5.6.2 CardioLogModel — state: activities, activity, minutes, distanceText, outcome;
// actions: choose · submit. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

@Observable
@MainActor
final class CardioLogModel {
    var activities: [SeedExercise]
    var activity: SeedExercise?
    var minutes: Int
    var distanceText = ""
    var submitError: String?
    var outcome: CelebrationOutcome?
    let distanceUnit: String           // A9: "km" or "mi" — the same field SessionSummaryLine reads

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let lastMinutesById: [String: Int]

    init(store: Store = .shared, userId: String? = nil, seed: SeedCatalog = .shared, distanceUnit: String? = nil, timeZone: TimeZone = .current) {
        let userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        let cardio = seed.exercises.filter { $0.type == "cardio" }
        let recent = (try? Self.recentCardioLogs(for: userId, store: store)) ?? []
        var seen: [String] = []
        var lastMinutes: [String: Int] = [:]
        for session in recent {
            guard let id = session.exercises.first?.exerciseId, !seen.contains(id) else { continue }
            seen.append(id)
            if let minutes = Self.loggedMinutes(session) { lastMinutes[id] = minutes }
        }
        let ordered = seen.compactMap { id in cardio.first { $0.id == id } } + cardio.filter { !seen.contains($0.id) }
        self.store = store
        self.userId = userId
        self.timeZone = timeZone
        self.distanceUnit = distanceUnit ?? AuthStore.shared.distanceUnit
        self.lastMinutesById = lastMinutes
        self.activities = ordered
        self.activity = ordered.first
        self.minutes = Self.prefill(for: ordered.first, lastMinutesById: lastMinutes)
    }

    // Last-used first: every completed cardio log on the phone, newest first (A2); Store.completedSessions is latest-first
    private static func recentCardioLogs(for userId: String, store: Store) throws -> [LocalSession] {
        try store.completedSessions(for: userId).filter { $0.workoutKind == "cardio" }
    }

    // A cardio log is one exercise with one done set; its holdSeconds are the logged minutes (A2)
    private static func loggedMinutes(_ session: LocalSession) -> Int? {
        session.exercises.first?.sets.first?.holdSeconds.map { $0 / TimeUnits.secondsPerMinute }
    }

    // SPEC: A2 — pre-filled with the last log for that activity, else the seed default; always inside the stepper's bounds
    private static func prefill(for activity: SeedExercise?, lastMinutesById: [String: Int]) -> Int {
        guard let activity else { return SpecConstants.cardioMinutesMin }
        let minutes = lastMinutesById[activity.id] ?? (activity.holdSeconds ?? 0) / TimeUnits.secondsPerMinute
        return min(SpecConstants.cardioMinutesMax, max(SpecConstants.cardioMinutesMin, minutes))
    }

    func choose(_ pick: SeedExercise) {
        activity = pick
        minutes = Self.prefill(for: pick, lastMinutesById: lastMinutesById)
    }

    var unitSuffix: String { distanceUnit == "km" ? "km" : "mi" }

    // SPEC: A2 · A9 — "2.1" in the user's distanceUnit → meters; empty or unreadable → nil ("Skip it if you don't know."); capped at
    // cardioDistanceMaxMeters so an invalid value is unreachable rather than rejected
    var distanceMeters: Int? {
        let text = distanceText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let value = Double(text), value > 0 else { return nil }
        let metersPerUnit = distanceUnit == "km" ? Double(SpecConstants.metersPerKilometer) : SpecConstants.metersPerMile
        return min(SpecConstants.cardioDistanceMaxMeters, Int((value * metersPerUnit).rounded()))
    }

    var canSubmit: Bool { activity != nil && minutes >= SpecConstants.cardioMinutesMin }

    // The same remembered answer PostModel and CelebrationScreen read ("shareToCrewDefault"); the celebration can still flip it
    var shareToCrew: Bool { UserDefaults.standard.object(forKey: "shareToCrewDefault") as? Bool ?? true }

    // SPEC: A2 · 5.3 optimistic write — the log is a completed session the moment it is saved; the queue follows; the
    // celebration is the normal one (+25 or +25 with the streak tick)
    func submit(now: Date = Date()) {
        guard let activity, canSubmit else { return }
        do {
            outcome = try SessionActions.logCardio(activity: activity, minutes: minutes, distanceMeters: distanceMeters, shareToCrew: shareToCrew, userId: userId, timeZone: timeZone, now: now, store: store)
            Haptics.play(.thump)
        } catch {
            submitError = AppError.storage("cardio").userLine
        }
    }
}
