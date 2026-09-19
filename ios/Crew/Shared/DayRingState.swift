// SPEC: 5.6.2 HomeModel.weeklyRing: [DayRingState] — the state of each day of the week, as HomeModel judges it (A17.4 · A18.7 ·
// A27 (a)). A28 R3 (2026-09-19): the legacy WeeklyRing VIEW left with Progress's ring history (the heat map's rows are the weeks
// now — system §11, one fact, one rendering); Home draws the system's FocusRing. The state stays: HomeModel and its tests read it.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

// A String raw value so the WeekSummary twin can take `[String]` and stay byte-identical to the TypeScript side,
// which has no enum to share. `rawValue` is the contract: "done" | "missed" | "rest" | "today" | "nextUp" | "upcoming".
enum DayRingState: String, Equatable {
    case done          // planned workout completed
    case missed        // planned, not done, day over — never red
    case rest          // no workout planned
    case today         // the open day
    case nextUp        // A17.4: the NEXT planned training day — the one question a rest day actually raises
    case upcoming      // a planned day after that one
}
