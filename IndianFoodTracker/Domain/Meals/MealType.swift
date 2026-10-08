import Foundation

/// The meals a day is divided into, in the order they appear on screen.
nonisolated enum MealType: String, CaseIterable, Identifiable {
    case preWorkout
    case breakfast
    case midMorning
    case lunch
    case snack
    case dinner
    case lateMeal

    var id: String { rawValue }

    /// Name shown as a section title, e.g. "Breakfast".
    var displayName: String {
        switch self {
        case .preWorkout:    return "Pre-workout"
        case .breakfast:    return "Breakfast"
        case .midMorning:   return "Mid-morning"
        case .lunch:        return "Lunch"
        case .snack: return "Snack"
        case .dinner:       return "Dinner"
        case .lateMeal:    return "Late meal"
        }
    }

    /// Text for the empty-row prompt, e.g. "Add breakfast".
    var addPrompt: String {
        switch self {
        case .preWorkout:    return "Add pre-workout"
        case .breakfast:    return "Add breakfast"
        case .midMorning:   return "Add mid-morning food"
        case .lunch:        return "Add lunch"
        case .snack: return "Add snack"
        case .dinner:       return "Add dinner"
        case .lateMeal:    return "Add late meal"
        }
    }

    /// An Apple SF Symbol name used as the meal's icon.
    var systemImage: String {
        switch self {
        case .preWorkout:    return "dumbbell"
        case .breakfast:    return "sunrise"
        case .midMorning:   return "cup.and.saucer"
        case .lunch:        return "sun.max"
        case .snack: return "leaf"
        case .dinner:       return "fork.knife"
        case .lateMeal:    return "moon.stars"
        }
    }
}
