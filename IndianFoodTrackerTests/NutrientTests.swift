import XCTest
@testable import IndianFoodTracker

@MainActor
final class NutrientTests: XCTestCase {

    func testNutrientIDRawValuesAreStable() {
        XCTAssertEqual(NutrientID.allCases.map(\.rawValue),
                       ["energyKcal", "protein", "carbs", "fat", "fiber", "sugar", "saturatedFat", "sodium"])
    }

    func testUnits() {
        XCTAssertEqual(NutrientID.energyKcal.unit, .kilocalories)
        XCTAssertEqual(NutrientID.sodium.unit, .milligrams)
        XCTAssertEqual(NutrientID.protein.unit, .grams)
        XCTAssertEqual(NutrientID.fiber.unit, .grams)
    }

    func testKnownZeroIsNotUnknown() {
        let knownZero = NutrientAmounts([.fiber: 0])
        let unknown = NutrientAmounts()
        XCTAssertEqual(knownZero[.fiber], 0)
        XCTAssertNil(unknown[.fiber])
        XCTAssertTrue(knownZero.isKnown(.fiber))
        XCTAssertFalse(unknown.isKnown(.fiber))
        XCTAssertNotEqual(knownZero, unknown)
    }

    func testSettingNilMakesNutrientUnknownAgain() {
        let amounts = NutrientAmounts([.fiber: 3, .protein: 5])
        let cleared = amounts.setting(.fiber, to: nil)
        XCTAssertNil(cleared[.fiber])
        XCTAssertEqual(cleared[.protein], 5)
        XCTAssertEqual(amounts[.fiber], 3)   // the original is untouched
    }

    func testScalingKeepsUnknownUnknownAndZeroKnown() {
        let amounts = NutrientAmounts([.protein: 10, .fat: 0])
        let scaled = amounts.scaled(by: 3, dividedBy: 2)
        XCTAssertEqual(scaled[.protein], 15)
        XCTAssertEqual(scaled[.fat], 0)
        XCTAssertTrue(scaled.isKnown(.fat))
        XCTAssertNil(scaled[.fiber])
    }

    func testAdjustmentsOnlyAffectKnownNutrientsAndNeverGoNegative() {
        let amounts = NutrientAmounts([.fat: 5])
        let result = amounts.applying(adjustments: [.fat: 4, .fiber: 2, .protein: -1])
        XCTAssertEqual(result[.fat], 9)
        XCTAssertNil(result[.fiber])      // unknown stays unknown
        XCTAssertNil(result[.protein])
        let clamped = amounts.applying(adjustments: [.fat: -100])
        XCTAssertEqual(clamped[.fat], 0)
        XCTAssertTrue(clamped.isKnown(.fat))
    }

    func testDecimalPrecision() {
        XCTAssertEqual(Fixtures.dec("0.1") + Fixtures.dec("0.2"), Fixtures.dec("0.3"))
        let a: Double = 0.1
        let b: Double = 0.2
        XCTAssertNotEqual(a + b, 0.3, "This is why nutrition math never uses Double.")
    }

    func testTotalOfNothingIsNoEntries() {
        let total = NutrientTotal.empty
        XCTAssertEqual(total.completeness, .noEntries)
        XCTAssertNil(total.displayableAmount)
        XCTAssertFalse(total.hasAnyKnownValue)
        XCTAssertFalse(total.isComplete)
    }

    func testTotalAllKnownIsComplete() {
        let total = NutrientTotal.empty.adding(3).adding(2).adding(5)
        XCTAssertEqual(total.knownAmount, 10)
        XCTAssertEqual(total.knownCount, 3)
        XCTAssertEqual(total.unknownCount, 0)
        XCTAssertEqual(total.completeness, .complete)
        XCTAssertEqual(total.displayableAmount, 10)
    }

    func testTotalMixedIsPartial() {
        let total = NutrientTotal.empty.adding(3).adding(nil).adding(5)
        XCTAssertEqual(total.knownAmount, 8)
        XCTAssertEqual(total.knownCount, 2)
        XCTAssertEqual(total.unknownCount, 1)
        XCTAssertEqual(total.completeness, .partial)
        XCTAssertFalse(total.isComplete)
        XCTAssertEqual(total.displayableAmount, 8)
    }

    func testTotalAllUnknownHasNoKnownValue() {
        let total = NutrientTotal.empty.adding(nil).adding(nil)
        XCTAssertEqual(total.completeness, .noKnownValues)
        XCTAssertEqual(total.knownAmount, 0)
        XCTAssertNil(total.displayableAmount, "Must not display 0 when nothing is known")
    }

    func testKnownZeroTotalIsDistinctFromUnknown() {
        let knownZero = NutrientTotal.empty.adding(0)
        let unknown = NutrientTotal.empty.adding(nil)
        XCTAssertEqual(knownZero.completeness, .complete)
        XCTAssertEqual(knownZero.displayableAmount, 0)
        XCTAssertNil(unknown.displayableAmount)
        XCTAssertNotEqual(knownZero, unknown)
    }

    func testTotalsOfNoEntries() {
        let totals = NutrientTotals.total(of: [])
        XCTAssertEqual(totals.entryCount, 0)
        for id in NutrientID.allCases {
            XCTAssertEqual(totals[id].completeness, .noEntries)
            XCTAssertNil(totals[id].displayableAmount)
        }
    }

    func testTotalsCountMissingNutrientAsUnknown() {
        let entries = [NutrientAmounts([.energyKcal: 1]), NutrientAmounts([.energyKcal: 1])]
        let totals = NutrientTotals.total(of: entries)
        XCTAssertEqual(totals.entryCount, 2)
        XCTAssertEqual(totals[.energyKcal].knownAmount, 2)
        XCTAssertEqual(totals[.energyKcal].completeness, .complete)
        XCTAssertEqual(totals[.fiber].unknownCount, 2)
        XCTAssertEqual(totals[.fiber].completeness, .noKnownValues)
    }
}
