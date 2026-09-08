// SPEC: Flow 3 rest timer — auto-start on check · quiet inline countdown · chime+haptic (a local notification when the phone is
// locked, only if permission was already granted — the permission ask itself waits for the first completed workout, 1D) ·
// per-workout length (G9 default 90 s) · off-able. WRITTEN — UNVERIFIED (needs Mac). T025

import Foundation
import Observation
import UserNotifications

@Observable
final class RestTimer {
    var lengthSeconds = SpecConstants.restTimerDefaultSeconds
    var enabled = true
    private(set) var endsAt: Date?

    var isRunning: Bool { endsAt != nil }

    func remaining(at now: Date = Date()) -> Int {
        guard let endsAt else { return 0 }
        return max(0, Int(endsAt.timeIntervalSince(now).rounded(.up)))
    }

    func start(now: Date = Date()) {
        guard enabled else { return }
        endsAt = now.addingTimeInterval(TimeInterval(lengthSeconds))
        scheduleChime()
    }

    func stop() {
        endsAt = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationId])
    }

    // Called by the view on each tick; fires the haptic exactly once when the countdown reaches zero in the foreground
    func tick(now: Date = Date()) -> Bool {
        guard let endsAt, now >= endsAt else { return false }
        self.endsAt = nil
        Haptics.play(.tick)
        return true
    }

    private static let notificationId = "rest-timer"

    private func scheduleChime() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest's over"
            content.body = "Next set."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(self.lengthSeconds), repeats: false)
            center.add(UNNotificationRequest(identifier: Self.notificationId, content: content, trigger: trigger))
        }
    }
}
