// SPEC: R-074 (3) — the bodyweight bound is a TYPO bound (30–300 kg), checked in kilograms whichever unit was typed, by the form and
// by the server with the same arithmetic. Twin of web/tests/engine/nutrition-targets.test.ts. (V57–V60, V64 pin the derivation.)

import XCTest
@testable import Crew

final class NutritionTargetsTests: XCTestCase {
    func testReadsWhatAPersonTypesWithAPointOrACommaToOneDecimal() {
        XCTAssertEqual(NutritionTargets.bodyweightTenthsFrom("176", "lb"), 1760)
        XCTAssertEqual(NutritionTargets.bodyweightTenthsFrom(" 80.5 ", "kg"), 805)
        XCTAssertEqual(NutritionTargets.bodyweightTenthsFrom("80,5", "kg"), 805)
        XCTAssertEqual(NutritionTargets.bodyweightTenthsFrom("80.25", "kg"), 803) // half-up to tenths
    }

    func testRefusesWhatIsNotANumberAndWhatIsNotABodyweight() {
        XCTAssertNil(NutritionTargets.bodyweightTenthsFrom("", "kg"))
        XCTAssertNil(NutritionTargets.bodyweightTenthsFrom("eighty", "kg"))
        XCTAssertNil(NutritionTargets.bodyweightTenthsFrom("-80", "kg"))
        XCTAssertNil(NutritionTargets.bodyweightTenthsFrom("8", "kg")) // a typo, not a judgement
        XCTAssertNil(NutritionTargets.bodyweightTenthsFrom("1760", "lb"))
    }

    func testHoldsTheTwoKilogramBoundsExactly() {
        XCTAssertTrue(NutritionTargets.bodyweightInBounds(300, "kg"))    // 30.0 kg
        XCTAssertFalse(NutritionTargets.bodyweightInBounds(299, "kg"))   // 29.9 kg
        XCTAssertTrue(NutritionTargets.bodyweightInBounds(3000, "kg"))   // 300.0 kg
        XCTAssertFalse(NutritionTargets.bodyweightInBounds(3001, "kg"))  // 300.1 kg
    }

    // nutrition addendum §5 — the bundled seed decodes on the phone, and holds exactly what the constants say shipped
    func testTheFastFoodSeedDecodesAndMatchesItsConstants() {
        let seed = SeedCatalog.shared.fastFood
        XCTAssertEqual(seed.chains.count, SpecConstants.fastFoodChainCount)
        for chain in seed.chains {
            XCTAssertGreaterThanOrEqual(seed.items.filter { $0.chainId == chain.id }.count, SpecConstants.fastFoodItemsPerChainMin, chain.name)
        }
    }

    func testChecksPoundsInKilograms() {
        XCTAssertFalse(NutritionTargets.bodyweightInBounds(661, "lb"))   // 66.1 lb = 29.98 kg
        XCTAssertTrue(NutritionTargets.bodyweightInBounds(662, "lb"))    // 66.2 lb = 30.03 kg
        XCTAssertTrue(NutritionTargets.bodyweightInBounds(6613, "lb"))   // 661.3 lb = 299.96 kg
        XCTAssertFalse(NutritionTargets.bodyweightInBounds(6615, "lb"))  // 661.5 lb = 300.05 kg
    }
}
