// SPEC: 8.8 — launch signposts asserted on device-farm CI (the assertion needs a device; deferred) · S01 warm start < 1 s to Home
// · 7.x performance budgets (launchToHomeMs). The app emits the intervals so Instruments and the CI assertion have something
// to read. Zero dependencies (OSLog is first-party). WRITTEN — UNVERIFIED (needs Mac). T043

import Foundation
import OSLog

enum Signposts {
    static let signposter = OSSignposter(subsystem: "com.yourteam.crew", category: "launch")
    nonisolated(unsafe) private static var launch: OSSignpostIntervalState?

    // CrewApp.init — the earliest point the app can mark
    static func beginLaunch() {
        launch = signposter.beginInterval("launchToHome")
    }

    // HomeScreen's first successful load — the moment the Five States Law calls "success"
    static func endLaunchIfNeeded() {
        guard let state = launch else { return }
        signposter.endInterval("launchToHome", state)
        launch = nil
    }
}
