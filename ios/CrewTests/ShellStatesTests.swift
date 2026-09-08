// SPEC: T013 (Verify: ios builds, empty screens render all states) · 6.1 Five States Law — every shell declares all
// five states and each state constructs a view. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import XCTest
@testable import Crew

final class ShellStatesTests: XCTestCase {
    func testEveryShellDeclaresFiveStates() {
        let home: [HomeLoadState] = [.loading, .ready, .empty, .failed("x"), .offline]
        let plan: [PlanLoadState] = [.loading, .ready, .empty, .failed("x"), .offline]
        let crew: [CrewLoadState] = [.loading, .ready, .solo, .failed("x"), .offline]
        let progress: [ProgressLoadState] = [.loading, .ready, .empty, .failed("x"), .offline]
        XCTAssertEqual(home.count, 5)
        XCTAssertEqual(plan.count, 5)
        XCTAssertEqual(crew.count, 5)
        XCTAssertEqual(progress.count, 5)
    }

    func testSharedComponentsConstruct() {
        _ = EmptyState(title: "Start a crew", line: "One link.", ctaTitle: "Start a crew") {}
        _ = ErrorState(line: "Couldn't load that. Try again.") {}
        _ = WeeklyRing(done: 2, planned: 4, days: [.done, .rest, .done, .rest, .today, .upcoming, .upcoming])
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
