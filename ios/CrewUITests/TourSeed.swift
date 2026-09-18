// SPEC: Appendix A 2026-09-18 A24 (1) — the tour's "demo data" is a REAL member on the CI harness, built through the real API the
// way 8.4's journeys are (C4: real things, no mocks; no fixture path inside the app): a plan that trains every day with loaded
// barbell work (so Progress has a line to draw), a crew with two crew-mates, six backdated workout days — the server accepts a
// client instant up to syncClientTimestampMaxAgeDays back (web/src/lib/server-clock.ts) — and today left OPEN, so Home shows a
// streak AND a workout to start. Macros are not seeded: "Log macros" is W8.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import Foundation

struct TourCast {
    let member: SeedSession
    let crewId: String
}

extension SeedClient {
    private static let secondsPerDay: TimeInterval = 86_400
    private static let seededDays = 6 // inside the 7-day reconciliation window, with a day to spare for a run that straddles midnight

    private func tourRow(_ id: String, _ name: String, _ pattern: String, _ order: Int) -> [String: Any] {
        ["exerciseId": id, "name": name, "pattern": pattern, "equipment": "barbell", "type": "strength", "targetSets": 3, "targetReps": 8, "order": order]
    }

    private func tourWorkouts() -> [[String: Any]] {
        [
            ["name": "Push day", "kind": "push", "exercises": [tourRow("barbell-bench-press", "Barbell Bench Press", "horizontalPush", 0), tourRow("barbell-overhead-press", "Barbell Overhead Press", "verticalPush", 1)]],
            ["name": "Pull day", "kind": "pull", "exercises": [tourRow("barbell-row", "Barbell Row", "horizontalPull", 0), tourRow("lat-pulldown", "Lat Pulldown", "verticalPull", 1)]],
            ["name": "Leg day", "kind": "legs", "exercises": [tourRow("barbell-back-squat", "Barbell Back Squat", "squat", 0), tourRow("barbell-romanian-deadlift", "Barbell Romanian Deadlift", "hinge", 1)]],
        ]
    }

    func putTourPlan(as session: SeedSession) async throws {
        let (_, status) = try await call("PUT", "plans", body: ["trainingWeekdays": Array(1...7), "workouts": tourWorkouts()], token: session.accessToken)
        guard status == 200 else { throw SeedError.unexpected("tour plans → \(status)") }
    }

    // One completed, posted workout `daysAgo` days back; the load climbs a little each day so the chart has a slope
    // The instant carries MILLISECONDS. ISO8601DateFormatter's default drops them, and a whole-second instant taken in the same second
    // as the crew's creation sorts BEFORE it — crew-stream.ts is join-forward, so the viewer never sees that post. It cost the tour a
    // crew-mate's card in the approved baseline (Sam's was never there) and both cards in run 35340692297 — and with them the React step.
    func logTourWorkout(daysAgo: Int, as session: SeedSession) async throws {
        let stamp = ISO8601DateFormatter()
        stamp.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let instant = stamp.string(from: Date().addingTimeInterval(-TimeInterval(daysAgo) * Self.secondsPerDay))
        let workout = tourWorkouts()[(Self.seededDays - daysAgo) % 3]
        let load = Double(135 + (Self.seededDays - daysAgo) * 5)
        let rows = (workout["exercises"] as? [[String: Any]] ?? []).map { row -> [String: Any] in
            let set: [String: Any] = ["targetReps": 8, "actualReps": 8, "weight": load, "weightUnit": "lb", "holdSeconds": NSNull(), "distanceMeters": NSNull(), "isWarmup": false, "done": true]
            var exercise = row
            exercise.removeValue(forKey: "pattern")
            exercise["sets"] = [set, set, set]
            return exercise
        }
        let snapshot: [String: Any] = ["name": workout["name"] ?? "Push day", "kind": workout["kind"] ?? "push", "isPlannedDay": true, "exercises": rows]
        let (data, status) = try await call("POST", "sessions", body: ["clientId": UUID().uuidString.lowercased(), "timezone": TimeZone.current.identifier, "startedAt": instant, "workoutSnapshot": snapshot], token: session.accessToken)
        guard status == 201, let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any], let created = reply["session"] as? [String: Any], let id = created["id"] as? String else { throw SeedError.unexpected("tour sessions → \(status) \(String(decoding: data, as: UTF8.self).prefix(200))") }
        let post: [String: Any] = ["clientId": UUID().uuidString.lowercased(), "shareToCrew": true]
        let (_, done) = try await call("PATCH", "sessions/\(id)", body: ["timezone": TimeZone.current.identifier, "status": "completed", "completedAt": instant, "post": post], token: session.accessToken)
        guard done == 200 else { throw SeedError.unexpected("tour sessions/\(id) → \(done)") }
    }

    // The whole cast. The crew and its joins come FIRST: the stream is join-forward (crew-stream.ts), so a post made before the
    // membership would never reach the Crew tab.
    func seedTourMember() async throws -> TourCast {
        let member = try await register(name: "Maya Tour")
        try await putTourPlan(as: member)
        let crew = try await createCrew(as: member)
        for name in ["Sam", "Priya"] {
            let mate = try await register(name: name)
            try await putTourPlan(as: mate)
            try await join(token: crew.token, as: mate)
            try await logTourWorkout(daysAgo: 0, as: mate) // the crew-mates have trained today; the member has not yet
        }
        for daysAgo in stride(from: Self.seededDays, through: 1, by: -1) { try await logTourWorkout(daysAgo: daysAgo, as: member) }
        return TourCast(member: member, crewId: crew.id)
    }
}
