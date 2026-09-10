// SPEC: A17.1 (owner-directed 2026-09-10) — the one ink sentence under Home's week strip.
//
// The owner's complaint was "I don't know what this screen is for or what the colors are for". The cause: the flame,
// the ring, the strip and the crew avatar each build a complete English sentence and render it ONLY to VoiceOver, so
// a sighted user gets a glyph, two bare numerals and seven dots. This function is that sentence, made visible.
//
// It returns BOTH forms from one pass — `short` for the eye, `spoken` for VoiceOver — because the alternative is two
// code paths that drift, and the strip's spoken label previously said something the screen did not.
//
// It names the colours IN SITU rather than in a legend: a legend is a split-attention lookup, and A16 already ratified
// "direct numeric labels, never a colour-only legend".
// Pure, and CONCRETE (C1: no generics) — the same shape the TypeScript twin takes.
// Twin of web/src/lib/engine/week-summary.ts.

import Foundation

struct WeekSummaryLines: Equatable {
    let short: String
    let spoken: String
}

enum WeekSummary {
    // Mon..Sun, matching the ISO ordering every other engine function uses. `short` duplicates DayLabel.weekdayNames
    // (C5: the second occurrence duplicates; the third extracts) and `full` is its first occurrence on this engine —
    // VoiceOver reads "Wednesday", never "Wed", because a screen reader says an abbreviation letter by letter.
    private static let short = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private static let full = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    private static func names(_ states: [String], matching match: String, from list: [String]) -> [String] {
        states.enumerated().compactMap { index, state in
            guard state == match, index < list.count else { return nil }
            return list[index]
        }
    }

    // SPEC: A17.1 — `states` is Mon..Sun: "done" | "missed" | "rest" | "today" | "nextUp" | "upcoming".
    static func weekSummary(_ states: [String]) -> WeekSummaryLines {
        let doneShort = names(states, matching: "done", from: short)
        let doneFull = names(states, matching: "done", from: full)
        let missedShort = names(states, matching: "missed", from: short)
        let missedFull = names(states, matching: "missed", from: full)
        let nextIndex = states.firstIndex(of: "nextUp")
        let todayIndex = states.firstIndex(of: "today")

        var shortParts: [String] = []
        var spokenParts: [String] = []
        if !doneShort.isEmpty {
            shortParts.append("\(doneShort.joined(separator: ", ")) done")
            spokenParts.append("\(doneFull.joined(separator: ", ")) done")
        }
        if !missedShort.isEmpty {
            shortParts.append("\(missedShort.joined(separator: ", ")) missed")
            spokenParts.append("\(missedFull.joined(separator: ", ")) missed")
        }
        // A8 — a week with nothing in it says so in words; it never renders as a zero or an empty count.
        if shortParts.isEmpty {
            shortParts.append("nothing logged yet")
            spokenParts.append("nothing logged yet")
        }
        if let todayIndex, todayIndex < full.count { spokenParts.append("today \(full[todayIndex])") }
        if let nextIndex, nextIndex < full.count {
            shortParts.append("next \(short[nextIndex])")
            spokenParts.append("next workout \(full[nextIndex])")
        }
        return WeekSummaryLines(short: "This week: \(shortParts.joined(separator: " · "))",
                                spoken: "This week: \(spokenParts.joined(separator: ", ")).")
    }
}
