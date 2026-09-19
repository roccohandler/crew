// SPEC: A28 (a), (f) — the Focus Card type scale (design/focus-card-system.md §4; EmberTokens.Typography): SF Pro throughout, every
// numeral SF Pro Rounded, tracking as a fraction of the size, eyebrows rendered uppercase while the string stays sentence case
// (R-083 (7)). 6.5 / 6.7 — Dynamic Type still applies: the size follows its role's text style curve through UIFontMetrics, and the
// modifier reads `dynamicTypeSize`, so a change of text size re-renders the text. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import UIKit

struct TypeRoleStyle: ViewModifier {
    let role: EmberTokens.TypeRole
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let size = UIFontMetrics(forTextStyle: uiTextStyle).scaledValue(for: role.size, compatibleWith: traits)
        content
            .font(.system(size: size, weight: role.weight, design: role.rounded ? .rounded : .default))
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
    func typeRole(_ role: EmberTokens.TypeRole) -> some View {
        modifier(TypeRoleStyle(role: role))
    }
}

extension Text {
    // SPEC: A28 (f) · system §4 — "every numeral is SF Pro Rounded Bold; words are never rounded": a sentence set in a word role
    // ("Push day · 6 of 6 sets", "3×8", "8 · 8 · 8 @ 150 lb") takes Rounded Bold on its digit runs alone. Text-level design and
    // weight outrank the role's font.
    init(numerals string: String) {
        var result = Text(verbatim: "")
        var run = ""
        var runIsDigits = false
        for character in string {
            if !run.isEmpty, character.isNumber != runIsDigits {
                result = result + (runIsDigits ? Text(verbatim: run).fontDesign(.rounded).fontWeight(.bold) : Text(verbatim: run))
                run = ""
            }
            run.append(character)
            runIsDigits = character.isNumber
        }
        if !run.isEmpty { result = result + (runIsDigits ? Text(verbatim: run).fontDesign(.rounded).fontWeight(.bold) : Text(verbatim: run)) }
        self = result
    }
}
