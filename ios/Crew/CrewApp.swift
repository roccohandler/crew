// SPEC: 5.2 CrewApp.swift (entry; auth routing; tab bar) · S01 (warm start bypasses splash; launch frame matches
// Home's skeleton) · E6 (every foreground drains the sync queue — SyncDriver) · T007 scaffold — the tab bar and auth
// routing land in T013 (RootView). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

@main
struct CrewApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Signposts.beginLaunch() // 8.8: the launch → Home interval starts here
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-resetState") { Self.resetState() }               // CrewUITests journey ①: a fresh install, every run
        if arguments.contains("-seededReturningUser") { Self.seedReturningUser() } // CrewUITests journey ②: yesterday's member
    }

    // 8.4 journey ① starts from nothing: the Keychain session, the SwiftData store and the pre-auth draft are cleared.
    private static func resetState() {
        AuthStore.shared.signOutLocally()
        DraftStore().clear()
        let context = Store.shared.context
        try? context.delete(model: LocalPlan.self)
        try? context.delete(model: LocalSession.self)
        try? context.delete(model: LocalPost.self)
        try? context.delete(model: LocalGamificationState.self)
        try? context.delete(model: LocalPause.self)
        try? context.delete(model: LocalCrewSnapshot.self)
        try? context.delete(model: OpRecord.self)
        try? Store.shared.save()
    }

    // 8.4 journey ②: the test bundle (CrewUITests/SeedClient) registers the member, their plan, first post and crew through the
    // real API, then hands the signed-in session over in CREW_SEED_SESSION. The phone wakes signed in with an empty Store and
    // hydrates from the server exactly as a reinstalled phone does (RootView → ServerHydrate) — no test-only path in the app.
    private static func seedReturningUser() {
        guard let raw = ProcessInfo.processInfo.environment["CREW_SEED_SESSION"], let session = try? JSONDecoder.crew.decode(AuthSessionDTO.self, from: Data(raw.utf8)) else { return }
        resetState()
        AuthStore.shared.store(session)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { SyncDriver.foreground() } } // E6: what was logged goes out
    }
}
