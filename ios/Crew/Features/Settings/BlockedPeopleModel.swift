// SPEC: E9 — block/unblock, silent both ways · A7 (owner-directed 2026-09-08): Settings › Blocked people = the list (GET blocks)
// + Unblock (DELETE blocks). WRITTEN — UNVERIFIED (needs Mac). T041

import Foundation
import Observation

@Observable
@MainActor
final class BlockedPeopleModel {
    var people: [BlockedUserDTO] = []
    var isLoaded = false
    var errorLine: String?

    func refresh() async {
        do {
            people = try await Api.shared.blockedUsers()
            errorLine = nil
        } catch let error as AppError { errorLine = error.userLine } catch { errorLine = AppError.invalidResponse.userLine }
        isLoaded = true
    }

    // SPEC: E9 — unblock is immediate; the other side is never told
    func unblock(userId: String) async {
        do {
            _ = try await Api.shared.unblock(userId: userId)
            people.removeAll { $0.userId == userId }
        } catch let error as AppError { errorLine = error.userLine } catch { errorLine = AppError.invalidResponse.userLine }
    }
}
