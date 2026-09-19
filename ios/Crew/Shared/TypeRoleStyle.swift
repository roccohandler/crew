// SPEC: A28 (a), (f) — the Focus Card type scale (design/focus-card-system.md §4; EmberTokens.Typography): SF Pro throughout, every
// numeral SF Pro Rounded, tracking as a fraction of the size, eyebrows rendered uppercase while the string stays sentence case
// (R-083 (7)). 6.5 / 6.7 — Dynamic Type still applies: the size follows its role's text style curve through UIFontMetrics, and the
// modifier reads `dynamicTypeSize`, so a change of text size re-renders the text. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import UIKit

struct TypeRoleStyle: ViewModifier {
    let role: EmberTokens.TypeRole
    var numeral = false // a word role carrying a figure ("3×8", "2 exercises") — every numeral is rounded (§4)
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let size = UIFontMetrics(forTextStyle: uiTextStyle).scaledValue(for: role.size, compatibleWith: traits)
        content
            .font(.system(size: size, weight: role.weight, design: role.rounded || numeral ? .rounded : .default))
            .tracking(size * role.tracking)
            .textCase(role.uppercase ? .uppercase : nil)
    }

    private var uiTextStyle: UIFont.TextStyle {
        switch role.relativeTo {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

extension View {
    func typeRole(_ role: EmberTokens.TypeRole, numeral: Bool = false) -> some View {
        modifier(TypeRoleStyle(role: role, numeral: numeral))
    }
}
