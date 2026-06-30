import XCTest
@testable import GaussEngine

/// Comprehensive tests for unit conversion across all unit categories.
final class UnitConversionTests: XCTestCase {

    var engine: GaussEngine!

    override func setUp() {
        engine = try! GaussEngine()
    }

    // MARK: - Helper

    /// Evaluate input and return the numeric value, asserting it is a unit.
    func unitValue(_ input: String) -> Double? {
        let result = engine.evaluateLine(input)
        if case .unit(let val, _, _) = result.value {
            return val
        }
        return nil
    }

    // MARK: - Length

    func testInchesToCm() {
        let result = engine.evaluateLine("5 inches in cm")
        XCTAssertTrue(result.formatted.contains("12.7"), "Expected '12.7' in '\(result.formatted)'")
        XCTAssertTrue(result.formatted.contains("cm"), "Expected 'cm' in '\(result.formatted)'")
    }

    func testMileToKm() {
        guard let val = unitValue("1 mile in km") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1.609344, accuracy: 0.0001)
    }

    func testCmToM() {
        guard let val = unitValue("100 cm in m") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1.0, accuracy: 0.0001)
    }

    func testFootToInches() {
        guard let val = unitValue("1 foot in inches") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 12.0, accuracy: 0.0001)
    }

    func testKmToMiles() {
        guard let val = unitValue("10 km in miles") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 6.21371, accuracy: 0.0001)
    }

    func testMeterToFeet() {
        guard let val = unitValue("1 m in feet") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 3.28084, accuracy: 0.0001)
    }

    // MARK: - Weight

    func testKgToPounds() {
        guard let val = unitValue("2 kg in pounds") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 4.40925, accuracy: 0.001)
    }

    func testPoundToOunces() {
        guard let val = unitValue("1 pound in ounces") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 16.0, accuracy: 0.001)
    }

    func testGramsToOunces() {
        guard let val = unitValue("100 grams in ounces") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 3.52740, accuracy: 0.001)
    }

    func testKgToGrams() {
        guard let val = unitValue("1 kg in grams") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1000.0, accuracy: 0.01)
    }

    func testOuncesToGrams() {
        guard let val = unitValue("1 ounce in grams") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 28.3495, accuracy: 0.001)
    }

    // MARK: - Volume

    func testGallonToLitres() {
        guard let val = unitValue("1 gallon in litres") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 3.785411784, accuracy: 0.001)
    }

    func testMlToTeaspoons() {
        guard let val = unitValue("20 ml in teaspoons") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 4.058, accuracy: 0.01)
    }

    func testCupToMl() {
        guard let val = unitValue("1 cup in ml") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 236.588, accuracy: 0.01)
    }

    func testLitresToMl() {
        guard let val = unitValue("2 litres in ml") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 2000.0, accuracy: 0.01)
    }

    func testPintToGallon() {
        guard let val = unitValue("8 pints in gallons") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1.0, accuracy: 0.0001)
    }

    // MARK: - Area

    func testHectareToAcres() {
        guard let val = unitValue("1 hectare in acres") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 2.47105, accuracy: 0.001)
    }

    func testSqMileToHectares() {
        // "sq mile" is a multi-word variant not yet tokenizable as a single token.
        // Use the si2 abbreviation variant "mi2" instead.
        guard let val = unitValue("1 mi2 in hectares") else {
            return XCTFail("Expected unit result for 1 mi2 in hectares")
        }
        XCTAssertEqual(val, 258.999, accuracy: 0.01)
    }

    func testSqMeterToSqFoot() {
        // Use single-token variants: m2 → ft2
        guard let val = unitValue("1 m2 in ft2") else {
            return XCTFail("Expected unit result for 1 m2 in ft2")
        }
        XCTAssertEqual(val, 10.7639, accuracy: 0.001)
    }

    // MARK: - Temperature

    func testCelsiusToFahrenheit() {
        guard let val = unitValue("100 celsius in fahrenheit") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 212.0, accuracy: 0.001)
    }

    func testFahrenheitToCelsius() {
        guard let val = unitValue("32 fahrenheit in celsius") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 0.0, accuracy: 0.001)
    }

    func testKelvinToCelsius() {
        guard let val = unitValue("0 kelvin in celsius") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, -273.15, accuracy: 0.001)
    }

    /// -40°C == -40°F (the crossover point)
    func testCelsiusFahrenheitCrossover() {
        guard let val = unitValue("-40 celsius in fahrenheit") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, -40.0, accuracy: 0.001)
    }

    func testCelsiusToKelvin() {
        guard let val = unitValue("0 celsius in kelvin") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 273.15, accuracy: 0.001)
    }

    // MARK: - Angle

    func testDegreesToRadians() {
        guard let val = unitValue("180 degrees in radians") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, Double.pi, accuracy: 0.00001)
    }

    func testRadiansToDegrees() {
        guard let val = unitValue("1 radian in degrees") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 57.2958, accuracy: 0.001)
    }

    // MARK: - Data

    func testGiBToMB() {
        guard let val = unitValue("1 GiB in MB") else {
            return XCTFail("Expected unit result")
        }
        // 1 GiB = 1073741824 bytes = 1073.741824 MB
        XCTAssertEqual(val, 1073.741824, accuracy: 0.01)
    }

    func testMBToKB() {
        guard let val = unitValue("3 MB in KB") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 3000.0, accuracy: 0.01)
    }

    func testBitsToBytes() {
        guard let val = unitValue("8 bits in bytes") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1.0, accuracy: 0.0001)
    }

    func testGBToMB() {
        guard let val = unitValue("1 GB in MB") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1000.0, accuracy: 0.01)
    }

    func testKiBToBytes() {
        guard let val = unitValue("1 KiB in bytes") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 1024.0, accuracy: 0.01)
    }

    // MARK: - Time

    func testHourToMinutes() {
        guard let val = unitValue("1 hour in minutes") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 60.0, accuracy: 0.01)
    }

    func testDayToHours() {
        guard let val = unitValue("1 day in hours") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 24.0, accuracy: 0.01)
    }

    func testWeekToDays() {
        guard let val = unitValue("1 week in days") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 7.0, accuracy: 0.01)
    }

    func testHoursToMinutes() {
        guard let val = unitValue("15 hours in minutes") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 900.0, accuracy: 0.01)
    }

    func testMinutesToSeconds() {
        guard let val = unitValue("5 minutes in seconds") else {
            return XCTFail("Expected unit result")
        }
        XCTAssertEqual(val, 300.0, accuracy: 0.01)
    }

    // MARK: - Formatted output checks

    func testFormattedInchesToCm() {
        let result = engine.evaluateLine("5 inches in cm")
        // Should contain the numeric value and unit
        XCTAssertFalse(result.formatted.isEmpty)
        XCTAssertTrue(result.formatted.contains("12.7"))
        XCTAssertTrue(result.formatted.contains("cm"))
    }

    func testFormattedKgToPounds() {
        let result = engine.evaluateLine("2 kg in pounds")
        XCTAssertFalse(result.formatted.isEmpty)
    }

    func testFormattedGallonToLitres() {
        let result = engine.evaluateLine("1 gallon in litres")
        XCTAssertFalse(result.formatted.isEmpty)
    }
}
