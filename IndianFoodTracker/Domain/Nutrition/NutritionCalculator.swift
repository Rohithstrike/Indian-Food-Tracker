import Foundation

/// All nutrition math. Pure, deterministic, Decimal-only, and independent of any UI or storage.
nonisolated enum NutritionCalculator {
    /// Stored with every log entry, so a future rule change never silently reshapes history.
    static let version = 1

    /// Consumed amounts are rounded to this many decimal places when stored.
    static let storedPlaces = 4

    /// The measured amount (grams or millilitres) a portion represents.
    static func measuredAmount(for portion: Portion) -> Decimal {
        switch portion {
        case .measured(let amount):
            return amount
        case .servings(let count, let serving):
            return count * serving.baseAmount
        }
    }

    /// base nutrition, adjusted by variants, scaled to the measured amount, rounded once.
    /// Invalid inputs (non-positive reference or amount) give no values at all (everything unknown).
    static func consumed(perReference nutrients: NutrientAmounts,
                         referenceAmount: Decimal,
                         measuredAmount: Decimal,
                         variants: [FoodVariant]) -> NutrientAmounts {
        guard referenceAmount > 0, measuredAmount > 0 else { return NutrientAmounts() }
        var adjusted = nutrients
        for variant in variants {
            adjusted = adjusted.applying(adjustments: variant.adjustments)
        }
        return adjusted
            .scaled(by: measuredAmount, dividedBy: referenceAmount)
            .rounded(places: storedPlaces)
    }

    /// Display rounding. Half away from zero. Use this only at the display boundary.
    static func rounded(_ value: Decimal, places: Int,
                        mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, places, mode)
        return output
    }
}
