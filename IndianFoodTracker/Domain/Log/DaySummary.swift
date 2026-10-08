import Foundation

nonisolated extension MealType {
    /// Position in the day, from Pre-workout (0) to Late meal (6).
    var displayOrder: Int { MealType.allCases.firstIndex(of: self) ?? 0 }
}

/// Everything logged on one day. Derived from entries, never stored, so there is a single
/// source of truth. An unlogged day is "no data", not zero.
nonisolated struct DaySummary: Equatable, Sendable {
    let day: LocalDate
    let entries: [FoodLogEntry]
    let totals: NutrientTotals

    init(day: LocalDate, entries allEntries: [FoodLogEntry]) {
        let dayEntries = allEntries
            .filter { $0.day == day }
            .sorted { a, b in
                if a.meal.displayOrder != b.meal.displayOrder { return a.meal.displayOrder < b.meal.displayOrder }
                if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
                if a.loggedAt != b.loggedAt { return a.loggedAt < b.loggedAt }
                return a.id.uuidString < b.id.uuidString
            }
        self.day = day
        self.entries = dayEntries
        self.totals = NutrientTotals.total(of: dayEntries.map(\.consumed))
    }

    var isEmpty: Bool { entries.isEmpty }

    func entries(for meal: MealType) -> [FoodLogEntry] {
        entries.filter { $0.meal == meal }
    }

    func totals(for meal: MealType) -> NutrientTotals {
        NutrientTotals.total(of: entries(for: meal).map(\.consumed))
    }
}
