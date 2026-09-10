// SPEC: 5.6.2 HomeModel state types — enum TodayState { bridge · workout · rest · paused · allDone } (S07: all five states,
// the bridge until the first post, 1D) and the crew strip's MemberDot (Flow 10: the strip is absent, not empty, for solo).
// A2: a workout state knows whether its workout carries a cardio block. A3 (owner-directed 2026-09-08): the paused day is a
// DayLabel, never raw ISO. Split from HomeModel.swift for the C9 cap. WRITTEN — UNVERIFIED (needs Mac). T024

import Foundation

enum BridgeKind: Equatable {
    case workout, rest
}

enum TodayState: Equatable {
    case bridge(BridgeKind)
    // A2: "+ cardio" when the workout carries a cardio block. A14: `lines` is the day's ACTUAL work (HomeLines) and `tail`
    // the mobility/cardio summary — the card shows what you are doing, not how big it is; the count line stays but drops
    // to a whisper (the identity line outranks it).
    case workout(name: String, exerciseCount: Int, hasCardio: Bool, lines: [HomeLine], tail: String?)
    case rest(posted: Bool)
    case paused(until: String)                                        // A3: a DayLabel ("Sat Sep 12"), never raw ISO
    case allDone
}

struct MemberDot: Equatable, Identifiable, Codable {
    let id: String
    let displayName: String
    var profilePhotoKey: String? = nil // E1/A7: the member's picture when set; an older snapshot without the key decodes as nil
    let streak: Int
    let postedToday: Bool
    let paused: Bool
}
