import XCTest
@testable import IndianFoodTracker

@MainActor
final class FoodLogEntryTests: XCTestCase {

    // MARK: - The critical invariant

    func testEditingAFoodNeverChangesAnAlreadyLoggedEntry() throws {
        var food = Fixtures.food()
        let entry = try Fixtures.makeEntry(food: food, portion: .measured(100))
        let consumedBefore = entry.consumed
        let snapshotBefore = entry.snapshot

        // The catalog is corrected later.
        food.nutrients = food.nutrients.setting(.energyKcal, to: 999).setting(.protein, to: 99)
        food.name = "CORRECTED NAME"
        food.revision += 1

        XCTAssertEqual(entry.consumed, consumedBefore)
        XCTAssertEqual(entry.snapshot, snapshotBefore)
        XCTAssertEqual(entry.consumed[.energyKcal], 200)
        XCTAssertEqual(entry.snapshot.name, "TEST FOOD (not real data)")
        XCTAssertEqual(entry.snapshot.foodRevision, 1)

        // Only a NEW entry sees the correction.
        let newer = try Fixtures.makeEntry(food: food, portion: .measured(100))
        XCTAssertEqual(newer.consumed[.energyKcal], 999)
        XCTAssertEqual(newer.snapshot.foodRevision, 2)
    }

    func testReplacingTheCatalogDoesNotChangeHistoryTotals() throws {
        var catalog: [FoodID: Food] = ["test.food": Fixtures.food()]
        let entries = [
            try Fixtures.makeEntry(food: catalog["test.food"]!, portion: .measured(100), meal: .breakfast),
            try Fixtures.makeEntry(food: catalog["test.food"]!, portion: .measured(50), meal: .lunch)
        ]
        let before = DaySummary(day: Fixtures.today, entries: entries)

        var corrected = Fixtures.food()
        corrected.nutrients = corrected.nutrients.setting(.energyKcal, to: 1)
        catalog["test.food"] = corrected
        catalog["test.food"] = nil   // and then the food is deleted

        let after = DaySummary(day: Fixtures.today, entries: entries)
        XCTAssertEqual(after, before)
        XCTAssertEqual(after.totals[.energyKcal].knownAmount, 300)
    }

    func testEditingQuantityRecalculatesFromTheFrozenProfileNotTheLiveFood() throws {
        var food = Fixtures.food()
        let entry = try Fixtures.makeEntry(food: food, portion: .measured(100))
        food.nutrients = food.nutrients.setting(.energyKcal, to: 999)
        let edited = try entry.withPortion(.measured(250))
        XCTAssertEqual(edited.consumed[.energyKcal], 500)   // 200 per 100 g, not 999
        XCTAssertEqual(edited.id, entry.id)
        XCTAssertEqual(edited.snapshot, entry.snapshot)
    }

    private func entryFromAFoodThatNoLongerExists() throws -> FoodLogEntry {
        let temporaryFood = Fixtures.food()
        return try Fixtures.makeEntry(food: temporaryFood, portion: .servings(2, Fixtures.piece))
    }

    func testEntryStaysUsableAfterTheFoodIsGone() throws {
        let entry = try entryFromAFoodThatNoLongerExists()
        XCTAssertEqual(entry.snapshot.name, "TEST FOOD (not real data)")
        XCTAssertEqual(entry.consumed[.energyKcal], 160)   // 80 g
        let edited = try entry.withPortion(.servings(1, Fixtures.bowl))   // 150 g
        XCTAssertEqual(edited.consumed[.energyKcal], 300)
    }

    // MARK: - Meals and days

    func testEveryMealCanBeAssociated() throws {
        for meal in MealType.allCases {
            XCTAssertEqual(try Fixtures.makeEntry(meal: meal).meal, meal)
        }
        XCTAssertEqual(try Fixtures.makeEntry(meal: .preWorkout).meal, .preWorkout)
    }

