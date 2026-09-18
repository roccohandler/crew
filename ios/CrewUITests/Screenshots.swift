// The journeys photograph themselves. Every shot is attached to the test result, so `ios/TestResults.xcresult` (uploaded by the
// CI ios job on every run) shows the real app on a real simulator — the only way to LOOK at the iPhone screens from a machine
// that is not a Mac. Owner order 2026-09-18, item 1 (the STORYBOARD): every shot is a NUMBERED STEP, "NN-<screen> — <action>",
// counted per test in the order taken; the CI job exports the bundle's attachments (`xcrun xcresulttool export attachments`) and
// `ios/scripts/storyboard.mjs` turns them into `storyboard/<Test>/NN-<slug>.png` plus an `index.md` (test · step · screen · action)
// in the `ios-storyboard` artifact — the agent reviews every flow from that artifact.
// SPEC: 8.4 (the journeys are the record) · 8.9 (the snapshot matrix these shots are the first step toward).
// WRITTEN — UNVERIFIED (needs Mac + simulator). T028 / T035

import XCTest

// One counter per test, keyed by the test's name. UI tests run serially (project.yml: CrewAll, no parallelization), so a plain
// static is safe here; `nonisolated(unsafe)` says so to the compiler in both language modes.
enum StoryboardStep {
    nonisolated(unsafe) static var counts: [String: Int] = [:]

    static func next(for test: String) -> Int {
        let step = (counts[test] ?? 0) + 1
        counts[test] = step
        return step
    }
}

extension XCTestCase {
    // .keepAlways: a passing run keeps its pictures too — the point is to see the app, not only to debug a failure
    func shoot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "%02d-%@", StoryboardStep.next(for: self.name), name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
