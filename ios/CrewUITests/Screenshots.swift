// The journeys photograph themselves. Every shot is attached to the test result, so `ios/UITestResults.xcresult` (uploaded by
// the CI ios job on every run) shows the real app on a real simulator — the only way to LOOK at the iPhone screens from a
// machine that is not a Mac. Open the bundle in Xcode, or unzip it and read Data/ for the PNGs.
// SPEC: 8.4 (the journeys are the record) · 8.9 (the snapshot matrix these shots are the first step toward).
// WRITTEN — UNVERIFIED (needs Mac + simulator). T028 / T035

import XCTest

extension XCTestCase {
    // .keepAlways: a passing run keeps its pictures too — the point is to see the app, not only to debug a failure
    func shoot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
