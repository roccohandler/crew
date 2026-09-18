// SPEC: A26 (owner-approved 2026-09-18) — every equipment tag has ONE SF Symbol, in one mapping (exercises.json
// enums.equipmentSymbol). A symbol NAME is only a string until a phone draws it, and a wrong one draws nothing at all and
// fails no build — so this asks the system for each one. Runs under Xcode only (UIKit); check-seeds holds the shape.
// WRITTEN — UNVERIFIED (needs Mac).

import UIKit
import XCTest
@testable import Crew

final class EquipmentSymbolTests: XCTestCase {
    func testEveryEquipmentTagResolvesToARealSFSymbol() {
        let seed = SeedCatalog.shared
        let tags = Set(seed.exercises.map(\.equipment))
        XCTAssertEqual(Set(seed.equipmentSymbol.keys), tags) // a tag the catalog uses always has a symbol, and nothing else does
        for (tag, symbol) in seed.equipmentSymbol {
            XCTAssertNotNil(UIImage(systemName: symbol), "\(tag): the system has no symbol named \(symbol)")
        }
    }
}
