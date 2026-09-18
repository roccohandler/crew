// SPEC: A23 (Appendix A 2026-09-18) · docs/education-copy-draft.md §A rules 1, 4, 7 — the seen-state a whisper lives by, against a
// throwaway UserDefaults suite and a test-provided sender, no mocks (C4): a whisper shows until it is seen and never again; the first
// tap clears every whisper showing, together; what the server holds joins what the phone holds; what the phone saw offline goes up —
// whole, never a delta — the next time it can; what was seen before the account existed joins the account; and a log out leaves the
// next person on this phone with nothing seen. This file is NOT in ios/Package.swift (Observation + UserDefaults on the app target).
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class WhisperStateTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        suiteName = "whisper-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // The server as a test sees it: what it was sent, and what it answers (nil = unreachable)
    private final class Server {
        var received: [[String]] = []
        var reachable = true
        var held: Set<String> = []
    }

    private func state(_ server: Server) -> WhisperState {
        WhisperState(defaults: defaults, send: { ids in
            server.received.append(ids)
            guard server.reachable else { return nil }
            server.held.formUnion(ids)
            return Array(server.held).sorted()
        })
    }

    func testAWhisperShowsUntilItIsSeenAndTheFirstTapClearsEveryOneShowing() async {
        let server = Server()
        let whispers = state(server)
        await whispers.load(userId: "u1", serverSeen: [])
        XCTAssertTrue(whispers.shouldShow(.whyPpl))
        whispers.appeared(.whyPpl)
        whispers.appeared(.howRevealSwap) // the reveal carries two; each sits under its own element
        whispers.clearVisible()           // the first tap anywhere
        XCTAssertFalse(whispers.shouldShow(.whyPpl))
        XCTAssertFalse(whispers.shouldShow(.howRevealSwap))
        XCTAssertTrue(whispers.shouldShow(.howPause), "a whisper that was not on screen is untouched")
        whispers.clearVisible()           // nothing showing: nothing to do, nothing sent
        await whispers.resendIfNeeded()
        XCTAssertEqual(server.held, ["why.ppl", "how.revealSwap"])
    }

    func testWhatTheServerHoldsJoinsWhatThePhoneHolds() async {
        let whispers = state(Server())
        await whispers.load(userId: "u1", serverSeen: ["why.streak"]) // seen on the web
        XCTAssertFalse(whispers.shouldShow(.whyStreak))
        XCTAssertTrue(whispers.shouldShow(.howPause))
    }

    func testADismissalMadeOfflineGoesUpWholeTheNextTimeItCan() async {
        let server = Server()
        server.reachable = false
        let whispers = state(server)
        await whispers.load(userId: "u1", serverSeen: [])
        whispers.markSeen(["how.pause"])
        await whispers.resendIfNeeded()
        XCTAssertFalse(whispers.shouldShow(.howPause), "offline, the phone still remembers")
        XCTAssertTrue(server.held.isEmpty)
        server.reachable = true
        whispers.markSeen(["why.streak"])
        await whispers.resendIfNeeded() // the next foreground
        XCTAssertEqual(server.held, ["how.pause", "why.streak"], "the WHOLE local set goes up, so a lost PATCH is repaired by the next one")
        let sentBefore = server.received.count
        await whispers.resendIfNeeded()
        XCTAssertEqual(server.received.count, sentBefore, "nothing new: nothing sent")
    }

    func testWhatWasSeenBeforeTheAccountExistedJoinsTheAccount() async {
        let server = Server()
        let beforeSignup = state(server)
        beforeSignup.appeared(.whyPpl)
        beforeSignup.clearVisible() // the reveal, signed out: kept on the phone, sent nowhere
        XCTAssertTrue(server.received.isEmpty)
        let afterSignup = state(server) // the next launch reads the same phone
        XCTAssertFalse(afterSignup.shouldShow(.whyPpl))
        await afterSignup.load(userId: "u1", serverSeen: [])
        XCTAssertEqual(server.held, ["why.ppl"])
    }

    func testALogOutLeavesTheNextPersonWithNothingSeenAndTheAccountKeepsItsOwn() async {
        let server = Server()
        let whispers = state(server)
        await whispers.load(userId: "u1", serverSeen: [])
        whispers.markSeen(["how.pause"])
        whispers.signedOut()
        XCTAssertTrue(whispers.shouldShow(.howPause), "a new person on this phone has seen nothing")
        await whispers.load(userId: "u1", serverSeen: []) // the same account signs back in, offline from the server's point of view
        XCTAssertFalse(whispers.shouldShow(.howPause), "the account's own set stayed on the phone under its id")
    }
}
