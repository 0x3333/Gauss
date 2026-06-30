import XCTest
@testable import GaussEngine

/// Tests for date ranges, "unit between dates", workdays, and date literal parsing.
final class DateRangeWorkdayTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Date Literal Parsing

    func testMonthDayLiteral() {
        // "March 19" should parse as a date
        let result = engine.evaluateLine("March 19")
        if case .date = result.value {
            // pass — it's a date
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    func testDayMonthLiteral() {
        // "10 June" should also parse as a date
        let result = engine.evaluateLine("10 June")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    func testMonthAbbreviation() {
        // "Oct 21" should parse as a date
        let result = engine.evaluateLine("Oct 21")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    // MARK: - Date Arithmetic with Date Literals

    func testDateLiteralPlusDays() {
        // "March 19 + 52 days" should produce a date
        let result = engine.evaluateLine("March 19 + 52 days")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date for 'March 19 + 52 days', got \(result.value)")
        }
    }

    func testDateLiteralPlusWeeks() {
        // "10 June + 3 weeks" should produce a date
        let result = engine.evaluateLine("10 June + 3 weeks")
        if case .date = result.value {
            // pass
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    // MARK: - Date Ranges (date TO date)

    func testDateRangeMonthToMonth() {
        // "March 20 to June 5" should produce a dateDifference
        let result = engine.evaluateLine("March 20 to June 5")
        if case .dateDifference(let months, let weeks, let days) = result.value {
            // March 20 to June 5 = 2 months 2 weeks 2 days
            XCTAssertEqual(months, 2)
            XCTAssertEqual(weeks, 2)
            XCTAssertEqual(days, 2)
        } else {
            XCTFail("Expected .dateDifference, got \(result.value)")
        }
    }

    func testDateRangeTodayToTomorrow() {
        // "today to tomorrow" = 0 months 0 weeks 1 day
        let result = engine.evaluateLine("today to tomorrow")
        if case .dateDifference(let months, let weeks, let days) = result.value {
            XCTAssertEqual(months, 0)
            XCTAssertEqual(weeks, 0)
            XCTAssertEqual(days, 1)
        } else {
            XCTFail("Expected .dateDifference, got \(result.value)")
        }
    }

    func testDateRangeSameDay() {
        // "March 1 to March 1" = 0 days
        let result = engine.evaluateLine("March 1 to March 1")
        if case .dateDifference(let months, let weeks, let days) = result.value {
            XCTAssertEqual(months, 0)
            XCTAssertEqual(weeks, 0)
            XCTAssertEqual(days, 0)
        } else {
            XCTFail("Expected .dateDifference, got \(result.value)")
        }
    }

    func testDateRangeFormattedOutput() {
        let result = engine.evaluateLine("March 20 to June 5")
        XCTAssertEqual(result.formatted, "2 months 2 weeks 2 days")
    }

    func testDateRangeSingleMonth() {
        // Jan 1 to Feb 1 = 1 month
        let result = engine.evaluateLine("January 1 to February 1")
        if case .dateDifference(let months, let weeks, let days) = result.value {
            XCTAssertEqual(months, 1)
            XCTAssertEqual(weeks, 0)
            XCTAssertEqual(days, 0)
        } else {
            XCTFail("Expected .dateDifference, got \(result.value)")
        }
    }

    // MARK: - Unit Between Dates

    func testWeeksBetween() {
        // "weeks between October 21 and December 2" = 6 weeks
        let result = engine.evaluateLine("weeks between October 21 and December 2")
        if case .duration(let val, _) = result.value {
            XCTAssertEqual(val, 6)
        } else {
            XCTFail("Expected .duration, got \(result.value)")
        }
    }

    func testDaysBetween() {
        // "days between January 1 and January 31" = 30 days
        let result = engine.evaluateLine("days between January 1 and January 31")
        if case .duration(let val, _) = result.value {
            XCTAssertEqual(val, 30)
        } else {
            XCTFail("Expected .duration, got \(result.value)")
        }
    }

    func testMonthsBetween() {
        // "months between March 1 and September 1" = 6 months
        let result = engine.evaluateLine("months between March 1 and September 1")
        if case .duration(let val, _) = result.value {
            XCTAssertEqual(val, 6)
        } else {
            XCTFail("Expected .duration, got \(result.value)")
        }
    }

    func testWeeksBetweenFormatted() {
        let result = engine.evaluateLine("weeks between October 21 and December 2")
        XCTAssertEqual(result.formatted, "6 weeks")
    }

    // MARK: - Workdays

    func testWorkdayAddition() {
        // Monday March 3, 2025 + 5 workdays = Monday March 10
        // (skips Saturday March 8 and Sunday March 9)
        // Use a fixed date via engine evaluation
        let results = engine.evaluateDocument("March 3 + 5 workdays")
        if case .date(let resultDate) = results[0].value {
            let calendar = Calendar.current
            let day = calendar.component(.day, from: resultDate)
            let month = calendar.component(.month, from: resultDate)
            XCTAssertEqual(month, 3) // still March
            XCTAssertEqual(day, 10)  // March 10
        } else {
            XCTFail("Expected .date, got \(results[0].value)")
        }
    }

    func testWorkdaySkipsWeekend() {
        // Friday March 7 + 1 workday = Monday March 10
        // (skips Saturday 8 and Sunday 9)
        let results = engine.evaluateDocument("March 7 + 1 workdays")
        if case .date(let resultDate) = results[0].value {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: resultDate)
            // Should be Monday (weekday 2)
            XCTAssertEqual(weekday, 2, "Expected Monday, got weekday \(weekday)")
        } else {
            XCTFail("Expected .date, got \(results[0].value)")
        }
    }

    func testWorkdayFormatsAsDate() {
        let result = engine.evaluateLine("March 3 + 5 workdays")
        // Should format as a date string
        XCTAssertFalse(result.formatted.isEmpty, "Workday result should have formatted output")
    }

    // MARK: - Duration Formatting

    func testDurationSingular() {
        // "weeks between January 1 and January 8" = 1 week
        let result = engine.evaluateLine("weeks between January 1 and January 8")
        XCTAssertEqual(result.formatted, "1 week")
    }

    func testDurationPlural() {
        let result = engine.evaluateLine("days between January 1 and January 4")
        XCTAssertEqual(result.formatted, "3 days")
    }
}
