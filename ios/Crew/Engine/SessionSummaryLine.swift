// SPEC: A6 (owner-directed 2026-09-08) — one summary line per post: strength "Push day · 12/12 sets · 44 min"; cardio
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

    // SPEC: A6 — sessionSummaryLine(workoutName, isCardio, setsDone, setsPlanned, minutes, cardioMinutes, distanceMeters,
    // distanceUnit): a strength session reads sets and wall-clock minutes; a cardio log reads its logged minutes (the session's
    // own minutes when none were logged) and, when known, the distance
    static func sessionSummaryLine(workoutName: String, isCardio: Bool, setsDone: Int, setsPlanned: Int, minutes: Int, cardioMinutes: Int?, distanceMeters: Int?, distanceUnit: String) -> String {
        if !isCardio { return "\(workoutName) · \(setsDone)/\(setsPlanned) sets · \(minutes) min" }
        let line = "\(workoutName) · \(cardioMinutes ?? minutes) min"
        guard let distanceMeters else { return line }
        return "\(line) · \(distanceText(distanceMeters: distanceMeters, distanceUnit: distanceUnit))"
    }
}
