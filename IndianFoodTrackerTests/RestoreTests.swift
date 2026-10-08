import XCTest
@testable import IndianFoodTracker

/// `restore` rebuilds an entry exactly as it was stored. It must never recalculate history.
@MainActor
final class RestoreTests: XCTestCase {

    private func rebuilt(_ e: FoodLogEntry, day: LocalDate? = nil,
                         consumed: NutrientAmounts? = nil,
                         calculatorVersion: Int? = nil) -> FoodLogEntry {
        FoodLogEntry.restore(id: e.id, day: day ?? e.day, meal: e.meal, loggedAt: e.loggedAt,
                             sortOrder: e.sortOrder, snapshot: e.snapshot, portion: e.portion,
                             variants: e.variants, consumed: consumed ?? e.consumed,
                             calculatorVersion: calculatorVersion ?? e.calculatorVersion)
    }

    func testRestoreUsesStoredConsumedAndCalculatorVersion() throws {
        let entry = try Fixtures.makeEntry()
        XCTAssertEqual(entry.consumed[.energyKcal], 200)
        // Pretend an older calculator stored different numbers. Recomputing would give 200.
        let stored = NutrientAmounts([.energyKcal: 12_345, .protein: Fixtures.dec("1.2345")])
        let restored = rebuilt(entry, consumed: stored, calculatorVersion: 0)
        XCTAssertEqual(restored.consumed, stored)
        XCTAssertEqual(restored.calculatorVersion, 0)
        XCTAssertNotEqual(restored.consumed, entry.consumed)
        XCTAssertEqual(restored.snapshot, entry.snapshot)
    }

    func testRestoringAFreshEntryEqualsTheOriginal() throws {
        let entry = try Fixtures.makeEntry(
            portion: .servings(Fixtures.dec("1.5"), Fixtures.piece),
            variants: [Fixtures.lessOil, Fixtures.highSugar],
            day: Fixtures.today.yesterday!, meal: .preWorkout, sortOrder: 3)
        XCTAssertEqual(rebuilt(entry), entry)
    }

    func testEditingARestoredEntryRecalculatesFromItsOwnSnapshot() throws {
        let entry = try Fixtures.makeEntry()
        let restored = rebuilt(entry, consumed: NutrientAmounts([.energyKcal: 1]), calculatorVersion: 0)
        let edited = try restored.withPortion(.measured(250))
        XCTAssertEqual(edited.consumed[.energyKcal], 500)   // 200 per 100 g, from the snapshot
        XCTAssertEqual(edited.calculatorVersion, NutritionCalculator.version)
        XCTAssertEqual(edited.snapshot, entry.snapshot)
    }

    func testMealAndDayChangesKeepStoredValues() throws {
        let entry = try Fixtures.makeEntry(meal: .breakfast)
        let stored = NutrientAmounts([.energyKcal: 777])
        let old = rebuilt(entry, consumed: stored, calculatorVersion: 0)

        let movedMeal = old.withMeal(.dinner)
        XCTAssertEqual(movedMeal.consumed, stored)
        XCTAssertEqual(movedMeal.calculatorVersion, 0)

        let movedDay = try old.withDay(Fixtures.today.yesterday!, today: Fixtures.today)
        XCTAssertEqual(movedDay.consumed, stored)
        XCTAssertEqual(movedDay.calculatorVersion, 0)
    }

    func testRestoreDoesNotApplyTheFutureDayRule() throws {
        let entry = try Fixtures.makeEntry()
        let future = Fixtures.today.tomorrow!
        let restored = rebuilt(entry, day: future)
        XCTAssertEqual(restored.day, future)
        XCTAssertEqual(restored.consumed, entry.consumed)
    }

    func testMemberwiseSnapshotMatchesFoodInit() {
        let food = Fixtures.food(fiber: 2)
        let fromFood = FoodSnapshot(food)
        let memberwise = FoodSnapshot(foodID: food.id, name: food.name, unit: food.unit,
                                      referenceAmount: food.referenceAmount, nutrients: food.nutrients,
                                      servings: food.servings, variants: food.variants,
                                      foodRevision: food.revision)
        XCTAssertEqual(fromFood, memberwise)
        let different = FoodSnapshot(foodID: food.id, name: "Other", unit: food.unit,
                                     referenceAmount: food.referenceAmount, nutrients: food.nutrients,
                                     servings: food.servings, variants: food.variants,
                                     foodRevision: food.revision)
        XCTAssertNotEqual(fromFood, different)
    }

    func testRestorePreservesKnownZeroAndUnknown() throws {
        let entry = try Fixtures.makeEntry()
        let withZero = rebuilt(entry, consumed: NutrientAmounts([.energyKcal: 1, .fiber: 0]))
        let withoutFiber = rebuilt(entry, consumed: NutrientAmounts([.energyKcal: 1]))
        XCTAssertEqual(withZero.consumed[.fiber], 0)
        XCTAssertTrue(withZero.consumed.isKnown(.fiber))
        XCTAssertNil(withoutFiber.consumed[.fiber])
        XCTAssertNotEqual(withZero.consumed, withoutFiber.consumed)
    }

    func testRestoreWorksOffTheMainActor() async throws {
        let entry = try Fixtures.makeEntry()
        let energy = await Task.detached {
            FoodLogEntry.restore(id: entry.id, day: entry.day, meal: entry.meal,
                                 loggedAt: entry.loggedAt, sortOrder: entry.sortOrder,
                                 snapshot: entry.snapshot, portion: entry.portion,
                                 variants: entry.variants, consumed: entry.consumed,
                                 calculatorVersion: entry.calculatorVersion).consumed[.energyKcal]
        }.value
        XCTAssertEqual(energy, 200)
    }
}
