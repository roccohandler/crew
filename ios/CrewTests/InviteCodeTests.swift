// SPEC: A21.3 / W4 — the pasted invite code is read out of a bare code, a full link, or a link with a query or fragment; twin of
// web/tests/engine/invite-code.test.ts (same cases, same answers). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class InviteCodeTests: XCTestCase {
    func testAcceptsABareCodeTrimmed() {
        XCTAssertEqual(InviteCode.token(from: "  abc123DEF  "), "abc123DEF")
    }

    func testReadsTheCodeOutOfAFullLinkWithOrWithoutAQueryOrFragment() {
        XCTAssertEqual(InviteCode.token(from: "https://crew-eta-one.vercel.app/join/abc123DEF"), "abc123DEF")
        XCTAssertEqual(InviteCode.token(from: "https://crew-eta-one.vercel.app/join/abc123DEF?utm=x#top"), "abc123DEF")
        XCTAssertEqual(InviteCode.token(from: "crew-eta-one.vercel.app/join/abc123DEF/"), "abc123DEF")
    }

    func testRejectsNothingWhitespaceInsideACodeAndALinkWithNoCode() {
        XCTAssertNil(InviteCode.token(from: ""))
        XCTAssertNil(InviteCode.token(from: "   "))
        XCTAssertNil(InviteCode.token(from: "abc 123"))
        XCTAssertNil(InviteCode.token(from: "https://crew-eta-one.vercel.app/join/"))
    }
}
