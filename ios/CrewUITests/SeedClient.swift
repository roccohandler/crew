// SPEC: 8.4 journey ② needs a returning member: a signed-in account with a plan for today, a first post (the bridge is gone), a
// crew, and a crew-mate who reacts. The test bundle builds all of it through the real API on the local server (web:
// `node tests/e2e/dev-server.mjs` — in-memory Mongo + next dev on :3000, the harness Playwright uses), hands the member's
// session to the app (CREW_SEED_SESSION), and reacts as the crew-mate mid-test. URLSession only; nothing is shared with the
// app target. A1 (2026-09-08): the plan is trainingWeekdays plus the Push · Pull · Legs rotation, no weekday on a workout.
// WRITTEN — UNVERIFIED (needs Mac + simulator). T035

import Foundation

struct SeedSession {
    let json: String          // the register reply exactly as the app decodes it (AuthSessionDTO)
    let accessToken: String
    let userId: String
}

enum SeedError: Error {
    case unexpected(String)
}

struct SeedClient {
    let baseURL = URL(string: ProcessInfo.processInfo.environment["CREW_API_BASE_URL"] ?? "http://localhost:3000/api/v1")!
    private static var ipCounter = 0

    // The G11 auth limiter is 10 req/min per IP; every call arrives from its own address, as Vercel would set it
    private static func freshIp() -> String {
        ipCounter += 1
        return "203.0.113.\((ipCounter + Int(ProcessInfo.processInfo.processIdentifier)) % 250)"
    }

