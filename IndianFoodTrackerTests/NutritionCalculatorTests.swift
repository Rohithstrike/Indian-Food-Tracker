import XCTest
@testable import IndianFoodTracker

@MainActor
final class NutritionCalculatorTests: XCTestCase {

    func testMeasuredAmountForPortions() {
        XCTAssertEqual(NutritionCalculator.measuredAmount(for: .measured(75)), 75)
        XCTAssertEqual(NutritionCalculator.measuredAmount(for: .servings(Fixtures.dec("1.5"), Fixtures.piece)), 60)
        XCTAssertEqual(NutritionCalculator.measuredAmount(for: .servings(2, Fixtures.bowl)), 300)
    }

    func testConsumedScalesByMeasuredAmount() {
        let food = Fixtures.food()
        let result = NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                  measuredAmount: 60, variants: [])
        XCTAssertEqual(result[.energyKcal], 120)
        XCTAssertEqual(result[.protein], 6)
        XCTAssertEqual(result[.carbs], 18)
        XCTAssertEqual(result[.fat], 3)
        XCTAssertNil(result[.fiber])
    }

    func testFractionalQuantitiesStayExact() {
        let food = Fixtures.food()
        func energy(_ grams: String) -> Decimal? {
            NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                         measuredAmount: Fixtures.dec(grams), variants: [])[.energyKcal]
        }
        XCTAssertEqual(energy("37.5"), 75)
        XCTAssertEqual(energy("125.5"), 251)
        let protein = NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                   measuredAmount: Fixtures.dec("125.5"), variants: [])[.protein]
        XCTAssertEqual(protein, Fixtures.dec("12.55"))
        // 1.25 servings of a 40 g piece is 50 g
        XCTAssertEqual(NutritionCalculator.measuredAmount(for: .servings(Fixtures.dec("1.25"), Fixtures.piece)), 50)
    }

    func testVariantsAdjustPerReferenceBeforeScaling() {
        let food = Fixtures.food()
        let heavy = NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                 measuredAmount: 100, variants: [Fixtures.heavyOil])
        XCTAssertEqual(heavy[.energyKcal], 236)
        XCTAssertEqual(heavy[.fat], 9)
        XCTAssertEqual(heavy[.protein], 10)
        let heavy60 = NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                   measuredAmount: 60, variants: [Fixtures.heavyOil])
        XCTAssertEqual(heavy60[.energyKcal], Fixtures.dec("141.6"))
        XCTAssertEqual(heavy60[.fat], Fixtures.dec("5.4"))
        let both = NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                measuredAmount: 100, variants: [Fixtures.lessOil, Fixtures.highSugar])
        XCTAssertEqual(both[.energyKcal], 202)
        XCTAssertEqual(both[.carbs], 35)
    }

    func testVariantNeverInventsAnUnknownNutrient() {
        let base = NutrientAmounts([.fat: 5])
        let result = NutritionCalculator.consumed(perReference: base, referenceAmount: 100,
                                                  measuredAmount: 100, variants: [Fixtures.heavyOil])
        XCTAssertNil(result[.energyKcal])
        XCTAssertEqual(result[.fat], 9)
    }

    func testVariantCannotMakeANutrientNegative() {
        let extreme = FoodVariant(id: "x", group: "Oil", label: "Extreme", adjustments: [.fat: -100])
        let result = NutritionCalculator.consumed(perReference: NutrientAmounts([.fat: 5]), referenceAmount: 100,
                                                  measuredAmount: 100, variants: [extreme])
        XCTAssertEqual(result[.fat], 0)
        XCTAssertTrue(result.isKnown(.fat))
    }

    func testStoredValuesRoundToFourPlaces() {
        let base = NutrientAmounts([.energyKcal: 10])
        let one = NutritionCalculator.consumed(perReference: base, referenceAmount: 3, measuredAmount: 1, variants: [])
        let two = NutritionCalculator.consumed(perReference: base, referenceAmount: 3, measuredAmount: 2, variants: [])
        XCTAssertEqual(one[.energyKcal], Fixtures.dec("3.3333"))
        XCTAssertEqual(two[.energyKcal], Fixtures.dec("6.6667"))
    }

    func testDisplayRoundingIsHalfAwayFromZero() {
        XCTAssertEqual(NutritionCalculator.rounded(Fixtures.dec("2.5"), places: 0), 3)
        XCTAssertEqual(NutritionCalculator.rounded(Fixtures.dec("2.4"), places: 0), 2)
        XCTAssertEqual(NutritionCalculator.rounded(Fixtures.dec("1.005"), places: 2), Fixtures.dec("1.01"))
        XCTAssertEqual(NutritionCalculator.rounded(Fixtures.dec("-2.5"), places: 0), -3)
    }

    func testTotalsSumStoredValuesWithoutReRounding() {
        let third = NutrientAmounts([.energyKcal: Fixtures.dec("3.3333")])
        let totals = NutrientTotals.total(of: [third, third, third])
        XCTAssertEqual(totals[.energyKcal].knownAmount, Fixtures.dec("9.9999"))
    }

    func testInvalidInputsGiveNoValues() {
        let food = Fixtures.food()
        XCTAssertTrue(NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 0,
                                                   measuredAmount: 50, variants: []).isEmpty)
        XCTAssertTrue(NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                   measuredAmount: 0, variants: []).isEmpty)
        XCTAssertTrue(NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: 100,
                                                   measuredAmount: -5, variants: []).isEmpty)
    }

    func testConstants() {
        XCTAssertEqual(NutritionCalculator.version, 1)
        XCTAssertEqual(NutritionCalculator.storedPlaces, 4)
    }

    func testCalculatorWorksOffTheMainActor() async {
        let food = Fixtures.food()
        let result = await Task.detached {
            NutritionCalculator.consumed(perReference: food.nutrients, referenceAmount: food.referenceAmount,
                                         measuredAmount: 60, variants: [])
        }.value
        XCTAssertEqual(result[.energyKcal], 120)
    }
}
