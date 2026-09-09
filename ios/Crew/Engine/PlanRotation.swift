// SPEC: A1 (owner-directed 2026-09-08) — workouts rotate in the plan's stored order (Push → Pull → Legs for generated
// plans); the next workout is the one after the LAST COMPLETED rotation workout; only a completed workout advances the
// pointer — never a missed day, a pause, or a plan edit; the pointer is DERIVED from history, never stored; a session
// whose kind is outside the cycle (a standalone cardio log, A2) never advances it. Balance is automatic: over any 3k
// completed workouts each kind occurs k times. Twin of web/src/lib/engine/plan-rotation.ts — identical names. Pure,
// Foundation only. WRITTEN — UNVERIFIED on a Mac; verified on Linux (ios/Package.swift).

import Foundation

struct RotationSession: Equatable {
    let kind: String?           // nil on legacy sessions, which carry only a name
    let name: String
    let completedAt: Date?
    let status: String          // inProgress | completed | discarded
}

struct DayProjection: Equatable {
    enum State: String, Codable {
        case done, planned, open, rest
    }

    let dayKey: String
    let weekday: Int            // ISO 1 = Monday … 7 = Sunday
    let state: State
    let kind: String?
}

enum PlanRotation {
    // SPEC: A1 — cycle[(i + 1) % n]; cycle[0] when nothing rotation-worthy has been completed or the last kind left the plan
    static func nextWorkoutKind(lastCompletedKind: String?, cycle: [String]) -> String {
        guard let last = lastCompletedKind, let index = cycle.firstIndex(of: last) else { return cycle.first ?? "" }
        return cycle[(index + 1) % cycle.count]
    }

    // SPEC: A1 — legacy sessions carry only a name: "Push day" → push, "Pull day" → pull, "Leg day" → legs,
    // "Full body A" → fullBodyA, "Full body B" → fullBodyB, anything else → nil
    static func workoutKindFromName(_ name: String) -> String? {
        let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("push") { return "push" }
        if lower.hasPrefix("pull") { return "pull" }
        if lower.hasPrefix("leg") { return "legs" }
        if lower.hasPrefix("full body a") { return "fullBodyA" }
        if lower.hasPrefix("full body b") { return "fullBodyB" }
        return nil
    }

    private static func rotationKind(of session: RotationSession, cycle: [String]) -> String? {
        guard let kind = session.kind ?? workoutKindFromName(session.name), cycle.contains(kind) else { return nil }
        return kind
    }

    // SPEC: A1 — the latest COMPLETED session whose kind (or name-inferred kind) is in the cycle; a miss, a pause and a
    // plan edit leave no completed session behind, so none of them can move the pointer
    static func lastRotationKind(sessions: [RotationSession], cycle: [String]) -> String? {
        var latest: (completedAt: Date, kind: String)?
        for session in sessions {
            guard session.status == "completed", let completedAt = session.completedAt, let kind = rotationKind(of: session, cycle: cycle) else { continue }
            if let current = latest, completedAt <= current.completedAt { continue }
            latest = (completedAt, kind)
        }
        return latest?.kind
    }

    // SPEC: A1 — 7 entries Mon..Sun: done (a completed rotation session that day, kind from completedKindByDay) · rest
    // (weekday ∉ trainingWeekdays) · open (a past training day with nothing completed — no word, no red) · planned
    // (today and future training days; kinds run on from nextKind, one step per planned day)
    static func projectWeek(weekKey: String, todayKey: String, trainingWeekdays: [Int], cycle: [String], nextKind: String, completedKindByDay: [String: String]) -> [DayProjection] {
        let monday = DayKey.weekKey(for: weekKey)
        var pointer = nextKind
        return (0..<TimeUnits.daysPerWeek).map { offset in
            let dayKey = DayKey.addDays(monday, offset)
            let weekday = DayKey.isoWeekday(dayKey)
            if let done = completedKindByDay[dayKey] { return DayProjection(dayKey: dayKey, weekday: weekday, state: .done, kind: done) }
            if !trainingWeekdays.contains(weekday) { return DayProjection(dayKey: dayKey, weekday: weekday, state: .rest, kind: nil) }
            if dayKey < todayKey { return DayProjection(dayKey: dayKey, weekday: weekday, state: .open, kind: nil) }
            let planned = DayProjection(dayKey: dayKey, weekday: weekday, state: .planned, kind: pointer)
            pointer = nextWorkoutKind(lastCompletedKind: pointer, cycle: cycle)
            return planned
        }
    }

    // SPEC: A1 · A3 (the what's-next line) — the next planned day strictly after a day; nil when the plan has no training days
    static func nextTrainingDayKey(afterDayKey: String, trainingWeekdays: [Int]) -> String? {
        for offset in 1...TimeUnits.daysPerWeek {
            let candidate = DayKey.addDays(afterDayKey, offset)
            if trainingWeekdays.contains(DayKey.isoWeekday(candidate)) { return candidate }
        }
        return nil
    }
}
