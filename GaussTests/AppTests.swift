import XCTest
@testable import Gauss

final class AppTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }

    func testHotkeyShowsHiddenWindow() {
        XCTAssertEqual(
            WindowTogglePolicy.action(isVisible: false, isKey: false, isAppActive: false),
            .show
        )
    }

    func testHotkeyShowsVisibleUnfocusedWindow() {
        XCTAssertEqual(
            WindowTogglePolicy.action(isVisible: true, isKey: false, isAppActive: true),
            .show
        )
    }

    func testHotkeyShowsVisibleWindowWhenAppInactive() {
        XCTAssertEqual(
            WindowTogglePolicy.action(isVisible: true, isKey: true, isAppActive: false),
            .show
        )
    }

    func testHotkeyHidesFocusedWindow() {
        XCTAssertEqual(
            WindowTogglePolicy.action(isVisible: true, isKey: true, isAppActive: true),
            .hide
        )
    }
}
