// SPEC: A21.4 / W4 (owner-approved 2026-09-17) · 1D · E5 · T033 — the notification permission is asked ONCE, after the first
// completed workout (ReminderOptInSheet); granted → registerForRemoteNotifications → the device token goes to POST push-token
// through OpKind.pushToken (E6: offline-safe; the server upserts on the token); every signed-in launch re-registers when already
// authorized (Apple: the token can change). Denied → in-app banners, never re-prompt (E5). The simulator has no APNs and fails to
// register — nothing to send, nothing lost. UIApplicationDelegateAdaptor in CrewApp. WRITTEN — UNVERIFIED (needs Mac).

import UIKit
import UserNotifications

final class PushRegistrar: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = Self.hex(deviceToken)
        Task { @MainActor in try? SyncQueue.shared.enqueue(.pushToken, payload: PushTokenRequestDTO(token: token, platform: "ios")) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // E5: no retry loop, no banner — a simulator, or a device without APNs, simply has no token
    }

    // The APNs token as the server stores it: lowercase hex (pushTokenSchema's shape)
    nonisolated static func hex(_ data: Data) -> String { data.map { String(format: "%02x", $0) }.joined() }

    // SPEC: A21.4 — asked once, at the 1D moment; true when the person allowed notifications
    @MainActor static func requestPermissionAndRegister() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted { UIApplication.shared.registerForRemoteNotifications() }
        return granted
    }

    // Every signed-in launch: an already-authorized phone re-registers so a rotated token reaches the server
    @MainActor static func registerIfAuthorized() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }
}
