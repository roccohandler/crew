// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — the invite CODE is the crew's inviteToken, nothing new (Appendix A A21 GAP reading,
// owner-confirmed). A person pastes whatever they were sent: the bare code, the full link, or a link with a query or fragment; this
// reads the code out of any of them. Twin of web/src/lib/invite-code.ts — same rules, same answers. Pure (C2); the hero's
// "I have an invite" (OnboardingModel), the empty Crew tab (CrewModel) and the Invite screen's "Copy code" call it.

import Foundation

enum InviteCode {
    private static let joinSegment = "/join/"

    static func token(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var afterJoin = trimmed
        if let range = trimmed.range(of: joinSegment, options: .backwards) { afterJoin = String(trimmed[range.upperBound...]) }
        let token = afterJoin.split(maxSplits: 1, omittingEmptySubsequences: false, whereSeparator: { "?#/".contains($0) }).first.map(String.init) ?? ""
        guard !token.isEmpty, token.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        return token
    }
}