    func register(name: String) async throws -> SeedSession {
        let email = "\(name.lowercased().replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 0..<1_000_000))@example.com"
        let body: [String: Any] = ["email": email, "password": "journey password 1", "displayName": name, "timezone": TimeZone.current.identifier, "eulaAccepted": true, "birthYear": 1993]
        let (data, status) = try await call("POST", "auth/register", body: body, token: nil)
        guard status == 201, let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any], let token = reply["accessToken"] as? String,
              let user = reply["user"] as? [String: Any], let id = user["id"] as? String else { throw SeedError.unexpected("register → \(status) \(String(decoding: data, as: UTF8.self).prefix(300))") }
        return SeedSession(json: String(decoding: data, as: UTF8.self), accessToken: token, userId: id)
    }

    // Every weekday is a training day, so the journey never depends on the day it runs (1B's Mon/Wed/Fri would); the rotation
    // (A1) puts Push day first on a fresh account — the workout journey ② starts (putPlanSchema: trainingWeekdays + workouts by kind)
    func putPlanForEveryDay(as session: SeedSession) async throws {
        func row(_ id: String, _ name: String, _ pattern: String) -> [String: Any] {
            ["exerciseId": id, "name": name, "pattern": pattern, "equipment": "bodyweight", "type": "strength", "targetSets": 3, "targetReps": 10, "order": 0]
        }
        let workouts: [[String: Any]] = [
            ["name": "Push day", "kind": "push", "exercises": [row("push-up", "Push-Up", "horizontalPush")]],
            ["name": "Pull day", "kind": "pull", "exercises": [row("inverted-row", "Inverted Row", "horizontalPull")]],
            ["name": "Leg day", "kind": "legs", "exercises": [row("bodyweight-squat", "Bodyweight Squat", "squat")]],
        ]
        let (_, status) = try await call("PUT", "plans", body: ["trainingWeekdays": Array(1...7), "workouts": workouts], token: session.accessToken)
        guard status == 200 else { throw SeedError.unexpected("plans → \(status)") }
    }

    // The first flame: yesterday's member has posted before (1D — the bridge is gone for good)
    func postMeal(as session: SeedSession) async throws {
        let body: [String: Any] = ["clientId": UUID().uuidString.lowercased(), "type": "meal", "caption": "overnight oats", "shareToCrew": true, "timezone": TimeZone.current.identifier, "isPlannedDay": true]
        let (_, status) = try await call("POST", "posts", body: body, token: session.accessToken)
        guard status == 201 else { throw SeedError.unexpected("posts → \(status)") }
    }

    // SPEC: A18 / J034 — the seeds Home's four non-bridge states need, so CI can PHOTOGRAPH each one. Before this the
    // only non-bridge Home any test ever rendered was a workout day (journey ②, whose member trains every day) and a
    // rest day that asserted one string's absence. The owner reported a rest day; nothing in CI had ever looked at it.

    // A plan with ONE training day, chosen relative to today, so a state is deterministic on any day of the week.
    // `offsetFromToday` 0 → today trains (workout / all-done); 1 → tomorrow trains (today is a rest day).
    func putPlan(oneTrainingDayOffsetFromToday offset: Int, as session: SeedSession) async throws {
        let weekday = (Calendar.current.component(.weekday, from: Date().addingTimeInterval(TimeInterval(offset * 86_400))) + 5) % 7 + 1 // Foundation Sun=1 → ISO Mon=1
        let workouts: [[String: Any]] = [
            ["name": "Push day", "kind": "push", "exercises": [["exerciseId": "push-up", "name": "Push-Up", "pattern": "horizontalPush", "equipment": "bodyweight", "type": "strength", "targetSets": 3, "targetReps": 10, "order": 0]]],
            ["name": "Pull day", "kind": "pull", "exercises": [["exerciseId": "inverted-row", "name": "Inverted Row", "pattern": "horizontalPull", "equipment": "bodyweight", "type": "strength", "targetSets": 3, "targetReps": 10, "order": 0]]],
            ["name": "Leg day", "kind": "legs", "exercises": [["exerciseId": "bodyweight-squat", "name": "Bodyweight Squat", "pattern": "squat", "equipment": "bodyweight", "type": "strength", "targetSets": 3, "targetReps": 10, "order": 0]]],
        ]
        let (_, status) = try await call("PUT", "plans", body: ["trainingWeekdays": [weekday], "workouts": workouts], token: session.accessToken)
        guard status == 200 else { throw SeedError.unexpected("plans → \(status)") }
    }

    // Flow 7 — a live pause, so Home renders `.paused`. Never retroactive: it starts today (pause-validation.ts).
    func pause(untilDaysFromNow days: Int, as session: SeedSession) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let body: [String: Any] = ["startDay": formatter.string(from: Date()), "endDay": formatter.string(from: Date().addingTimeInterval(TimeInterval(days * 86_400))), "timezone": TimeZone.current.identifier]
        let (_, status) = try await call("POST", "pause", body: body, token: session.accessToken)
        guard status == 201 || status == 200 else { throw SeedError.unexpected("pause → \(status)") }
    }

    func createCrew(as session: SeedSession) async throws -> (id: String, token: String) {
        let (data, status) = try await call("POST", "crews", body: ["name": "Night Shift", "emoji": "🌙"], token: session.accessToken)
        guard status == 201, let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any], let crew = reply["crew"] as? [String: Any],
              let id = crew["id"] as? String, let link = crew["inviteLink"] as? String, let token = link.components(separatedBy: "/join/").last else { throw SeedError.unexpected("crews → \(status)") }
        return (id, token)
    }

    func join(token: String, as session: SeedSession) async throws {
        let (_, status) = try await call("POST", "crews/join", body: ["token": token], token: session.accessToken)
        guard status == 201 else { throw SeedError.unexpected("join → \(status)") }
    }

    // The crew-mate's side of journey ②: wait for the member's workout to drop into the stream (the phone's queue sends it), then react
    func reactToTheWorkoutPost(crewId: String, emoji: String, as session: SeedSession, attempts: Int = 30) async throws {
        for _ in 0..<attempts {
            let (data, status) = try await call("GET", "crews/\(crewId)/stream", body: nil, token: session.accessToken)
            if status == 200, let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any], let items = reply["items"] as? [[String: Any]],
               let post = items.compactMap({ $0["post"] as? [String: Any] }).first(where: { $0["type"] as? String == "workout" }), let postId = post["id"] as? String {
                let (_, reacted) = try await call("POST", "posts/\(postId)/reactions", body: ["emoji": emoji], token: session.accessToken)
                guard reacted == 200 else { throw SeedError.unexpected("react → \(reacted)") }
                return
            }
            try await Task.sleep(for: .seconds(1))
        }
        throw SeedError.unexpected("no workout post reached the stream")
    }

    private func call(_ method: String, _ path: String, body: [String: Any]?, token: String?) async throws -> (Data, Int) {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("ios", forHTTPHeaderField: "X-Crew-Client")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.freshIp(), forHTTPHeaderField: "x-forwarded-for")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}
