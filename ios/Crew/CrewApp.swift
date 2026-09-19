// SPEC: 5.2 CrewApp.swift (entry; auth routing; tab bar) · S01 (warm start bypasses splash; launch frame matches
// Home's skeleton) · E6 (every foreground drains the sync queue — SyncDriver) · T007 scaffold — the tab bar and auth
// routing land in T013 (RootView). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

@main
struct CrewApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(PushRegistrar.self) private var pushRegistrar // A21.4: the APNs device token arrives here

    init() {
        Signposts.beginLaunch() // 8.8: the launch → Home interval starts here
        Chrome.apply() // A28 (a): titles, tab items and bars in the table's colours, never the platform's black
        // A24 (2026-09-18): the test bundle's launch arguments are read in a Debug build ONLY — no Release build (TestFlight, the
        // App Store) can be reset or handed a session from its command line
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetState") { Self.resetState() }               // CrewUITests journey ①: a fresh install, every run
        if arguments.contains("-seededReturningUser") { Self.seedReturningUser() } // CrewUITests journey ②: yesterday's member
        #endif
    }

    // 8.4 journey ① starts from nothing: the Keychain session, the SwiftData store and the pre-auth draft are cleared.
    // SPEC: A7 — the same reset serves Log out and Delete account (SettingsModel): the op queue and pauses go too (D7 fix).
    static func resetState() {
        AuthStore.shared.signOutLocally()
        WhisperState.shared.signedOut() // A23: the next account's whispers are its own
        DraftStore().clear()
        let context = Store.shared.context
        try? context.delete(model: LocalPlan.self)
        try? context.delete(model: LocalTrainingDays.self) // A27 (a): the plan's history goes with it
        try? context.delete(model: LocalSession.self)
        try? context.delete(model: LocalPost.self)
        try? context.delete(model: LocalGamificationState.self)
        try? context.delete(model: LocalPause.self)
        try? context.delete(model: LocalCrewSnapshot.self)
        try? context.delete(model: LocalNutritionTargets.self) // W8: the next account on this phone never reads this one's bodyweight
        try? context.delete(model: LocalSavedMeal.self)
        try? context.delete(model: LocalDayTemplate.self)
        try? context.delete(model: LocalMealLog.self)
        try? context.delete(model: OpRecord.self)
        try? Store.shared.save()
    }

    // 8.4 journey ②: the test bundle (CrewUITests/SeedClient) registers the member, their plan, first post and crew through the
    // real API, then hands the signed-in session over in CREW_SEED_SESSION. The phone wakes signed in with an empty Store and
    // hydrates from the server exactly as a reinstalled phone does (RootView → ServerHydrate) — no test-only path in the app.
    // A28 (a) — a UI test photographs Midnight with -uiDark (Debug only); every other launch follows the phone (nil)
    #if DEBUG
    private static var forcedScheme: ColorScheme? { ProcessInfo.processInfo.arguments.contains("-uiDark") ? .dark : nil }
    #else
    private static var forcedScheme: ColorScheme? { nil }
    #endif

    #if DEBUG
    private static func seedReturningUser() {
        guard let raw = ProcessInfo.processInfo.environment["CREW_SEED_SESSION"], let session = try? JSONDecoder.crew.decode(AuthSessionDTO.self, from: Data(raw.utf8)) else { return }
        resetState()
        AuthStore.shared.store(session)
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                // GAP: A28 GAP 6, R-084 (4) — lifted while dark carbs fails only on a card no shipped screen draws
                .preferredColorScheme(Self.forcedScheme) // A28 (a) (2026-09-19): light is the default and dark follows the phone — the lock of A21.10 as amended is lifted (R1)
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { SyncDriver.foreground() } } // E6: what was logged goes out
    }
}
