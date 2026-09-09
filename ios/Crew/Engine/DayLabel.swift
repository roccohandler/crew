// SPEC: A6 (owner-directed 2026-09-08) — readable day labels: Today · Yesterday · a weekday name up to
// dayLabelWeekdayWithinDays back · Mon Sep 8 · Mon Sep 8, 2025; week headers This week · Last week · Week of Sep 1.
// The English names live here (the app ships in English). Twin of web/src/lib/engine/day-label.ts — identical names.
// Pure, Foundation only. WRITTEN — UNVERIFIED on a Mac; verified on Linux (ios/Package.swift).

import Foundation

enum DayLabel {
    static let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    static let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    // "Sep 8" — no leading zero
    private static func monthDay(_ dayKey: String) -> String {
        let parts = DayKey.utcParts(dayKey)
        let month = parts.month >= 1 && parts.month <= monthNames.count ? monthNames[parts.month - 1] : ""
        return "\(month) \(parts.day)"
    }

    // SPEC: A6 — dayLabel(dayKey, todayKey): same → Today; yesterday → Yesterday; within dayLabelWeekdayWithinDays back →
    // weekday name; same year → Mon Sep 8; else Mon Sep 8, 2025 (a future day, e.g. a pause's return day, reads as a date)
    static func dayLabel(_ dayKey: String, todayKey: String) -> String {
        let daysBack = DayKey.daysBetween(dayKey, todayKey)
        if daysBack == 0 { return "Today" }
        if daysBack == 1 { return "Yesterday" }
        let weekday = weekdayNames[DayKey.isoWeekday(dayKey) - 1]
        if daysBack > 1 && daysBack <= SpecConstants.dayLabelWeekdayWithinDays { return weekday }
        let year = DayKey.utcParts(dayKey).year
        return year == DayKey.utcParts(todayKey).year ? "\(weekday) \(monthDay(dayKey))" : "\(weekday) \(monthDay(dayKey)), \(year)"
    }

    // SPEC: A6 — weekHeader(weekKey, todayWeekKey): This week · Last week · Week of Sep 1
    static func weekHeader(_ weekKey: String, todayWeekKey: String) -> String {
        if weekKey == todayWeekKey { return "This week" }
        if DayKey.addDays(weekKey, TimeUnits.daysPerWeek) == todayWeekKey { return "Last week" }
        return "Week of \(monthDay(weekKey))"
    }
}
