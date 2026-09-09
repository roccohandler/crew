// SPEC: A6 (owner-directed 2026-09-08) — one summary line per post: strength "Push day · 12/12 sets · 44 min"; cardio
// "Walk · 25 min" + " · 2.1 km" when a distance exists (the poster's units: kg → km, lb → mi; one decimal). A2 — a
// distance is stored in meters. Twin of web/src/lib/engine/session-summary-line.ts — identical names. Pure, Foundation
// only. WRITTEN — UNVERIFIED on a Mac; verified on Linux (ios/Package.swift).

import Foundation

enum SessionSummaryLine {
    // SPEC: A2 · A6 — meters → "2.1 km" (units kg) or "1.3 mi" (units lb), rounded half-up to tenths with integer
    // arithmetic so both engines print the same digit on an exact half (2250 m → 2.3 km)
    static func distanceText(distanceMeters: Int, units: String) -> String {
        let metric = units == "kg"
        let metersPerUnit = metric ? Double(SpecConstants.metersPerKilometer) : SpecConstants.metersPerMile
        let tenths = Int((Double(distanceMeters) / metersPerUnit * Double(SpecConstants.distanceDecimalScale)).rounded())
        let whole = tenths / SpecConstants.distanceDecimalScale
        let fraction = tenths % SpecConstants.distanceDecimalScale
        return "\(whole).\(fraction) \(metric ? "km" : "mi")"
    }

    // SPEC: A6 — sessionSummaryLine(workoutName, isCardio, setsDone, setsPlanned, minutes, cardioMinutes, distanceMeters,
    // units): a strength session reads sets and wall-clock minutes; a cardio log reads its logged minutes (the session's
    // own minutes when none were logged) and, when known, the distance
    static func sessionSummaryLine(workoutName: String, isCardio: Bool, setsDone: Int, setsPlanned: Int, minutes: Int, cardioMinutes: Int?, distanceMeters: Int?, units: String) -> String {
        if !isCardio { return "\(workoutName) · \(setsDone)/\(setsPlanned) sets · \(minutes) min" }
        let line = "\(workoutName) · \(cardioMinutes ?? minutes) min"
        guard let distanceMeters else { return line }
        return "\(line) · \(distanceText(distanceMeters: distanceMeters, units: units))"
    }
}
