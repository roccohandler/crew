// SPEC: Flow 4 time-smart tags · Decision Registry G10 boundaries. Twin of meal-tag.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum MealTag: String, CaseIterable, Codable {
    case breakfast, lunch, dinner, snack

    var emoji: String {
        switch self {
        case .breakfast: return "🍳"
        case .lunch: return "🥗"
        case .dinner: return "🍽"
        case .snack: return "🥤"
        }
    }

    static func tagFor(minuteOfDay: Int) -> MealTag {
        if minuteOfDay >= SpecConstants.mealTagBreakfastFromMinute && minuteOfDay < SpecConstants.mealTagLunchFromMinute { return .breakfast }
        if minuteOfDay >= SpecConstants.mealTagLunchFromMinute && minuteOfDay < SpecConstants.mealTagDinnerFromMinute { return .lunch }
        if minuteOfDay >= SpecConstants.mealTagDinnerFromMinute && minuteOfDay < SpecConstants.mealTagDinnerUntilMinute { return .dinner }
        return .snack
    }

    static func tagFor(date: Date, timeZone: TimeZone = .current) -> MealTag {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return tagFor(minuteOfDay: (components.hour ?? 0) * TimeUnits.minutesPerHour + (components.minute ?? 0))
    }
}
