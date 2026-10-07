import Foundation
import SwiftData

// SPIKE ONLY. Everything under Data/Spike/ can be deleted as one unit.
//
// Rules these models follow, so CloudKit stays possible later: every property has a default,
// nothing is marked unique, and there are no relationships (a log record points at its food
// by ID string only). They are `nonisolated` so the project's MainActor default does not
// spread into the pure domain through them.

@Model
nonisolated final class SpikeFoodRecord {
    var foodID: String = ""
    var name: String = ""
    var revision: Int = 1
    var updatedAt: Date = Date(timeIntervalSince1970: 0)
    var payload: Data = Data()

    init(foodID: String, name: String, revision: Int, updatedAt: Date, payload: Data) {
        self.foodID = foodID
        self.name = name
        self.revision = revision
        self.updatedAt = updatedAt
        self.payload = payload
    }
}

@Model
nonisolated final class SpikeLogRecord {
    #Index<SpikeLogRecord>([\.dayKey], [\.entryID])

    var entryID: UUID = UUID()
    var dayKey: Int = 0
    var mealRaw: String = ""
    var loggedAt: Date = Date(timeIntervalSince1970: 0)
    var sortOrder: Int = 0
    var foodRef: String = ""
    var calculatorVersion: Int = 0
    var deletedAt: Date? = nil
    var payload: Data = Data()

    init(entryID: UUID, dayKey: Int, mealRaw: String, loggedAt: Date, sortOrder: Int,
         foodRef: String, calculatorVersion: Int, payload: Data) {
        self.entryID = entryID
        self.dayKey = dayKey
        self.mealRaw = mealRaw
        self.loggedAt = loggedAt
        self.sortOrder = sortOrder
        self.foodRef = foodRef
        self.calculatorVersion = calculatorVersion
        self.payload = payload
    }
}

/// Throwaway model that compares two ways of storing a Decimal:
/// A) a native Decimal attribute, B) exact text.
@Model
nonisolated final class SpikeDecimalProbe {
    var label: String = ""
    var native: Decimal = 0
    var text: String = ""

    init(label: String, native: Decimal, text: String) {
        self.label = label
        self.native = native
        self.text = text
    }
}
