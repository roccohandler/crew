// SPEC: A9 (owner-directed 2026-09-09) — the device's own measurement system, sent once at signup so the first unit
// defaults are right for this phone instead of a hard-coded "lb". iOS 16+ reports it as Locale.MeasurementSystem, and it
// already honours the user's own override in Settings → General → Language & Region → Measurement System, so this is the
// user's stated preference rather than a guess from their country. `.uk` is the case the single old `units` field could
// never express: metric plates, imperial roads. The value is only a DEFAULT — the user confirms it in context on their
// first Session screen and can change either half in Settings forever after. Twin rule: unitsForMeasurementSystem in
// web/src/lib/users.ts.
//
// It lives in Api/ and NOT in Engine/ on purpose: Locale.measurementSystem is a Darwin API (iOS 16+), and Engine/ is
// compiled by ios/Package.swift on Linux so the twin engine and its vectors can run without a Mac. A platform lookup
// belongs on the API side of that line.

import Foundation

enum MeasurementSystemHint {
    // The three names the server's zod schema accepts, spelled exactly as Locale.MeasurementSystem spells them
    static func current(_ locale: Locale = .current) -> String {
        switch locale.measurementSystem {
        case .us: return "us"
        case .uk: return "uk"
        default: return "metric"
        }
    }
}
