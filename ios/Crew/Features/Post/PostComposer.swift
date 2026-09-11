// SPEC: Flow 4 — meal tag pre-guessed by time of day (one tap only if wrong) · "Same as yesterday" chip · text-only is legit ·
// same-day backfill "earlier today" · caption ≤ 280 (E20) · share toggle. WRITTEN — UNVERIFIED (needs Mac). T027

import SwiftUI

struct PostComposer: View {
    @Bindable var model: PostModel
    let hasCrew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            if let photo = model.photo {
                Image(uiImage: photo).resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: EmberTokens.Size.skeletonHero + EmberTokens.Size.skeletonHero).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
            }
            HStack(spacing: EmberTokens.Spacing.space8) {
                ForEach(MealTag.allCases, id: \.self) { tag in
                    Button { model.mealTag = tag } label: {
                        Text(tag.emoji).font(.title2)
                            .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
                            .background(model.mealTag == tag ? EmberColors.primaryButtonFill : EmberColors.card, in: Circle())
                            // A18.11 — the meal-tag chips: a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and never
                            // the 1.26:1 hairline family, which is for the seam between two surfaces.
                            .overlay(Circle().stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tag.rawValue.capitalized)
                    .accessibilityAddTraits(model.mealTag == tag ? .isSelected : [])
                }
                Spacer()
                // 6.3 — S11 names this chip in its acceptance criteria, and it sat in a row of 44 pt meal-tag circles at
                // roughly a third of their height
                if model.yesterdaysMeal() != nil, !model.repeated {
                    TextActionButton(title: "↻ Same as yesterday", horizontalPadding: 0, accessibilityLabel: "Same as yesterday") { model.repeatYesterday() }
                }
            }
            TextField("Say something (or don't)", text: $model.caption, axis: .vertical)
                .lineLimit(1...SpecConstants.captionComposerMaxLines)
                .padding(EmberTokens.Spacing.space12)
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                .onChange(of: model.caption) { _, value in if value.count > SpecConstants.captionMaxChars { model.caption = String(value.prefix(SpecConstants.captionMaxChars)) } }
            Toggle("Earlier today", isOn: $model.earlierToday).tint(EmberColors.inkText).foregroundStyle(EmberColors.inkText)
            if hasCrew { Toggle("Share to crew", isOn: $model.shareToCrew).tint(EmberColors.inkText).foregroundStyle(EmberColors.inkText) }
        }
    }
}