    func testFutureDaysAreRejected() {
        let tomorrow = Fixtures.today.tomorrow!
        XCTAssertThrowsError(try Fixtures.makeEntry(day: tomorrow)) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.dayIsInFuture)
        }
    }

    func testTodayAndPastDaysAreAllowed() throws {
        XCTAssertEqual(try Fixtures.makeEntry(day: Fixtures.today).day, Fixtures.today)
        XCTAssertEqual(try Fixtures.makeEntry(day: Fixtures.today.yesterday!).day, Fixtures.today.yesterday!)
        XCTAssertEqual(try Fixtures.makeEntry(day: Fixtures.date(2025, 1, 1)).day, Fixtures.date(2025, 1, 1))
    }

    func testWithMealKeepsNutritionUntouched() throws {
        let entry = try Fixtures.makeEntry(meal: .breakfast)
        let moved = entry.withMeal(.dinner)
        XCTAssertEqual(moved.meal, .dinner)
        XCTAssertEqual(moved.consumed, entry.consumed)
        XCTAssertEqual(moved.calculatorVersion, entry.calculatorVersion)
    }

    func testWithDayRules() throws {
        let entry = try Fixtures.makeEntry()
        let yesterday = Fixtures.today.yesterday!
        let moved = try entry.withDay(yesterday, today: Fixtures.today)
        XCTAssertEqual(moved.day, yesterday)
        XCTAssertEqual(moved.consumed, entry.consumed)
        XCTAssertThrowsError(try entry.withDay(Fixtures.today.tomorrow!, today: Fixtures.today)) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.dayIsInFuture)
        }
    }

    // MARK: - Validation

    func testQuantityMustBePositive() {
        for portion in [Portion.measured(0), .measured(-5), .servings(0, Fixtures.piece), .servings(-1, Fixtures.piece)] {
            XCTAssertThrowsError(try Fixtures.makeEntry(portion: portion)) { error in
                XCTAssertEqual(error as? FoodLogError, FoodLogError.quantityNotPositive)
            }
        }
    }

    func testServingMustComeFromTheFood() {
        let cup = ServingDefinition(id: "cup", label: "cup", baseAmount: 200)
        XCTAssertThrowsError(try Fixtures.makeEntry(portion: .servings(1, cup))) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.servingNotFromFood)
        }
    }

    func testVariantRules() throws {
        let stranger = FoodVariant(id: "stranger", group: "Other", label: "Odd", adjustments: [.fat: 1])
        XCTAssertThrowsError(try Fixtures.makeEntry(variants: [stranger])) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.variantNotFromFood)
        }
        XCTAssertThrowsError(try Fixtures.makeEntry(variants: [Fixtures.lessOil, Fixtures.heavyOil])) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.duplicateVariantGroup)
        }
        // Different groups together are fine.
        XCTAssertNoThrow(try Fixtures.makeEntry(variants: [Fixtures.lessOil, Fixtures.highSugar]))
    }

    func testFoodMustBeLoggable() {
        XCTAssertThrowsError(try Fixtures.makeEntry(food: Fixtures.food(includeEnergy: false))) { error in
            XCTAssertEqual(error as? FoodLogError, FoodLogError.foodNotLoggable)
        }
    }

    // MARK: - Variants, estimates, calculator version

    func testEstimateFlag() throws {
        XCTAssertFalse(try Fixtures.makeEntry().isEstimate)
        XCTAssertTrue(try Fixtures.makeEntry(variants: [Fixtures.lessOil]).isEstimate)
        var food = Fixtures.food()
        let exact = FoodVariant(id: "exact", group: "Exact", label: "Measured",
                                adjustments: [.fat: 1], isEstimate: false)
        food.variants.append(exact)
        XCTAssertFalse(try Fixtures.makeEntry(food: food, variants: [exact]).isEstimate)
    }

    func testChangingVariantsRecalculatesFromTheSnapshot() throws {
        let entry = try Fixtures.makeEntry(variants: [Fixtures.heavyOil])
        XCTAssertEqual(entry.consumed[.energyKcal], 236)
        XCTAssertEqual(entry.snapshot.nutrients[.energyKcal], 200)   // the frozen base is never mutated
        let plain = try entry.withVariants([])
        XCTAssertEqual(plain.consumed[.energyKcal], 200)
        let lighter = try entry.withVariants([Fixtures.lessOil])
        XCTAssertEqual(lighter.consumed[.energyKcal], 182)
    }

    func testUnknownAndKnownZeroFiberSurviveLogging() throws {
        let unknown = try Fixtures.makeEntry(food: Fixtures.food(fiber: nil))
        XCTAssertNil(unknown.consumed[.fiber])
        let zero = try Fixtures.makeEntry(food: Fixtures.food(fiber: 0))
        XCTAssertEqual(zero.consumed[.fiber], 0)
        XCTAssertTrue(zero.consumed.isKnown(.fiber))
    }

    func testCalculatorVersionIsStored() throws {
        let entry = try Fixtures.makeEntry()
        XCTAssertEqual(entry.calculatorVersion, NutritionCalculator.version)
        XCTAssertEqual(try entry.withPortion(.measured(10)).calculatorVersion, NutritionCalculator.version)
    }

    func testLoggingWorksOffTheMainActor() async throws {
        let food = Fixtures.food()
        let consumed = await Task.detached {
            (try? FoodLogEntry.make(food: food, portion: .measured(100), day: LocalDate.epoch,
                                   today: LocalDate.epoch, meal: .preWorkout,
                                   loggedAt: Date(timeIntervalSince1970: 0)))?.consumed[.energyKcal]
        }.value
        XCTAssertEqual(consumed, 200)
    }
}
