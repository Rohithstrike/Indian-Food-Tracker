import Foundation
@testable import IndianFoodTracker

/// Shared test data. Every number here is FAKE and describes no real food.
nonisolated enum Fixtures {
    /// Build decimals from strings. Decimal LITERALS such as 0.1 pass through Double and lose precision.
    static func dec(_ text: String) -> Decimal { Decimal(string: text)! }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> LocalDate {
        LocalDate(year: year, month: month, day: day)!
    }

    static let today = date(2026, 10, 7)
    static let loggedAt = Date(timeIntervalSince1970: 1_000_000)

    static let piece = ServingDefinition(id: "piece", label: "piece", baseAmount: 40, isDefault: true)
    static let bowl = ServingDefinition(id: "bowl", label: "bowl", baseAmount: 150)

    static let lessOil = FoodVariant(id: "oil.less", group: "Oil", label: "Less",
                                     adjustments: [.energyKcal: -18, .fat: -2])
    static let heavyOil = FoodVariant(id: "oil.heavy", group: "Oil", label: "Heavy",
                                      adjustments: [.energyKcal: 36, .fat: 4])
    static let highSugar = FoodVariant(id: "sugar.high", group: "Sugar", label: "High",
                                       adjustments: [.energyKcal: 20, .carbs: 5])

    /// Per 100 g: energy 200, protein 10, carbs 30, fat 5. Fiber unknown unless given.
    static func food(id: FoodID = "test.food", fiber: Decimal? = nil, includeEnergy: Bool = true) -> Food {
        var values: [NutrientID: Decimal] = [.protein: 10, .carbs: 30, .fat: 5]
        if includeEnergy { values[.energyKcal] = 200 }
        if let fiber { values[.fiber] = fiber }
        return Food(id: id, name: "TEST FOOD (not real data)", source: .system, unit: .grams,
                    referenceAmount: 100, nutrients: NutrientAmounts(values),
                    servings: [piece, bowl], variants: [lessOil, heavyOil, highSugar])
    }

    static func makeEntry(food: Food = Fixtures.food(), portion: Portion = .measured(100),
                          variants: [FoodVariant] = [], day: LocalDate = Fixtures.today,
                          meal: MealType = .lunch, sortOrder: Int = 0,
                          id: UUID = UUID()) throws -> FoodLogEntry {
        try FoodLogEntry.make(food: food, portion: portion, variants: variants, day: day,
                              today: today, meal: meal, loggedAt: loggedAt,
                              sortOrder: sortOrder, id: id)
    }
}
