import Foundation
import Observation

/// TEMPORARY display shape for one logged food on the Today screen.
/// Replaced by the real MealEntry (with a nutrition snapshot) in Milestone 12.
struct TodayItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let detail: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    /// Fiber in grams. nil means UNKNOWN (never treated as zero).
    var fiber: Int? = nil
}

/// A fiber total that never pretends unknown values are zero.
/// `knownGrams` adds up only the foods whose fiber is known.
struct FiberTotal: Equatable {
    let knownGrams: Int
    let knownCount: Int
    let unknownCount: Int

    /// True when every food had fiber data.
    var isComplete: Bool { unknownCount == 0 }
    /// False when no food had fiber data, so `knownGrams` must not be shown as a real value.
    var hasAnyKnownValue: Bool { knownCount > 0 }

    /// Returns nil when there are no foods at all.
    static func total(of items: [TodayItem]) -> FiberTotal? {
        guard !items.isEmpty else { return nil }
        var grams = 0
        var known = 0
        var unknown = 0
        for item in items {
            if let fiber = item.fiber {
                grams += fiber
                known += 1
            } else {
                unknown += 1
            }
        }
        return FiberTotal(knownGrams: grams, knownCount: known, unknownCount: unknown)
    }
}

/// Prepares everything the Today screen displays.
@Observable
final class TodayViewModel {
    /// PLACEHOLDER target. The real, user-set target arrives with Settings (Milestone 17).
    static let placeholderCalorieTarget = 2_000

    var calorieTarget: Int = TodayViewModel.placeholderCalorieTarget
    private(set) var itemsByMeal: [MealType: [TodayItem]] = [:]

    // MARK: - Totals

    private var allItems: [TodayItem] {
        MealType.allCases.flatMap { items(for: $0) }
    }

    var isEmpty: Bool { allItems.isEmpty }
    var totalCalories: Int { allItems.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { allItems.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Int { allItems.reduce(0) { $0 + $1.carbs } }
    var totalFat: Int { allItems.reduce(0) { $0 + $1.fat } }

    /// nil when nothing is logged. Unknown fiber is never counted as zero.
    var fiberTotal: FiberTotal? { FiberTotal.total(of: allItems) }

    /// Negative when the user is over target.
    var remainingCalories: Int { calorieTarget - totalCalories }

    /// Fraction of the target eaten. Can exceed 1.
    var progress: Double {
        calorieTarget > 0 ? Double(totalCalories) / Double(calorieTarget) : 0
    }

    func items(for meal: MealType) -> [TodayItem] {
        itemsByMeal[meal] ?? []
    }

    // MARK: - Greeting and date

    var greeting: String {
        Self.greeting(forHour: Calendar.current.component(.hour, from: .now))
    }

    var dateText: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    /// 5-11 morning, 12-16 afternoon, otherwise evening.
    static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    // MARK: - Debug only

    func clearAll() {
        itemsByMeal = [:]
    }

    #if DEBUG
    /// Clearly fake sample data so the populated design can be judged.
    /// Compiled out of release builds. Removed when real logging exists.
    func loadDemoData() {
        func demo(_ n: Int, _ kcal: Int, _ p: Int, _ c: Int, _ f: Int, fiber: Int? = nil) -> TodayItem {
            TodayItem(name: "DEMO food \(n)", detail: "Sample values, not real data",
                      calories: kcal, protein: p, carbs: c, fat: f, fiber: fiber)
        }
        itemsByMeal = [
            .breakfast: [demo(1, 220, 6, 38, 4, fiber: 3), demo(2, 160, 8, 12, 9, fiber: 1)],
            .midMorning: [demo(3, 90, 1, 22, 0, fiber: 2)],
            .lunch: [demo(4, 450, 18, 60, 14, fiber: 6), demo(5, 120, 4, 18, 3)],
            .dinner: [demo(6, 380, 22, 30, 18, fiber: 4)]
        ]
    }

    static var demo: TodayViewModel {
        let viewModel = TodayViewModel()
        viewModel.loadDemoData()
        return viewModel
    }
    #endif
}
