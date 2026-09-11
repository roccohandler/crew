// SPEC: 6.1 The Five States Law (loading · ready · empty · error · offline) · A18.12 · 5.6.6 (a screen holds zero logic).
//
// A18.12 — WHY THIS IS A FUNCTION AND NOT A BRANCH INSIDE THE VIEW. `HomeScreen` declared five states and `load()`
// could only ever assign three of them: `.offline` had no assignment anywhere, so Home's OfflineBanner had never
// rendered on any device. Meanwhile 6.1 was certified by a test that builds a five-element literal array and asserts
// it has five elements — a test that cannot fail and says nothing about whether a state can be reached.
//
// Making the decision a pure function makes reachability testable without a Mac: ShellStatesTests now feeds real
// inputs and checks that every state comes back out. `.loading` is the initial value and the only one that is not a
// function of the model, which is why it is not returned here.
//
// Home is Store-only by design (S07: correct today-state < 500 ms warm, nothing waits on the network), so it cannot
// discover the network itself. `SyncQueue` already distinguishes "offline" from "failed" for E6 ("no network is not a
// failed attempt") and now publishes it; `.ready` and `.offline` render identical content, and the thin banner is the
// whole difference.

import Foundation

enum HomeLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline

    // Order matters and is stated once: an error outranks everything (there is nothing to show), no plan outranks
    // the network (the fix is onboarding, not a reconnect), and offline is a qualifier on a screen that already works.
    static func of(loadError: String?, hasPlan: Bool, offline: Bool) -> HomeLoadState {
        if let loadError { return .failed(loadError) }
        if !hasPlan { return .empty }
        return offline ? .offline : .ready
    }
}
