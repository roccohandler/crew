// SPEC: A21.4 / W4 — the reminder opt-in asks once, after the first completed workout, while no time is stored (E5: never re-prompt);
// the picker pre-fills at the suggested minute (G12); the APNs token is stored as lowercase hex (pushTokenSchema). WRITTEN — UNVERIFIED.

import XCTest
@testable import Crew

final class ReminderOptInTests: XCTestCase {
    func testAsksOnceAfterTheFirstCompletedWorkoutWhileNoTimeIsStored() {
        XCTAssertTrue(ReminderOptIn.shouldAsk(askedBefore: false, storedReminderTime: nil, completedWorkouts: 1))
        XCTAssertFalse(ReminderOptIn.shouldAsk(askedBefore: true, storedReminderTime: nil, completedWorkouts: 1), "E5: never re-prompt")
        XCTAssertFalse(ReminderOptIn.shouldAsk(askedBefore: false, storedReminderTime: "07:30", completedWorkouts: 3), "a stored time means Settings already answered")
        XCTAssertFalse(ReminderOptIn.shouldAsk(askedBefore: false, storedReminderTime: nil, completedWorkouts: 0), "1D: after the first completed workout, not before")
    }

    func testTheDeviceTokenIsLowercaseHex() {
        XCTAssertEqual(PushRegistrar.hex(Data([0x00, 0xAB, 0xFF, 0x10])), "00abff10")
        XCTAssertEqual(PushRegistrar.hex(Data()), "")
    }

    func testThePickerPreFillsAtTheSuggestedMinuteWhenNothingIsStored() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: SettingsModel.reminderDate(stored: nil))
        XCTAssertEqual(parts.hour, SpecConstants.reminderSuggestedMinuteOfDay / TimeUnits.minutesPerHour)
        XCTAssertEqual(parts.minute, SpecConstants.reminderSuggestedMinuteOfDay % TimeUnits.minutesPerHour)
    }
}
