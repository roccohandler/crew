// SPEC: Appendix A 2026-09-18 A24 (1) — the tour's "demo data" is a REAL member on the CI harness, built through the real API the
// way 8.4's journeys are (C4: real things, no mocks; no fixture path inside the app): a plan that trains every day — the A26 canonical
// templates, every row loaded (so Progress has a line to draw) —, a crew with two crew-mates, six backdated workout days — the server accepts a
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

    // A26 (owner-approved 2026-09-18): the tour member trains the CANONICAL templates — the owner's own Push, Pull and Legs, the
    // brand-new 3×8 — so every toured screen shows the plan a real install gets, equipment tags and the repeated rope curl
    // included. Typed by hand, as every tour fixture is: a UI-test bundle cannot import the app's SeedCatalog.
    private func tourRows(_ rows: [(id: String, name: String, pattern: String, equipment: String)]) -> [[String: Any]] {
        rows.enumerated().map { order, row in
            ["exerciseId": row.id, "name": row.name, "pattern": row.pattern, "equipment": row.equipment, "type": "strength", "targetSets": 3, "targetReps": 8, "order": order]
        }
    }

    // A26 · A28 (d): every workout closes with its canonical mobility block (plan-templates.json mobilityBlocks), as a real install
    // does — the Home card and the Logger's checklist have holds to show (ui-reviewer, run 35440565004: no "Mobility · 3 holds" row)
    private func tourHolds(_ rows: [(id: String, name: String, seconds: Int, perSide: Bool)], after strength: Int) -> [[String: Any]] {
        rows.enumerated().map { offset, row in
            ["exerciseId": row.id, "name": row.name, "pattern": "mobility", "equipment": "bodyweight", "type": "mobility", "targetSets": 1, "targetReps": 0, "holdSeconds": row.seconds, "perSide": row.perSide, "order": strength + offset]
        }
    }

    private func tourWorkouts() -> [[String: Any]] {
        let ropeCurl = (id: "cable-rope-curl", name: "Cable Rope Biceps Curl", pattern: "biceps", equipment: "cable")
        return [
            ["name": "Push day", "kind": "push", "exercises": tourRows([
                ("barbell-bench-press", "Barbell Bench Press", "horizontalPush", "barbell"), ("cable-rope-triceps-extension", "Cable Rope Triceps Extension", "triceps", "cable"),
                ("machine-incline-press", "Machine Incline Press", "horizontalPush", "machine"), ("cable-triceps-pushdown", "Cable Bar Triceps Extension", "triceps", "cable"),
                ("machine-decline-press", "Machine Decline Press", "horizontalPush", "machine"),
            ]) + tourHolds([("doorway-pec-stretch", "Rack Pec Stretch", 60, true), ("thoracic-opener", "Thoracic Opener", 90, false), ("childs-pose", "Child's Pose", 90, false)], after: 5)],
            ["name": "Pull day", "kind": "pull", "exercises": tourRows([
                ("lat-pulldown", "Lat Pulldown", "verticalPull", "machine"), ropeCurl, ("machine-row", "Seated Machine Row", "horizontalPull", "machine"), ropeCurl,
                ("cable-face-pull", "Cable Face Pull", "rearDelt", "cable"), ropeCurl,
            ]) + tourHolds([("wall-lat-stretch", "Wall Lat Stretch", 90, false), ("cross-body-shoulder-stretch", "Cross-Body Shoulder Stretch", 60, true), ("cat-cow", "Cat-Cow", 90, false)], after: 6)],
            ["name": "Leg day", "kind": "legs", "exercises": tourRows([
                ("machine-standing-calf-raise", "Standing Calf Raise", "calf", "machine"), ("leg-press", "Leg Press", "squat", "machine"), ("leg-extension", "Leg Extension", "squat", "machine"),
                ("seated-leg-curl", "Seated Hamstring Curl", "hinge", "machine"), ("dumbbell-walking-lunge", "Dumbbell Lunge", "lunge", "dumbbell"),
            ]) + tourHolds([("couch-stretch", "Wall Hip Flexor Stretch", 90, true), ("pigeon-stretch", "Pigeon Stretch", 60, true), ("wall-calf-stretch", "Wall Calf Stretch", 45, true)], after: 5)],
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
        let strengthRows = (workout["exercises"] as? [[String: Any]] ?? []).filter { ($0["type"] as? String) == "strength" } // the logged history is lifts
        let rows = strengthRows.map { row -> [String: Any] in
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
