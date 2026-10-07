import Foundation
import SwiftData

// SPIKE ONLY. The smallest set of operations needed to prove the criteria. This is not the
// production repository layer.

nonisolated enum SpikeStoreError: Error, Equatable {
    case entryNotFound(UUID)
}

nonisolated struct SpikeProbeValue: Sendable {
    let label: String
    let native: Decimal
    let text: String
}

nonisolated enum SpikeStore {
    static var schema: Schema {
        Schema([SpikeFoodRecord.self, SpikeLogRecord.self, SpikeDecimalProbe.self])
    }

    // MARK: Containers (CloudKit off, no entitlements)

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(UUID().uuidString, schema: schema,
                                               isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeOnDiskContainer(at url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: Foods

    static func upsert(_ food: Food, at date: Date, in context: ModelContext) throws {
        let raw = food.id.rawValue
        var descriptor = FetchDescriptor<SpikeFoodRecord>(
            predicate: #Predicate<SpikeFoodRecord> { $0.foodID == raw })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            try SpikeCodec.apply(food, at: date, to: existing)
        } else {
            context.insert(try SpikeCodec.record(for: food, updatedAt: date))
        }
        try context.save()
    }

    static func fetchFood(id: FoodID, in context: ModelContext) throws -> Food? {
        let raw = id.rawValue
        var descriptor = FetchDescriptor<SpikeFoodRecord>(
            predicate: #Predicate<SpikeFoodRecord> { $0.foodID == raw })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return nil }
        return try SpikeCodec.food(from: record)
    }

    /// Hard delete, to prove log entries never depend on a food row.
    static func deleteFood(id: FoodID, in context: ModelContext) throws {
        let raw = id.rawValue
        let descriptor = FetchDescriptor<SpikeFoodRecord>(
            predicate: #Predicate<SpikeFoodRecord> { $0.foodID == raw })
        for record in try context.fetch(descriptor) { context.delete(record) }
        try context.save()
    }

    // MARK: Log entries

    static func insert(_ entry: FoodLogEntry, in context: ModelContext) throws {
        context.insert(try SpikeCodec.record(for: entry))
        try context.save()
    }

    static func update(_ entry: FoodLogEntry, in context: ModelContext) throws {
        let id = entry.id
        var descriptor = FetchDescriptor<SpikeLogRecord>(
            predicate: #Predicate<SpikeLogRecord> { $0.entryID == id })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { throw SpikeStoreError.entryNotFound(id) }
        try SpikeCodec.apply(entry, to: record)
        try context.save()
    }

    static func softDelete(entryID: UUID, at date: Date, in context: ModelContext) throws {
        var descriptor = FetchDescriptor<SpikeLogRecord>(
            predicate: #Predicate<SpikeLogRecord> { $0.entryID == entryID })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { throw SpikeStoreError.entryNotFound(entryID) }
        record.deletedAt = date
        try context.save()
    }

    static func entries(on day: LocalDate, in context: ModelContext) throws -> [FoodLogEntry] {
        try entries(from: day, through: day, in: context)
    }

    /// Inclusive range. Day keys sort the same way calendar days do, so a numeric range is exact.
    static func entries(from first: LocalDate, through last: LocalDate,
                        in context: ModelContext) throws -> [FoodLogEntry] {
        let low = first.dayKey
        let high = last.dayKey
        let descriptor = FetchDescriptor<SpikeLogRecord>(
            predicate: #Predicate<SpikeLogRecord> {
                $0.dayKey >= low && $0.dayKey <= high && $0.deletedAt == nil
            },
            sortBy: [SortDescriptor(\SpikeLogRecord.dayKey),
                     SortDescriptor(\SpikeLogRecord.sortOrder),
                     SortDescriptor(\SpikeLogRecord.loggedAt)])
        return try context.fetch(descriptor).map { try SpikeCodec.entry(from: $0) }
    }

    /// Counts every stored log record, including soft-deleted ones.
    static func recordCount(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<SpikeLogRecord>())
    }

    // MARK: Decimal probe

    static func insertProbe(label: String, value: Decimal, in context: ModelContext) throws {
        context.insert(SpikeDecimalProbe(label: label, native: value, text: SpikeDecimalText.encode(value)))
        try context.save()
    }

    static func fetchProbes(in context: ModelContext) throws -> [SpikeProbeValue] {
        try context.fetch(FetchDescriptor<SpikeDecimalProbe>())
            .map { SpikeProbeValue(label: $0.label, native: $0.native, text: $0.text) }
    }
}
