// SPEC: docs/api.md Nutrition (nutrition addendum §2, RATIFIED 2026-09-18) — the phone READS nutrition through four GETs (a pull,
// NutritionHydrate) and WRITES it through the queue (5.6.3: putNutritionTargets · upsertSavedMeal · deleteSavedMeal · putDayTemplate ·
// createMealLog · deleteMealLog — the payload structs below mirror lib/validate-nutrition.ts 1:1 by name). Two calls are network-only,
// like endPause: Settings' "Delete my nutrition data" (DELETE nutrition/targets { everything }) and the once-only birth year (PATCH
// users/me, ApiSettings). Behind the 18+ gate the server answers 404 (under 18: the surface does not exist) or birthYearRequired.
// Names identical to web/src/lib/api-client-nutrition.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct NutritionTargetsDTO: Codable, Equatable {
    let bodyweight: Double        // in `unit`, to one decimal
    let unit: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let source: String
    let updatedAt: Date
}

struct NutritionTargetsReplyDTO: Codable {
    let targets: NutritionTargetsDTO?
}

struct SavedMealSourceDTO: Codable, Equatable {
    let kind: String              // manual | seed
    let chainId: String?
    let itemId: String?
}

struct SavedMealDTO: Codable, Equatable {
    let id: String
    let clientId: String
    let name: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let source: SavedMealSourceDTO
    let createdAt: Date
}

struct SavedMealListDTO: Codable {
    let items: [SavedMealDTO]
}

struct TemplateSlotDTO: Codable, Equatable {
    let savedMealId: String       // the server id; `meal.clientId` is what the phone keys by
    let label: String
    let meal: SavedMealDTO
}

struct DayTemplateDTO: Codable {
    let slots: [TemplateSlotDTO]
}

struct MealLogDTO: Codable, Equatable {
    let id: String
    let clientId: String
    let dayKey: String
    let savedMealId: String?      // the server id of the meal it copied, when there was one
    let name: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let quickAdd: Bool
    let createdAt: Date
}

struct MealLogListDTO: Codable {
    let items: [MealLogDTO]
}

// MARK: Queue payloads (5.6.3) — what each op carries, as the server's validators read it

// All three grams (the user overwrote them → manual) or none (derive from the bodyweight → derived; this is also "Recalculate")
struct PutTargetsPayload: Codable, Equatable {
    let bodyweight: Double
    let unit: String
    var proteinG: Int? = nil
    var carbsG: Int? = nil
    var fatG: Int? = nil
}

struct SavedMealSeedDTO: Codable, Equatable {
    let chainId: String
    let itemId: String
}

struct UpsertSavedMealPayload: Codable, Equatable {
    let clientId: String
    let name: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    var seed: SavedMealSeedDTO? = nil
}

struct NutritionIdPayload: Codable, Equatable {
    let id: String                // the clientId the row was created with (the server accepts either id)
}

struct PutTemplatePayload: Codable, Equatable {
    let slots: [TemplateSlotFacts]
}

struct CreateMealLogPayload: Codable, Equatable {
    let clientId: String
    let timezone: String
    var savedMealId: String? = nil
    let name: String
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let quickAdd: Bool
    let createdAt: Date
}

struct DeleteNutritionRequestDTO: Codable {
    let everything: Bool
}

extension Api {
    func nutritionTargets() async throws -> NutritionTargetsReplyDTO { try await send("GET", "nutrition/targets") }
    func savedMeals() async throws -> SavedMealListDTO { try await send("GET", "nutrition/saved-meals") }
    func dayTemplate() async throws -> DayTemplateDTO { try await send("GET", "nutrition/template") }
    func mealLogs(dayKey: String) async throws -> MealLogListDTO { try await send("GET", "nutrition/logs", query: [URLQueryItem(name: "dayKey", value: dayKey)]) }
    // SPEC: §4 Settings "Delete my nutrition data" — network-only, like endPause: there is no op for it (R-074 (8))
    func deleteNutritionData() async throws -> OkDTO { try await send("DELETE", "nutrition/targets", body: DeleteNutritionRequestDTO(everything: true)) }
}
