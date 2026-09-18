// SPEC: docs/api.md sessions + the sync op payloads (createSession · patchSession; A22: createPost is retired) — DTOs mirror
// lib/validate-sessions.ts and lib/validate-posts.ts 1:1. A1 (2026-09-08): the snapshot names its plan kind; A2: a cardio set
// carries an optional distance; A6: a workout post carries the server-written summary line. WRITTEN — UNVERIFIED (needs Mac).
// T024–T027

import Foundation

struct SetLogDTO: Codable, Equatable {
    var targetReps: Int
    var actualReps: Int
    var weight: Double?
    var holdSeconds: Int?
    var distanceMeters: Int?   // A2: cardio only, optional; nil elsewhere (absent on the wire — Codable omits a nil)
    var weightUnit: String?    // A9: the unit this weight was ENTERED in; absent on a row written before the split
    var isWarmup: Bool
    var done: Bool
}

struct SessionExerciseDTO: Codable, Equatable {
    var exerciseId: String
    var name: String
    var equipment: String
    var type: String           // strength | mobility | cardio (A2)
    var targetSets: Int
    var targetReps: Int
    var holdSeconds: Int?
    var order: Int
    var skipped: Bool
    var sets: [SetLogDTO]
}

// A1: `kind` is the plan kind the session runs ("cardio" for a standalone log, A2); the server no longer needs a weekday
struct WorkoutSnapshotDTO: Codable, Equatable {
    var name: String
    var kind: String?
    var isPlannedDay: Bool
    var exercises: [SessionExerciseDTO]
}

struct CreateSessionPayload: Codable {
    let clientId: String
    let timezone: String
    let startedAt: Date
    let workoutSnapshot: WorkoutSnapshotDTO
}

struct CompletionPostDTO: Codable {
    let clientId: String
    let shareToCrew: Bool
    let caption: String?   // A22 G2: the optional line is the one thing a workout post carries — no photo
}

struct PatchSessionPayload: Codable {
    let sessionId: String
    let timezone: String
    let exercises: [SessionExerciseDTO]?
    let status: String?
    let completedAt: Date?
    let post: CompletionPostDTO?
}

// A22 (2026-09-18): no photoKey, no mealTag, no earlierToday — the plate journal is gone (posts.ts PostResponse)
struct PostDTO: Codable, Equatable {
    let id: String
    let clientId: String?      // the id this phone (or another) created it with — hydration and deletePost address it by this
    let type: String           // workout | cardio (a legacy meal or text row reads by its caption)
    let sessionId: String?
    let caption: String
    let crewId: String?
    let dayKey: String
    let isPlannedDay: Bool
    let workoutCompleted: Bool
    let summary: String?       // A6: the one readable line the server wrote at workout completion
    let createdAt: Date
}

struct PostListDTO: Codable {
    let items: [PostDTO]
}

// docs/api.md GET sessions — a session as the server holds it (sessionResponse): the snapshot plus its set logs
struct SessionDTO: Codable {
    let id: String
    let clientId: String
    let dayKey: String
    let status: String
    let workoutName: String
    let workoutKind: String?   // A1: the plan kind the snapshot ran; "cardio" for a log (A2); nil on legacy rows
    let isPlannedDay: Bool
    let startedAt: Date
    let completedAt: Date?
    let timezone: String
    let exercises: [SessionExerciseDTO]
    let updatedAt: Date
}

struct SessionListDTO: Codable {
    let items: [SessionDTO]
}

extension Api {
    // The journal and the history, forever (Flow 6; Progress) — a fresh phone hydrates from them (ServerHydrate)
    func myPosts() async throws -> PostListDTO { try await send("GET", "posts") }
    func mySessions() async throws -> SessionListDTO { try await send("GET", "sessions") }
}
