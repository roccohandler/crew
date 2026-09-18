// SPEC: nutrition addendum §2 (RATIFIED 2026-09-18) — the four nutrition documents as local @Model classes: the iOS twins of the
// server's nutritionTargets · savedMeals · dayTemplate · mealLogs, offline-first (E6). PRIVATE AND UNGAMIFIED: nothing here is ever
// read by the crew snapshot, a post, the gamification state or an achievement counter (clauses ③ ④). The targets row is the ONLY
// place a bodyweight exists on the phone (E1's one exception; delete the row and none is left, V64). A saved meal is known by the
// clientId this phone (or another) created it with; a template slot and a log name a meal by that clientId. A log keeps its OWN copy
// of the name and the grams, so editing or deleting a meal never rewrites a day. CrewApp.resetState wipes all four on log out.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@Model
final class LocalNutritionTargets {
    @Attribute(.unique) var userId: String
    var bodyweightTenths: Int        // tenths of `unit` — the engine's integer form (NutritionTargets)
    var unit: String                 // lb | kg — the account's weight unit when the bodyweight was typed (A9)
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var source: String               // derived | manual
    var updatedAt: Date

    init(userId: String, bodyweightTenths: Int, unit: String, proteinG: Int, carbsG: Int, fatG: Int, source: String, updatedAt: Date) {
        self.userId = userId
        self.bodyweightTenths = bodyweightTenths
        self.unit = unit
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.source = source
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalSavedMeal {
    @Attribute(.unique) var clientId: String
    var serverId: String?            // known after a pull; a log or a slot that arrives FROM the server names the meal by it
    var userId: String
    var name: String
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var seedChainId: String?         // set together with seedItemId when the meal was copied from the fast-food seed (§5)
    var seedItemId: String?
    var createdAt: Date

    init(clientId: String, userId: String, name: String, proteinG: Int, carbsG: Int, fatG: Int, seedChainId: String?, seedItemId: String?, createdAt: Date) {
        self.clientId = clientId
        self.userId = userId
        self.name = name
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.seedChainId = seedChainId
        self.seedItemId = seedItemId
        self.createdAt = createdAt
    }
}

// One slot of the template as it is stored inside LocalDayTemplate.slotsJSON, in order
struct TemplateSlotFacts: Codable, Equatable {
    let savedMealId: String          // the saved meal's clientId
    let label: String                // the user's own word ("Breakfast"); "" when none
}

@Model
final class LocalDayTemplate {
    @Attribute(.unique) var userId: String
    var slotsJSON: Data              // [TemplateSlotFacts] — an ordered checklist, never a requirement
    var updatedAt: Date

    init(userId: String, slotsJSON: Data, updatedAt: Date) {
        self.userId = userId
        self.slotsJSON = slotsJSON
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalMealLog {
    @Attribute(.unique) var clientId: String
    var userId: String
    var dayKey: String               // the 3 AM day in the device's zone (E8); the server stamps its own from createdAt (E15)
    var savedMealId: String?         // the saved meal's clientId; nil for a quick add
    var name: String
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var quickAdd: Bool
    var createdAt: Date

    init(clientId: String, userId: String, dayKey: String, savedMealId: String?, name: String, proteinG: Int, carbsG: Int, fatG: Int, quickAdd: Bool, createdAt: Date) {
        self.clientId = clientId
        self.userId = userId
        self.dayKey = dayKey
        self.savedMealId = savedMealId
        self.name = name
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.quickAdd = quickAdd
        self.createdAt = createdAt
    }
}
