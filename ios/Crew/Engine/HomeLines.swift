// SPEC: A14 (owner-directed 2026-09-09) — Home shows the day's ACTUAL work, not its size. Owner-reported: "it's not clear
// visually what the work should be". Before this, the card read "5 exercises + mobility" — a measurement of the workout
// rather than the workout — while the plan editor two taps away listed every row.
//
// C5 governs the sets×reps phrase: this is its THIRD occurrence (web GeneratedPlan.targetsLabel, iOS
// WorkoutDraftText.repsText, now Home), so it is extracted here into a plain function.
// Pure and CONCRETE (C1: no generics) — the same shape the TypeScript twin takes.
// Twin of web/src/lib/engine/home-lines.ts.

import Foundation

struct HomeExercise: Equatable {
    let name: String
    let type: String          // strength | mobility | cardio (A2)
    let targetSets: Int
    let targetReps: Int
    let targetRepsMax: Int?
    let holdSeconds: Int?
    let order: Int
}

struct HomeLine: Equatable {
    let name: String
    let detail: String
}

enum HomeLines {
    // SPEC: A14 · A4 — "3×8", or "3×8–10" when the row carries a rep range
    static func setsByReps(targetSets: Int, targetReps: Int, targetRepsMax: Int?) -> String {
        let reps = targetRepsMax.flatMap { $0 == targetReps ? nil : "\(targetReps)–\($0)" } ?? "\(targetReps)"
        return "\(targetSets)×\(reps)"
    }

    // SPEC: A14 — the strength rows in plan order; mobility and cardio are the tail line, never rows of their own, so the
    // card stays the length of the actual lifting
    static func strengthLines(_ exercises: [HomeExercise]) -> [HomeLine] {
        exercises
            .filter { $0.type == "strength" }
            .sorted { $0.order < $1.order }
            .map { HomeLine(name: $0.name, detail: setsByReps(targetSets: $0.targetSets, targetReps: $0.targetReps, targetRepsMax: $0.targetRepsMax)) }
    }

    // SPEC: A2 — cardio and mobility seconds → minutes, rounded exactly the way the server and JournalFacts round
    private static func minutes(ofSeconds seconds: Int) -> Int {
        Int((Double(seconds) / Double(TimeUnits.secondsPerMinute)).rounded())
    }

    // SPEC: A14 · A2 — "+ mobility · 3 holds" / "+ mobility · 3 holds · cardio · 20 min"; nil when the workout is pure
    // lifting (a zero is never a verdict, A8 — an absent tail says nothing rather than saying "0 holds")
    static func tailLine(_ exercises: [HomeExercise]) -> String? {
        let holds = exercises.filter { $0.type == "mobility" }.count
        let cardioSeconds = exercises.filter { $0.type == "cardio" }.reduce(0) { $0 + ($1.holdSeconds ?? 0) }
        var parts: [String] = []
        if holds > 0 { parts.append("mobility · \(holds) \(holds == 1 ? "hold" : "holds")") }
        if cardioSeconds > 0 { parts.append("cardio · \(minutes(ofSeconds: cardioSeconds)) min") }
        return parts.isEmpty ? nil : "+ " + parts.joined(separator: " · ")
    }
}
