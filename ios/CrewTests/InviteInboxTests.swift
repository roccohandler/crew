// SPEC: 1A · A21.3 · W7 code half (owner order 2026-09-18, item 3) — a tapped invite link hands its token to the pasted-code path
// exactly once; a URL that is not an invite is ignored. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class InviteInboxTests: XCTestCase {
    func testAnInviteLinkIsHeldOnceAndTakenOnce() throws {
        let inbox = InviteInbox()
        inbox.receive(try XCTUnwrap(URL(string: "https://crew.example.com/join/k3Jx9Qa7?ref=text#top")))
        XCTAssertEqual(inbox.pendingCode, "k3Jx9Qa7")
        XCTAssertEqual(inbox.consume(), "k3Jx9Qa7")
        XCTAssertNil(inbox.pendingCode)
        XCTAssertNil(inbox.consume())
    }

    func testAUrlThatIsNotAnInviteIsIgnored() throws {
        let inbox = InviteInbox()
        inbox.receive(try XCTUnwrap(URL(string: "https://crew.example.com/privacy")))
        inbox.receive(try XCTUnwrap(URL(string: "https://crew.example.com/join/")))
        XCTAssertNil(inbox.pendingCode)
    }
}
