// SPEC: A16.a (REQUIRED, not optional — App Review 1.4.1 covers "calculations") · nutrition addendum §3 — How targets are estimated:
// every factor named, every source a LINK that opens in the in-app browser the legal pages use, and the estimate-and-clinician line.
// The words are shared/copy/nutrition-method.json (Generated/CopyData.swift), so the web prints the same page and every number in it
// is a constant resolved by the generator. Ink only. R-093: a source is the kit's text button — ink, Semibold, no underline — and the
// page sits on the 20 pt gutter (ui-reviewer, run 35445082374). Twin of web nutrition/method. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct NutritionMethodCopy: Decodable {
    struct Step: Decodable, Identifiable {
        let heading: String
        let body: String
        let sourceIds: [String]
        var id: String { heading }
    }

    struct Source: Decodable, Identifiable {
        let id: String
        let label: String
        let url: String
    }

    let title: String
    let lead: String
    let steps: [Step]
    let clinician: String
    let sources: [Source]

    // Generated at build time from the shared file, so a decode failure is a build defect, not a runtime state
    static let shared: NutritionMethodCopy = {
        do { return try JSONDecoder().decode(NutritionMethodCopy.self, from: Data(CopyData.nutritionMethodJSON.utf8)) } catch { fatalError("nutrition-method copy failed to decode: \(error)") }
    }()
}

struct SourceLink: Identifiable {
    let id: String
    let url: URL
}

struct NutritionMethodScreen: View {
    private let copy = NutritionMethodCopy.shared
    @State private var opened: SourceLink?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                Text(copy.lead).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                ForEach(copy.steps) { step in
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                        Text(step.heading).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                        Text(step.body).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                        ForEach(copy.sources.filter { step.sourceIds.contains($0.id) }) { source in
                            Button { opened = URL(string: source.url).map { SourceLink(id: source.id, url: $0) } } label: {
                                Text(source.label).typeRole(EmberTokens.Typography.textButton).foregroundStyle(EmberColors.ink).multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(.isLink)
                        }
                    }
                }
                Text(copy.clinician).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(copy.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { link in SafariView(url: link.url).ignoresSafeArea() }
    }
}
