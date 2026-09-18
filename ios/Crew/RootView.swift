// SPEC: 5.2 CrewApp (auth routing; tab bar) · 1A as amended 2026-09-18 (owner-directed, "launch: real UI first" — the launch
// frame IS HOME, drawn at once from what the phone holds; no skeleton, no splash) · S01 (auth restored silently) · 1C
// (authenticate once per device — the Keychain outlives a reinstall, so a signed-in phone can wake with an empty Store: Home
// draws anyway and ServerHydrate fills it behind the screen, piece by piece) · Flow 10 (solo is a full experience — every tab works with zero
// friends) · A21.3 / W4 (owner-approved 2026-09-17): an invited signup lands INSIDE the crew — the join marks it once, the tab
// bar opens on Crew once · A21.4: an already-authorized phone re-registers for push on every signed-in launch (PushRegistrar) ·
// T013. Screens hold ZERO logic (5.6.6): this view only branches on view state. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct RootView: View {
    private let auth = AuthStore.shared

    var body: some View {
        if auth.isSignedIn {
            MainTabs() // 2026-09-18: straight to the real screens; a reinstalled phone's Store fills behind them (MainTabs.task)
        } else {
            OnboardingFlow()
        }
    }
}

enum MainTab: Hashable {
    case home, plan, crew, progress, settings
}

// SPEC: A21.3 — after an invited signup the phone lands INSIDE the crew (1A, S13): the join sets this once, the tab bar reads it once
enum LandingFlags {
    private static let crewTabKey = "landInCrewTabOnce"

    static func markCrewTab() { UserDefaults.standard.set(true, forKey: crewTabKey) }

    static func consumeCrewTab() -> Bool {
        let pending = UserDefaults.standard.bool(forKey: crewTabKey)
        if pending { UserDefaults.standard.removeObject(forKey: crewTabKey) }
        return pending
    }
}

struct MainTabs: View {
    @State private var selection: MainTab

    init() {
        _selection = State(initialValue: LandingFlags.consumeCrewTab() ? .crew : .home)
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeScreen().tabItem { Label("Home", systemImage: "house") }.tag(MainTab.home)
            PlanScreen().tabItem { Label("Plan", systemImage: "calendar") }.tag(MainTab.plan)
            CrewScreen().tabItem { Label("Crew", systemImage: "person.2") }.tag(MainTab.crew)
            ProgressScreen(onGoHome: { selection = .home }).tabItem { Label("Progress", systemImage: "chart.bar") }.tag(MainTab.progress) // W6: the empty state's CTA is today
            SettingsScreen().tabItem { Label("Settings", systemImage: "gearshape") }.tag(MainTab.settings)
        }
        .tint(EmberColors.inkText) // Part III law ① — chrome is monochrome forever
        // E6: the queue runs from the first signed-in frame — launch, foreground, network back. 2026-09-18: the reinstall pull runs
        // here too, in the background — Home is already on screen saying "syncing" and fills as each piece lands (ServerHydrate.state)
        .task {
            SyncDriver.start()
            await PushRegistrar.registerIfAuthorized()
            await ServerHydrate.pullIfEmpty(userId: AuthStore.shared.currentUser?.id ?? "local", store: .shared)
        }
    }
}
