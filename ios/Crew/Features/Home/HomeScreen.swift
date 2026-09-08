// SPEC: S07 Home — all five states; the BRIDGE until the first post (1D); today-state < 500 ms warm; ≤3 taps launch→fast-logged;
// Quick Complete hidden once today counts; Resume banner when a session is open; crew strip absent for solo. Part III law ④:
// the flame is the first ember the user sees. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T024

import SwiftUI

enum HomeLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline
}

struct HomeScreen: View {
    @State private var model = HomeModel()
    @State private var loadState: HomeLoadState = .loading
    @State private var activeSession: LocalSession?
    @State private var celebration: CelebrationOutcome?
    @State private var posting = false
    @State private var rebuilding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: HomeSkeleton()
                case .ready, .offline: content
                case .empty: EmptyState(title: "Build your week", line: "Three questions and your plan is ready.", ctaTitle: "Build my week") { rebuilding = true }
                case .failed(let line): ErrorState(line: line) { load() }
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Today")
            .navigationDestination(item: $activeSession) { session in SessionScreen(session: session) { outcome in activeSession = nil; celebration = outcome; model.refresh() } }
            .sheet(item: $celebration) { outcome in CelebrationScreen(outcome: outcome) { celebration = nil; model.refresh() } }
            .sheet(isPresented: $posting) { NutritionPostScreen { posting = false; model.refresh() } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
            .task { load() }
            .onChange(of: scenePhase) { _, phase in if phase == .active, loadState != .loading { load() } } // E8/V04: elapsed days are judged on every foreground
            .modifier(EdgePrompts(model: model, onKeepGoing: { activeSession = model.keepGoingWithStaleSession() }, onRebuild: { rebuilding = true }))
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                if loadState == .offline { OfflineBanner(lastSyncedLine: "Showing what you had — syncing when you're back.") }
                if let session = model.resumeSession { SecondaryButton(title: "Resume workout · \(session.workoutName)") { activeSession = session } }
                HStack(alignment: .center, spacing: EmberTokens.Spacing.space16) {
                    StreakFlame(streak: model.streak, paused: isPaused)
                    Spacer()
                    if model.ringPlanned > 0 { WeeklyRing(done: model.ringDone, planned: model.ringPlanned, days: model.weeklyRing) }
                }
                TodayCard(state: model.today, onStart: { activeSession = model.startWorkout() }, onPost: { posting = true })
                if model.quickCompleteAvailable, !isBridge { SecondaryButton(title: "Quick complete") { celebration = model.quickComplete(shareToCrew: true) } }
                if let members = model.crewStrip, !isBridge { CrewStrip(members: members) } // absent (not empty) for solo
            }
            .padding(EmberTokens.Spacing.space16)
        }
    }

    private var isPaused: Bool { if case .paused = model.today { return true } else { return false } }
    private var isBridge: Bool { if case .bridge = model.today { return true } else { return false } } // 1D: nothing else competes

    private func load() {
        model.refresh()
        if let line = model.loadError { loadState = .failed(line) } else { loadState = model.hasPlan ? .ready : .empty }
        Signposts.endLaunchIfNeeded() // 8.8: launch → Home interval closes on the first real state
    }
}

// SPEC: T042 — the three edge prompts, in priority order: welcome back (E4, full screen) → stale session (S01) → held uploads (E19).
// Screens branch only on view state; every trigger and every consequence lives in HomeModel (5.6.6).
struct EdgePrompts: ViewModifier {
    let model: HomeModel
    let onKeepGoing: () -> Void
    let onRebuild: () -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: Binding(get: { model.welcomeBack }, set: { _ in })) {
                WelcomeBackScreen(longestStreak: model.longestStreak, onKeep: { Task { await model.acknowledgeWelcomeBack() } }, onRebuild: { Task { await model.acknowledgeWelcomeBack(); onRebuild() } })
            }
            .sheet(isPresented: Binding(get: { !model.welcomeBack && model.staleSession != nil }, set: { _ in })) {
                StaleSessionPrompt(workoutName: model.staleSession?.workoutName ?? "Your workout", onKeepGoing: onKeepGoing, onDiscard: { model.discardStaleSession() })
            }
            .sheet(isPresented: Binding(get: { !model.welcomeBack && model.staleSession == nil && !model.heldUploads.isEmpty }, set: { _ in })) {
                FailedUploadSheet(records: model.heldUploads) { model.resolveUpload($0, choice: $1) }
            }
    }
}

// LocalSession is Identifiable + Hashable through PersistentModel (SwiftData) — no extension, or the conformance is redundant
extension CelebrationOutcome: Identifiable {
    var id: String { postDraft.clientId }
}
