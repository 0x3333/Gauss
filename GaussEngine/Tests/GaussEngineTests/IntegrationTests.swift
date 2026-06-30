import XCTest
@testable import GaussEngine

final class IntegrationTests: XCTestCase {

    func testFullPipeline() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("$8 times 5")
        XCTAssertEqual(result.value, .currency(40, "USD"))
        XCTAssertEqual(result.formatted, "$40")
        XCTAssertEqual(result.lineType, .expression)
    }

    func testMultiLine() {
        let engine = try! GaussEngine()
        let results = engine.evaluateDocument("""
        price = $8 times 5
        tax = 8%
        15% on price
        """)
        XCTAssertEqual(results[0].formatted, "$40")
        XCTAssertEqual(results[1].formatted, "8 %")
        // 15% on $40 = $46
        XCTAssertEqual(results[2].formatted, "$46")
    }

    func testHeader() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("# My Calculations")
        XCTAssertEqual(result.lineType, .header("My Calculations"))
        XCTAssertEqual(result.formatted, "")
    }

    func testComment() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("// a note")
        XCTAssertEqual(result.lineType, .comment("a note"))
    }

    func testLabel() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("Price: $10 + $5")
        XCTAssertEqual(result.lineType, .label("Price"))
        XCTAssertEqual(result.formatted, "$15")
    }

    func testEmptyLine() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("")
        XCTAssertEqual(result.lineType, .empty)
    }

    func testNumberFormatting() {
        let engine = try! GaussEngine()
        XCTAssertEqual(engine.evaluateLine("10 / 3").formatted, "3.33")
        XCTAssertEqual(engine.evaluateLine("10 / 2").formatted, "5")
        XCTAssertEqual(engine.evaluateLine("1000 + 234").formatted, "1,234")
    }

    func testCurrencyFormatting() {
        let engine = try! GaussEngine()
        XCTAssertEqual(engine.evaluateLine("$40").formatted, "$40")
        XCTAssertEqual(engine.evaluateLine("$7.31").formatted, "$7.31")
        XCTAssertEqual(engine.evaluateLine("$7.30").formatted, "$7.30")
    }

    func testUnitFormatting() {
        let engine = try! GaussEngine()
        let result = engine.evaluateLine("5 inches in cm")
        XCTAssertTrue(result.formatted.contains("12.7"), "Expected 12.7 in '\(result.formatted)'")
        XCTAssertTrue(result.formatted.contains("cm"), "Expected 'cm' in '\(result.formatted)'")
    }

    func testSumAcrossDocument() {
        let engine = try! GaussEngine()
        let results = engine.evaluateDocument("""
        10
        20
        30
        sum
        """)
        XCTAssertEqual(results[3].value, .number(60))
    }

    func testInfinityFormatting() {
        let engine = try! GaussEngine()
        XCTAssertEqual(engine.evaluateLine("5 / 0").formatted, "∞")
        XCTAssertEqual(engine.evaluateLine("-5 / 0").formatted, "-∞")
    }

    func testPercentageFormatting() {
        let engine = try! GaussEngine()
        XCTAssertEqual(engine.evaluateLine("8.5%").formatted, "8.5 %")
    }

    // MARK: - Additional coverage

    func testDocumentResetsContext() {
        let engine = try! GaussEngine()
        // First doc sets a variable
        _ = engine.evaluateDocument("x = 10")
        // Second doc should reset — 'x' should be undefined
        let results = engine.evaluateDocument("x")
        XCTAssertEqual(results[0].value, .undefined)
    }

    func testReevaluateAll() {
        let engine = try! GaussEngine()
        let results = engine.reevaluateAll("5 + 3")
        XCTAssertEqual(results[0].value, .number(8))
    }

    func testLabelWithNoExpression() {
        let engine = try! GaussEngine()
        // A label with no expression after it
        let result = engine.evaluateLine("Note:")
        XCTAssertEqual(result.lineType, .label("Note"))
        XCTAssertEqual(result.value, .undefined)
    }

    func testValueFormatterUndefined() {
        let formatter = ValueFormatter()
        XCTAssertEqual(formatter.format(.undefined), "")
    }

    func testValueFormatterCircular() {
        let formatter = ValueFormatter()
        XCTAssertEqual(formatter.format(.circular), "circular")
    }

    func testValueFormatterInfinity() {
        let formatter = ValueFormatter()
        XCTAssertEqual(formatter.format(.infinity(false)), "∞")
        XCTAssertEqual(formatter.format(.infinity(true)), "-∞")
    }

    func testValueFormatterString() {
        let formatter = ValueFormatter()
        XCTAssertEqual(formatter.format(.string("hello")), "hello")
    }

    func testValueFormatterColor() {
        let formatter = ValueFormatter()
        XCTAssertEqual(formatter.format(.color(.hex("FF5733"))), "#FF5733")
        XCTAssertEqual(formatter.format(.color(.rgb(255, 87, 51))), "rgb(255, 87, 51)")
    }

    func testLargeNumberFormatting() {
        let engine = try! GaussEngine()
        // 1 million should format with commas
        let result = engine.evaluateLine("1000000")
        XCTAssertEqual(result.formatted, "1,000,000")
    }
}
