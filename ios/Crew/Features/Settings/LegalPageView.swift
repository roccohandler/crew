// SPEC: A7 (owner-directed 2026-09-08) — Privacy policy and Terms open {APP_BASE_URL}/privacy and /terms in an in-app browser
// (SFSafariViewController; first-party, zero dependencies — Part IV). The pages are the web app's static placeholders until the
// owner replaces them. WRITTEN — UNVERIFIED (needs Mac). T041

import SafariServices
import SwiftUI

enum LegalPage: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
