// The one Swift file that names time units and calendar constants (the web twin is lib/time-units.ts). Not spec
// numbers, so not in spec-constants.json; exempt from the doctrine literal scan by name. WRITTEN — UNVERIFIED.

import Foundation

enum TimeUnits {
    static let msPerSecond = 1000
    static let secondsPerMinute = 60
    static let minutesPerHour = 60
    static let secondsPerHour = 3600
    static let hoursPerDay = 24
    static let secondsPerDay = 86_400
    static let daysPerWeek = 7
    static let gregorianSunday = 1   // Calendar.Component.weekday numbering
    static let gregorianMonday = 2
}
