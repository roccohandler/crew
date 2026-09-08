// SPEC: V37 (pulse) · V38 (weekly crew ring restarts Monday) · V39 (comeback banner) · V40 (membership as of each day).
// Twin of crew-rules.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct MemberFacts: Codable, Equatable {
    let userId: String
    let joinedDayKey: String
    let leftDayKey: String?
}

struct MemberPostFacts: Codable, Equatable {
    let userId: String
    let dayKey: String
}

struct Pulse: Codable, Equatable {
    let posted: Int
    let total: Int
}

struct DayPulse: Codable, Equatable {
    let dayKey: String
    let posted: Int
    let total: Int
}

enum CrewRules {
    static func memberOn(_ member: MemberFacts, dayKey: String) -> Bool {
        member.joinedDayKey <= dayKey && (member.leftDayKey == nil || member.leftDayKey! > dayKey)
    }

    static func crewPulse(members: [MemberFacts], posts: [MemberPostFacts], dayKey: String) -> Pulse {
        let present = members.filter { memberOn($0, dayKey: dayKey) }
        let ids = Set(present.map(\.userId))
        let posted = Set(posts.filter { ids.contains($0.userId) && $0.dayKey == dayKey }.map(\.userId))
        return Pulse(posted: posted.count, total: present.count)
    }

    static func crewWeeklyRing(members: [MemberFacts], posts: [MemberPostFacts], asOfDayKey: String) -> [DayPulse] {
        var ring: [DayPulse] = []
        var day = DayKey.weekKey(for: asOfDayKey)
        while day <= asOfDayKey {
            let pulse = crewPulse(members: members, posts: posts, dayKey: day)
            ring.append(DayPulse(dayKey: day, posted: pulse.posted, total: pulse.total))
            day = DayKey.addDays(day, 1)
        }
        return ring
    }

    // README kind achievements: days in [fromDay, toDay] on which the pulse was full with at least crewMinMembers present
    static func fullPulseDays(members: [MemberFacts], posts: [MemberPostFacts], fromDay: String, toDay: String) -> Int {
        var count = 0
        var day = fromDay
        while day <= toDay {
            let pulse = crewPulse(members: members, posts: posts, dayKey: day)
            if pulse.total >= SpecConstants.crewMinMembers, pulse.posted == pulse.total { count += 1 }
            day = DayKey.addDays(day, 1)
        }
        return count
    }

    // Complete Mon–Sun weeks (Monday ≥ fromDay, Sunday ≤ toDay) whose seven days were all full
    static func fullPulseWeeks(members: [MemberFacts], posts: [MemberPostFacts], fromDay: String, toDay: String) -> Int {
        var count = 0
        var monday = DayKey.weekKey(for: fromDay)
        if monday < fromDay { monday = DayKey.addDays(monday, TimeUnits.daysPerWeek) }
        while DayKey.addDays(monday, TimeUnits.daysPerWeek - 1) <= toDay {
            if fullPulseDays(members: members, posts: posts, fromDay: monday, toDay: DayKey.addDays(monday, TimeUnits.daysPerWeek - 1)) == TimeUnits.daysPerWeek { count += 1 }
            monday = DayKey.addDays(monday, TimeUnits.daysPerWeek)
        }
        return count
    }

    // One member's posts in order → which of them carry the COMEBACK banner (once per return, never the first post)
    static func comebackBanner(postDayKeys: [String], pauses: [Pause]) -> [Bool] {
        var previous: String?
        return postDayKeys.map { dayKey in
            var banner = false
            if let last = previous, dayKey != last {
                banner = GamificationPost.quietDaysBetween(last, dayKey, pauses: pauses) >= SpecConstants.comebackMissedDaysThreshold
            }
            previous = dayKey
            return banner
        }
    }
}
