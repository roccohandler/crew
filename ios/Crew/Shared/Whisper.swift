// SPEC: A23 (Appendix A 2026-09-18, the education layer) · docs/education-copy-draft.md §A — a WHISPER: one line that explains why
// the app works the way it does or how to use it, shown ONCE, the first time its moment arrives. secondaryText ink directly under the
// element it explains — no border, no card, no icon, never orange (law ③); never in a modal or a sheet, never on the bridge (the
// caller's gate). It leaves on the first tap anywhere on the screen (RootView's one gesture → WhisperState.clearVisible); two on one
// screen leave together. VoiceOver hears it once, on appearance (rule 6). Every line lives in ONE file, shared/copy/education.json
// (Generated/CopyData.swift), and an id that does not exist cannot compile (WhisperId). 1A stands: teach by doing, not touring.
// Twin of web components/Whisper.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

// shared/copy/education.json, decoded once: the whispers and the How Crew works page (S19)
struct EducationCopy: Decodable {
    struct WhisperLine: Decodable, Identifiable {
        let id: String
        let line: String
        let moment: String
        let gate: String              // all | adult (behind the 18+ nutrition gate, A16.c)
    }

    struct Source: Decodable {
        let label: String
        let url: String
        let gate: String
    }

    struct PageSection: Decodable, Identifiable {
        let id: String
        let heading: String
        let body: String
        let adultBody: String
        let source: Source?
    }

    struct Note: Decodable {
        let draft: Bool
        let heading: String
        let body: String
    }

    struct Page: Decodable {
        let title: String
        let note: Note
        let sections: [PageSection]
        let whispersHeading: String
        let clinician: String
    }

    let whispers: [WhisperLine]
    let page: Page

    // Generated at build time from the shared file, so a decode failure is a build defect, not a runtime state
    static let shared: EducationCopy = {
        do { return try JSONDecoder().decode(EducationCopy.self, from: Data(CopyData.educationJSON.utf8)) } catch { fatalError("education copy failed to decode: \(error)") }
    }()

    func line(_ id: WhisperId) -> String { whispers.first { $0.id == id.rawValue }?.line ?? "" }
}

struct Whisper: View {
    let id: WhisperId
    private let state = WhisperState.shared

    init(_ id: WhisperId) { self.id = id }

    var body: some View {
        if state.shouldShow(id) {
            Text(EducationCopy.shared.line(id))
                .font(.footnote)
                .foregroundStyle(EmberColors.secondaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps, it never widens the column
                .onAppear {
                    state.appeared(id)
                    UIAccessibility.post(notification: .announcement, argument: EducationCopy.shared.line(id)) // rule 6: read once, on appearance
                }
                .onDisappear { state.disappeared(id) }
        }
    }
}
