import XCTest
@testable import GaussEngine

/// Tests for hex, binary, octal number literals and bitwise operations.
final class NumberSystemTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Hex literals

    func testHexLiteral0xFF() {
        // 0xFF = 255
        let result = engine.evaluateLine("0xFF")
        XCTAssertEqual(result.value, .number(255))
        XCTAssertEqual(result.formatted, "255")
    }

    func testHexLiteral0x0F() {
        // 0x0F = 15
        let result = engine.evaluateLine("0x0F")
        XCTAssertEqual(result.value, .number(15))
    }

    func testHexLiteral0x100() {
        // 0x100 = 256
        let result = engine.evaluateLine("0x100")
        XCTAssertEqual(result.value, .number(256))
    }

    func testHexLiteralUppercase() {
        // 0XFF = 255 (uppercase X)
        let result = engine.evaluateLine("0XFF")
        XCTAssertEqual(result.value, .number(255))
    }

    func testHexArithmetic() {
        // 0xFF + 1 = 256
        let result = engine.evaluateLine("0xFF + 1")
        XCTAssertEqual(result.value, .number(256))
    }

    // MARK: - Binary literals

    func testBinaryLiteral0b1010() {
        // 0b1010 = 10
        let result = engine.evaluateLine("0b1010")
        XCTAssertEqual(result.value, .number(10))
        XCTAssertEqual(result.formatted, "10")
    }

    func testBinaryLiteral0b1111() {
        // 0b1111 = 15
        let result = engine.evaluateLine("0b1111")
        XCTAssertEqual(result.value, .number(15))
    }

    func testBinaryLiteral0b0() {
        XCTAssertEqual(engine.evaluateLine("0b0").value, .number(0))
    }

    func testBinaryLiteral0b11111111() {
        // 0b11111111 = 255
        XCTAssertEqual(engine.evaluateLine("0b11111111").value, .number(255))
    }

    // MARK: - Octal literals

    func testOctalLiteral0o17() {
        // 0o17 = 15
        let result = engine.evaluateLine("0o17")
        XCTAssertEqual(result.value, .number(15))
        XCTAssertEqual(result.formatted, "15")
    }

    func testOctalLiteral0o10() {
        // 0o10 = 8
        XCTAssertEqual(engine.evaluateLine("0o10").value, .number(8))
    }

    func testOctalLiteral0o77() {
        // 0o77 = 63
        XCTAssertEqual(engine.evaluateLine("0o77").value, .number(63))
    }

    // MARK: - Bitwise AND (band)

    func testBitwiseAnd() {
        // 0xFF band 0x0F = 0x0F = 15
        let result = engine.evaluateLine("0xFF band 0x0F")
        XCTAssertEqual(result.value, .number(15))
    }

    func testBitwiseAndZero() {
        // 0b1010 band 0b0101 = 0
        let result = engine.evaluateLine("0b1010 band 0b0101")
        XCTAssertEqual(result.value, .number(0))
    }

    func testBitwiseAndSelf() {
        // 255 band 255 = 255
        let result = engine.evaluateLine("255 band 255")
        XCTAssertEqual(result.value, .number(255))
    }

    // MARK: - Left Shift (lshift)

    func testLeftShift() {
        // 1 lshift 8 = 256
        let result = engine.evaluateLine("1 lshift 8")
        XCTAssertEqual(result.value, .number(256))
    }

    func testLeftShiftSmall() {
        // 1 lshift 4 = 16
        let result = engine.evaluateLine("1 lshift 4")
        XCTAssertEqual(result.value, .number(16))
    }

    func testLeftShiftZero() {
        // 5 lshift 0 = 5
        let result = engine.evaluateLine("5 lshift 0")
        XCTAssertEqual(result.value, .number(5))
    }

    // MARK: - Bitwise OR (bor)

    func testBitwiseOr() {
        // 0xFF bor 0x100 = 0x1FF = 511
        let result = engine.evaluateLine("0xFF bor 0x100")
        XCTAssertEqual(result.value, .number(511))
    }

    func testBitwiseOrZero() {
        // 0 bor 42 = 42
        let result = engine.evaluateLine("0 bor 42")
        XCTAssertEqual(result.value, .number(42))
    }

    // MARK: - Bitwise XOR (bxor)

    func testBitwiseXor() {
        // 0xF0 bxor 0xFF = 0x0F = 15
        let result = engine.evaluateLine("0xF0 bxor 0xFF")
        XCTAssertEqual(result.value, .number(15))
    }

    func testBitwiseXorSelf() {
        // 255 bxor 255 = 0
        let result = engine.evaluateLine("255 bxor 255")
        XCTAssertEqual(result.value, .number(0))
    }

    func testBitwiseXorZero() {
        // 42 bxor 0 = 42
        let result = engine.evaluateLine("42 bxor 0")
        XCTAssertEqual(result.value, .number(42))
    }

    // MARK: - Right Shift (rshift)

    func testRightShift() {
        // 256 rshift 4 = 16
        let result = engine.evaluateLine("256 rshift 4")
        XCTAssertEqual(result.value, .number(16))
    }

    func testRightShiftOne() {
        // 256 rshift 1 = 128
        let result = engine.evaluateLine("256 rshift 1")
        XCTAssertEqual(result.value, .number(128))
    }

    func testRightShiftZero() {
        // 16 rshift 0 = 16
        let result = engine.evaluateLine("16 rshift 0")
        XCTAssertEqual(result.value, .number(16))
    }

    // MARK: - Mixed base arithmetic

    func testHexPlusBinary() {
        // 0xFF + 0b1 = 256
        let result = engine.evaluateLine("0xFF + 0b1")
        XCTAssertEqual(result.value, .number(256))
    }

    func testOctalPlusHex() {
        // 0o10 + 0x10 = 8 + 16 = 24
        let result = engine.evaluateLine("0o10 + 0x10")
        XCTAssertEqual(result.value, .number(24))
    }
}
