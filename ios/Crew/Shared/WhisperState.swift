// SPEC: A23 (Appendix A 2026-09-18, the education layer) · docs/education-copy-draft.md §A rule 7 — WHICH WHISPERS THIS ACCOUNT HAS
// ALREADY SEEN, on any device. The server holds the list (`user.whispersSeen`, a union that never shrinks); this holder keeps
// seen = the server's list ∪ a per-account local set in UserDefaults, so a whisper dismissed offline never shows twice: markSeen writes
// the local set at once and PATCHes the WHOLE set when it can (idempotent — there is no sync op for it), and every signed-in launch and
// foreground re-sends whatever the server has not acknowledged. Before an account exists (the plan reveal) the set is the phone's own
// ("anon") and joins the account at the first signed-in load. `visible` is what is on screen now: the first tap anywhere clears it
// (RootView's one listener, AnyTapWatcher — rule 4; whispers never render in a sheet, rule 3). One @Observable holder (5.6.2), plain functions, and the
// sender is a plain function passed at init so tests run without a network (C3, C4). Twin of web components/Whisper.tsx.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

@Observable
@MainActor
final class WhisperState {
    // The signed-in account is read HERE, synchronously, so the FIRST frame already knows what has been seen: a whisper that showed
    // and then vanished a moment later would move every control under it (the web build lost a tap to exactly that, journey ⑤)
    @ObservationIgnored static let shared = WhisperState(defaults: .standard, userId: AuthStore.shared.currentUser?.id, serverSeen: AuthStore.shared.currentUser?.whispersSeen ?? [], send: WhisperState.patch)

    private(set) var seen: Set<String> = []
    @ObservationIgnored private var visible: Set<String> = []
    @ObservationIgnored private var userId: String?
    @ObservationIgnored private var acknowledged: Set<String> = []   // what the server is known to hold
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let send: ([String]) async -> [String]?

    init(defaults: UserDefaults, userId: String? = nil, serverSeen: [String] = [], send: @escaping ([String]) async -> [String]?) {
        self.defaults = defaults
        self.send = send
        adopt(userId: userId, serverSeen: serverSeen)
    }

    private static func key(_ userId: String?) -> String { "whispersSeen.\(userId ?? "anon")" }

    // PATCH users/me { whispersSeen } → the server's union, or nil when it could not be reached (offline is not a failure, E6)
    private static func patch(_ ids: [String]) async -> [String]? {
        guard let user = try? await Api.shared.updateMe(UpdateMeRequestDTO(whispersSeen: ids)) else { return nil }
        AuthStore.shared.updateCurrentUser(user)
        return user.whispersSeen ?? []
    }

    func shouldShow(_ id: WhisperId) -> Bool { !seen.contains(id.rawValue) }

    // Every signed-in frame and every change of the account's list: the phone's own ("anon") set joins the account's, the server's
    // list joins both, and anything the server has not acknowledged goes up
    func load(userId: String?, serverSeen: [String]) async {
        adopt(userId: userId, serverSeen: serverSeen)
        await resendIfNeeded()
    }

    // The synchronous half: what this phone holds and what the server said, merged and written back
    private func adopt(userId: String?, serverSeen: [String]) {
        self.userId = userId
        acknowledged = Set(serverSeen)
        var local = Set(defaults.stringArray(forKey: WhisperState.key(userId)) ?? [])
        if userId != nil {
            local.formUnion(defaults.stringArray(forKey: WhisperState.key(nil)) ?? [])
            defaults.removeObject(forKey: WhisperState.key(nil))
        }
        local.formUnion(serverSeen)
        defaults.set(Array(local).sorted(), forKey: WhisperState.key(userId))
        seen = local
    }

    // A7 — a real log out (and the UI tests' -resetState): the next person on this phone starts from nothing — the phone's own set is
    // forgotten, so a new signup sees the reveal's whispers; an account's set stays on the phone under its id and returns with it
    func signedOut() {
        userId = nil
        acknowledged = []
        visible = []
        defaults.removeObject(forKey: WhisperState.key(nil))
        seen = []
    }

    func appeared(_ id: WhisperId) { visible.insert(id.rawValue) }
    func disappeared(_ id: WhisperId) { visible.remove(id.rawValue) }

    // SPEC: §A rule 4 — the first tap anywhere on the screen: every whisper showing leaves together, for good
    func clearVisible() {
        guard !visible.isEmpty else { return }
        markSeen(visible)
        visible = []
    }

    // The tap's own half (AnyTapWatcher): WHAT leaves is decided at the tap, the leaving happens one main-queue turn later — so the
    // row never changes a List inside the touch that is selecting another row, and a whisper on the screen that same tap OPENS is not
    // taken with it (CI run 35345590260: the tap on the Settings tab cleared Settings' pause whisper before anyone had seen it).
    func clearVisibleAfterThisTap() {
        guard !visible.isEmpty else { return }
        let leaving = visible
        visible = []
        DispatchQueue.main.async { self.markSeen(leaving) }
    }

    func markSeen(_ ids: Set<String>) {
        seen.formUnion(ids)
        defaults.set(Array(seen).sorted(), forKey: WhisperState.key(userId))
        Task { await resendIfNeeded() }
    }

    // The whole local set, never a delta: a PATCH that was lost offline is repaired by the next one
    func resendIfNeeded() async {
        guard userId != nil, !seen.isSubset(of: acknowledged) else { return }
        guard let server = await send(Array(seen).sorted()) else { return }
        acknowledged = Set(server)
    }
}
