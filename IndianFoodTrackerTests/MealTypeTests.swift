import XCTest
import UIKit
@testable import IndianFoodTracker

/// Locks the finalized V1 meal taxonomy: order, names, prompts, stable raw values.
@MainActor
final class MealTypeTests: XCTestCase {

    private let expectedOrder: [MealType] = [
        .preWorkout, .breakfast, .midMorning, .lunch, .snack, .dinner, .lateMeal
    ]

    func testSevenMealsInExactOrder() {
        XCTAssertEqual(MealType.allCases.count, 7)
        XCTAssertEqual(MealType.allCases, expectedOrder)
        XCTAssertEqual(MealType.allCases.first, .preWorkout)
        XCTAssertEqual(MealType.allCases.last, .lateMeal)
    }

    func testDisplayNames() {
        XCTAssertEqual(MealType.allCases.map(\.displayName),
                       ["Pre-workout", "Breakfast", "Mid-morning", "Lunch", "Snack", "Dinner", "Late meal"])
    }

    func testAddPrompts() {
        XCTAssertEqual(MealType.allCases.map(\.addPrompt),
                       ["Add pre-workout", "Add breakfast", "Add mid-morning food", "Add lunch",
                        "Add snack", "Add dinner", "Add late meal"])
    }

    func testRawValuesAreStable() {
        // These strings will be stored in user data later. They must never change.
        XCTAssertEqual(MealType.allCases.map(\.rawValue),
                       ["preWorkout", "breakfast", "midMorning", "lunch", "snack", "dinner", "lateMeal"])
    }

    func testIdsMatchRawValues() {
        for meal in MealType.allCases {
            XCTAssertEqual(meal.id, meal.rawValue)
        }
    }

    func testRawValueRoundTrip() {
        for meal in MealType.allCases {
            XCTAssertEqual(MealType(rawValue: meal.rawValue), meal)
        }
        XCTAssertNil(MealType(rawValue: "notAMeal"))
    }

    func testSymbolsAreUniqueAndExist() {
        let names = MealType.allCases.map(\.systemImage)
        XCTAssertEqual(Set(names).count, names.count)
        for name in names {
            XCTAssertNotNil(UIImage(systemName: name), "SF Symbol not found: \(name)")
        }
    }

    func testAddFoodRequestCarriesMealContext() {
        for meal in MealType.allCases {
            XCTAssertEqual(AddFoodRequest(meal: meal).meal, meal)
        }
        XCTAssertNil(AddFoodRequest(meal: nil).meal)
    }
}
