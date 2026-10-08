import Foundation

/// A calendar day in the Gregorian calendar, independent of time zone and time of day.
/// The persisted form is `dayKey`, an Int such as 20261007.
nonisolated struct LocalDate: Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    static let validYears = 1...9999
    static let epoch = LocalDate(year: 1970, month: 1, day: 1)!

    init?(year: Int, month: Int, day: Int) {
        guard Self.validYears.contains(year),
              (1...12).contains(month),
              day >= 1,
              day <= Self.daysInMonth(year: year, month: month) else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Decodes a persisted key such as 20261007. Returns nil for anything that is not a real date.
    init?(dayKey: Int) {
        self.init(year: dayKey / 10_000, month: (dayKey / 100) % 100, day: dayKey % 100)
    }

    var dayKey: Int { year * 10_000 + month * 100 + day }

    static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        case 2: return isLeapYear(year) ? 29 : 28
        default: return 0
        }
    }

    // MARK: - Day arithmetic (pure integer math, no Calendar)

    /// Days since 1970-01-01. Negative before that date.
    var daysSinceEpoch: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    init?(daysSinceEpoch days: Int) {
        guard days > -4_000_000, days < 4_000_000 else { return nil }
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        self.init(year: m <= 2 ? y + 1 : y, month: m, day: d)
    }

    /// nil if the result would fall outside the supported years.
    func adding(days: Int) -> LocalDate? {
        let (sum, overflow) = daysSinceEpoch.addingReportingOverflow(days)
        guard !overflow else { return nil }
        return LocalDate(daysSinceEpoch: sum)
    }

    var yesterday: LocalDate? { adding(days: -1) }
    var tomorrow: LocalDate? { adding(days: 1) }

    func days(until other: LocalDate) -> Int {
        other.daysSinceEpoch - daysSinceEpoch
    }

    // MARK: - From an instant

    /// The calendar day an instant falls on in the given time zone, using an explicit Gregorian
    /// calendar (never `Calendar.current`). The caller supplies the instant, so the domain
    /// never reads the system clock.
    static func containing(_ instant: Date, in timeZone: TimeZone) -> LocalDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: instant)
        return LocalDate(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1) ?? .epoch
    }

    // MARK: - Comparable, description

    static func < (lhs: LocalDate, rhs: LocalDate) -> Bool {
        lhs.dayKey < rhs.dayKey
    }

    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
