import XCTest
@testable import Gauss

final class AppTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }

    func testCalculatorFloatsWhenAlwaysOnTop() {
        XCTAssertEqual(WindowLevelPolicy.calculator(alwaysOnTop: true), .floating)
    }

    func testCalculatorNormalWhenAlwaysOnTopOff() {
        XCTAssertEqual(WindowLevelPolicy.calculator(alwaysOnTop: false), .normal)
    }

    func testPreferencesSitsAboveCalculatorWhenAlwaysOnTop() {
        let prefs = WindowLevelPolicy.preferences(alwaysOnTop: true)
        let calc = WindowLevelPolicy.calculator(alwaysOnTop: true)
        XCTAssertGreaterThan(prefs.rawValue, calc.rawValue)
    }

    func testPreferencesNormalWhenAlwaysOnTopOff() {
        XCTAssertEqual(WindowLevelPolicy.preferences(alwaysOnTop: false), .normal)
    }
}
