import XCTest
@testable import GaussEngine

/// Tests for developer features: color conversion, base64, timestamp, and scientific notation.
final class DevFeatureTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Color Conversion: Hex → RGB

    func testHexToRgb() {
        // #FF5733 in rgb → rgb(255, 87, 51)
        let result = engine.evaluateLine("#FF5733 in rgb")
        XCTAssertEqual(result.value, .color(.rgb(255, 87, 51)))
        XCTAssertEqual(result.formatted, "rgb(255, 87, 51)")
    }

    func testHexToRgbBlack() {
        let result = engine.evaluateLine("#000000 in rgb")
        XCTAssertEqual(result.value, .color(.rgb(0, 0, 0)))
    }

    func testHexToRgbWhite() {
        let result = engine.evaluateLine("#FFFFFF in rgb")
        XCTAssertEqual(result.value, .color(.rgb(255, 255, 255)))
    }

    // MARK: - Color Conversion: RGB → Hex

    func testRgbToHex() {
        // rgb(30, 64, 175) in hex → #1E40AF
        let result = engine.evaluateLine("rgb(30, 64, 175) in hex")
        XCTAssertEqual(result.value, .color(.hex("1E40AF")))
        XCTAssertEqual(result.formatted, "#1E40AF")
    }

    func testRgbToHexBlack() {
        let result = engine.evaluateLine("rgb(0, 0, 0) in hex")
        XCTAssertEqual(result.value, .color(.hex("000000")))
    }

    func testRgbToHexWhite() {
        let result = engine.evaluateLine("rgb(255, 255, 255) in hex")
        XCTAssertEqual(result.value, .color(.hex("FFFFFF")))
    }

    // MARK: - Color Conversion: Hex → HSL

    func testHexToHsl() {
        // #FF5733 → approximately hsl(11, 100%, 60%)
        let result = engine.evaluateLine("#FF5733 in hsl")
        if case .color(.hsl(let h, let s, let l)) = result.value {
            XCTAssertEqual(h, 11, "Expected hue ~11°")
            XCTAssertEqual(s, 1.0, accuracy: 0.01, "Expected saturation ~100%")
            XCTAssertEqual(l, 0.6, accuracy: 0.01, "Expected lightness ~60%")
        } else {
            XCTFail("Expected HSL color, got \(result.value)")
        }
    }

    func testHexToHslFormatted() {
        let result = engine.evaluateLine("#FF5733 in hsl")
        // Formatted should be "hsl(11, 100%, 60%)" approximately
        XCTAssertTrue(result.formatted.hasPrefix("hsl("), "Expected hsl() format, got '\(result.formatted)'")
    }

    // MARK: - ColorConverter unit tests

    func testColorConverterHexToRgb() {
        let converter = ColorConverter()
        let result = converter.hexToRgb("FF5733")
        XCTAssertEqual(result?.0, 255)
        XCTAssertEqual(result?.1, 87)
        XCTAssertEqual(result?.2, 51)
    }

    func testColorConverterRgbToHex() {
        let converter = ColorConverter()
        let hex = converter.rgbToHex(255, 87, 51)
        XCTAssertEqual(hex, "FF5733")
    }

    func testColorConverterRgbToHsl() {
        let converter = ColorConverter()
        let (h, s, l) = converter.rgbToHsl(255, 0, 0)
        XCTAssertEqual(h, 0)       // red hue
        XCTAssertEqual(s, 1.0, accuracy: 0.01)
        XCTAssertEqual(l, 0.5, accuracy: 0.01)
    }

    func testColorConverterHslRoundtrip() {
        let converter = ColorConverter()
        let (r, g, b) = converter.hslToRgb(h: 0, s: 1.0, l: 0.5)
        XCTAssertEqual(r, 255)
        XCTAssertEqual(g, 0)
        XCTAssertEqual(b, 0)
    }

    // MARK: - Base64 Encoding

    func testBase64Encode() {
        // "hello world" to base64 → "aGVsbG8gd29ybGQ="
        let result = engine.evaluateLine("\"hello world\" to base64")
        XCTAssertEqual(result.value, .string("aGVsbG8gd29ybGQ="))
        XCTAssertEqual(result.formatted, "aGVsbG8gd29ybGQ=")
    }

    func testBase64EncodeHello() {
        let result = engine.evaluateLine("\"hello\" to base64")
        XCTAssertEqual(result.value, .string("aGVsbG8="))
    }

    func testBase64EncodeEmpty() {
        let result = engine.evaluateLine("\"\" to base64")
        XCTAssertEqual(result.value, .string(""))
    }

    // MARK: - Base64 Decoding

    func testBase64Decode() {
        // "aGVsbG8=" from base64 → "hello"
        let result = engine.evaluateLine("\"aGVsbG8=\" to frombase64")
        XCTAssertEqual(result.value, .string("hello"))
        XCTAssertEqual(result.formatted, "hello")
    }

    func testBase64DecodeHelloWorld() {
        let result = engine.evaluateLine("\"aGVsbG8gd29ybGQ=\" to frombase64")
        XCTAssertEqual(result.value, .string("hello world"))
    }

    // MARK: - Base64Converter unit tests

    func testBase64ConverterEncode() {
        let converter = Base64Converter()
        XCTAssertEqual(converter.encode("hello"), "aGVsbG8=")
        XCTAssertEqual(converter.encode("hello world"), "aGVsbG8gd29ybGQ=")
    }

    func testBase64ConverterDecode() {
        let converter = Base64Converter()
        XCTAssertEqual(converter.decode("aGVsbG8="), "hello")
        XCTAssertEqual(converter.decode("aGVsbG8gd29ybGQ="), "hello world")
    }

    func testBase64ConverterDecodeInvalid() {
        let converter = Base64Converter()
        // Invalid base64 should return nil
        XCTAssertNil(converter.decode("!!!invalid!!!"))
    }

    // MARK: - Timestamp to Date

    func testTimestampToDate() {
        // 1742659200 to date → 2025-03-22 (UTC)
        let result = engine.evaluateLine("1742659200 to date")
        if case .date(let d) = result.value {
            // Verify it's a date (non-empty formatted)
            XCTAssertFalse(result.formatted.isEmpty)
            // The Unix timestamp 1742659200 corresponds to 2025-03-22 UTC
            let converter = TimestampConverter()
            let expected = converter.toDate(1742659200)
            XCTAssertEqual(d.timeIntervalSince1970, expected.timeIntervalSince1970, accuracy: 1)
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    func testUnixEpoch() {
        // 0 to date → 1970-01-01 UTC
        let result = engine.evaluateLine("0 to date")
        if case .date(let d) = result.value {
            XCTAssertEqual(d.timeIntervalSince1970, 0, accuracy: 1)
        } else {
            XCTFail("Expected .date, got \(result.value)")
        }
    }

    // MARK: - TimestampConverter unit tests

    func testTimestampConverterToDate() {
        let converter = TimestampConverter()
        let d = converter.toDate(0)
        XCTAssertEqual(d.timeIntervalSince1970, 0)
    }

    func testTimestampConverterToUnix() {
        let converter = TimestampConverter()
        let d = Date(timeIntervalSince1970: 1742659200)
        let ts = converter.toUnix(d)
        XCTAssertEqual(ts, 1742659200, accuracy: 1)
    }

    func testTimestampConverterFormatDate() {
        let converter = TimestampConverter()
        let d = Date(timeIntervalSince1970: 0)
        let formatted = converter.formatDate(d)
        XCTAssertEqual(formatted, "1970-01-01")
    }

    // MARK: - Date to Unix

    func testDateToUnix() {
        // today to unix → a large number (current unix timestamp)
        let result = engine.evaluateLine("today to unix")
        if case .number(let ts) = result.value {
            // Should be a reasonable unix timestamp (after 2020)
            XCTAssertGreaterThan(ts, 1_577_836_800) // > 2020-01-01
        } else {
            XCTFail("Expected .number (unix timestamp), got \(result.value)")
        }
    }

    // MARK: - Scientific Notation

    func testScientificNotation() {
        // 299792458 in sci → string in scientific format
        let result = engine.evaluateLine("299792458 in sci")
        if case .string(let s) = result.value {
            XCTAssertTrue(s.contains("e"), "Expected scientific notation with 'e', got '\(s)'")
        } else {
            XCTFail("Expected .string, got \(result.value)")
        }
    }

    func testScientificNotationSmall() {
        let result = engine.evaluateLine("0.000001 in sci")
        if case .string(let s) = result.value {
            XCTAssertTrue(s.contains("e"), "Expected scientific notation, got '\(s)'")
        } else {
            XCTFail("Expected .string, got \(result.value)")
        }
    }
}
