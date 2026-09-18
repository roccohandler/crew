// SPEC: 5.2 CrewApp (auth routing; tab bar) · 1A (the launch frame matches Home's skeleton, no splash) · S01 (auth
// restored silently) · 1C (authenticate once per device — the Keychain outlives a reinstall, so a signed-in phone can wake
// with an empty Store: it fills it first, ServerHydrate) · Flow 10 (solo is a full experience — every tab works with zero
// friends) · A21.3 / W4 (owner-approved 2026-09-17): an invited signup lands INSIDE the crew — the join marks it once, the tab
// bar opens on Crew once · A21.4: an already-authorized phone re-registers for push on every signed-in launch (PushRegistrar) ·
// T013. Screens hold ZERO logic (5.6.6): this view only branches on view state. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct RootView: View {
    private let auth = AuthStore.shared
    @State private var hydratedUserId: String?

    var body: some View {
        if !auth.isSignedIn {
            OnboardingFlow()
        } else if hydratedUserId == auth.currentUser?.id {
            MainTabs()
        } else {
            HomeSkeleton() // 1A: the launch frame IS Home's skeleton — a fresh device fills its Store behind it, bounded (6.1)
                .task {
                    await ServerHydrate.pullIfEmptyBounded(userId: auth.currentUser?.id ?? "local", store: .shared)
                    hydratedUserId = auth.currentUser?.id
                }
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
            ProgressScreen().tabItem { Label("Progress", systemImage: "chart.bar") }.tag(MainTab.progress)
            SettingsScreen().tabItem { Label("Settings", systemImage: "gearshape") }.tag(MainTab.settings)
        }
        .tint(EmberColors.inkText) // Part III law ① — chrome is monochrome forever
        .task { SyncDriver.start(); await PushRegistrar.registerIfAuthorized() } // E6: the queue runs from the first signed-in frame — launch, foreground, network back
    }
}
