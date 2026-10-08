import Foundation

/// A stable, permanent food identifier such as "sys.idli.plain". Never reused, never an array index.
nonisolated struct FoodID: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init(stringLiteral value: String) { self.rawValue = value }
    var description: String { rawValue }
}

/// The unit that nutrition is measured against.
nonisolated enum MeasureUnit: String, Hashable, Sendable {
    case grams
    case milliliters
}

nonisolated enum FoodSource: String, Hashable, Sendable {
    case system
    case user
    case recipe
}

/// A household unit mapped to a measurable amount, e.g. "1 piece = 40 g".
nonisolated struct ServingDefinition: Equatable, Hashable, Sendable, Identifiable {
    let id: String
    let label: String
    /// In the food's unit (grams or millilitres).
    let baseAmount: Decimal
    var isDefault: Bool = false
}

/// A cooking variation such as "Less oil". Adjustments are added to the food's per-reference
/// nutrients. Variants are estimates unless stated otherwise.
nonisolated struct FoodVariant: Equatable, Hashable, Sendable, Identifiable {
    let id: String
    let group: String
    let label: String
    let adjustments: [NutrientID: Decimal]
    var isEstimate: Bool = true
}

/// A food definition (catalog or user). Editing it NEVER changes entries that were already logged.
nonisolated struct Food: Equatable, Sendable, Identifiable {
    let id: FoodID
    var name: String
    var aliases: [String] = []
    var source: FoodSource = .user
    var unit: MeasureUnit = .grams
    /// The amount the nutrients are stated for, e.g. 100 (grams).
    var referenceAmount: Decimal = 100
    var nutrients: NutrientAmounts
    var servings: [ServingDefinition] = []
    var variants: [FoodVariant] = []
    /// Increases when the user edits a user food. Recorded in each snapshot.
    var revision: Int = 1
}

nonisolated enum FoodValidationIssue: Equatable, Sendable {
    case emptyName
    case nonPositiveReferenceAmount
    case missingEnergy
    case negativeNutrient
    case duplicateServingID
    case nonPositiveServingAmount
    case duplicateVariantID
}

nonisolated extension Food {
    var validationIssues: [FoodValidationIssue] {
        var issues: [FoodValidationIssue] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyName) }
        if referenceAmount <= 0 { issues.append(.nonPositiveReferenceAmount) }
        if nutrients[.energyKcal] == nil { issues.append(.missingEnergy) }
        if nutrients.hasNegativeValue { issues.append(.negativeNutrient) }
        if Set(servings.map(\.id)).count != servings.count { issues.append(.duplicateServingID) }
        if servings.contains(where: { $0.baseAmount <= 0 }) { issues.append(.nonPositiveServingAmount) }
        if Set(variants.map(\.id)).count != variants.count { issues.append(.duplicateVariantID) }
        return issues
    }

    /// Energy must be known to log a food. Every other nutrient may be unknown.
    var isLoggable: Bool { validationIssues.isEmpty }

    var defaultServing: ServingDefinition? {
        servings.first(where: \.isDefault) ?? servings.first
    }
}
