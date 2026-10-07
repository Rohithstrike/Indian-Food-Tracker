import Foundation

// SPIKE ONLY. Store-agnostic DTOs and mappers. Every Decimal is written as exact text, so no
// floating-point conversion can touch it. The domain types themselves are never Codable.

nonisolated enum SpikeCodecError: Error, Equatable {
    case invalidDecimal(String)
    case unknownNutrient(String)
    case unknownMeal(String)
    case unknownUnit(String)
    case unknownSource(String)
    case unknownPortionKind(String)
    case missingServing
    case invalidDayKey(Int)
}

nonisolated enum SpikeDecimalText {
    static func encode(_ value: Decimal) -> String { value.description }

    static func decode(_ text: String) throws -> Decimal {
        guard let value = Decimal(string: text) else { throw SpikeCodecError.invalidDecimal(text) }
        return value
    }

    static func encode(_ dictionary: [NutrientID: Decimal]) -> [String: String] {
        var out: [String: String] = [:]
        for (id, value) in dictionary { out[id.rawValue] = encode(value) }
        return out
    }

    static func decodeDictionary(_ stored: [String: String]) throws -> [NutrientID: Decimal] {
        var out: [NutrientID: Decimal] = [:]
        for (key, text) in stored {
            guard let id = NutrientID(rawValue: key) else { throw SpikeCodecError.unknownNutrient(key) }
            out[id] = try decode(text)
        }
        return out
    }
}

nonisolated struct SpikeAmountsDTO: Codable, Equatable, Sendable {
    var values: [String: String]

    init(_ amounts: NutrientAmounts) {
        var dictionary: [NutrientID: Decimal] = [:]
        for id in amounts.knownIDs {
            if let value = amounts[id] { dictionary[id] = value }
        }
        values = SpikeDecimalText.encode(dictionary)
    }

    func toDomain() throws -> NutrientAmounts {
        NutrientAmounts(try SpikeDecimalText.decodeDictionary(values))
    }
}

nonisolated struct SpikeServingDTO: Codable, Equatable, Sendable {
    var id: String
    var label: String
    var baseAmount: String
    var isDefault: Bool

    init(_ serving: ServingDefinition) {
        id = serving.id
        label = serving.label
        baseAmount = SpikeDecimalText.encode(serving.baseAmount)
        isDefault = serving.isDefault
    }

    func toDomain() throws -> ServingDefinition {
        ServingDefinition(id: id, label: label,
                          baseAmount: try SpikeDecimalText.decode(baseAmount), isDefault: isDefault)
    }
}

nonisolated struct SpikeVariantDTO: Codable, Equatable, Sendable {
    var id: String
    var group: String
    var label: String
    var adjustments: [String: String]
    var isEstimate: Bool

    init(_ variant: FoodVariant) {
        id = variant.id
        group = variant.group
        label = variant.label
        adjustments = SpikeDecimalText.encode(variant.adjustments)
        isEstimate = variant.isEstimate
    }

    func toDomain() throws -> FoodVariant {
        FoodVariant(id: id, group: group, label: label,
                    adjustments: try SpikeDecimalText.decodeDictionary(adjustments),
                    isEstimate: isEstimate)
    }
}

nonisolated struct SpikeSnapshotDTO: Codable, Equatable, Sendable {
    var foodID: String
    var name: String
    var unit: String
    var referenceAmount: String
    var nutrients: SpikeAmountsDTO
    var servings: [SpikeServingDTO]
    var variants: [SpikeVariantDTO]
    var foodRevision: Int

    init(_ snapshot: FoodSnapshot) {
        foodID = snapshot.foodID.rawValue
        name = snapshot.name
        unit = snapshot.unit.rawValue
        referenceAmount = SpikeDecimalText.encode(snapshot.referenceAmount)
        nutrients = SpikeAmountsDTO(snapshot.nutrients)
        servings = snapshot.servings.map { SpikeServingDTO($0) }
        variants = snapshot.variants.map { SpikeVariantDTO($0) }
        foodRevision = snapshot.foodRevision
    }

    func toDomain() throws -> FoodSnapshot {
        guard let measure = MeasureUnit(rawValue: unit) else { throw SpikeCodecError.unknownUnit(unit) }
        return FoodSnapshot(foodID: FoodID(rawValue: foodID), name: name, unit: measure,
                            referenceAmount: try SpikeDecimalText.decode(referenceAmount),
                            nutrients: try nutrients.toDomain(),
                            servings: try servings.map { try $0.toDomain() },
                            variants: try variants.map { try $0.toDomain() },
                            foodRevision: foodRevision)
    }
}

nonisolated struct SpikePortionDTO: Codable, Equatable, Sendable {
    var kind: String
    var quantity: String
    var serving: SpikeServingDTO?

    init(_ portion: Portion) {
        switch portion {
        case .measured(let amount):
            kind = "measured"
            quantity = SpikeDecimalText.encode(amount)
            serving = nil
        case .servings(let count, let definition):
            kind = "servings"
            quantity = SpikeDecimalText.encode(count)
            serving = SpikeServingDTO(definition)
        }
    }

    func toDomain() throws -> Portion {
        let amount = try SpikeDecimalText.decode(quantity)
        switch kind {
        case "measured":
            return .measured(amount)
        case "servings":
            guard let serving else { throw SpikeCodecError.missingServing }
            return .servings(amount, try serving.toDomain())
        default:
            throw SpikeCodecError.unknownPortionKind(kind)
        }
    }
}

