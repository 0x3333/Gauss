import XCTest
@testable import GaussEngine

final class GaussEngineTests: XCTestCase {
    func testEngineInitializes() {
        let engine = try! GaussEngine()
        XCTAssertNotNil(engine)
    }
}
