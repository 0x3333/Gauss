import XCTest
@testable import GaussEngine

/// Tests for variable assignment, reference, compound assignment, and special tokens.
final class VariableTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Basic Assignment and Reference

    func testAssignmentAndReference() {
        // "price = $8 times 5" → $40, then "price" → $40
        let results = engine.evaluateDocument("price = $8 times 5\nprice")
        XCTAssertEqual(results[0].value, .currency(40, "USD"))
        XCTAssertEqual(results[0].formatted, "$40")
        XCTAssertEqual(results[1].value, .currency(40, "USD"))
        XCTAssertEqual(results[1].formatted, "$40")
    }

    func testVariableUsedInExpression() {
        // "price = $40" then "price - $5" → $35
        let results = engine.evaluateDocument("price = $40\nprice - $5")
        XCTAssertEqual(results[1].value, .currency(35, "USD"))
        XCTAssertEqual(results[1].formatted, "$35")
    }

    func testVariableArithmetic() {
        let results = engine.evaluateDocument("x = 10\nx * 3")
        XCTAssertEqual(results[1].value, .number(30))
    }

    func testMultipleVariables() {
        let results = engine.evaluateDocument("a = 5\nb = 3\na + b")
        XCTAssertEqual(results[2].value, .number(8))
    }

    // MARK: - Compound Assignment

    func testCompoundAddition() {
        // "total = $100" then "total += $50" → $150
        let results = engine.evaluateDocument("total = $100\ntotal += $50")
        XCTAssertEqual(results[1].value, .currency(150, "USD"))
        XCTAssertEqual(results[1].formatted, "$150")
    }

    func testCompoundSubtraction() {
        let results = engine.evaluateDocument("x = 100\nx -= 30")
        XCTAssertEqual(results[1].value, .number(70))
    }

    func testCompoundMultiplication() {
        let results = engine.evaluateDocument("x = 5\nx *= 4")
        XCTAssertEqual(results[1].value, .number(20))
    }

    func testCompoundDivision() {
        let results = engine.evaluateDocument("x = 20\nx /= 4")
        XCTAssertEqual(results[1].value, .number(5))
    }

    // MARK: - Variable/Unit Conflict (Variable Takes Precedence)

    func testVariableOverridesUnit() {
        // "m = 5" defines a variable "m"; then "m * 2" should use the variable (10),
        // not treat "m" as meters.
        let results = engine.evaluateDocument("m = 5\nm * 2")
        XCTAssertEqual(results[1].value, .number(10))
    }

    // MARK: - Undefined Variable

    func testUndefinedVariable() {
        // "unknown * 2" → undefined (empty formatted)
        let result = engine.evaluateLine("unknown * 2")
        XCTAssertEqual(result.value, .undefined)
        XCTAssertEqual(result.formatted, "")
    }

    func testUndefinedVariableInDocument() {
        let results = engine.evaluateDocument("foo + 1")
        XCTAssertEqual(results[0].value, .undefined)
    }

    // MARK: - Context Reset Between Documents

    func testContextResetBetweenDocuments() {
        _ = engine.evaluateDocument("x = 42")
        let results = engine.evaluateDocument("x")
        XCTAssertEqual(results[0].value, .undefined)
    }

    // MARK: - Special Tokens: sum, avg, prev

    func testSum() {
        let results = engine.evaluateDocument("10\n20\n30\nsum")
        XCTAssertEqual(results[3].value, .number(60))
        XCTAssertEqual(results[3].formatted, "60")
    }

    func testAvg() {
        let results = engine.evaluateDocument("10\n20\navg")
        XCTAssertEqual(results[2].value, .number(15))
        XCTAssertEqual(results[2].formatted, "15")
    }

    func testPrev() {
        // "42" then "prev + 8" → 50
        let results = engine.evaluateDocument("42\nprev + 8")
        XCTAssertEqual(results[1].value, .number(50))
        XCTAssertEqual(results[1].formatted, "50")
    }

    func testTotal() {
        // "total" is an alias for sum
        let results = engine.evaluateDocument("5\n10\ntotal")
        XCTAssertEqual(results[2].value, .number(15))
    }

    func testAverage() {
        // "average" is an alias for avg
        let results = engine.evaluateDocument("10\n30\naverage")
        XCTAssertEqual(results[2].value, .number(20))
    }

    func testSumWithCurrency() {
        let results = engine.evaluateDocument("$10\n$20\n$30\nsum")
        XCTAssertEqual(results[3].value, .currency(60, "USD"))
    }

    func testPrevOnFirstLine() {
        // prev on line 0 → undefined (no previous line)
        let results = engine.evaluateDocument("prev")
        XCTAssertEqual(results[0].value, .undefined)
    }

    func testSumOnEmptyDocument() {
        let results = engine.evaluateDocument("sum")
        // Sum of nothing should be 0
        XCTAssertEqual(results[0].value, .number(0))
    }
}
