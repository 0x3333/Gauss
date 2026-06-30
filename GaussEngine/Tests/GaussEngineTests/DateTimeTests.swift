import XCTest
@testable import GaussEngine

/// Tests for date/time keywords and date arithmetic.
final class DateTimeTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Date keywords

    func testTodayIsDate() {
        let result = engine.evaluateLine("today")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    func testTodayFormatIsNonEmpty() {
        let result = engine.evaluateLine("today")
        XCTAssertFalse(result.formatted.isEmpty)
    }

    func testTomorrowIsOneDayAfterToday() {
        let todayResult = engine.evaluateLine("today")
        let tomorrowResult = engine.evaluateLine("tomorrow")
        if case .date(let t) = todayResult.value, case .date(let tm) = tomorrowResult.value {
            let diff = tm.timeIntervalSince(t)
            XCTAssertEqual(diff, 86400, accuracy: 1)
        } else {
            XCTFail("Expected date values")
        }
    }

    func testYesterdayIsOneDayBeforeToday() {
        let todayResult = engine.evaluateLine("today")
        let yesterdayResult = engine.evaluateLine("yesterday")
        if case .date(let t) = todayResult.value, case .date(let y) = yesterdayResult.value {
            let diff = t.timeIntervalSince(y)
            XCTAssertEqual(diff, 86400, accuracy: 1)
        } else {
            XCTFail("Expected date values")
        }
    }

    func testNowIsDate() {
        let result = engine.evaluateLine("now")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    // MARK: - Date Arithmetic

    func testTodayPlusDays() {
        // "today + 7 days" should produce a date 7 days from now
        let result = engine.evaluateLine("today + 7 days")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date for 'today + 7 days', got \(result.value)")
        }
    }

    func testTodayPlusDaysIsOneWeekAhead() {
        let todayResult = engine.evaluateLine("today")
        let futureResult = engine.evaluateLine("today + 7 days")
        if case .date(let t) = todayResult.value, case .date(let f) = futureResult.value {
            let diff = f.timeIntervalSince(t)
            XCTAssertEqual(diff, 7 * 86400, accuracy: 1)
        } else {
            XCTFail("Expected date values")
        }
    }

    func testTodayMinusDays() {
        let result = engine.evaluateLine("today - 3 days")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date for 'today - 3 days', got \(result.value)")
        }
    }

    func testTodayMinusWeeks() {
        let todayResult = engine.evaluateLine("today")
        let pastResult = engine.evaluateLine("today - 2 weeks")
        if case .date(let t) = todayResult.value, case .date(let p) = pastResult.value {
            let diff = t.timeIntervalSince(p)
            XCTAssertEqual(diff, 14 * 86400, accuracy: 1)
        } else {
            XCTFail("Expected date values")
        }
    }

    func testTodayPlusHours() {
        let todayResult = engine.evaluateLine("today")
        let laterResult = engine.evaluateLine("today + 24 hours")
        if case .date(let t) = todayResult.value, case .date(let l) = laterResult.value {
            let diff = l.timeIntervalSince(t)
            XCTAssertEqual(diff, 86400, accuracy: 1)
        } else {
            XCTFail("Expected date values")
        }
    }

    // MARK: - Duration conversion (via unit conversion)

    func testHoursToMinutes() {
        // "15 hours in minutes" → 900 min (plain unit conversion, no date)
        let result = engine.evaluateLine("15 hours in minutes")
        if case .unit(let val, _, let cat) = result.value {
            XCTAssertEqual(cat, "time")
            XCTAssertEqual(val, 900, accuracy: 0.01)
        } else {
            XCTFail("Expected unit result, got \(result.value)")
        }
    }

    func testDaysToHours() {
        let result = engine.evaluateLine("2 days in hours")
        if case .unit(let val, _, _) = result.value {
            XCTAssertEqual(val, 48, accuracy: 0.01)
        } else {
            XCTFail("Expected unit result, got \(result.value)")
        }
    }
}
