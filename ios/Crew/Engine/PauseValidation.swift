// SPEC: V22 (never retroactive) · V23 (≤ pauseMaxDays) · V44 (one active pause at a time), in that order.
// Twin of pause-validation.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum PauseRejection: String, Codable {
    case retroactive, tooLong, alreadyPaused
}

struct PauseValidationResult: Equatable {
    let accepted: Bool
    let reason: PauseRejection?
}

enum PauseValidation {
    static func validatePauseRequest(today: String, startDay: String, endDay: String, existingPauses: [Pause]) -> PauseValidationResult {
        if startDay < today { return PauseValidationResult(accepted: false, reason: .retroactive) }
        if DayKey.daysBetween(startDay, endDay) > SpecConstants.pauseMaxDays { return PauseValidationResult(accepted: false, reason: .tooLong) }
        if existingPauses.contains(where: { $0.endDay > today }) { return PauseValidationResult(accepted: false, reason: .alreadyPaused) }
        return PauseValidationResult(accepted: true, reason: nil)
    }
}
