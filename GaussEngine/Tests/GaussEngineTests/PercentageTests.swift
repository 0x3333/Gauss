import XCTest
@testable import GaussEngine

/// Tests for percentage operations: of, on, off.
final class PercentageTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Percentage of currency

    func testPercentOfCurrency() {
        // 20% of $150 = $30
        let result = engine.evaluateLine("20% of $150")
        XCTAssertEqual(result.value, .currency(30, "USD"))
        XCTAssertEqual(result.formatted, "$30")
    }

    func testPercentOnCurrency() {
        // 15% on $20 = $23
        let result = engine.evaluateLine("15% on $20")
        XCTAssertEqual(result.value, .currency(23, "USD"))
        XCTAssertEqual(result.formatted, "$23")
    }

    func testPercentOffCurrency() {
        // 20% off $50 = $40
        let result = engine.evaluateLine("20% off $50")
        XCTAssertEqual(result.value, .currency(40, "USD"))
        XCTAssertEqual(result.formatted, "$40")
    }

    // MARK: - Percentage of plain numbers

    func testPercentOfNumber() {
        // 50% of 200 = 100
        let result = engine.evaluateLine("50% of 200")
        XCTAssertEqual(result.value, .number(100))
        XCTAssertEqual(result.formatted, "100")
    }

    func testPercentOnNumber() {
        // 10% on 100 = 110
        let result = engine.evaluateLine("10% on 100")
        XCTAssertEqual(result.value, .number(110))
        XCTAssertEqual(result.formatted, "110")
    }

    func testPercentOffNumber() {
        // 25% off 80 = 60
        let result = engine.evaluateLine("25% off 80")
        XCTAssertEqual(result.value, .number(60))
        XCTAssertEqual(result.formatted, "60")
    }

    // MARK: - Edge cases

    func testZeroPercent() {
        // 0% of $100 = $0
        let result = engine.evaluateLine("0% of $100")
        XCTAssertEqual(result.value, .currency(0, "USD"))
    }

    func testHundredPercentOff() {
        // 100% off 50 = 0
        let result = engine.evaluateLine("100% off 50")
        XCTAssertEqual(result.value, .number(0))
    }

    func testHundredPercentOf() {
        // 100% of 75 = 75
        let result = engine.evaluateLine("100% of 75")
        XCTAssertEqual(result.value, .number(75))
    }

    func testLargePercent() {
        // 200% of 50 = 100
        let result = engine.evaluateLine("200% of 50")
        XCTAssertEqual(result.value, .number(100))
    }

    func testDecimalPercent() {
        // 12.5% of 200 = 25
        let result = engine.evaluateLine("12.5% of 200")
        XCTAssertEqual(result.value, .number(25))
    }

    func testPercentOfVariableResult() {
        // Using a variable defined via evaluateDocument
        let results = engine.evaluateDocument("price = $200\n10% of price")
        XCTAssertEqual(results[1].value, .currency(20, "USD"))
    }
}
