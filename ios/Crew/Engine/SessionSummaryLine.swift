// SPEC: A6 (owner-directed 2026-09-08) as amended by A28 (c) (2026-09-19) — one summary line per post: strength "Push day · 12 of
// 12 sets" (no minutes: nothing shows the time a workout took; "N of M" as mockups 05 and 11 print it); cardio
// "Walk · 25 min" + " · 2.1 km" when a distance exists (the poster's distanceUnit; one decimal). A2 — a distance is
// stored in meters. A9 — the unit is the poster's own distanceUnit, no longer inferred from their weight unit. Twin of web/src/lib/engine/session-summary-line.ts — identical names. Pure, Foundation
// only. WRITTEN — UNVERIFIED on a Mac; verified on Linux (ios/Package.swift).

import Foundation

enum SessionSummaryLine {
    // SPEC: A2 · A6 · A9 — meters → "2.1 km" or "1.3 mi" in the poster's distanceUnit, rounded half-up to tenths with integer
    // arithmetic so both engines print the same digit on an exact half (2250 m → 2.3 km)
    static func distanceText(distanceMeters: Int, distanceUnit: String) -> String {
        let metric = distanceUnit == "km"
        let metersPerUnit = metric ? Double(SpecConstants.metersPerKilometer) : SpecConstants.metersPerMile
        let tenths = Int((Double(distanceMeters) / metersPerUnit * Double(SpecConstants.distanceDecimalScale)).rounded())
        let whole = tenths / SpecConstants.distanceDecimalScale
        let fraction = tenths % SpecConstants.distanceDecimalScale
        return "\(whole).\(fraction) \(metric ? "km" : "mi")"
    }

    // SPEC: A6 · A28 (c) — sessionSummaryLine(workoutName, isCardio, setsDone, setsPlanned, cardioMinutes, distanceMeters,
    // distanceUnit): a strength session reads its sets and nothing of the clock; a cardio log reads its ENTERED minutes (GAP 4 in
    // A28: they stand until the owner rules) and, when known, the distance — the wall-clock fallback is gone with every session clock
    static func sessionSummaryLine(workoutName: String, isCardio: Bool, setsDone: Int, setsPlanned: Int, cardioMinutes: Int?, distanceMeters: Int?, distanceUnit: String) -> String {
        if !isCardio { return "\(workoutName) · \(setsDone) of \(setsPlanned) sets" }
        var parts = [workoutName]
        if let cardioMinutes { parts.append("\(cardioMinutes) min") }
        if let distanceMeters { parts.append(distanceText(distanceMeters: distanceMeters, distanceUnit: distanceUnit)) }
        return parts.joined(separator: " · ")
    }

    // SPEC: A28 (c) · R-086 — a summary STORED before A28 carries the workout's minutes ("Push day · 12/12 sets · 44 min"); it reads at
    // render as "Push day · 12 of 12 sets". A cardio line's entered minutes stand (GAP 4), and nothing stored is rewritten.
    static func withoutWorkoutMinutes(_ stored: String) -> String {
        let parts = stored.components(separatedBy: " · ")
        guard let minutes = parts.last, minutes.hasSuffix(" min"), let sets = parts.dropLast().last, sets.hasSuffix(" sets") else { return stored }
        let counts = sets.dropLast(" sets".count).split(separator: "/", omittingEmptySubsequences: false)
        guard let done = counts.first, let planned = counts.last, counts.dropFirst().count == 1, Int(done) != nil, Int(planned) != nil else { return stored }
        return (parts.dropLast().dropLast() + ["\(done) of \(planned) sets"]).joined(separator: " · ")
    }
}
