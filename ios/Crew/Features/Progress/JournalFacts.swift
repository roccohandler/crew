// SPEC: A6 (owner-directed 2026-09-08) — one summary line per post: a workout reads LocalPost.summary (the server's line) or the
// same line computed from the local session through the SessionSummaryLine twin, with the server's rounding (wall-clock minutes
// and cardio minutes both rounded); a meal reads "Dinner · 4:31 PM" (+ " · earlier today"). A2 — cardio minutes and distance
// come from done cardio sets. Plain functions over the Store (C2), shared by the journal, the day card and the celebration.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

@MainActor
enum JournalFacts {
    // SPEC: A2 · A6 — done, non-warm-up sets of one exercise type (strength → sets/week; cardio and mobility → minutes)
    static func doneSets(_ session: LocalSession, type: String) -> [LocalSetLog] {
        session.exercises.filter { $0.type == type }.flatMap(\.sets).filter { $0.done && !$0.isWarmup }
    }

    // SPEC: A2 — seconds → minutes, rounded the way the server rounds; a fact, never a target
    static func minutes(ofSeconds seconds: Int) -> Int {
        Int((Double(seconds) / Double(TimeUnits.secondsPerMinute)).rounded())
    }

    // SPEC: A2 — the minutes of every done cardio set; nil when none was done
    static func cardioMinutes(_ session: LocalSession) -> Int? {
        let sets = doneSets(session, type: "cardio")
        return sets.isEmpty ? nil : minutes(ofSeconds: sets.reduce(0) { $0 + ($1.holdSeconds ?? 0) })
    }

    // SPEC: A2 — the distance of every done cardio set; nil when none carried one
    static func distanceMeters(_ session: LocalSession) -> Int? {
        let distances = doneSets(session, type: "cardio").compactMap(\.distanceMeters)
        return distances.isEmpty ? nil : distances.reduce(0, +)
    }

    // SPEC: A6 — wall-clock minutes (completedAt − startedAt), rounded like the server
    static func wallClockMinutes(_ session: LocalSession) -> Int {
        guard let completedAt = session.completedAt else { return 0 }
        return Int((completedAt.timeIntervalSince(session.startedAt) / Double(TimeUnits.secondsPerMinute)).rounded())
    }

    // SPEC: A6 — the local twin of the server's post summary; a session of kind cardio reads its logged minutes and distance
    static func summaryLine(_ session: LocalSession, distanceUnit: String) -> String { // A9: the line carries a distance, never a weight
        let facts = Completion.completionFacts(SessionActions.setFacts(session))
        return SessionSummaryLine.sessionSummaryLine(workoutName: session.workoutName, isCardio: session.workoutKind == "cardio", setsDone: facts.setsDone, setsPlanned: facts.setsPlanned, minutes: wallClockMinutes(session), cardioMinutes: cardioMinutes(session), distanceMeters: distanceMeters(session), distanceUnit: distanceUnit)
    }

    // SPEC: A2 · S10 — " + Walk 25 min" for every cardio block with a done set; a skipped block shows nothing (skips are private)
    static func cardioSuffix(_ session: LocalSession) -> String {
        session.exercises.sorted { $0.order < $1.order }.filter { $0.type == "cardio" }.compactMap { exercise -> String? in
            let done = exercise.sets.filter { $0.done && !$0.isWarmup }
            guard !done.isEmpty else { return nil }
            return " + \(exercise.name) \(minutes(ofSeconds: done.reduce(0) { $0 + ($1.holdSeconds ?? 0) })) min"
        }.joined()
    }

    // The session behind a workout post: by client id on this phone; a hydrated post (sessionClientId nil) joins by day, taking
    // the completed session nearest the post's time
    static func session(for post: LocalPost, store: Store) -> LocalSession? {
        if let clientId = post.sessionClientId, let session = try? store.session(clientId: clientId) { return session }
        let completed = ((try? store.sessions(for: post.userId, dayKey: post.dayKey)) ?? []).filter { $0.status == "completed" }
        return completed.min { secondsApart($0, post) < secondsApart($1, post) }
    }

    private static func secondsApart(_ session: LocalSession, _ post: LocalPost) -> TimeInterval {
        abs((session.completedAt ?? session.startedAt).timeIntervalSince(post.createdAt))
    }

    // SPEC: A6 — the one line under a journal row: "Push day · 12/12 sets · 44 min" · "Walk · 25 min · 2.1 km" · "Dinner · 4:31 PM"
    static func line(for post: LocalPost, store: Store = .shared, distanceUnit: String) -> String {
        if post.type == "workout" {
            if let summary = post.summary, !summary.isEmpty { return summary }
            return session(for: post, store: store).map { summaryLine($0, distanceUnit: distanceUnit) } ?? "Workout ✓"
        }
        let meal = MealTag(rawValue: post.mealTag ?? "").map { $0.rawValue.capitalized } ?? "Meal"
        let time = post.createdAt.formatted(date: .omitted, time: .shortened)
        return "\(meal) · \(time)\(post.earlierToday ? " · earlier today" : "")"
    }
}
