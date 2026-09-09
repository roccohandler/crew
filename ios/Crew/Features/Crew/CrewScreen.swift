// SPEC: S12 Crew screen — loading, empty (new crew), offline; pulse correct (3 AM day); unified stream time-ordered; posts as
// in-stream cards; long-press reactions; comeback banner; 7-day window · Flow 10 (solo: one warm invitation) · Part IV polling.
// A5 (owner-directed 2026-09-08): the header is pinned above the stream; a crew of one gets the invite card and no composer;
// the invite sheet follows a create. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). T031

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
                case .loading: ListSkeleton()
                case .solo: CrewSoloView { showsCreate = true }
                case .failed(let line): ErrorState(line: line) { Task { await model.refresh() } }
                case .ready, .offline: content
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Crew")
            .toolbar { if model.crew != nil { ToolbarItem(placement: .primaryAction) { Button("Invite") { showsInvite = true } } } }
            .sheet(isPresented: $showsInvite) { InviteScreen(model: model) }
            .sheet(isPresented: $showsCreate) { CreateCrewScreen(model: model) }
            .onChange(of: showsCreate) { _, showing in if !showing, model.consumeInvitePrompt() { showsInvite = true } } // Flow 6: link follows the name
            .task { await model.refresh(); model.startPolling() }
            .onDisappear { model.stopPolling() }
        }
    }

    // A5: strip and banner pinned above the scroll view; only the stream keeps the chat-style bottom anchor
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
                    if model.stream.isEmpty && model.canCompose {
                        Text("Quiet in here. Post a workout or a plate and it lands right here.").font(.body).foregroundStyle(EmberColors.secondaryText)
                    }
                    StreamList(items: model.stream, members: model.members, myUserId: myUserId,
                               onReact: { postId, emoji in model.react(postId: postId, emoji: emoji) },
                               onReport: { postId in Task { await model.report(postId: postId) } },
                               onBlock: { userId in Task { await model.block(userId: userId) } })
                }
                .padding(EmberTokens.Spacing.space16)
            }
            .defaultScrollAnchor(.bottom)
            if model.canCompose { composer }
        }
    }

    private var composer: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            TextField("Say something", text: $model.draft, axis: .vertical)
                .lineLimit(1...SpecConstants.chatComposerMaxLines)
                .padding(EmberTokens.Spacing.space12)
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
            Button { model.send() } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title).foregroundStyle(EmberColors.inkText)
                    .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .buttonStyle(.plain)
            .disabled(model.draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Send")
        }
        .padding(EmberTokens.Spacing.space12)
        .background(EmberColors.canvas)
    }
}
