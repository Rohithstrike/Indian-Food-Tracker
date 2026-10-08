import Foundation

/// Stable identifiers for nutrients. Raw values will be stored in user data, so never change them.
/// New nutrients can be added at the end without any schema change.
nonisolated enum NutrientID: String, CaseIterable, Hashable, Sendable {
    case energyKcal
    case protein
    case carbs
    case fat
    case fiber
    case sugar
    case saturatedFat
    case sodium

    var unit: NutrientUnit {
        switch self {
        case .energyKcal: return .kilocalories
        case .sodium:     return .milligrams
        default:          return .grams
        }
    }
}

nonisolated enum NutrientUnit: String, Hashable, Sendable {
    case kilocalories
    case grams
    case milligrams
}
