// SPEC: S07 Home — all five states; the BRIDGE until the first post (1D); today-state < 500 ms warm; ≤3 taps launch→fast-logged;
// Quick Complete hidden once today counts; Resume banner when a session is open; crew strip absent for solo. A3 (owner-directed
// 2026-09-08): a camera toolbar button ("Post a meal") on every non-bridge state, Log cardio under the workout card, the Bonus
// workout sheet, the what's-next line. Part III law ④: the flame is the first ember the user sees. Screens hold ZERO logic
// (5.6.6). A21.9 (owner-approved 2026-09-17): the celebration's two buttons are the only way out and the post follows the tap;
// A21.4: the reminder opt-in follows the FIRST completed workout's celebration, once. WRITTEN — UNVERIFIED (needs Mac). T024

import SwiftUI

struct HomeScreen: View {
    @State private var model = HomeModel(welcomeBackAckDay: AuthStore.shared.currentUser?.welcomeBackAckDay) // E4: the account remembers the answer (as ProgressScreen and SettingsScreen read units)
    @State private var loaded = false
    @State private var activeSession: LocalSession?
    @State private var celebration: CelebrationOutcome?
    @State private var posting = false
    @State private var rebuilding = false
    @State private var choosingBonus = false
    @State private var loggingCardio = false
    @State private var offerReminder = false // A21.4: decided when a celebration is answered, presented once the sheet is down
    @State private var showsReminder = false
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
            // A3 gave every non-bridge state a camera. A18.10 NARROWS it: not on a state whose CARD already offers a
            // meal CTA. On the rest day the owner photographed, posting was reachable three ways at three weights —
            // an unlabelled nav glyph, an ink-filled card primary and a slot — and the glyph was the screen's only
            // unlabelled control. Apple's own navigation guidance names that redundancy as a cause of confusion.
            .toolbar { if showsCameraButton { ToolbarItem(placement: .primaryAction) { postButton } } }
            .navigationDestination(item: $activeSession) { session in SessionScreen(session: session) { outcome in activeSession = nil; celebration = outcome; model.refresh() } }
            .navigationDestination(isPresented: $loggingCardio) { CardioLogScreen { outcome in loggingCardio = false; celebration = outcome; model.refresh() } } // A2: then the normal celebration
            // SPEC: A21.9 — no swipe-to-dismiss: a celebration is answered by one of its two buttons or not at all; the tapped
            // button posts (answerCelebration), then the sheet comes down, then — after the first workout — the reminder opt-in (A21.4)
            .sheet(item: $celebration, onDismiss: { if offerReminder { offerReminder = false; showsReminder = true } }) { outcome in
                CelebrationScreen(outcome: outcome) { share in model.answerCelebration(outcome, shareToCrew: share); offerReminder = model.shouldOfferReminder(); celebration = nil }
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showsReminder) { ReminderOptInSheet(userId: model.userId, storedReminderTime: AuthStore.shared.currentUser?.reminderTime) { showsReminder = false } }
            .sheet(isPresented: $posting) { NutritionPostScreen { posting = false; model.refresh() } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
            .sheet(isPresented: $choosingBonus) { BonusWorkoutSheet(workouts: model.bonusWorkouts) { workout in choosingBonus = false; activeSession = model.startBonus(workout) } }
            .task { model.postUnanswered(); load() } // A21.9: a celebration the app died under posts privately first
            .onChange(of: scenePhase) { _, phase in if phase == .active, loaded { load() } } // E8/V04: elapsed days are judged on every foreground
            .modifier(EdgePrompts(model: model, onKeepGoing: { activeSession = model.keepGoingWithStaleSession() }, onRebuild: { rebuilding = true }))
        }
    }

    // SPEC: A14 — three groups with real rhythm (sectionGap between, rowGap within) instead of a uniform 16 pt between every
    // element. F09 measured Home at 24–66% dead canvas with its whole interactive surface ending ~385 pt from the top: the
    // emptiness read as absence rather than confidence precisely BECAUSE nothing was grouped. The fix is content and rhythm,
    // not less whitespace. 6.7 already requires the controls to bottom-anchor into the thumb zone at Pro Max — the
    // minHeight + Spacer does that here without stealing the scroll when the day is a long one.
    private var content: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                    // A20.9 — the banner states the two facts the queue publishes instead of one constant sentence.
                    if loadState == .offline {
                        OfflineBanner(lastSyncedLine: "Showing what you had — syncing when you're back.", pending: model.pendingToSend, lastSyncedAt: model.lastSyncedAt)
                    }
                    // A18.8 — NOT on the bridge. The bridge lasts until the first POST and starting a workout is not a
                    // post, so an abandoned first workout put this banner beside the bridge's own CTA: two prompts on
                    // the one screen §1D says carries none. The bridge's single button resumes instead (TodayCard).
                    if let session = model.resumeSession, !isBridge { SecondaryButton(title: "Resume workout · \(session.workoutName)") { activeSession = session } }
                    HomeHeader(streak: model.streak, shields: model.shields, ringDone: model.ringDone, ringPlanned: model.ringPlanned, week: model.weeklyRing, isBridge: isBridge, isPaused: isPaused)
                    // A17.2 / H019 — the flexible space moved from BELOW the card to ABOVE it. Under A14 it sat after
                    // the card, so on every short state (rest, all-done, paused) the day's ink-filled primary was
                    // stranded in the upper half and the slack became one contiguous hole — ~29% of the screen on
                    // `.paused`, where the card renders no controls at all. Here the slack is a section break under
                    // the header group, and the card, its primary and the vector row all sit in the thumb zone.
                    // A18.3 — THE SPACE GETS CONTENT. Idle states only (rest · all-done): on a workout day the card
                    // IS what is next, and that state is the tallest on the smallest phone (H009).
                    if let nextUp = model.nextUp, !isBridge { NextUpBlock(facts: nextUp) }
                    Spacer(minLength: 0)
                    TodayCard(state: model.today,
                              streak: model.streak,
                              nextUpLine: model.nextUpLine,
                              todaySummaryLines: model.todaySummaryLines,
                              resuming: model.resumeSession != nil,
                              onStart: { activeSession = model.startWorkout() },
                              onPost: { posting = true },
                              onEndPause: { Task { await model.endPause() } })
                    if model.quickCompleteAvailable, !isBridge { SecondaryButton(title: "Quick complete") { celebration = model.quickComplete() } }
                    if !isBridge { // §1D: the bridge carries one CTA and nothing else, ever
                        // A17.1 / H034 — sectionGap, not rowGap. These were bound at 8 pt, the gap design-tokens.json
                        // documents as "within one group", while every real boundary on this screen is 24 — so the
                        // layout asserted the crew avatar was a fourth vector slot.
                        VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                            // A14 — the three vectors as peers. Every standalone duplicate that used to sit here or in
                            // the card (Log cardio, Bonus workout) is gone: these ARE those affordances now, at a
                            // position that no longer moves between states (F10, A17.3).
                            VectorRow(slots: model.vectors,
                                      onWorkout: { if let session = model.startWorkout() { activeSession = session } else { choosingBonus = true } },
                                      onCardio: { loggingCardio = true },
                                      onMeal: { posting = true })
                            // absent (not empty) for solo AND below crewMinMembers (A17.1)
                            if let members = model.crewStrip {
                                VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                                    // A17.1 — the strip was a bare avatar with an unexplained dot and numeral. Ink,
                                    // never tappable (law ①): the Crew tab is where a member opens.
                                    Text("Your crew").font(.caption).foregroundStyle(EmberColors.secondaryText)
                                    CrewStrip(members: members)
                                }
                            }
                        }
                    }
                }
                .padding(EmberTokens.Spacing.space16)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
        }
    }

    // Ink, like every control (Part III law ①); the label is the a11y name — the glyph alone says nothing to VoiceOver
    private var postButton: some View {
        // 6.3: a bare toolbar Image is hit-tested at the glyph (~22×18 pt) plus whatever padding UIKit happens to add;
        // the frame and contentShape make the target explicit rather than inherited
        Button { posting = true } label: {
            Image(systemName: "camera")
                .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Post a meal")
    }

    // SPEC: A17.4 / S07 — the title NAMES THE STATE, so the screen says what today is before anything else is read.
    // The BRIDGE keeps "Today": §1D says that screen carries one CTA and nothing else, and a state name there would be
    // the first thing a brand-new user reads about a day they have not started.
    private var title: String {
        switch model.today {
        case .bridge: return "Today"
        case .workout(let name, _, _, _, _): return name
        case .rest: return "Rest day"
        case .paused: return "Plan paused"
        case .allDone: return "Done for today"
        }
    }

    private var isPaused: Bool { if case .paused = model.today { return true } else { return false } }
    private var isBridge: Bool { if case .bridge = model.today { return true } else { return false } } // 1D: nothing else competes

    // A18.10 — no camera where the card already asks for a meal. Rest is the state that asks (a filled "Post a meal"
    // before the day counts, an outline "Post another" after); every other state keeps the glyph, because there the
    // camera is the only nav-level route and "Log a meal" is a row rather than a screen-level action.
    private var showsCameraButton: Bool {
        if isBridge { return false } // §1D
        if case .rest = model.today { return false }
        return true
    }

    // A18.12 — the branch lives in HomeLoadState.of (5.6.6: a screen holds zero logic), which is also what makes
    // `.offline` — declared since T013 and assigned nowhere — testable as REACHABLE rather than merely declared.
    //
    // A20.9 — IT IS COMPUTED, NOT `@State`. As stored state it was assigned in exactly ONE place, inside `load()`,
    // which runs on `.task` and on `scenePhase → .active` and nowhere else — while EIGHT paths call `model.refresh()`
    // directly (the session and cardio completions, the celebration and nutrition sheet dismissals, `endPause`,
    // `startBonus`, `quickComplete`, and the edge prompts). So after logging anything, the banner and the error layer
    // were whatever they had been at the last foreground: `loadError` could be set inside `refresh()` and the screen
    // would not become `.failed` until the app was backgrounded and reopened. Computing it over the `@Observable`
    // model is the pattern CrewScreen.swift:21-26 already uses, and it deletes the whole class of bug.
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

// LocalSession is Identifiable + Hashable through PersistentModel (SwiftData) — no extension, or the conformance is redundant
extension CelebrationOutcome: Identifiable {
    var id: String { postDraft.clientId }
}
