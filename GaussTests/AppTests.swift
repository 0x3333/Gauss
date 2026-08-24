import XCTest
@testable import Gauss

final class AppTests: XCTestCase {

    func testGhostShownWhenTextFollowsCursorOnSameLine() {
        let text = "1 Braz in US dollar" as NSString
        let cursor = ("1 Braz" as NSString).length
        XCTAssertTrue(CalcTextView.shouldShowGhost(in: text, cursorPos: cursor))
    }

    func testGhostShownAtEndOfLine() {
        let text = "1 Braz" as NSString
        XCTAssertTrue(CalcTextView.shouldShowGhost(in: text, cursorPos: text.length))
    }

    func testGhostShownBeforeNewline() {
        let text = "1 Braz\n2 + 2" as NSString
        let cursor = ("1 Braz" as NSString).length
        XCTAssertTrue(CalcTextView.shouldShowGhost(in: text, cursorPos: cursor))
    }

    func testGhostShownWhenOnlyTrailingWhitespace() {
        let text = "1 Braz  " as NSString
        let cursor = ("1 Braz" as NSString).length
        XCTAssertTrue(CalcTextView.shouldShowGhost(in: text, cursorPos: cursor))
    }

    func testGhostHiddenInMiddleOfWord() {
        let text = "Brazilian" as NSString
        XCTAssertFalse(CalcTextView.shouldShowGhost(in: text, cursorPos: 4))
    }

    func testGhostHiddenAtStart() {
        XCTAssertFalse(CalcTextView.shouldShowGhost(in: "Braz", cursorPos: 0))
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
