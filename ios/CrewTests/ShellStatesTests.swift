// SPEC: T013 (Verify: ios builds, empty screens render all states) · 6.1 Five States Law — every shell declares all
// five states and each state constructs a view. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import XCTest
@testable import Crew

final class ShellStatesTests: XCTestCase {
    // A18.12 — THIS TEST USED TO COUNT A LITERAL. It built `[.loading, .ready, .empty, .failed("x"), .offline]` and
    // asserted the array had five elements, which is true of any five-element array and says nothing about whether a
    // state can be REACHED. Under it, Home's `.offline` was assigned nowhere in the app: the OfflineBanner had never
    // rendered on a device, and 6.1's Five States Law was certified by an assertion that could not fail.
    //
    // Home's state is now a pure function of the model (HomeLoadState.of), so reachability is checkable here without
    // a Mac: every state below is produced from real inputs. `.loading` is the initial value, not a function of the
    // model, so it is the one state asserted by construction.
    func testHomeReachesEveryOneOfItsFiveStates() {
        let initial: HomeLoadState = .loading
        XCTAssertEqual(initial, .loading)
        XCTAssertEqual(HomeLoadState.of(loadError: "Couldn't load that.", hasPlan: true, offline: false), .failed("Couldn't load that."))
        XCTAssertEqual(HomeLoadState.of(loadError: nil, hasPlan: false, offline: false), .empty)
        XCTAssertEqual(HomeLoadState.of(loadError: nil, hasPlan: true, offline: false), .ready)
        XCTAssertEqual(HomeLoadState.of(loadError: nil, hasPlan: true, offline: true), .offline)
        // the precedence, stated once so it cannot drift: an error outranks everything (there is nothing to show),
        // and no plan outranks the network (the fix is onboarding, not a reconnect)
        XCTAssertEqual(HomeLoadState.of(loadError: "x", hasPlan: false, offline: true), .failed("x"))
        XCTAssertEqual(HomeLoadState.of(loadError: nil, hasPlan: false, offline: true), .empty)
    }

    // The other three shells still only DECLARE their five; making each of them reachable is its own pass, and this
    // says so rather than implying more coverage than there is (debt.md 2026-09-10).
    func testTheOtherShellsDeclareFiveStates() {
        let plan: [PlanLoadState] = [.loading, .ready, .empty, .failed("x"), .offline]
        let crew: [CrewLoadState] = [.loading, .ready, .solo, .failed("x"), .offline]
        let progress: [ProgressLoadState] = [.loading, .ready, .empty, .failed("x"), .offline]
        XCTAssertEqual(plan.count, 5)
        XCTAssertEqual(crew.count, 5)
        XCTAssertEqual(progress.count, 5)
    }

    func testSharedComponentsConstruct() {
        _ = EmptyState(title: "Start a crew", line: "One link.", ctaTitle: "Start a crew") {}
        _ = ErrorState(line: "Couldn't load that. Try again.") {}
        _ = WeeklyRing(done: 2, planned: 4)
        _ = StreakFlame(streak: 0, paused: false)
        _ = AvatarView(displayName: "Sam Rivera", image: nil)
        _ = HomeSkeleton()
        XCTAssertEqual(EmberTokens.Haptic.allCases.count, 4)
    }

    @MainActor
    func testInMemoryStoreOpens() throws {
        let store = Store(inMemory: true)
        XCTAssertNil(try store.plan(for: "user-1"))
        let state = try store.gamificationState(for: "user-1")
        XCTAssertEqual(state.level, SpecConstants.startingLevel)
    }
}
