// SPEC: S05 — the plan survives auth failure/abandon and resumes at the save screen next launch. The pre-auth draft is
// plain JSON in the app's Application Support directory (no account exists yet, so nothing else can own it).
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct OnboardingDraft: Codable {
    let selectedDays: Set<Int>
    let experience: String?
    let equipment: String?
    let draft: PlanDraft?
    let inviteToken: String?
}

struct DraftStore {
    let url: URL

    init(url: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        self.url = url ?? support.appending(path: "onboarding-draft.json")
    }

    func load() -> OnboardingDraft? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.crew.decode(OnboardingDraft.self, from: data)
    }

    func save(_ draft: OnboardingDraft) {
        guard let data = try? JSONEncoder.crew.encode(draft) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
