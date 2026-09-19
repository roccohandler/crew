// SPEC: S12 Crew screen — loading, empty (new crew), offline; pulse correct (3 AM day); unified stream time-ordered; posts as
// in-stream cards; long-press reactions; comeback banner; 7-day window · Flow 10 (solo: one warm invitation) · Part IV polling.
// A21.2 (owner-approved 2026-09-17): free-text chat is gone — there is NO composer on this screen; the stream is posts + system
// lines + reactions. A5 (owner-directed 2026-09-08): the header is pinned above the stream; a crew of one gets the invite card;
// the invite sheet follows a create. A21.3 / W4 (owner-approved 2026-09-17): the solo tab offers "I have an invite" (JoinByCodeSheet);
// 1C: the profile-photo prompt shows once after the first join or create, after any invite sheet is down. W7 (owner order 2026-09-18,
// item 3): a tapped invite link opens the same join sheet with the code filled and looked up (InviteInbox). Screens hold ZERO logic
// (5.6.6). A27 (b) · A28 (f) · R5: Manage crew is pushed from the tab (its own screen); Invite does only invite; the stream's cards,
// strip and lines are the system's (ink marks, no accent). R-092: the title is the page's own on the 20 pt gutter, with Manage and
// Invite beside it as the kit's text buttons (the navigation bar's large title sat on a 16 pt margin, and its items were 17 pt
// Regular); the stream opens scrolled to its newest post instead of pinning a short stream to the bottom, which left ~175 pt of
// empty canvas under the header. WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

enum CrewLoadState: Equatable {
    case loading
    case ready
    case solo
    case failed(String)
    case offline
}

struct CrewScreen: View {
    @State private var model = CrewModel()
    @State private var showsInvite = false
    @State private var managing = false // A27 (b): Manage crew, pushed from the tab
    @State private var showsCreate = false
    @State private var showsJoinByCode = false // A21.3
    @State private var showsPhotoPrompt = false // 1C
    private var myUserId: String { AuthStore.shared.currentUser?.id ?? "" }

    private var loadState: CrewLoadState {
        if let error = model.loadError, model.crew == nil { return .failed(error) }
        if !model.isLoaded && model.crew == nil { return .loading }
        if model.crew == nil { return .solo }
        return model.offline ? .offline : .ready
    }

    // SPEC: 1A · A21.3 · W7 — the link's token takes the same path as a pasted code; the server's refusals (already in a crew, full,
    // dead) read under the field exactly as they do for a paste (S13)
    private func openInviteFromLink() async {
        guard let code = InviteInbox.shared.consume() else { return }
        model.inviteCode = code
        showsJoinByCode = true
        await model.lookUpInvite()
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                switch loadState {
                case .loading: LoadingLine(line: "Loading your crew…").padding(EmberTokens.Focus.gutter) // 6.1 (2026-09-18): a line, not a skeleton
                case .solo: CrewSoloView(onStart: { showsCreate = true }, onHaveInvite: { showsJoinByCode = true })
                case .failed(let line): ErrorState(line: line) { Task { await model.refresh() } }
                case .ready, .offline: content
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Crew")
            .toolbar(.hidden, for: .navigationBar) // the title is the page's own; Manage crew keeps its bar
            .navigationDestination(isPresented: $managing) { ManageCrewScreen(model: model) }
            .sheet(isPresented: $showsInvite) { InviteScreen(model: model) }
            .sheet(isPresented: $showsCreate) { CreateCrewScreen(model: model) }
            .sheet(isPresented: $showsJoinByCode) { JoinByCodeSheet(model: model) }
            .sheet(isPresented: $showsPhotoPrompt) { ProfilePhotoPrompt { showsPhotoPrompt = false } }
            // 1C: the photo prompt waits for the invite sheet (after a create) or the code sheet (after a join) to come down, and
            // follows the crew's arrival when an invited signup lands here before its join has landed
            .onChange(of: showsInvite) { _, showing in if !showing, model.consumePhotoPrompt() { showsPhotoPrompt = true } }
            .onChange(of: showsJoinByCode) { _, showing in if !showing, model.consumePhotoPrompt() { showsPhotoPrompt = true } }
            .onChange(of: model.crew?.id) { _, id in if id != nil, !showsInvite, !showsJoinByCode, model.consumePhotoPrompt() { showsPhotoPrompt = true } }
            .onChange(of: showsCreate) { _, showing in if !showing, model.consumeInvitePrompt() { showsInvite = true } } // Flow 6: link follows the name
            .task { await model.refresh(); model.startPolling(); if model.consumePhotoPrompt() { showsPhotoPrompt = true } } // 1C: an invited signup lands here with the prompt pending
            .task(id: InviteInbox.shared.pendingCode) { await openInviteFromLink() }
            .onDisappear { model.stopPolling() }
        }
    }

    // A27 (b): Invite does only invite; Manage crew holds rename, the link, removal and leaving (text buttons in ink, A28 (f))
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space16) {
            Text("Crew").typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
            Spacer(minLength: EmberTokens.Spacing.space8)
            if model.crew != nil {
                TextActionButton(title: "Manage", horizontalPadding: 0, accessibilityLabel: "Manage crew", role: EmberTokens.Typography.textButton) { managing = true }
                TextActionButton(title: "Invite", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { showsInvite = true }
            }
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.top, EmberTokens.Spacing.space32)
        .padding(.bottom, EmberTokens.Spacing.space8)
    }

    // A5: strip and banner pinned above the scroll view; the stream opens at its newest post (nearest the thumb) — scrolled there, not
    // anchored, so a stream shorter than the screen starts under the header
    private var content: some View {
        VStack(spacing: 0) {
            if loadState == .offline, let synced = model.lastSyncedAt { OfflineBanner(lastSyncedLine: "Last synced \(synced.formatted(date: .omitted, time: .shortened)).").padding(.horizontal, EmberTokens.Focus.gutter) }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                if let crew = model.crew { MemberStrip(crewName: crew.name, emoji: crew.emoji, pulse: model.pulse, members: model.members) }
                if model.hasCrewmates { Whisper(.whyCrews) } // A23: a crew, not a crew of one
                if model.isCrewOfOne, let crew = model.crew { CrewOfOneCard(crew: crew, isCaptain: model.isCaptain) { model.copyInviteLink() }; Whisper(.howInvite) } // A23 · R-076
                if let notice = model.noticeLine { Text(notice).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).accessibilityAddTraits(.updatesFrequently) }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space8)
            ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    if model.stream.isEmpty && model.hasCrewmates {
                        Text("Quiet in here. Post a workout and it lands right here.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
                    }
                    StreamList(items: model.stream, members: model.members, myUserId: myUserId,
                               onReact: { postId, emoji in model.react(postId: postId, emoji: emoji) },
                               onReport: { postId in Task { await model.report(postId: postId) } },
                               onBlock: { userId in Task { await model.block(userId: userId) } })
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.vertical, EmberTokens.Spacing.space16)
            }
            .onAppear { if let last = model.stream.last?.itemId { reader.scrollTo(last, anchor: .bottom) } }
            .onChange(of: model.stream.last?.itemId) { _, last in if let last { withAnimation { reader.scrollTo(last, anchor: .bottom) } } }
            }
        }
    }
}
