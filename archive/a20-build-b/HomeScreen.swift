// SPEC: S07 Home — all five states; the BRIDGE until the first post (§1D); today-state < 500 ms warm; ≤3 taps
// launch→fast-logged; Quick Complete hidden once today counts; crew strip absent for solo. Screens hold ZERO logic
// (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T024
//
// A20 (owner-directed 2026-09-11) — the fifth Home review. The owner's report was "it looks too complicated and things
// don't look like they're syncing". The structure here answers the first half; Build A answered the second.
//
//   A20.1 ONE LIST. The day's workout card is gone and its work is row one of TODAY'S LOG. That single move deletes
//     three duplicate routes to one intent: the card's "Start workout", the "Quick complete" secondary beneath it
//     (now the workout row's trailing mark, A20.3's one named exception) and the "Resume workout · Push day" banner
//     that appeared above everything when a session was open (now the row's own subtitle, A20.5).
//   A20.6 THE CREW STRIP LEAVES. It was a mirror of the Crew tab one tab-tap away, it rendered only for crews of 3+,
//     and it was one more element that appeared and disappeared. The shield folded into the streak caption instead —
//     it is the one fact here with no neighbour, so it is kept rather than dropped.
//   A20.7 A DATE LINE. The one place the app states which day it is reasoning about, which is also the cheapest check
//     a user has against "is this up to date". The nav title still NAMES THE STATE (A17.4(c) reaffirmed).
//   A20.8 THE BAR. A19.1 ratified "Home last"; the owner moved it here because this pass rewrites the layout anyway
//     and doing the anchor twice is worse. `.crewBottomBar` is CONDITIONAL — a day that asks nothing gets no bar,
//     which is A17.3 and A18.9 both. This is the first time 6.7's "primary actions stay bottom-anchored regardless of
//     how much canvas exists above" is mechanically true on Home rather than true only while the screen happens to fit.
//   A20.9 THE BANNER IS PINNED. It was the first child of a ScrollView, so the one element that can explain a lag
//     scrolled away from the content it was explaining. `safeAreaInset(edge: .top)` holds it.

import SwiftUI

