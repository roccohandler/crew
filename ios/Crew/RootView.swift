// SPEC: 5.2 CrewApp (auth routing; tab bar) · 1A (the launch frame matches Home's skeleton, no splash) · S01 (auth
// restored silently) · 1C (authenticate once per device — the Keychain outlives a reinstall, so a signed-in phone can wake
// with an empty Store: it fills it first, ServerHydrate) · Flow 10 (solo is a full experience — every tab works with zero
// friends) · T013. Screens hold ZERO logic (5.6.6): this view only branches on view state. WRITTEN — UNVERIFIED (needs Mac).

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

struct MainTabs: View {
    var body: some View {
        TabView {
            HomeScreen().tabItem { Label("Home", systemImage: "house") }
            PlanScreen().tabItem { Label("Plan", systemImage: "calendar") }
            CrewScreen().tabItem { Label("Crew", systemImage: "person.2") }
            ProgressScreen().tabItem { Label("Progress", systemImage: "chart.bar") }
            SettingsScreen().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(EmberColors.inkText) // Part III law ① — chrome is monochrome forever
        .task { SyncDriver.start() } // E6: the queue runs from the first signed-in frame — launch, foreground, network back
    }
}
