import XCTest
import SwiftData
@testable import IndianFoodTracker

/// Persistence spike, criteria 1 to 8. Every food and number here is FAKE test data.
@MainActor
final class SwiftDataSpikeTests: XCTestCase {

    private static let trickyDecimalStrings = [
        "3.3333", "12.55", "0.0001", "999999.9999", "0", "0.1", "-1.5", "12345678901234567.8901"
    ]

    // MARK: Helpers (deliberately not named test*)

    private func tempStoreURL() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ift-spike-\(UUID().uuidString).store")
        addTeardownBlock {
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
        }
        return url
    }

    private func entry(day: LocalDate, meal: MealType = .lunch, grams: Decimal = 100,
                       sortOrder: Int = 0, fiber: Decimal? = nil) throws -> FoodLogEntry {
        try Fixtures.makeEntry(food: Fixtures.food(fiber: fiber), portion: .measured(grams),
                               day: day, meal: meal, sortOrder: sortOrder)
    }

    /// Writes probes to an on-disk store, closes it, reopens it, and reads them back.
    private func probesAfterReopen(_ values: [Decimal]) throws -> [SpikeProbeValue] {
        let url = tempStoreURL()
        do {
            let container = try SpikeStore.makeOnDiskContainer(at: url)
            let context = ModelContext(container)
            for (index, value) in values.enumerated() {
                try SpikeStore.insertProbe(label: String(index), value: value, in: context)
            }
        }
        let reopened = try SpikeStore.makeOnDiskContainer(at: url)
        return try SpikeStore.fetchProbes(in: ModelContext(reopened))
    }

    // MARK: Criterion 1: containers initialize

    func testInMemoryContainerInitializes() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        XCTAssertEqual(try SpikeStore.recordCount(in: ModelContext(container)), 0)
    }

    func testOnDiskContainerInitializes() throws {
        let container = try SpikeStore.makeOnDiskContainer(at: tempStoreURL())
        XCTAssertEqual(try SpikeStore.recordCount(in: ModelContext(container)), 0)
    }

    // MARK: Criterion 2: save and fetch

    func testFoodSaveAndFetch() throws {
        let context = ModelContext(try SpikeStore.makeInMemoryContainer())
        let food = Fixtures.food(id: "sys.test.food", fiber: 2)
        try SpikeStore.upsert(food, at: Fixtures.loggedAt, in: context)
        XCTAssertEqual(try SpikeStore.fetchFood(id: food.id, in: context), food)
        XCTAssertNil(try SpikeStore.fetchFood(id: "sys.test.missing", in: context))
    }

    func testEntrySaveAndFetch() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let original = try Fixtures.makeEntry(portion: .servings(Fixtures.dec("1.5"), Fixtures.piece),
                                              variants: [Fixtures.lessOil, Fixtures.highSugar],
                                              meal: .preWorkout, sortOrder: 3)
        try SpikeStore.insert(original, in: ModelContext(container))
        let fetched = try SpikeStore.entries(on: original.day, in: ModelContext(container))
        XCTAssertEqual(fetched, [original])
    }

    // MARK: Criterion 3: Decimal exactness (B must pass, A is measured)

    func testDecimalStrategyB_StringProbeIsExactOnDisk() throws {
        let values = Self.trickyDecimalStrings.map { Fixtures.dec($0) }
        let probes = try probesAfterReopen(values)
        XCTAssertEqual(probes.count, values.count)
        for probe in probes {
            guard let index = Int(probe.label), values.indices.contains(index) else {
                XCTFail("unexpected probe label \(probe.label)"); continue
            }
            let original = values[index]
            XCTAssertEqual(probe.text, original.description)
            XCTAssertEqual(try SpikeDecimalText.decode(probe.text), original)
            print("SPIKE-DECIMAL-B \(original) -> \(probe.text)")
        }
    }

    func testDecimalStrategyB_EntryPayloadIsExactOnDisk() throws {
        var food = Fixtures.food(id: "sys.test.decimals")
        food.nutrients = NutrientAmounts([
            .energyKcal: Fixtures.dec("3.3333"), .protein: Fixtures.dec("12.55"),
            .fat: Fixtures.dec("0.0001"), .carbs: Fixtures.dec("999999.9999"), .fiber: 0
        ])
        let original = try Fixtures.makeEntry(food: food, portion: .measured(100))
        let url = tempStoreURL()
        do {
            let container = try SpikeStore.makeOnDiskContainer(at: url)
            try SpikeStore.insert(original, in: ModelContext(container))
        }
        let reopened = try SpikeStore.makeOnDiskContainer(at: url)
        let fetched = try SpikeStore.entries(on: original.day, in: ModelContext(reopened))
        XCTAssertEqual(fetched, [original])
        guard let restored = fetched.first else { return XCTFail("entry missing after reopen") }
        for id in NutrientID.allCases {
            XCTAssertEqual(restored.consumed[id]?.description, original.consumed[id]?.description,
                           "consumed \(id) changed")
            XCTAssertEqual(restored.snapshot.nutrients[id]?.description,
                           original.snapshot.nutrients[id]?.description, "snapshot \(id) changed")
        }
        XCTAssertEqual(restored.consumed[.fiber], 0)
        XCTAssertNil(restored.consumed[.sugar])
    }

    func testDecimalStrategyA_NativeAttributeIsMeasured() throws {
        let values = Self.trickyDecimalStrings.map { Fixtures.dec($0) }
        let probes = try probesAfterReopen(values)
        XCTAssertEqual(probes.count, values.count)   // the only hard assertion: rows came back
        var exact = 0
        for probe in probes {
            guard let index = Int(probe.label), values.indices.contains(index) else { continue }
            let original = values[index]
            let isExact = probe.native == original
            if isExact { exact += 1 }
            print("SPIKE-DECIMAL-A original=\(original) stored=\(probe.native) exact=\(isExact)")
        }
        print("SPIKE-DECIMAL-A summary: \(exact) of \(values.count) exact")
    }

    // MARK: Criterion 4: snapshot independence

    func testSnapshotSurvivesFoodEditAndDeletion() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let context = ModelContext(container)
        var food = Fixtures.food(id: "sys.test.chicken")
        try SpikeStore.upsert(food, at: Fixtures.loggedAt, in: context)
        let original = try Fixtures.makeEntry(food: food, portion: .servings(2, Fixtures.piece),
                                              variants: [Fixtures.lessOil])
        try SpikeStore.insert(original, in: context)

        food.nutrients = food.nutrients.setting(.energyKcal, to: 999)
        food.name = "CORRECTED"
        food.revision += 1
        try SpikeStore.upsert(food, at: Fixtures.loggedAt, in: context)
        XCTAssertEqual(try SpikeStore.fetchFood(id: food.id, in: context)?.nutrients[.energyKcal], 999)
        XCTAssertEqual(try SpikeStore.entries(on: original.day, in: ModelContext(container)), [original])

        try SpikeStore.deleteFood(id: food.id, in: context)
        XCTAssertNil(try SpikeStore.fetchFood(id: food.id, in: context))
        let afterDelete = try SpikeStore.entries(on: original.day, in: ModelContext(container))
        XCTAssertEqual(afterDelete, [original])
        XCTAssertEqual(afterDelete.first?.snapshot.name, "TEST FOOD (not real data)")
    }

    func testEditingStoredEntryRecomputesFromItsOwnSnapshot() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let context = ModelContext(container)
        let original = try Fixtures.makeEntry(portion: .measured(100))
        try SpikeStore.insert(original, in: context)
        let edited = try original.withPortion(.measured(250))
        try SpikeStore.update(edited, in: context)
        let reread = try SpikeStore.entries(on: original.day, in: ModelContext(container))
        XCTAssertEqual(reread, [edited])
        XCTAssertEqual(reread.first?.consumed[.energyKcal], 500)
        XCTAssertEqual(reread.first?.snapshot, original.snapshot)
    }

    func testStoredValuesAreNeverRecalculatedOnRead() throws {
        let base = try Fixtures.makeEntry()
        let stored = NutrientAmounts([.energyKcal: 12_345, .protein: Fixtures.dec("1.2345")])
        let old = FoodLogEntry.restore(id: base.id, day: base.day, meal: base.meal,
                                       loggedAt: base.loggedAt, sortOrder: base.sortOrder,
                                       snapshot: base.snapshot, portion: base.portion,
                                       variants: base.variants, consumed: stored, calculatorVersion: 0)
        let container = try SpikeStore.makeInMemoryContainer()
        try SpikeStore.insert(old, in: ModelContext(container))
        let fetched = try SpikeStore.entries(on: base.day, in: ModelContext(container))
        XCTAssertEqual(fetched, [old])
        XCTAssertEqual(fetched.first?.consumed, stored)
        XCTAssertEqual(fetched.first?.calculatorVersion, 0)
    }

    // MARK: Criterion 5: day queries

    func testFetchByDay() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let context = ModelContext(container)
        let today = try entry(day: Fixtures.today, meal: .lunch)
        let alsoToday = try entry(day: Fixtures.today, meal: .breakfast)
        let yesterday = try entry(day: Fixtures.today.yesterday!, meal: .dinner)
        for e in [today, alsoToday, yesterday] { try SpikeStore.insert(e, in: context) }
        let fetchedToday = try SpikeStore.entries(on: Fixtures.today, in: ModelContext(container))
        XCTAssertEqual(Set(fetchedToday.map(\.id)), Set([today.id, alsoToday.id]))
        let fetchedYesterday = try SpikeStore.entries(on: Fixtures.today.yesterday!, in: ModelContext(container))
        XCTAssertEqual(fetchedYesterday.map(\.id), [yesterday.id])
    }

    func testRangeFetchAcrossYearBoundaryAndLeapDay() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let context = ModelContext(container)
        let dec31 = try entry(day: Fixtures.date(2025, 12, 31))
        let jan1 = try entry(day: Fixtures.date(2026, 1, 1))
        let jan2 = try entry(day: Fixtures.date(2026, 1, 2))
        let leap = try entry(day: Fixtures.date(2024, 2, 29))
        for e in [dec31, jan1, jan2, leap] { try SpikeStore.insert(e, in: context) }

        let boundary = try SpikeStore.entries(from: Fixtures.date(2025, 12, 31),
                                              through: Fixtures.date(2026, 1, 1),
                                              in: ModelContext(container))
        XCTAssertEqual(boundary.map(\.id), [dec31.id, jan1.id])   // sorted by day

        let leapRange = try SpikeStore.entries(from: Fixtures.date(2024, 2, 28),
                                               through: Fixtures.date(2024, 3, 1),
                                               in: ModelContext(container))
        XCTAssertEqual(leapRange.map(\.id), [leap.id])
    }

    func testSoftDeletedEntriesAreExcluded() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let context = ModelContext(container)
        let keep = try entry(day: Fixtures.today, meal: .breakfast)
        let remove = try entry(day: Fixtures.today, meal: .dinner)
        try SpikeStore.insert(keep, in: context)
        try SpikeStore.insert(remove, in: context)
        try SpikeStore.softDelete(entryID: remove.id, at: Fixtures.loggedAt, in: context)
        let fetched = try SpikeStore.entries(on: Fixtures.today, in: ModelContext(container))
        XCTAssertEqual(fetched.map(\.id), [keep.id])
        XCTAssertEqual(try SpikeStore.recordCount(in: ModelContext(container)), 2)   // still stored
        XCTAssertThrowsError(try SpikeStore.softDelete(entryID: UUID(), at: Fixtures.loggedAt, in: context))
    }

    func testEmptyDayReturnsNothing() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        try SpikeStore.insert(try entry(day: Fixtures.today), in: ModelContext(container))
        XCTAssertTrue(try SpikeStore.entries(on: Fixtures.date(2025, 6, 1), in: ModelContext(container)).isEmpty)
    }

    func testDaySummaryFromFetchedEntriesMatchesOriginal() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let originals = [
            try entry(day: Fixtures.today, meal: .breakfast, grams: 50, sortOrder: 0, fiber: 4),
            try entry(day: Fixtures.today, meal: .lunch, grams: 100, sortOrder: 1),
            try entry(day: Fixtures.today.yesterday!, meal: .dinner, grams: 100)
        ]
        for e in originals { try SpikeStore.insert(e, in: ModelContext(container)) }
        let fetched = try SpikeStore.entries(on: Fixtures.today, in: ModelContext(container))
        XCTAssertEqual(DaySummary(day: Fixtures.today, entries: fetched),
                       DaySummary(day: Fixtures.today, entries: originals))
        XCTAssertEqual(DaySummary(day: Fixtures.today, entries: fetched).totals[.fiber].completeness, .partial)
    }

    func testUnknownFiberAndKnownZeroSurviveStorage() throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let unknown = try entry(day: Fixtures.today, meal: .breakfast, fiber: nil)
        let zero = try entry(day: Fixtures.today, meal: .lunch, fiber: 0)
        try SpikeStore.insert(unknown, in: ModelContext(container))
        try SpikeStore.insert(zero, in: ModelContext(container))
        let fetched = try SpikeStore.entries(on: Fixtures.today, in: ModelContext(container))
        let byID = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        XCTAssertNil(byID[unknown.id]?.consumed[.fiber])
        XCTAssertEqual(byID[zero.id]?.consumed[.fiber], 0)
        XCTAssertEqual(byID[zero.id]?.consumed.isKnown(.fiber), true)
    }

    // MARK: Criterion 6: isolation under the MainActor default

    func testBackgroundWriteMainReadUnderMainActorDefault() async throws {
        let container = try SpikeStore.makeInMemoryContainer()
        let original = try entry(day: Fixtures.today, meal: .preWorkout)
        try await Task.detached {
            let context = ModelContext(container)
            try SpikeStore.insert(original, in: context)
        }.value
        let fetched = try SpikeStore.entries(on: Fixtures.today, in: ModelContext(container))
        XCTAssertEqual(fetched, [original])
    }

    // MARK: Criterion 7: in-memory stores are isolated

    func testTwoInMemoryContainersAreIsolated() throws {
        let first = try SpikeStore.makeInMemoryContainer()
        let second = try SpikeStore.makeInMemoryContainer()
        try SpikeStore.insert(try entry(day: Fixtures.today), in: ModelContext(first))
        XCTAssertEqual(try SpikeStore.recordCount(in: ModelContext(first)), 1)
        XCTAssertEqual(try SpikeStore.recordCount(in: ModelContext(second)), 0)
    }

    // MARK: Criterion 8: data survives closing and reopening

    func testOnDiskDataSurvivesReopen() throws {
        let url = tempStoreURL()
        let original = try entry(day: Fixtures.today, meal: .snack, grams: Fixtures.dec("37.5"), fiber: 2)
        let food = Fixtures.food(id: "sys.test.persisted")
        do {
            let container = try SpikeStore.makeOnDiskContainer(at: url)
            let context = ModelContext(container)
            try SpikeStore.upsert(food, at: Fixtures.loggedAt, in: context)
            try SpikeStore.insert(original, in: context)
        }
        let reopened = try SpikeStore.makeOnDiskContainer(at: url)
        let context = ModelContext(reopened)
        XCTAssertEqual(try SpikeStore.entries(on: Fixtures.today, in: context), [original])
        XCTAssertEqual(try SpikeStore.fetchFood(id: food.id, in: context), food)
    }
}