struct HomeScreen: View {
    @State private var model = HomeModel(welcomeBackAckDay: AuthStore.shared.currentUser?.welcomeBackAckDay) // E4
    @State private var loaded = false
    @State private var activeSession: LocalSession?
    @State private var celebration: CelebrationOutcome?
    @State private var posting = false
    @State private var rebuilding = false
    @State private var choosingBonus = false
    @State private var loggingCardio = false
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
            .navigationTitle(title)
            .navigationDestination(item: $activeSession) { session in SessionScreen(session: session) { outcome in activeSession = nil; celebration = outcome; model.refresh() } }
            .navigationDestination(isPresented: $loggingCardio) { CardioLogScreen { outcome in loggingCardio = false; celebration = outcome; model.refresh() } } // A2
            .sheet(item: $celebration) { outcome in CelebrationScreen(outcome: outcome) { celebration = nil; model.refresh() } }
            .sheet(isPresented: $posting) { NutritionPostScreen { posting = false; model.refresh() } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
            .sheet(isPresented: $choosingBonus) { BonusWorkoutSheet(workouts: model.bonusWorkouts) { workout in choosingBonus = false; activeSession = model.startBonus(workout) } }
            .task { load() }
            .onChange(of: scenePhase) { _, phase in if phase == .active, loaded { load() } } // E8/V04: elapsed days judged on every foreground
            .modifier(EdgePrompts(model: model, onKeepGoing: { activeSession = model.keepGoingWithStaleSession() }, onRebuild: { rebuilding = true }))
        }
    }

    @ViewBuilder
    private var content: some View {
        if isBridge {
            // §1D — one CTA and nothing else, ever. No header, no log list, no next-up row, no bar.
            ScrollView {
                BridgeCard(kind: bridgeKind, nextUpLine: model.nextUpLine, resuming: model.resumeSession != nil,
                           onStart: { activeSession = model.startWorkout() },
                           onPost: { posting = true })
                    .padding(EmberTokens.Spacing.space16)
            }
        } else {
            // A20.8 — the bar is applied PER STATE rather than once with a conditional body, because `Bar` is a
            // compile-time type: a `@ViewBuilder` that switches between a button and `EmptyView` produces
            // `_ConditionalContent`, which `CrewBottomBar` cannot tell from a real bar, and the states A17.3 and
            // A18.9 cleared would still get a hairline and an inset of empty canvas. Each branch names its own bar,
            // and the two states that ask nothing get no modifier at all.
            switch model.today {
            case .workout:
                page.crewBottomBar {
                    PrimaryButton(title: model.resumeSession != nil ? "Resume workout" : "Start workout") { activeSession = model.startWorkout() }
                }
            case .paused:
                // A18.6c's string, unchanged — Settings and PauseScreen already use it (6.6: one action, one wording)
                page.crewBottomBar { SecondaryButton(title: "End the pause now") { Task { await model.endPause() } } }
            case .bridge, .rest, .allDone:
                page
            }
        }
    }

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                Text(model.dateLine) // A20.7
                    .font(EmberTokens.Typography.caption)
                    .foregroundStyle(EmberColors.secondaryText)
                HomeHeader(streak: model.streak, shields: model.shields, ringDone: model.ringDone, ringPlanned: model.ringPlanned, week: model.weeklyRing, isBridge: false, isPaused: isPaused)
                StateBlock(state: model.today, streak: model.streak, todaySummaryLines: model.todaySummaryLines)
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                    Text("TODAY'S LOG")
                        .font(EmberTokens.Typography.sectionLabel)
                        .foregroundStyle(EmberColors.secondaryText)
                    LogRowList(rows: model.logRows, onTap: tapped, onQuickComplete: { celebration = model.quickComplete(shareToCrew: true) })
                }
                if let nextUp = model.nextUp { NextUpRow(facts: nextUp) } // A20.1: last, on every state that has one
            }
            .padding(EmberTokens.Spacing.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .top) { banner } // A20.9: it cannot scroll away from what it explains
    }

    // A20.9 — the two facts SyncQueue publishes, not a constant sentence on an invisible strip.
    @ViewBuilder
    private var banner: some View {
        if loadState == .offline {
            OfflineBanner(lastSyncedLine: "Showing what you had — syncing when you're back.", pending: model.pendingToSend, lastSyncedAt: model.lastSyncedAt)
                .padding(.horizontal, EmberTokens.Spacing.space16)
                .padding(.bottom, EmberTokens.Spacing.space8)
        }
    }

    // The log list is Home's only launcher for all three vectors — SessionScreen, CardioLogScreen and
    // NutritionPostScreen each have exactly one call site, and it is here.
    private func tapped(_ row: HomeLogRow) {
        switch row.id {
        case "cardio": loggingCardio = true
        case "meal": posting = true
        default: if let session = model.startWorkout() { activeSession = session } else { choosingBonus = true }
        }
    }

    // SPEC: A17.4(c) / S07 — the title NAMES THE STATE, so the screen says what today is before anything else is read.
    // A20.7 reaffirms it: the date line was added ABOVE this rather than in place of it, and what A20.1 deleted is the
    // card headline that repeated it verbatim.
    private var title: String {
        switch model.today {
        case .bridge: return "Today" // §1D: a state name here is the first thing a brand-new user reads about a day they have not started
        case .workout(let name, _, _, _, _): return name
        case .rest: return "Rest day"
        case .paused: return "Plan paused"
        case .allDone: return "Done for today"
        }
    }

    private var isPaused: Bool { if case .paused = model.today { return true } else { return false } }
    private var isBridge: Bool { if case .bridge = model.today { return true } else { return false } }
    private var bridgeKind: BridgeKind { if case .bridge(let kind) = model.today { return kind } else { return .rest } }

    // A18.12 — the branch lives in HomeLoadState.of (5.6.6). A20.9 — COMPUTED, not `@State`: as stored state it was
    // assigned in one place inside `load()`, while eight paths call `model.refresh()` directly, so the banner and the
    // error layer were whatever they had been at the last foreground. This is the pattern CrewScreen.swift already uses.
    private var loadState: HomeLoadState {
        guard loaded else { return .loading }
        return HomeLoadState.of(loadError: model.loadError, hasPlan: model.hasPlan, offline: model.offline)
    }

    private func load() {
        model.refresh()
        loaded = true
        Signposts.endLaunchIfNeeded() // 8.8: launch → Home interval closes on the first real state
    }
}

// LocalSession is Identifiable + Hashable through PersistentModel (SwiftData) — no extension, or it is redundant
extension CelebrationOutcome: Identifiable {
    var id: String { postDraft.clientId }
}
