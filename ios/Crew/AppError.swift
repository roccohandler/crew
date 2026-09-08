// SPEC: C13 — errors are boring: one AppError enum for the whole app, one standard shape from the server
// (`{ error: { code, message } }`). WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum AppError: Error, Equatable {
    case unauthorized                       // 401 — the session is gone; sign in again
    case offline                            // no network (E6 — the solo loop keeps working)
    case server(code: String, message: String, status: Int)
    case invalidResponse
    case storage(String)

    // 6.1 Error state: what happened + what to do, one sentence, no codes
    var userLine: String {
        switch self {
        case .unauthorized: return "Your session ended. Sign in to keep going."
        case .offline: return "You're offline. Everything you log is saved and will sync when you're back."
        case .server(_, let message, _): return message
        case .invalidResponse: return "Something came back wrong from the server. Try again."
        case .storage: return "Couldn't save that on this phone. Try again."
        }
    }
}
