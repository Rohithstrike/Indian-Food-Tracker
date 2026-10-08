import XCTest
@testable import IndianFoodTracker

@MainActor
final class FoodTests: XCTestCase {

    func testValidFoodHasNoIssues() {
        let food = Fixtures.food()
        XCTAssertTrue(food.validationIssues.isEmpty)
        XCTAssertTrue(food.isLoggable)
        XCTAssertEqual(food.defaultServing, Fixtures.piece)
    }

    func testEmptyName() {
        var food = Fixtures.food()
        food.name = "   "
        XCTAssertTrue(food.validationIssues.contains(.emptyName))
    }

    func testNonPositiveReferenceAmount() {
        var food = Fixtures.food()
        food.referenceAmount = 0
        XCTAssertTrue(food.validationIssues.contains(.nonPositiveReferenceAmount))
    }

    func testEnergyMustBeKnownToLog() {
        let food = Fixtures.food(includeEnergy: false)
        XCTAssertTrue(food.validationIssues.contains(.missingEnergy))
        XCTAssertFalse(food.isLoggable)
        // Every other nutrient may be unknown.
        XCTAssertTrue(Fixtures.food(fiber: nil).isLoggable)
    }

    func testNegativeNutrient() {
        var food = Fixtures.food()
        food.nutrients = food.nutrients.setting(.protein, to: -1)
        XCTAssertTrue(food.validationIssues.contains(.negativeNutrient))
    }

    func testDuplicateServingIDs() {
        var food = Fixtures.food()
        food.servings = [Fixtures.piece, Fixtures.piece]
        XCTAssertTrue(food.validationIssues.contains(.duplicateServingID))
    }

    func testNonPositiveServingAmount() {
        var food = Fixtures.food()
        food.servings = [ServingDefinition(id: "zero", label: "zero", baseAmount: 0)]
        XCTAssertTrue(food.validationIssues.contains(.nonPositiveServingAmount))
    }

    func testDuplicateVariantIDs() {
        var food = Fixtures.food()
        food.variants = [Fixtures.lessOil, Fixtures.lessOil]
        XCTAssertTrue(food.validationIssues.contains(.duplicateVariantID))
    }

    func testFoodIDLiteralAndEquality() {
        let id: FoodID = "sys.example.id"
        XCTAssertEqual(id, FoodID(rawValue: "sys.example.id"))
        XCTAssertEqual(id.rawValue, "sys.example.id")
        XCTAssertNotEqual(id, FoodID(rawValue: "sys.example.other"))
    }
}
