// SPEC: docs/api.md sessions + the sync op payloads (createSession · patchSession · createPost) — DTOs mirror
// lib/validate-sessions.ts and lib/validate-posts.ts 1:1. WRITTEN — UNVERIFIED (needs Mac). T024–T027

import Foundation

struct SetLogDTO: Codable, Equatable {
    var targetReps: Int
    var actualReps: Int
    var weight: Double?
    var holdSeconds: Int?
    var isWarmup: Bool
    var done: Bool
}

struct SessionExerciseDTO: Codable, Equatable {
    var exerciseId: String
    var name: String
    var equipment: String
    var type: String
    var targetSets: Int
    var targetReps: Int
    var holdSeconds: Int?
    var order: Int
    var skipped: Bool
    var sets: [SetLogDTO]
}

struct WorkoutSnapshotDTO: Codable, Equatable {
    var name: String
    var weekday: Int
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
    let caption: String?
    let photoKey: String?
}

struct PatchSessionPayload: Codable {
    let sessionId: String
    let timezone: String
    let exercises: [SessionExerciseDTO]?
    let status: String?
    let completedAt: Date?
    let post: CompletionPostDTO?
}

struct CreatePostPayload: Codable {
    let clientId: String
    let type: String
    let sessionId: String?
    let photoKey: String?
    let caption: String?
    let mealTag: String?
    let shareToCrew: Bool
    let timezone: String
    let isPlannedDay: Bool
    let workoutCompleted: Bool
    let earlierToday: Bool?
    let createdAt: Date
}

struct PostDTO: Codable, Equatable {
    let id: String
    let clientId: String?      // the id this phone (or another) created it with — hydration and deletePost address it by this
    let type: String
    let sessionId: String?
    let photoKey: String?
    let caption: String
    let mealTag: String?
    let crewId: String?
    let dayKey: String
    let isPlannedDay: Bool
    let workoutCompleted: Bool
    let earlierToday: Bool
    let createdAt: Date
}

struct PostReplyDTO: Codable {
    let post: PostDTO
    let gamification: GamificationStateDTO
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
    func createPost(_ payload: CreatePostPayload) async throws -> PostReplyDTO {
        try await send("POST", "posts", body: payload)
    }

    // The journal and the history, forever (Flow 6; Progress) — a fresh phone hydrates from them (ServerHydrate)
    func myPosts() async throws -> PostListDTO { try await send("GET", "posts") }
    func mySessions() async throws -> SessionListDTO { try await send("GET", "sessions") }
}
