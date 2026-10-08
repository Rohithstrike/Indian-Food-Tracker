import Foundation

/// Nutrient values for some quantity of food.
///
/// A MISSING key means UNKNOWN. A present key, including 0, means KNOWN.
/// Unknown is never converted to zero anywhere in the domain.
nonisolated struct NutrientAmounts: Equatable, Sendable {
    private var values: [NutrientID: Decimal]

    init(_ values: [NutrientID: Decimal] = [:]) {
        self.values = values
    }

    subscript(_ id: NutrientID) -> Decimal? { values[id] }

    func isKnown(_ id: NutrientID) -> Bool { values[id] != nil }
    var knownIDs: Set<NutrientID> { Set(values.keys) }
    var isEmpty: Bool { values.isEmpty }
    var hasNegativeValue: Bool { values.values.contains { $0 < 0 } }

    /// Passing nil makes the nutrient unknown again.
    func setting(_ id: NutrientID, to value: Decimal?) -> NutrientAmounts {
        var copy = self
        copy.values[id] = value
        return copy
    }

    /// Multiplies first, then divides, so precision is lost at most once. Unknown stays unknown.
    func scaled(by numerator: Decimal, dividedBy denominator: Decimal) -> NutrientAmounts {
        NutrientAmounts(values.mapValues { $0 * numerator / denominator })
    }

    func rounded(places: Int) -> NutrientAmounts {
        NutrientAmounts(values.mapValues { NutritionCalculator.rounded($0, places: places) })
    }

    /// Adds adjustments only to nutrients that are KNOWN. Unknown nutrients stay unknown, because
    /// adding to an unknown value would invent data. Results never go below zero.
    func applying(adjustments: [NutrientID: Decimal]) -> NutrientAmounts {
        var result = values
        for (id, delta) in adjustments {
            guard let current = result[id] else { continue }
            result[id] = max(current + delta, 0)
        }
        return NutrientAmounts(result)
    }
}
