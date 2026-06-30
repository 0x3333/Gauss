import XCTest
@testable import GaussEngine

/// Comprehensive tests for built-in math functions.
final class MathFunctionTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Root functions

    func testSqrt() {
        XCTAssertEqual(engine.evaluateLine("sqrt(144)").value, .number(12))
        XCTAssertEqual(engine.evaluateLine("sqrt(144)").formatted, "12")
    }

    func testSqrtFraction() {
        let result = engine.evaluateLine("sqrt(2)")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 1.414213, accuracy: 0.0001)
        } else { XCTFail() }
    }

    // MARK: - Absolute value

    func testAbsNegative() {
        XCTAssertEqual(engine.evaluateLine("abs(-5)").value, .number(5))
        XCTAssertEqual(engine.evaluateLine("abs(-5)").formatted, "5")
    }

    func testAbsPositive() {
        XCTAssertEqual(engine.evaluateLine("abs(3)").value, .number(3))
    }

    // MARK: - Rounding

    func testRoundUp() {
        XCTAssertEqual(engine.evaluateLine("round(3.7)").value, .number(4))
        XCTAssertEqual(engine.evaluateLine("round(3.7)").formatted, "4")
    }

    func testRoundDown() {
        XCTAssertEqual(engine.evaluateLine("round(3.2)").value, .number(3))
    }

    func testFloor() {
        XCTAssertEqual(engine.evaluateLine("floor(3.7)").value, .number(3))
        XCTAssertEqual(engine.evaluateLine("floor(3.7)").formatted, "3")
    }

    func testFloorNegative() {
        XCTAssertEqual(engine.evaluateLine("floor(-2.3)").value, .number(-3))
    }

    func testCeil() {
        XCTAssertEqual(engine.evaluateLine("ceil(3.2)").value, .number(4))
        XCTAssertEqual(engine.evaluateLine("ceil(3.2)").formatted, "4")
    }

    func testCeilNegative() {
        XCTAssertEqual(engine.evaluateLine("ceil(-2.7)").value, .number(-2))
    }

    // MARK: - Factorial

    func testFact5() {
        XCTAssertEqual(engine.evaluateLine("fact(5)").value, .number(120))
        XCTAssertEqual(engine.evaluateLine("fact(5)").formatted, "120")
    }

    func testFact0() {
        XCTAssertEqual(engine.evaluateLine("fact(0)").value, .number(1))
    }

    func testFact1() {
        XCTAssertEqual(engine.evaluateLine("fact(1)").value, .number(1))
    }

    func testFact10() {
        XCTAssertEqual(engine.evaluateLine("fact(10)").value, .number(3628800))
    }

    // MARK: - Trigonometry

    func testSinZero() {
        XCTAssertEqual(engine.evaluateLine("sin(0)").value, .number(0))
        XCTAssertEqual(engine.evaluateLine("sin(0)").formatted, "0")
    }

    func testCosZero() {
        XCTAssertEqual(engine.evaluateLine("cos(0)").value, .number(1))
        XCTAssertEqual(engine.evaluateLine("cos(0)").formatted, "1")
    }

    func testTanZero() {
        XCTAssertEqual(engine.evaluateLine("tan(0)").value, .number(0))
    }

    func testSinPiOver2() {
        let result = engine.evaluateLine("sin(1.5707963267948966)")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 1.0, accuracy: 0.0001)
        } else { XCTFail() }
    }

    // MARK: - Logarithm

    func testLog100() {
        let result = engine.evaluateLine("log(100)")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 2.0, accuracy: 0.0001)
        } else { XCTFail() }
        XCTAssertEqual(engine.evaluateLine("log(100)").formatted, "2")
    }

    func testLog1000() {
        let result = engine.evaluateLine("log(1000)")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 3.0, accuracy: 0.0001)
        } else { XCTFail() }
    }

    func testLnOne() {
        let result = engine.evaluateLine("ln(1)")
        XCTAssertEqual(result.value, .number(0))
        XCTAssertEqual(result.formatted, "0")
    }

    func testLnE() {
        let result = engine.evaluateLine("ln(2.718281828)")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 1.0, accuracy: 0.0001)
        } else { XCTFail() }
    }

    // MARK: - Power operator

    func testPower2to10() {
        let result = engine.evaluateLine("2 ^ 10")
        XCTAssertEqual(result.value, .number(1024))
        XCTAssertEqual(result.formatted, "1,024")
    }

    func testPower3to3() {
        XCTAssertEqual(engine.evaluateLine("3 ^ 3").value, .number(27))
    }

    func testPowerFraction() {
        // 4 ^ 0.5 = 2 (square root)
        let result = engine.evaluateLine("4 ^ 0.5")
        if case .number(let v) = result.value {
            XCTAssertEqual(v, 2.0, accuracy: 0.0001)
        } else { XCTFail() }
    }
}
