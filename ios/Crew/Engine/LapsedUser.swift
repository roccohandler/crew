// SPEC: E4 / S18 — 14+ quiet days → one warm screen ("Your record still stands" → Keep my plan · Rebuild), no guilt recap, ever ·
// S01 — a stale (> a day) in-progress session triggers the stale-session prompt. Pure twin of web lib/lapsed-user.ts.
// WRITTEN — UNVERIFIED (needs Mac). T042

import Foundation

enum LapsedUser {
    static func quietDays(lastActivityDay: String, today: String) -> Int {
        max(0, DayKey.daysBetween(lastActivityDay, today))
    }

    // GAP: "quiet" = no post of any kind (a completed workout always leaves a workout post). A user with no post yet is on the
    // bridge, never lapsed. The choice is remembered per quiet spell: an acknowledgement dated after the last activity silences
    // the screen until the user is active again and then goes quiet for another 14 days.
    static func shouldShowWelcomeBack(lastActivityDay: String?, ackDay: String?, today: String) -> Bool {
        guard let lastActivityDay else { return false }
        guard quietDays(lastActivityDay: lastActivityDay, today: today) >= SpecConstants.lapsedUserQuietDays else { return false }
        guard let ackDay else { return true }
        return ackDay <= lastActivityDay
    }

    static func isStaleSession(startedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(startedAt) > TimeInterval(SpecConstants.staleInProgressSessionAfterHours * TimeUnits.secondsPerHour)
    }
}
