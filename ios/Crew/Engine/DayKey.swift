// SPEC: E8 (the day ends 3 AM local; edge cases resolve in the user's favor) · E20 (Monday week-start) ·
// shared/vectors/README.md "Dates, days, weeks" · V05–V10. Twin of web/src/lib/engine/day-key.ts — identical names.
// Pure functions, zero imports beyond Foundation; time enters as a parameter. WRITTEN — UNVERIFIED (needs Mac). T016

import Foundation

enum DayKey {
    private static let boundarySeconds = TimeInterval(SpecConstants.dayBoundaryHour * TimeUnits.secondsPerHour)

    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func utcParts(_ dayKey: String) -> (year: Int, month: Int, day: Int) {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) } // YYYY-MM-DD → year, month, day
        return (parts.first ?? 0, parts.dropFirst().first ?? 0, parts.last ?? 0)
    }

    static func format(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    // The local calendar date of an instant in a zone
    static func localDateOf(_ instant: Date, timeZone: TimeZone) -> String {
        let components = calendar(in: timeZone).dateComponents([.year, .month, .day], from: instant)
        return format(year: components.year!, month: components.month!, day: components.day!)
    }

    // The instant of local midnight for a calendar date in a zone
    static func startOfDay(_ dayKey: String, timeZone: TimeZone) -> Date {
        let parts = utcParts(dayKey)
        var components = DateComponents()
        components.year = parts.year
        components.month = parts.month
        components.day = parts.day
        return calendar(in: timeZone).date(from: components)!
    }

    static func addDays(_ dayKey: String, _ days: Int) -> String {
        let parts = utcParts(dayKey)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let base = utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day))!
        let shifted = utc.date(byAdding: .day, value: days, to: base)!
        let components = utc.dateComponents([.year, .month, .day], from: shifted)
        return format(year: components.year!, month: components.month!, day: components.day!)
    }

    static func daysBetween(_ fromDayKey: String, _ toDayKey: String) -> Int {
        let from = startOfDay(fromDayKey, timeZone: TimeZone(identifier: "UTC")!)
        let to = startOfDay(toDayKey, timeZone: TimeZone(identifier: "UTC")!)
        return Int((to.timeIntervalSince(from) / TimeInterval(TimeUnits.secondsPerDay)).rounded())
    }

    // SPEC: E8 — dayKey(for: Date, tz: TimeZone) -> String
    static func dayKey(for instant: Date, tz timeZone: TimeZone) -> String {
        let local = localDateOf(instant, timeZone: timeZone)
        for candidate in [addDays(local, -1), local, addDays(local, 1)] {
            let dayStart = startOfDay(candidate, timeZone: timeZone).addingTimeInterval(boundarySeconds)
            let dayEnd = startOfDay(addDays(candidate, 1), timeZone: timeZone).addingTimeInterval(boundarySeconds)
            if dayStart <= instant && instant < dayEnd { return candidate }
        }
        return local
    }

    // SPEC: E20 — weekKey(for dayKey: String) -> String: the Monday of that week
    static func weekKey(for dayKey: String) -> String {
        let utc = TimeZone(identifier: "UTC")!
        let weekday = calendar(in: utc).component(.weekday, from: startOfDay(dayKey, timeZone: utc)) // 1 = Sunday … 7 = Saturday
        let daysSinceMonday = (weekday - TimeUnits.gregorianMonday + TimeUnits.daysPerWeek) % TimeUnits.daysPerWeek
        return addDays(dayKey, -daysSinceMonday)
    }

    // ISO weekday: 1 = Monday … 7 = Sunday (E20)
    static func isoWeekday(_ dayKey: String) -> Int {
        let utc = TimeZone(identifier: "UTC")!
        let weekday = calendar(in: utc).component(.weekday, from: startOfDay(dayKey, timeZone: utc))
        return weekday == TimeUnits.gregorianSunday ? TimeUnits.daysPerWeek : weekday - 1
    }
}
