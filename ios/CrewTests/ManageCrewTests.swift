// SPEC: E2 · A27 (b) (owner-approved 2026-09-18) — Manage crew offers the Captain all four jobs (rename, replace the link, remove a
// member, leave) and everyone else Leave alone; the server enforces the same line (web/tests/api/crews.test.ts). mvp-definition R5's
// "E2's Captain-only powers tested on both platforms". WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class ManageCrewTests: XCTestCase {
    func testTheCaptainSeesAllFourJobs() {
        XCTAssertEqual(ManageCrewAction.actions(isCaptain: true), [.rename, .replaceLink, .removeMember, .leave])
    }

    func testAMemberMayOnlyLeave() {
        XCTAssertEqual(ManageCrewAction.actions(isCaptain: false), [.leave])
    }
}
