import Foundation

/// A running total for ONE nutrient that never pretends unknown values are zero.
nonisolated struct NutrientTotal: Equatable, Sendable {
    enum Completeness: Equatable, Sendable {
        case noEntries       // nothing was logged
        case noKnownValues   // entries exist, but none has this nutrient
        case partial         // some entries have it, some do not
        case complete        // every entry has it
    }

    private(set) var knownAmount: Decimal = 0
    private(set) var knownCount = 0
    private(set) var unknownCount = 0

    static let empty = NutrientTotal()
    init() {}

    func adding(_ amount: Decimal?) -> NutrientTotal {
        var copy = self
        if let amount {
            copy.knownAmount += amount
            copy.knownCount += 1
        } else {
            copy.unknownCount += 1
        }
        return copy
    }

    var completeness: Completeness {
        if knownCount + unknownCount == 0 { return .noEntries }
        if knownCount == 0 { return .noKnownValues }
        return unknownCount == 0 ? .complete : .partial
    }

    var hasAnyKnownValue: Bool { knownCount > 0 }
    var isComplete: Bool { completeness == .complete }

    /// The amount that is safe to display. nil when no entry has a known value (never 0).
    var displayableAmount: Decimal? { hasAnyKnownValue ? knownAmount : nil }
}

/// Totals for every nutrient across a set of entries.
nonisolated struct NutrientTotals: Equatable, Sendable {
    let entryCount: Int
    private let totals: [NutrientID: NutrientTotal]

    private init(entryCount: Int, totals: [NutrientID: NutrientTotal]) {
        self.entryCount = entryCount
        self.totals = totals
    }

    subscript(_ id: NutrientID) -> NutrientTotal { totals[id] ?? .empty }

    /// Sums stored (already rounded) values. Nothing is re-rounded here.
    static func total(of amounts: [NutrientAmounts]) -> NutrientTotals {
        var totals: [NutrientID: NutrientTotal] = [:]
        for id in NutrientID.allCases {
            var total = NutrientTotal.empty
            for entry in amounts {
                total = total.adding(entry[id])
            }
            totals[id] = total
        }
        return NutrientTotals(entryCount: amounts.count, totals: totals)
    }
}