/// What lives in the log record's payload. The day, meal, time, sort order and calculator
/// version are separate columns, so there is exactly one copy of each.
nonisolated struct SpikeEntryPayloadDTO: Codable, Equatable, Sendable {
    var snapshot: SpikeSnapshotDTO
    var portion: SpikePortionDTO
    var variants: [SpikeVariantDTO]
    var consumed: SpikeAmountsDTO
}

nonisolated struct SpikeFoodDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var aliases: [String]
    var source: String
    var unit: String
    var referenceAmount: String
    var nutrients: SpikeAmountsDTO
    var servings: [SpikeServingDTO]
    var variants: [SpikeVariantDTO]
    var revision: Int

    init(_ food: Food) {
        id = food.id.rawValue
        name = food.name
        aliases = food.aliases
        source = food.source.rawValue
        unit = food.unit.rawValue
        referenceAmount = SpikeDecimalText.encode(food.referenceAmount)
        nutrients = SpikeAmountsDTO(food.nutrients)
        servings = food.servings.map { SpikeServingDTO($0) }
        variants = food.variants.map { SpikeVariantDTO($0) }
        revision = food.revision
    }

    func toDomain() throws -> Food {
        guard let foodSource = FoodSource(rawValue: source) else { throw SpikeCodecError.unknownSource(source) }
        guard let measure = MeasureUnit(rawValue: unit) else { throw SpikeCodecError.unknownUnit(unit) }
        return Food(id: FoodID(rawValue: id), name: name, aliases: aliases, source: foodSource,
                    unit: measure, referenceAmount: try SpikeDecimalText.decode(referenceAmount),
                    nutrients: try nutrients.toDomain(),
                    servings: try servings.map { try $0.toDomain() },
                    variants: try variants.map { try $0.toDomain() },
                    revision: revision)
    }
}

nonisolated enum SpikeCodec {
    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    // MARK: Log entries

    static func payload(for entry: FoodLogEntry) throws -> Data {
        try encoder().encode(SpikeEntryPayloadDTO(
            snapshot: SpikeSnapshotDTO(entry.snapshot),
            portion: SpikePortionDTO(entry.portion),
            variants: entry.variants.map { SpikeVariantDTO($0) },
            consumed: SpikeAmountsDTO(entry.consumed)))
    }

    static func record(for entry: FoodLogEntry) throws -> SpikeLogRecord {
        SpikeLogRecord(entryID: entry.id, dayKey: entry.day.dayKey, mealRaw: entry.meal.rawValue,
                       loggedAt: entry.loggedAt, sortOrder: entry.sortOrder,
                       foodRef: entry.snapshot.foodID.rawValue,
                       calculatorVersion: entry.calculatorVersion,
                       payload: try payload(for: entry))
    }

    static func apply(_ entry: FoodLogEntry, to record: SpikeLogRecord) throws {
        record.dayKey = entry.day.dayKey
        record.mealRaw = entry.meal.rawValue
        record.loggedAt = entry.loggedAt
        record.sortOrder = entry.sortOrder
        record.foodRef = entry.snapshot.foodID.rawValue
        record.calculatorVersion = entry.calculatorVersion
        record.payload = try payload(for: entry)
    }

    /// Rebuilds the entry exactly as stored. It never recalculates.
    static func entry(from record: SpikeLogRecord) throws -> FoodLogEntry {
        guard let day = LocalDate(dayKey: record.dayKey) else { throw SpikeCodecError.invalidDayKey(record.dayKey) }
        guard let meal = MealType(rawValue: record.mealRaw) else { throw SpikeCodecError.unknownMeal(record.mealRaw) }
        let stored = try JSONDecoder().decode(SpikeEntryPayloadDTO.self, from: record.payload)
        return FoodLogEntry.restore(id: record.entryID, day: day, meal: meal, loggedAt: record.loggedAt,
                                    sortOrder: record.sortOrder,
                                    snapshot: try stored.snapshot.toDomain(),
                                    portion: try stored.portion.toDomain(),
                                    variants: try stored.variants.map { try $0.toDomain() },
                                    consumed: try stored.consumed.toDomain(),
                                    calculatorVersion: record.calculatorVersion)
    }

    // MARK: Foods

    static func record(for food: Food, updatedAt: Date) throws -> SpikeFoodRecord {
        SpikeFoodRecord(foodID: food.id.rawValue, name: food.name, revision: food.revision,
                        updatedAt: updatedAt, payload: try encoder().encode(SpikeFoodDTO(food)))
    }

    static func apply(_ food: Food, at updatedAt: Date, to record: SpikeFoodRecord) throws {
        record.name = food.name
        record.revision = food.revision
        record.updatedAt = updatedAt
        record.payload = try encoder().encode(SpikeFoodDTO(food))
    }

    static func food(from record: SpikeFoodRecord) throws -> Food {
        try JSONDecoder().decode(SpikeFoodDTO.self, from: record.payload).toDomain()
    }
}
