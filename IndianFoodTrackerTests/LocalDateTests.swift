import XCTest
@testable import IndianFoodTracker

@MainActor
final class LocalDateTests: XCTestCase {

    func testValidDates() {
        XCTAssertNotNil(LocalDate(year: 2026, month: 10, day: 7))
        XCTAssertNotNil(LocalDate(year: 2024, month: 2, day: 29))
        XCTAssertNotNil(LocalDate(year: 2000, month: 2, day: 29))
        XCTAssertNotNil(LocalDate(year: 2026, month: 12, day: 31))
    }

    func testInvalidDates() {
        XCTAssertNil(LocalDate(year: 2026, month: 2, day: 29))
        XCTAssertNil(LocalDate(year: 1900, month: 2, day: 29))
        XCTAssertNil(LocalDate(year: 2026, month: 4, day: 31))
        XCTAssertNil(LocalDate(year: 2026, month: 13, day: 1))
        XCTAssertNil(LocalDate(year: 2026, month: 0, day: 1))
        XCTAssertNil(LocalDate(year: 2026, month: 1, day: 0))
        XCTAssertNil(LocalDate(year: 0, month: 1, day: 1))
        XCTAssertNil(LocalDate(year: 10_000, month: 1, day: 1))
    }

    func testDayKeyAndDescription() {
        let d = Fixtures.date(2026, 10, 7)
        XCTAssertEqual(d.dayKey, 20261007)
        XCTAssertEqual(d.description, "2026-10-07")
        XCTAssertEqual(Fixtures.date(2026, 1, 2).dayKey, 20260102)
    }

    func testDayKeyRoundTripAndRejection() {
        XCTAssertEqual(LocalDate(dayKey: 20261007), Fixtures.date(2026, 10, 7))
        for key in [0, -1, 20261340, 20260230, 20260007, 202610070, 99999999] {
            XCTAssertNil(LocalDate(dayKey: key), "dayKey \(key) should be rejected")
        }
    }

    func testEqualityHashingAndOrdering() {
        let a = Fixtures.date(2026, 10, 7)
        let b = Fixtures.date(2026, 10, 7)
        let c = Fixtures.date(2026, 10, 8)
        let d = Fixtures.date(2027, 1, 1)
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set([a, b, c]).count, 2)
        XCTAssertLessThan(a, c)
        XCTAssertLessThan(c, d)
        XCTAssertEqual([d, c, a].sorted(), [a, c, d])
    }

    func testKnownDayCounts() {
        XCTAssertEqual(LocalDate.epoch.daysSinceEpoch, 0)
        XCTAssertEqual(Fixtures.date(2000, 1, 1).daysSinceEpoch, 10_957)
        XCTAssertEqual(Fixtures.date(1969, 12, 31).daysSinceEpoch, -1)
        XCTAssertEqual(Fixtures.date(2026, 10, 7).days(until: Fixtures.date(2026, 10, 10)), 3)
    }

    func testDayArithmeticRoundTrips() {
        for i in stride(from: -50_000, through: 100_000, by: 37) {
            let d = LocalDate(daysSinceEpoch: i)!
            XCTAssertEqual(d.daysSinceEpoch, i)
            XCTAssertEqual(d.adding(days: 1)?.daysSinceEpoch, i + 1)
        }
    }

    func testYesterdayAndTomorrowAcrossBoundaries() {
        XCTAssertEqual(Fixtures.date(2026, 3, 1).yesterday, Fixtures.date(2026, 2, 28))
        XCTAssertEqual(Fixtures.date(2024, 3, 1).yesterday, Fixtures.date(2024, 2, 29))
        XCTAssertEqual(Fixtures.date(2026, 1, 1).yesterday, Fixtures.date(2025, 12, 31))
        XCTAssertEqual(Fixtures.date(2026, 12, 31).tomorrow, Fixtures.date(2027, 1, 1))
        XCTAssertEqual(Fixtures.date(2024, 2, 28).tomorrow, Fixtures.date(2024, 2, 29))
        XCTAssertEqual(Fixtures.date(2026, 2, 28).tomorrow, Fixtures.date(2026, 3, 1))
    }

    func testAddingDaysOutOfRange() {
        XCTAssertNil(Fixtures.date(9999, 12, 31).adding(days: 1))
        XCTAssertNil(Fixtures.date(2026, 10, 7).adding(days: Int.max))
        XCTAssertNil(Fixtures.date(2026, 10, 7).adding(days: Int.min))
    }

    // 2026-10-07 20:00 UTC
    private var instant: TimeInterval {
        TimeInterval(Fixtures.date(2026, 10, 7).daysSinceEpoch * 86_400 + 72_000)
    }

    func testContainingDependsOnTimeZone() {
        let date = Date(timeIntervalSince1970: instant)
        XCTAssertEqual(LocalDate.containing(date, in: TimeZone(identifier: "UTC")!), Fixtures.date(2026, 10, 7))
        XCTAssertEqual(LocalDate.containing(date, in: TimeZone(identifier: "Asia/Kolkata")!), Fixtures.date(2026, 10, 8))
        XCTAssertEqual(LocalDate.containing(date, in: TimeZone(identifier: "America/Los_Angeles")!), Fixtures.date(2026, 10, 7))
    }

    func testContainingAtMidnightBoundary() {
        let kolkata = TimeZone(identifier: "Asia/Kolkata")!
        let start = Fixtures.date(2026, 10, 7).daysSinceEpoch * 86_400
        // 18:29:59 UTC is 23:59:59 in Kolkata. 18:30:00 UTC is midnight, the next day.
        XCTAssertEqual(LocalDate.containing(Date(timeIntervalSince1970: TimeInterval(start + 66_599)), in: kolkata),
                       Fixtures.date(2026, 10, 7))
        XCTAssertEqual(LocalDate.containing(Date(timeIntervalSince1970: TimeInterval(start + 66_600)), in: kolkata),
                       Fixtures.date(2026, 10, 8))
    }

    func testDaylightSavingDayIs25Hours() {
        // US clocks go back on 2026-11-01, so that day in Los Angeles lasts 25 hours.
        let la = TimeZone(identifier: "America/Los_Angeles")!
        let midnightLocal = Fixtures.date(2026, 11, 1).daysSinceEpoch * 86_400 + 7 * 3_600   // 00:00 PDT
        func day(_ secondsAfter: Int) -> LocalDate {
            LocalDate.containing(Date(timeIntervalSince1970: TimeInterval(midnightLocal + secondsAfter)), in: la)
        }
        XCTAssertEqual(day(0), Fixtures.date(2026, 11, 1))
        XCTAssertEqual(day(24 * 3_600 + 1_800), Fixtures.date(2026, 11, 1))   // 23:30 PST, still Nov 1
        XCTAssertEqual(day(25 * 3_600), Fixtures.date(2026, 11, 2))
    }
}
