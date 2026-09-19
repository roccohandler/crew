// SPEC: A23 (Appendix A 2026-09-18) · docs/education-copy-draft.md §C, §D — S19 "How Crew works": the one re-readable page behind
// the whispers, reached from Settings → About (a row above Version). One scrolling page, nothing interactive but links (every source
// opens in the in-app browser the legal pages use): the note from Max (the owner's own, ratified 2026-09-19 — R-081; a "Draft" label
// shows only while page.note.draft is true, and it is false), the seven sections
// in the owner's order, what the whispers said — verbatim, in trigger order — and the A16.a line. The page renders for every age;
// under 18, or with no birth year on file, the Protein section drops its numeric sentence and its source link and the three nutrition
// whispers are omitted — with no copy about the omission (A16.c: no upsell). Every word is shared/copy/education.json, so the web
// prints the same page. Ink and secondary ink only: no orange text (law ③). Twin of web (app)/how-crew-works.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct HowCrewWorksScreen: View {
    private let copy = EducationCopy.shared
    private let adult = AuthStore.shared.nutrition == .available
    @State private var opened: SourceLink?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                Card {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                        Text(copy.page.note.heading).font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
                        if copy.page.note.draft { Text("Draft").font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                        Text(copy.page.note.body).font(.body).foregroundStyle(EmberColors.inkText)
                    }
                }
                ForEach(copy.page.sections) { section in
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                        Text(section.heading).font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
                        Text(adult && !section.adultBody.isEmpty ? "\(section.body) \(section.adultBody)" : section.body).font(.body).foregroundStyle(EmberColors.inkText)
                        if let source = section.source, source.gate == "all" || adult, let url = URL(string: source.url) {
                            Button { opened = SourceLink(id: section.id, url: url) } label: {
                                Text(source.label).font(.footnote).underline().foregroundStyle(EmberColors.secondaryText).multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
                            }
                            .accessibilityAddTraits(.isLink)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                    Text(copy.page.whispersHeading).font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
                    ForEach(copy.whispers.filter { $0.gate == "all" || adult }) { whisper in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(whisper.line).font(.body).foregroundStyle(EmberColors.inkText)
                            Text(whisper.moment).font(.footnote).foregroundStyle(EmberColors.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                Text(copy.page.clinician).font(.footnote).foregroundStyle(EmberColors.secondaryText)
            }
            .padding(EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(copy.page.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { link in SafariView(url: link.url).ignoresSafeArea() }
    }
}
