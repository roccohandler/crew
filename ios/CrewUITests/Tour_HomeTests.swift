// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, HOME (filled · cardio log · rest day + bonus sheet · the bridge ·
// empty + rebuild sheet). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI (TourSteps.swift says
// why); every step is a shot named NN_<tab>_<screen>_<state> for design/baselines/. The paused Home is in Tour_SettingsTests.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_HomeTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testFilled() async throws {
        tourLaunch(app, as: try await tourFilledMember(seed))
        tourWaitForHome(app)
        tourShot(app, "home_home_filled", "launched as a member with a six-day streak, a crew and today's workout open")
        if tourTap(tourButton(app, startingWith: "Log cardio")) {
            tourShot(app, "home_cardiolog_empty", "tapped Log cardio")
            tourBack(app)
        }
    }

    func testRestDay() async throws {
        let member = try await tourEmptyMember(seed, "Rest Tour")
        do { try await seed.putPlan(oneTrainingDayOffsetFromToday: 1, as: member); try await seed.logCardio(as: member) } catch { throw XCTSkip("the tour seed failed: \(error)") }
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourShot(app, "home_home_restday", "launched on a rest day")
        if tourTap(tourButton(app, startingWith: "Log workout")) {
            tourShot(app, "home_bonus_sheet", "tapped Log workout on a rest day")
            tourDismissSheet(app)
        }
    }

    func testBridge() async throws {
        let member = try await tourEmptyMember(seed, "Bridge Tour")
        do { try await seed.putTourPlan(as: member) } catch { throw XCTSkip("the tour seed failed: \(error)") }
        tourLaunch(app, as: member)
        _ = app.buttons["Start your first workout"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_bridge", "launched with a plan and no post yet")
    }

    func testEmpty() async throws {
        tourLaunch(app, as: try await tourEmptyMember(seed, "Empty Tour"))
        _ = app.buttons["Build my week"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_empty", "launched with no plan")
        if tourTap(app.buttons["Build my week"]) {
            tourShot(app, "home_rebuild_sheet", "tapped Build my week")
            tourDismissSheet(app)
        }
    }
}
