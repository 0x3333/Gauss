import XCTest
@testable import GaussEngine

/// Tests for quick-win features: reverse percentages, random, midpoint.
final class QuickWinFeatureTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - "X is what % of Y"

    func testWhatPercentOf() {
        // 75 is what % of 600 = 12.5%
        let result = engine.evaluateLine("75 is what % of 600")
        XCTAssertEqual(result.value, .percentage(12.5))
    }

    func testWhatPercentOfHalf() {
        // 50 is what % of 100 = 50%
        let result = engine.evaluateLine("50 is what % of 100")
        XCTAssertEqual(result.value, .percentage(50))
    }

    func testWhatPercentOfFull() {
        // 200 is what % of 200 = 100%
        let result = engine.evaluateLine("200 is what % of 200")
        XCTAssertEqual(result.value, .percentage(100))
    }

    func testWhatPercentOfZeroDenominator() {
        // 50 is what % of 0 = undefined
        let result = engine.evaluateLine("50 is what % of 0")
        XCTAssertEqual(result.value, .undefined)
    }

    // MARK: - "X is Y% off what"

    func testIsPercentOffWhat() {
        // 90 is 10% off what = 100
        let result = engine.evaluateLine("90 is 10% off what")
        XCTAssertEqual(result.value, .number(100))
    }

    func testIsPercentOffWhatCurrency() {
        // $85 is 15% off what = $100
        let result = engine.evaluateLine("$85 is 15% off what")
        if case .currency(let amount, let code) = result.value {
            XCTAssertEqual(amount, 100, accuracy: 0.01)
            XCTAssertEqual(code, "USD")
        } else {
            XCTFail("Expected currency, got \(result.value)")
        }
    }

    func testIsHundredPercentOffWhat() {
        // 0 is 100% off what = undefined (division by zero)
        let result = engine.evaluateLine("0 is 100% off what")
        XCTAssertEqual(result.value, .undefined)
    }

    // MARK: - "X% of what is Y" (existing AST, newly wired)

    func testPercentOfWhatIs() {
        // 20% of what is 30 = 150
        let result = engine.evaluateLine("20% of what is 30")
        XCTAssertEqual(result.value, .number(150))
    }

    func testPercentOfWhatIsCurrency() {
        // 10% of what is $50 = $500
        let result = engine.evaluateLine("10% of what is $50")
        XCTAssertEqual(result.value, .currency(500, "USD"))
    }

    // MARK: - Random number between X and Y

    func testRandomBetween() {
        // random number between 1 and 10 — result should be in [1, 10]
        let result = engine.evaluateLine("random number between 1 and 10")
        if case .number(let n) = result.value {
            XCTAssertTrue(n >= 1 && n <= 10, "Random \(n) not in [1, 10]")
            XCTAssertEqual(n, n.rounded(), "Random should be integer")
        } else {
            XCTFail("Expected number, got \(result.value)")
        }
    }

    func testRandomBetweenShortForm() {
        // random between 5 and 20 — shorter form without "number"
        let result = engine.evaluateLine("random between 5 and 20")
        if case .number(let n) = result.value {
            XCTAssertTrue(n >= 5 && n <= 20, "Random \(n) not in [5, 20]")
        } else {
            XCTFail("Expected number, got \(result.value)")
        }
    }

    func testRandomBetweenSameNumber() {
        // random between 7 and 7 = 7
        let result = engine.evaluateLine("random between 7 and 7")
        XCTAssertEqual(result.value, .number(7))
    }

    // MARK: - Midpoint between X and Y

    func testMidpoint() {
        // midpoint between 50 and 150 = 100
        let result = engine.evaluateLine("midpoint between 50 and 150")
        XCTAssertEqual(result.value, .number(100))
    }

    func testMidpointSameNumber() {
        // midpoint between 10 and 10 = 10
        let result = engine.evaluateLine("midpoint between 10 and 10")
        XCTAssertEqual(result.value, .number(10))
    }

    func testMidpointNegatives() {
        // midpoint between -10 and 10 = 0
        let result = engine.evaluateLine("midpoint between -10 and 10")
        XCTAssertEqual(result.value, .number(0))
    }

    func testMidpointDecimals() {
        // midpoint between 0 and 1 = 0.5
        let result = engine.evaluateLine("midpoint between 0 and 1")
        XCTAssertEqual(result.value, .number(0.5))
    }
}
