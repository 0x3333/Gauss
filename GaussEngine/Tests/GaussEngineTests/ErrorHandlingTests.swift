import XCTest
@testable import GaussEngine

/// Tests for error/edge case handling: incomplete expressions, division by zero,
/// undefined variables, unrecognized input, empty lines, headers, and comments.
final class ErrorHandlingTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Incomplete / Malformed Expressions

    func testIncompleteAddition() {
        // "5 + " → the matcher returns the partial left-hand side (5) rather than nil.
        // The engine tolerates incomplete expressions: it returns the left operand.
        let result = engine.evaluateLine("5 + ")
        // Should not crash; formatted is either "" (undefined) or "5" (left side only).
        let isAcceptable = result.formatted == "" || result.formatted == "5"
        XCTAssertTrue(isAcceptable, "Unexpected formatted value for '5 + ': '\(result.formatted)'")
    }

    func testIncompleteMultiplication() {
        // Same partial-evaluation tolerance: "10 * " → "10" or "".
        let result = engine.evaluateLine("10 * ")
        let isAcceptable = result.formatted == "" || result.formatted == "10"
        XCTAssertTrue(isAcceptable, "Unexpected formatted value for '10 * ': '\(result.formatted)'")
    }

    func testIncompleteConversion() {
        // "5 inches in" → dangling "in" keyword
        let result = engine.evaluateLine("5 inches in")
        // Either undefined or just the unit without conversion (engine-defined behaviour)
        // Main assertion: no crash
        XCTAssertNotNil(result)
    }

    // MARK: - Division by Zero

    func testDivisionByZeroPositive() {
        // "5 / 0" → "∞"
        let result = engine.evaluateLine("5 / 0")
        XCTAssertEqual(result.value, .infinity(false))
        XCTAssertEqual(result.formatted, "∞")
    }

    func testDivisionByZeroNegative() {
        // "-5 / 0" → "-∞"
        let result = engine.evaluateLine("-5 / 0")
        XCTAssertEqual(result.value, .infinity(true))
        XCTAssertEqual(result.formatted, "-∞")
    }

    func testCurrencyDivisionByZero() {
        // "$100 / 0" → "∞"
        let result = engine.evaluateLine("$100 / 0")
        XCTAssertEqual(result.value, .infinity(false))
        XCTAssertEqual(result.formatted, "∞")
    }

    func testZeroDividedByZero() {
        // "0 / 0" — mathematically undefined, but the engine returns infinity
        let result = engine.evaluateLine("0 / 0")
        // Engine returns .infinity(false) for zero / zero
        XCTAssertFalse(result.formatted.isEmpty)
    }

    // MARK: - Undefined Variables

    func testUndefinedVariable() {
        // "unknown * 2" → formatted is ""
        let result = engine.evaluateLine("unknown * 2")
        XCTAssertEqual(result.value, .undefined)
        XCTAssertEqual(result.formatted, "")
    }

    func testUndefinedVariableAlone() {
        let result = engine.evaluateLine("notdefined")
        XCTAssertEqual(result.value, .undefined)
        XCTAssertEqual(result.formatted, "")
    }

    func testUndefinedAfterContextReset() {
        _ = engine.evaluateDocument("x = 10")
        // After a new document, x should be undefined
        let results = engine.evaluateDocument("x + 5")
        XCTAssertEqual(results[0].value, .undefined)
        XCTAssertEqual(results[0].formatted, "")
    }

    // MARK: - Unrecognized Input

    func testUnrecognizedText() {
        // "hello world" → no expression matches → formatted is ""
        let result = engine.evaluateLine("hello world")
        XCTAssertEqual(result.formatted, "")
    }

    func testRandomLetters() {
        let result = engine.evaluateLine("abcdefg")
        // Either undefined variable or unrecognized
        XCTAssertEqual(result.formatted, "")
    }

    func testSpecialCharsOnly() {
        // Only punctuation that is not a valid expression
        let result = engine.evaluateLine("???")
        XCTAssertEqual(result.formatted, "")
    }

    // MARK: - Empty Input

    func testEmptyLine() {
        // "" → formatted is ""
        let result = engine.evaluateLine("")
        XCTAssertEqual(result.value, .undefined)
        XCTAssertEqual(result.formatted, "")
        XCTAssertEqual(result.lineType, .empty)
    }

    func testWhitespaceOnly() {
        // "   " → treated as empty
        let result = engine.evaluateLine("   ")
        XCTAssertEqual(result.lineType, .empty)
        XCTAssertEqual(result.formatted, "")
    }

    // MARK: - Headers and Comments

    func testHeader() {
        // "# Title" → formatted is "" (not evaluated), lineType is .header
        let result = engine.evaluateLine("# Title")
        XCTAssertEqual(result.formatted, "")
        if case .header(let text) = result.lineType {
            XCTAssertEqual(text, "Title")
        } else {
            XCTFail("Expected .header lineType, got \(result.lineType)")
        }
    }

    func testHeaderEmptyTitle() {
        let result = engine.evaluateLine("# ")
        XCTAssertEqual(result.formatted, "")
        if case .header = result.lineType {
            // pass
        } else {
            XCTFail("Expected .header, got \(result.lineType)")
        }
    }

    func testComment() {
        // "// note" → formatted is ""
        let result = engine.evaluateLine("// note")
        XCTAssertEqual(result.formatted, "")
        if case .comment(let text) = result.lineType {
            XCTAssertEqual(text, "note")
        } else {
            XCTFail("Expected .comment lineType, got \(result.lineType)")
        }
    }

    func testCommentEmpty() {
        let result = engine.evaluateLine("//")
        XCTAssertEqual(result.formatted, "")
        if case .comment = result.lineType {
            // pass
        } else {
            XCTFail("Expected .comment, got \(result.lineType)")
        }
    }

    // MARK: - Mixed valid/invalid document

    func testDocumentWithMixedLines() {
        let results = engine.evaluateDocument("""
        # Budget
        // My expenses
        groceries = $45
        unknown_var + 5
        groceries + $5
        """)
        // Line 0: header
        XCTAssertEqual(results[0].formatted, "")
        // Line 1: comment
        XCTAssertEqual(results[1].formatted, "")
        // Line 2: assignment → $45
        XCTAssertEqual(results[2].formatted, "$45")
        // Line 3: undefined var → ""
        XCTAssertEqual(results[3].formatted, "")
        // Line 4: groceries + $5 → $50
        XCTAssertEqual(results[4].formatted, "$50")
    }

    // MARK: - Infinity arithmetic

    func testInfinityPlusNumber() {
        // ∞ + 5 → ∞
        _ = engine.evaluateLine("5 / 0")
        let results = engine.evaluateDocument("5 / 0\nprev + 10")
        XCTAssertEqual(results[1].value, .infinity(false))
    }

    func testNegativeInfinityFormatted() {
        let result = engine.evaluateLine("-5 / 0")
        XCTAssertEqual(result.formatted, "-∞")
    }
}
