// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, HOME, redrawn for A28 (d) (the Focus Card, design/targets 01–06):
// filled · the "+" sheet · cardio log · rest day + bonus sheet · the bridge · empty + rebuild sheet, each Home state photographed a
// second time in Midnight (A28 (a): dark is supported and reviewed like light — a "_dark" shot is judged against the "-dark"
// mockup). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI (TourSteps.swift says why); every step
// is a shot named NN_<tab>_<screen>_<state>. The done Home is in Tour_SessionTests, the off-season Home in Tour_SettingsTests.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_HomeTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testFilled() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourShot(app, "home_home_filled", "launched as a member with a six-day streak, a crew and today's workout open")
        if tourTap(app.buttons["home.add"]) {
            tourShot(app, "home_add_sheet", "tapped + on a training day")
            if tourTap(app.buttons["home.add.cardio"], timeout: 5) {
                _ = app.navigationBars["Log cardio"].waitForExistence(timeout: 10)
                tourShot(app, "home_cardiolog_empty", "tapped Log cardio in the + sheet")
                tourBack(app)
            }
        }
        tourLaunch(app, as: member, dark: true)
        tourWaitForHome(app)
        tourShot(app, "home_home_filled_dark", "the same Home with the phone in dark mode")
        // A28 (a), (b) — the celebration in Midnight (mockup 11 dark): Quick complete is the shortest way to one
        if tourTap(app.buttons["Quick complete"], timeout: 5) {
            _ = app.buttons["Share to crew"].waitForExistence(timeout: 15)
            tourShot(app, "session_celebration_complete_dark", "tapped Quick complete in dark mode")
        }
    }

    func testRestDay() async throws {
        let member = try await tourEmptyMember(seed, "Rest Tour")
        do { try await seed.putPlan(oneTrainingDayOffsetFromToday: 1, as: member); try await seed.logCardio(as: member) } catch { throw XCTSkip("the tour seed failed: \(error)") }
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourShot(app, "home_home_restday", "launched on a rest day")
        if tourTap(app.buttons["home.add"]) {
            tourShot(app, "home_add_sheet_rest", "tapped + on a rest day — cardio and a bonus workout")
            if tourTap(app.buttons["home.add.bonus"], timeout: 5) {
                _ = app.staticTexts["Bonus workout"].waitForExistence(timeout: 10)
                tourShot(app, "home_bonus_sheet", "tapped Bonus workout in the + sheet")
                tourDismissSheet(app)
            }
        }
        tourLaunch(app, as: member, dark: true)
        tourWaitForHome(app)
        tourShot(app, "home_home_restday_dark", "the same rest day in dark mode")
    }

    func testBridge() async throws {
        let member = try await tourEmptyMember(seed, "Bridge Tour")
        do { try await seed.putTourPlan(as: member) } catch { throw XCTSkip("the tour seed failed: \(error)") }
        tourLaunch(app, as: member)
        _ = app.buttons["Start your first workout"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_bridge", "launched with a plan and no post yet")
        tourLaunch(app, as: member, dark: true)
        _ = app.buttons["Start your first workout"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_bridge_dark", "the same first day in dark mode")
    }

    func testEmpty() async throws {
        let member = try await tourEmptyMember(seed, "Empty Tour")
        tourLaunch(app, as: member)
        _ = app.buttons["Build my week"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_empty", "launched with no plan")
        if tourTap(app.buttons["Build my week"]) {
            tourShot(app, "home_rebuild_sheet", "tapped Build my week")
            tourDismissSheet(app)
        }
        tourLaunch(app, as: member, dark: true)
        _ = app.buttons["Build my week"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_empty_dark", "the same empty Home in dark mode")
    }
}
