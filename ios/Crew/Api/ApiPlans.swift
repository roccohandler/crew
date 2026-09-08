// SPEC: docs/api.md plans (GET · PUT replace, forward-only) + crews/join preview (the invite-aware hero, 1A).
// DTOs mirror lib/validate-plans.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct PlanDTO: Codable, Equatable {
    let workouts: [PlanDraftWorkout]
    let updatedAt: Date?
}

struct PutPlanRequestDTO: Codable {
    let workouts: [PlanDraftWorkout]
}

struct CrewPreviewDTO: Codable, Equatable {
    let name: String
    let emoji: String
    let memberCount: Int
    let full: Bool
}

struct JoinCrewRequestDTO: Codable {
    let token: String
}

struct JoinCrewResponseDTO: Codable {
    let crewId: String
    let name: String
    let emoji: String
}

extension Api {
    func getPlan() async throws -> PlanDTO {
        try await send("GET", "plans")
    }

    func putPlan(_ draft: PlanDraft) async throws -> PlanDTO {
        try await send("PUT", "plans", body: PutPlanRequestDTO(workouts: draft.workouts))
    }

    func crewPreview(token: String) async throws -> CrewPreviewDTO {
        try await send("GET", "crews/join", query: [URLQueryItem(name: "token", value: token)], authenticated: false)
    }

    func joinCrew(token: String) async throws -> JoinCrewResponseDTO {
        try await send("POST", "crews/join", body: JoinCrewRequestDTO(token: token))
    }
}
