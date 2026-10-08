import XCTest
@testable import IndianFoodTracker

@MainActor
final class DaySummaryTests: XCTestCase {

    private func entry(_ meal: MealType, day: LocalDate = Fixtures.today, sortOrder: Int = 0,
                       fiber: Decimal? = nil, grams: Decimal = 100) throws -> FoodLogEntry {
        try Fixtures.makeEntry(food: Fixtures.food(fiber: fiber), portion: .measured(grams),
                               day: day, meal: meal, sortOrder: sortOrder)
    }

    func testEmptyDay() {
        let summary = DaySummary(day: Fixtures.today, entries: [])
        XCTAssertTrue(summary.isEmpty)
        XCTAssertEqual(summary.totals.entryCount, 0)
        XCTAssertEqual(summary.totals[.energyKcal].completeness, .noEntries)
        XCTAssertNil(summary.totals[.energyKcal].displayableAmount)
    }

    func testTotalsOnlyIncludeThatDay() throws {
        let entries = [
            try entry(.lunch, grams: 100),
            try entry(.breakfast, grams: 50),
            try entry(.dinner, day: Fixtures.today.yesterday!, grams: 100)
        ]
        let summary = DaySummary(day: Fixtures.today, entries: entries)
        XCTAssertEqual(summary.entries.count, 2)
        XCTAssertEqual(summary.totals.entryCount, 2)
        XCTAssertEqual(summary.totals[.energyKcal].knownAmount, 300)
        XCTAssertEqual(summary.totals[.protein].knownAmount, 15)
        XCTAssertEqual(summary.totals[.energyKcal].completeness, .complete)
    }

    func testFiberCompletenessStates() throws {
        let unknownOnly = DaySummary(day: Fixtures.today, entries: [try entry(.lunch), try entry(.dinner)])
        XCTAssertEqual(unknownOnly.totals[.fiber].completeness, .noKnownValues)
        XCTAssertNil(unknownOnly.totals[.fiber].displayableAmount)

        let mixed = DaySummary(day: Fixtures.today,
                               entries: [try entry(.lunch, fiber: 4, grams: 50), try entry(.dinner)])
        XCTAssertEqual(mixed.totals[.fiber].completeness, .partial)
        XCTAssertEqual(mixed.totals[.fiber].displayableAmount, 2)

        let allKnown = DaySummary(day: Fixtures.today,
                                  entries: [try entry(.lunch, fiber: 4, grams: 50), try entry(.dinner, fiber: 4, grams: 100)])
        XCTAssertEqual(allKnown.totals[.fiber].completeness, .complete)
        XCTAssertEqual(allKnown.totals[.fiber].displayableAmount, 6)
    }

    func testEntriesAreSortedByMealThenSortOrder() throws {
        let entries = [
            try entry(.dinner),
            try entry(.lunch, sortOrder: 1),
            try entry(.breakfast),
            try entry(.preWorkout),
            try entry(.lunch, sortOrder: 0)
        ]
        let summary = DaySummary(day: Fixtures.today, entries: entries)
        XCTAssertEqual(summary.entries.map(\.meal), [.preWorkout, .breakfast, .lunch, .lunch, .dinner])
        XCTAssertEqual(summary.entries(for: .lunch).map(\.sortOrder), [0, 1])
    }

    func testPerMealTotals() throws {
        let entries = [try entry(.lunch, grams: 100), try entry(.lunch, grams: 50), try entry(.dinner, grams: 100)]
        let summary = DaySummary(day: Fixtures.today, entries: entries)
        XCTAssertEqual(summary.totals(for: .lunch)[.energyKcal].knownAmount, 300)
        XCTAssertEqual(summary.totals(for: .dinner)[.energyKcal].knownAmount, 200)
        XCTAssertEqual(summary.totals(for: .snack)[.energyKcal].completeness, .noEntries)
    }

    func testDuplicateEntriesBothCount() throws {
        let entries = [try entry(.snack), try entry(.snack)]
        let summary = DaySummary(day: Fixtures.today, entries: entries)
        XCTAssertEqual(summary.entries.count, 2)
        XCTAssertNotEqual(entries[0].id, entries[1].id)
        XCTAssertEqual(summary.totals[.energyKcal].knownAmount, 400)
    }

    func testYesterdayAndTodayAreIndependent() throws {
        let yesterday = Fixtures.today.yesterday!
        let entries = [try entry(.lunch, day: yesterday, grams: 100), try entry(.lunch, grams: 50)]
        XCTAssertEqual(DaySummary(day: yesterday, entries: entries).totals[.energyKcal].knownAmount, 200)
        XCTAssertEqual(DaySummary(day: Fixtures.today, entries: entries).totals[.energyKcal].knownAmount, 100)
        XCTAssertTrue(DaySummary(day: Fixtures.date(2025, 6, 1), entries: entries).isEmpty)
    }
}
