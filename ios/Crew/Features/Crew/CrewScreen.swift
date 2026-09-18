// SPEC: S12 Crew screen — loading, empty (new crew), offline; pulse correct (3 AM day); unified stream time-ordered; posts as
// in-stream cards; long-press reactions; comeback banner; 7-day window · Flow 10 (solo: one warm invitation) · Part IV polling.
// A21.2 (owner-approved 2026-09-17): free-text chat is gone — there is NO composer on this screen; the stream is posts + system
// lines + reactions. A5 (owner-directed 2026-09-08): the header is pinned above the stream; a crew of one gets the invite card;
// the invite sheet follows a create. A21.3 / W4 (owner-approved 2026-09-17): the solo tab offers "I have an invite" (JoinByCodeSheet);
// 1C: the profile-photo prompt shows once after the first join or create, after any invite sheet is down. Screens hold ZERO logic
// (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T031

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

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: LoadingLine(line: "Loading your crew…").padding(EmberTokens.Spacing.space16) // 6.1 (2026-09-18): a line, not a skeleton
                case .solo: CrewSoloView(onStart: { showsCreate = true }, onHaveInvite: { showsJoinByCode = true })
                case .failed(let line): ErrorState(line: line) { Task { await model.refresh() } }
                case .ready, .offline: content
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Crew")
            .toolbar { if model.crew != nil { ToolbarItem(placement: .primaryAction) { Button("Invite") { showsInvite = true } } } }
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
            .onDisappear { model.stopPolling() }
        }
    }

    // A5: strip and banner pinned above the scroll view; the stream keeps its bottom anchor (the newest post is nearest the thumb)
    private var content: some View {
        VStack(spacing: 0) {
            if loadState == .offline, let synced = model.lastSyncedAt { OfflineBanner(lastSyncedLine: "Last synced \(synced.formatted(date: .omitted, time: .shortened)).") }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                if let crew = model.crew { MemberStrip(crewName: crew.name, emoji: crew.emoji, pulse: model.pulse, members: model.members) }
                if model.isCrewOfOne, let crew = model.crew { CrewOfOneCard(crew: crew, isCaptain: model.isCaptain) { model.copyInviteLink() } }
                if let notice = model.noticeLine { Text(notice).font(.footnote).foregroundStyle(EmberColors.secondaryText).accessibilityAddTraits(.updatesFrequently) }
            }
            .padding(.horizontal, EmberTokens.Spacing.space16)
            .padding(.top, EmberTokens.Spacing.space8)
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    if model.stream.isEmpty && model.hasCrewmates {
                        Text("Quiet in here. Post a workout and it lands right here.").font(.body).foregroundStyle(EmberColors.secondaryText)
                    }
                    StreamList(items: model.stream, members: model.members, myUserId: myUserId,
                               onReact: { postId, emoji in model.react(postId: postId, emoji: emoji) },
                               onReport: { postId in Task { await model.report(postId: postId) } },
                               onBlock: { userId in Task { await model.block(userId: userId) } })
                }
                .padding(EmberTokens.Spacing.space16)
            }
            .defaultScrollAnchor(.bottom)
        }
    }
}
