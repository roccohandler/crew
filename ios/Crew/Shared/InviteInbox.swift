// SPEC: 1A (a tapped invite opens the app) · A21.3 (the invite CODE path) · W7 code half (owner order 2026-09-18, item 3) — a
// universal link https://<host>/join/<token> lands on the SAME path a pasted code takes: the link's token is held here once; the
// hero's invite screen (signed out) or the Crew tab's join sheet (signed in) picks it up, fills the field and looks the crew up.
// One concrete holder, no layer (C2 · C3); a URL that is not an invite is ignored — nothing else in Crew opens by URL.
// WRITTEN — UNVERIFIED (needs Mac + a device: universal links do not resolve on a simulator without the association).

import Foundation
import Observation

@Observable
@MainActor
final class InviteInbox {
    static let shared = InviteInbox()
    private(set) var pendingCode: String?

    func receive(_ url: URL) {
        guard url.path.hasPrefix("/join/"), let token = InviteCode.token(from: url.absoluteString) else { return }
        pendingCode = token
    }

    // The screen that opens the code path takes the code exactly once
    func consume() -> String? {
        defer { pendingCode = nil }
        return pendingCode
    }
}
