import XCTest
@testable import IndianFoodTracker

/// Checks the Today screen's logic: greeting, totals, remaining calories, and progress.
@MainActor
final class TodayViewModelTests: XCTestCase {

    // MARK: - Greeting

    func testGreetingMorning() {
        XCTAssertEqual(TodayViewModel.greeting(forHour: 5), "Good morning")
        XCTAssertEqual(TodayViewModel.greeting(forHour: 11), "Good morning")
    }

    func testGreetingAfternoon() {
        XCTAssertEqual(TodayViewModel.greeting(forHour: 12), "Good afternoon")
        XCTAssertEqual(TodayViewModel.greeting(forHour: 16), "Good afternoon")
    }

    func testGreetingEvening() {
        XCTAssertEqual(TodayViewModel.greeting(forHour: 17), "Good evening")
        XCTAssertEqual(TodayViewModel.greeting(forHour: 23), "Good evening")
        XCTAssertEqual(TodayViewModel.greeting(forHour: 0), "Good evening")
        XCTAssertEqual(TodayViewModel.greeting(forHour: 4), "Good evening")
    }

    // MARK: - Empty state

    func testEmptyViewModel() {
        let viewModel = TodayViewModel()
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.totalCalories, 0)
        XCTAssertEqual(viewModel.totalProtein, 0)
        XCTAssertEqual(viewModel.totalCarbs, 0)
        XCTAssertEqual(viewModel.totalFat, 0)
        XCTAssertEqual(viewModel.remainingCalories, viewModel.calorieTarget)
        XCTAssertEqual(viewModel.progress, 0, accuracy: 0.0001)
        for meal in MealType.allCases {
            XCTAssertTrue(viewModel.items(for: meal).isEmpty)
        }
    }

    func testZeroTargetGivesZeroProgress() {
        let viewModel = TodayViewModel()
        viewModel.calorieTarget = 0
        XCTAssertEqual(viewModel.progress, 0, accuracy: 0.0001)
    }

    // MARK: - Totals (uses the clearly fake DEMO data, which only exists in debug builds)

    #if DEBUG
    func testDemoTotals() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.totalCalories, 1_420)
        XCTAssertEqual(viewModel.totalProtein, 59)
        XCTAssertEqual(viewModel.totalCarbs, 180)
        XCTAssertEqual(viewModel.totalFat, 48)
    }

    func testRemainingAndProgressUnderTarget() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        XCTAssertEqual(viewModel.remainingCalories, 580)
        XCTAssertEqual(viewModel.progress, 0.71, accuracy: 0.0001)
    }

    func testOverTarget() {
        let viewModel = TodayViewModel()
        viewModel.calorieTarget = 1_000
        viewModel.loadDemoData()
        XCTAssertEqual(viewModel.remainingCalories, -420)
        XCTAssertGreaterThan(viewModel.progress, 1)
    }

    func testMealsHaveExpectedItems() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        XCTAssertEqual(viewModel.items(for: .breakfast).count, 2)
        XCTAssertEqual(viewModel.items(for: .lunch).count, 2)
        XCTAssertTrue(viewModel.items(for: .snack).isEmpty)
        XCTAssertTrue(viewModel.items(for: .lateMeal).isEmpty)
    }

    func testClearAllEmptiesEverything() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        viewModel.clearAll()
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.totalCalories, 0)
    }
    #endif

    // MARK: - Fiber (nil means unknown, never zero)

    private func testItem(fiber: Int?) -> TodayItem {
        TodayItem(name: "TEST", detail: "test", calories: 100,
                  protein: 1, carbs: 2, fat: 3, fiber: fiber)
    }

    func testFiberDefaultsToUnknown() {
        let item = TodayItem(name: "TEST", detail: "test", calories: 100,
                             protein: 1, carbs: 2, fat: 3)
        XCTAssertNil(item.fiber)
    }

    func testFiberTotalAllKnownIsComplete() {
        let total = FiberTotal.total(of: [testItem(fiber: 3), testItem(fiber: 2), testItem(fiber: 5)])
        XCTAssertEqual(total?.knownGrams, 10)
        XCTAssertEqual(total?.knownCount, 3)
        XCTAssertEqual(total?.unknownCount, 0)
        XCTAssertEqual(total?.isComplete, true)
        XCTAssertEqual(total?.hasAnyKnownValue, true)
    }

    func testFiberTotalWithUnknownIsPartial() {
        let total = FiberTotal.total(of: [testItem(fiber: 3), testItem(fiber: nil), testItem(fiber: 5)])
        XCTAssertEqual(total?.knownGrams, 8)
        XCTAssertEqual(total?.knownCount, 2)
        XCTAssertEqual(total?.unknownCount, 1)
        XCTAssertEqual(total?.isComplete, false)
        XCTAssertEqual(total?.hasAnyKnownValue, true)
    }

    func testUnknownFiberIsNotTreatedAsZero() {
        let unknown = FiberTotal.total(of: [testItem(fiber: nil)])
        let knownZero = FiberTotal.total(of: [testItem(fiber: 0)])
        XCTAssertEqual(unknown?.isComplete, false)
        XCTAssertEqual(unknown?.hasAnyKnownValue, false)
        XCTAssertEqual(knownZero?.isComplete, true)
        XCTAssertEqual(knownZero?.hasAnyKnownValue, true)
        XCTAssertNotEqual(unknown, knownZero)
    }

    func testFiberTotalAllUnknownHasNoKnownValue() {
        let total = FiberTotal.total(of: [testItem(fiber: nil), testItem(fiber: nil)])
        XCTAssertEqual(total?.knownGrams, 0)
        XCTAssertEqual(total?.unknownCount, 2)
        XCTAssertEqual(total?.isComplete, false)
        XCTAssertEqual(total?.hasAnyKnownValue, false)
    }

    func testFiberTotalOfNoFoodsIsNil() {
        XCTAssertNil(FiberTotal.total(of: []))
    }

    func testEmptyViewModelHasNoFiberTotal() {
        XCTAssertNil(TodayViewModel().fiberTotal)
    }

    #if DEBUG
    func testDemoFiberIsPartialAndExcludesUnknownItem() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        let total = viewModel.fiberTotal
        XCTAssertEqual(total?.knownGrams, 16)
        XCTAssertEqual(total?.knownCount, 5)
        XCTAssertEqual(total?.unknownCount, 1)
        XCTAssertEqual(total?.isComplete, false)
        // Existing totals are unaffected by fiber.
        XCTAssertEqual(viewModel.totalCalories, 1_420)
        XCTAssertEqual(viewModel.totalProtein, 59)
        XCTAssertEqual(viewModel.totalCarbs, 180)
        XCTAssertEqual(viewModel.totalFat, 48)
    }

    func testClearAllRemovesFiberTotal() {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        viewModel.clearAll()
        XCTAssertNil(viewModel.fiberTotal)
    }
    #endif

    // MARK: - MealType

    func testMealOrderAndCount() {
        XCTAssertEqual(MealType.allCases, [.preWorkout, .breakfast, .midMorning, .lunch, .snack, .dinner, .lateMeal])
    }

    func testMealNamesAreUniqueAndNotEmpty() {
        let names = MealType.allCases.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count)
        for meal in MealType.allCases {
            XCTAssertFalse(meal.displayName.isEmpty)
            XCTAssertFalse(meal.addPrompt.isEmpty)
            XCTAssertFalse(meal.systemImage.isEmpty)
        }
    }
}
