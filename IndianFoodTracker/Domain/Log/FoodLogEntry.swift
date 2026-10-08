import Foundation

/// How much was eaten.
nonisolated enum Portion: Equatable, Sendable {
    /// Grams or millilitres, in the food's unit.
    case measured(Decimal)
    case servings(Decimal, ServingDefinition)

    var quantity: Decimal {
        switch self {
        case .measured(let amount): return amount
        case .servings(let count, _): return count
        }
    }
}

/// The food as it was at the moment of logging. Frozen: it never reads the live food again.
nonisolated struct FoodSnapshot: Equatable, Sendable {
    let foodID: FoodID
    let name: String
    let unit: MeasureUnit
    let referenceAmount: Decimal
    let nutrients: NutrientAmounts
    let servings: [ServingDefinition]
    let variants: [FoodVariant]
    let foodRevision: Int

    init(_ food: Food) {
        foodID = food.id
        name = food.name
        unit = food.unit
        referenceAmount = food.referenceAmount
        nutrients = food.nutrients
        servings = food.servings
        variants = food.variants
        foodRevision = food.revision
    }

    /// Rebuilds a snapshot from stored fields (used when reading from storage).
    init(foodID: FoodID, name: String, unit: MeasureUnit, referenceAmount: Decimal,
         nutrients: NutrientAmounts, servings: [ServingDefinition], variants: [FoodVariant],
         foodRevision: Int) {
        self.foodID = foodID
        self.name = name
        self.unit = unit
        self.referenceAmount = referenceAmount
        self.nutrients = nutrients
        self.servings = servings
        self.variants = variants
        self.foodRevision = foodRevision
    }
}

nonisolated enum FoodLogError: Error, Equatable, Sendable {
    case foodNotLoggable
    case dayIsInFuture
    case quantityNotPositive
    case servingNotFromFood
    case variantNotFromFood
    case duplicateVariantGroup
}

/// What the user actually ate. The `consumed` amounts are the authoritative numbers for display
/// and totals. Edits recompute from this entry's own frozen snapshot, never from the live food.
nonisolated struct FoodLogEntry: Equatable, Sendable, Identifiable {
    let id: UUID
    let day: LocalDate
    let meal: MealType
    let loggedAt: Date
    let sortOrder: Int
    let snapshot: FoodSnapshot
    let portion: Portion
    let variants: [FoodVariant]
    let consumed: NutrientAmounts
    let calculatorVersion: Int

    var isEstimate: Bool { variants.contains { $0.isEstimate } }

    private init(id: UUID, day: LocalDate, meal: MealType, loggedAt: Date, sortOrder: Int,
                 snapshot: FoodSnapshot, portion: Portion, variants: [FoodVariant],
                 consumed: NutrientAmounts, calculatorVersion: Int) {
        self.id = id
        self.day = day
        self.meal = meal
        self.loggedAt = loggedAt
        self.sortOrder = sortOrder
        self.snapshot = snapshot
        self.portion = portion
        self.variants = variants
        self.consumed = consumed
        self.calculatorVersion = calculatorVersion
    }

    // MARK: - Creating

    /// Logs a food. `today` is supplied by the caller. Future days are rejected.
    static func make(food: Food, portion: Portion, variants: [FoodVariant] = [],
                     day: LocalDate, today: LocalDate, meal: MealType, loggedAt: Date,
                     sortOrder: Int = 0, id: UUID = UUID()) throws -> FoodLogEntry {
        guard food.isLoggable else { throw FoodLogError.foodNotLoggable }
        guard day <= today else { throw FoodLogError.dayIsInFuture }
        let snapshot = FoodSnapshot(food)
        try validate(portion: portion, variants: variants, snapshot: snapshot)
        return FoodLogEntry(id: id, day: day, meal: meal, loggedAt: loggedAt, sortOrder: sortOrder,
                            snapshot: snapshot, portion: portion, variants: variants,
                            consumed: compute(snapshot: snapshot, portion: portion, variants: variants),
                            calculatorVersion: NutritionCalculator.version)
    }

    // MARK: - Restoring (from storage)

    /// Rebuilds an entry exactly as it was stored. It deliberately does NOT recalculate:
    /// `consumed` and `calculatorVersion` are used as persisted, so a later calculator change
    /// can never silently rewrite history. It does not apply the "no future day" rule either,
    /// because that rule is for creating or moving entries, not for reading history.
    static func restore(id: UUID, day: LocalDate, meal: MealType, loggedAt: Date, sortOrder: Int,
                        snapshot: FoodSnapshot, portion: Portion, variants: [FoodVariant],
                        consumed: NutrientAmounts, calculatorVersion: Int) -> FoodLogEntry {
        FoodLogEntry(id: id, day: day, meal: meal, loggedAt: loggedAt, sortOrder: sortOrder,
                     snapshot: snapshot, portion: portion, variants: variants,
                     consumed: consumed, calculatorVersion: calculatorVersion)
    }

    // MARK: - Editing (always from the frozen snapshot)

    func withPortion(_ newPortion: Portion) throws -> FoodLogEntry {
        try Self.validate(portion: newPortion, variants: variants, snapshot: snapshot)
        return updating(portion: newPortion)
    }

    func withVariants(_ newVariants: [FoodVariant]) throws -> FoodLogEntry {
        try Self.validate(portion: portion, variants: newVariants, snapshot: snapshot)
        return updating(variants: newVariants)
    }

    /// Changing the meal never touches the stored nutrition.
    func withMeal(_ newMeal: MealType) -> FoodLogEntry {
        updating(meal: newMeal)
    }

    /// Moving to another day never touches the stored nutrition. Future days are rejected.
    func withDay(_ newDay: LocalDate, today: LocalDate) throws -> FoodLogEntry {
        guard newDay <= today else { throw FoodLogError.dayIsInFuture }
        return updating(day: newDay)
    }

    // MARK: - Internals

    private func updating(day: LocalDate? = nil, meal: MealType? = nil,
                          portion: Portion? = nil, variants: [FoodVariant]? = nil) -> FoodLogEntry {
        let newPortion = portion ?? self.portion
        let newVariants = variants ?? self.variants
        let recalculate = portion != nil || variants != nil
        return FoodLogEntry(
            id: id,
            day: day ?? self.day,
            meal: meal ?? self.meal,
            loggedAt: loggedAt,
            sortOrder: sortOrder,
            snapshot: snapshot,
            portion: newPortion,
            variants: newVariants,
            consumed: recalculate
                ? Self.compute(snapshot: snapshot, portion: newPortion, variants: newVariants)
                : consumed,
            calculatorVersion: recalculate ? NutritionCalculator.version : calculatorVersion)
    }

    private static func compute(snapshot: FoodSnapshot, portion: Portion,
                                variants: [FoodVariant]) -> NutrientAmounts {
        NutritionCalculator.consumed(
            perReference: snapshot.nutrients,
            referenceAmount: snapshot.referenceAmount,
            measuredAmount: NutritionCalculator.measuredAmount(for: portion),
            variants: variants)
    }

    private static func validate(portion: Portion, variants: [FoodVariant],
                                 snapshot: FoodSnapshot) throws {
        guard portion.quantity > 0 else { throw FoodLogError.quantityNotPositive }
        if case .servings(_, let serving) = portion, !snapshot.servings.contains(serving) {
            throw FoodLogError.servingNotFromFood
        }
        for variant in variants where !snapshot.variants.contains(variant) {
            throw FoodLogError.variantNotFromFood
        }
        guard Set(variants.map(\.group)).count == variants.count else {
            throw FoodLogError.duplicateVariantGroup
        }
    }
}
