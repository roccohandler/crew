// SPEC: 5.6.2 CrewModel — state: crew?, stream (time-merged, 7-day window), members, pulse, draft; actions: poll (foreground
// 5–10 s) · send · react · unreact · create · join · leave · captainRemove · regenerateLink · report · block. Part IV (chat =
// polling). 6.1 Offline: social shows last-synced (LocalCrewSnapshot) + one thin banner. Optimistic sends through SyncQueue.
// A5 (owner-directed 2026-09-08): a crew of one has no composer; the invite sheet follows a create; report/block one long-press
// away (E9). WRITTEN — UNVERIFIED (needs Mac). T031 + T032 (crew rules already in CrewRules.swift)

import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class CrewModel {
    var crew: CrewDTO?
    var stream: [StreamItemDTO] = []
    var members: [MemberDot] = []
    var pulse = PulseDTO(posted: 0, total: 0)
    var draft = ""
    var offline = false
    var loadError: String?
    var lastSyncedAt: Date?
    var isLoaded = false
    var noticeLine: String?            // one-line confirmations: reported · blocked · link copied
    private var invitePromptPending = false

    private let store: Store
    private var pollTask: Task<Void, Never>?

    init(store: Store = .shared) {
        self.store = store
        loadSnapshot()
    }

    var isSolo: Bool { crew == nil }
    var isCaptain: Bool { crew?.captainId == AuthStore.shared.currentUser?.id }
    // SPEC: A5 — a crew of one shows the invite card and no composer until two members (crewMinMembers)
    var isCrewOfOne: Bool { crew != nil && members.count < SpecConstants.crewMinMembers }
    var canCompose: Bool { crew != nil && members.count >= SpecConstants.crewMinMembers }

    // 6.1 Offline — the last-synced stream from SwiftData, instantly
    private func loadSnapshot() {
        guard let snapshot = try? store.crewSnapshot() else { return }
        crew = CrewDTO(id: snapshot.crewId, name: snapshot.name, emoji: snapshot.emoji, captainId: snapshot.captainId, inviteLink: snapshot.inviteToken, muted: nil)
        stream = (try? JSONDecoder.crew.decode([StreamItemDTO].self, from: snapshot.streamJSON)) ?? []
        members = (try? JSONDecoder.crew.decode([MemberDot].self, from: snapshot.membersJSON)) ?? []
        lastSyncedAt = snapshot.syncedAt
    }

    func refresh() async {
        do {
            let mine = try await Api.shared.myCrew()
            crew = mine.crew
            if let crew = mine.crew {
                let feed = try await Api.shared.stream(crewId: crew.id, since: nil)
                stream = feed.items
                members = feed.members
                pulse = feed.pulse
                lastSyncedAt = feed.serverTime
                try saveSnapshot(crew: crew, feed: feed)
            } else {
                members = []
                stream = []
                if let snapshot = try? store.crewSnapshot() { store.context.delete(snapshot); try? store.save() }
            }
            offline = false
            loadError = nil
        } catch AppError.offline {
            offline = true
        } catch let error as AppError {
            loadError = error.userLine
        } catch {
            loadError = AppError.invalidResponse.userLine
        }
        isLoaded = true
    }

    private func saveSnapshot(crew: CrewDTO, feed: StreamDTO) throws {
        if let existing = try store.crewSnapshot() { store.context.delete(existing) }
        store.context.insert(LocalCrewSnapshot(crewId: crew.id, name: crew.name, emoji: crew.emoji, captainId: crew.captainId, inviteToken: crew.inviteLink, streamJSON: try JSONEncoder.crew.encode(feed.items), membersJSON: try JSONEncoder.crew.encode(feed.members), syncedAt: feed.serverTime))
        try store.save()
    }

    // SPEC: Part IV chat = polling 5–10 s while the screen is in the foreground
    func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(SpecConstants.chatPollIntervalMinSeconds))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
        noticeLine = nil
    }

    // Optimistic send: the line appears at once, the op goes through the queue (E6: chat holds drafts offline)
    func send() {
        guard let crew, !draft.trimmingCharacters(in: .whitespaces).isEmpty, let me = AuthStore.shared.currentUser?.id else { return }
        let body = String(draft.prefix(SpecConstants.chatMessageMaxChars))
        let clientId = UUID().uuidString.lowercased()
        stream.append(StreamItemDTO(kind: "message", at: Date(), userId: me, post: nil, reactions: nil, comeback: nil, id: clientId, body: body, deleted: false))
        try? SyncQueue.shared.enqueue(.sendMessage, payload: SendMessagePayload(crewId: crew.id, clientId: clientId, body: body))
        draft = ""
    }

    // Long-press a post → 🔥 💪 👏 😂 ❤️; tap again to un-react (E20). Reaction XP is the server's call (V27).
    func react(postId: String, emoji: String) {
        guard let me = AuthStore.shared.currentUser?.id else { return }
        let alreadyMine = stream.first { $0.post?.id == postId }?.reactions?.contains { $0.userId == me && $0.emoji == emoji } ?? false
        if alreadyMine {
            try? SyncQueue.shared.enqueue(.unreact, payload: UnreactPayload(postId: postId))
        } else {
            try? SyncQueue.shared.enqueue(.react, payload: ReactPayload(postId: postId, emoji: emoji))
            Haptics.play(.softTap)
        }
        stream = stream.map { item in
            guard item.post?.id == postId else { return item }
            var reactions = (item.reactions ?? []).filter { $0.userId != me }
            if !alreadyMine { reactions.append(ReactionSummaryDTO(emoji: emoji, userId: me)) }
            return StreamItemDTO(kind: item.kind, at: item.at, userId: item.userId, post: item.post, reactions: reactions, comeback: item.comeback, id: item.id, body: item.body, deleted: item.deleted)
        }
    }

    // SPEC: E9 — report from the stream: the post goes to the human moderation queue, the reporter hears one line
    func report(postId: String) async {
        do {
            _ = try await Api.shared.report(targetType: "post", targetId: postId, reason: "Reported from the crew stream")
            noticeLine = "Reported. A human will look."
        } catch let error as AppError { noticeLine = error.userLine } catch { noticeLine = AppError.invalidResponse.userLine }
    }

    // SPEC: E9 — block hides content both ways, silently; their items leave the stream at once, the server keeps them out
    func block(userId: String) async {
        do {
            _ = try await Api.shared.block(userId: userId)
            stream.removeAll { $0.userId == userId }
            noticeLine = "Blocked. You won't see each other."
        } catch let error as AppError { noticeLine = error.userLine } catch { noticeLine = AppError.invalidResponse.userLine }
    }

    // SPEC: A5 — the link is first-class: Copy link sits beside the share sheet on the crew-of-one card
    func copyInviteLink() {
        guard let link = crew?.inviteLink else { return }
        UIPasteboard.general.string = link
        noticeLine = "Link copied."
    }

    // SPEC: Flow 6 — after a successful create the invite sheet opens by itself (A5); the screen asks once and the flag resets
    func consumeInvitePrompt() -> Bool {
        defer { invitePromptPending = false }
        return invitePromptPending
    }

    func create(name: String, emoji: String) async {
        do {
            crew = try await Api.shared.createCrew(name: name, emoji: emoji).crew
            invitePromptPending = true
            await refresh()
        } catch let error as AppError { loadError = error.userLine } catch { loadError = AppError.invalidResponse.userLine }
    }

    func join(token: String) async {
        do { _ = try await Api.shared.joinCrew(token: token); await refresh() } catch let error as AppError { loadError = error.userLine } catch { loadError = AppError.invalidResponse.userLine }
    }

    func leave() async {
        guard let crew else { return }
        do { _ = try await Api.shared.leaveOrRemove(crewId: crew.id, userId: nil); self.crew = nil; await refresh() } catch let error as AppError { loadError = error.userLine } catch {}
    }

    func captainRemove(memberId: String) async {
        guard let crew, isCaptain else { return }
        do { _ = try await Api.shared.leaveOrRemove(crewId: crew.id, userId: memberId); await refresh() } catch let error as AppError { loadError = error.userLine } catch {}
    }

    func regenerateLink() async {
        guard let crew, isCaptain else { return }
        if let reply = try? await Api.shared.regenerateInvite(crewId: crew.id) { self.crew = CrewDTO(id: crew.id, name: crew.name, emoji: crew.emoji, captainId: crew.captainId, inviteLink: reply.inviteLink, muted: crew.muted) }
    }
}
