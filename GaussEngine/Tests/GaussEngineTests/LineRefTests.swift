import XCTest
@testable import GaussEngine

final class LineRefTests: XCTestCase {

    var engine: GaussEngine!
    var tokenizer: Tokenizer!
    var matcher: Matcher!

    override func setUp() {
        engine = try! GaussEngine()
        let definitions = try! DefinitionLoader()
        tokenizer = Tokenizer(definitions: definitions)
        matcher = Matcher(definitions: definitions)
    }

    func testTokenizeAtOne() {
        XCTAssertEqual(tokenizer.tokenize("@1"), [.lineRef(1)])
    }

    func testTokenizeAtTwelve() {
        XCTAssertEqual(tokenizer.tokenize("@12"), [.lineRef(12)])
    }

    func testTokenizeAtOnePlusTwo() {
        XCTAssertEqual(
            tokenizer.tokenize("@1 + 2"),
            [.lineRef(1), .op(.add), .number(2)]
        )
    }

    func testTokenizeAtOneNoSpace() {
        XCTAssertEqual(
            tokenizer.tokenize("@1+2"),
            [.lineRef(1), .op(.add), .number(2)]
        )
    }

    func testParseLineRef() {
        XCTAssertEqual(matcher.match([.lineRef(1)]), .lineRef(1))
    }

    func testParseLineRefInArithmetic() {
        let result = matcher.match([.lineRef(1), .op(.add), .number(2)])
        XCTAssertEqual(
            result,
            .arithmetic(.lineRef(1), .add, .literal(.number(2)))
        )
    }

    func testReferencePreviousLine() {
        let results = engine.evaluateDocument("2 + 2\n@1 + 2")
        XCTAssertEqual(results[0].value, .number(4))
        XCTAssertEqual(results[1].value, .number(6))
        XCTAssertEqual(results[1].formatted, "6")
    }

    func testReferencePreservesCurrency() {
        let results = engine.evaluateDocument("$8 times 5\n@1")
        XCTAssertEqual(results[1].value, .currency(40, "USD"))
        XCTAssertEqual(results[1].formatted, "$40")
    }

    func testReferenceMissingLine() {
        let results = engine.evaluateDocument("@3")
        XCTAssertEqual(results[0].value, .undefined)
    }

    func testSelfReferenceIsCircular() {
        let results = engine.evaluateDocument("@1")
        XCTAssertEqual(results[0].value, .circular)
    }

    func testForwardReferenceIsUndefined() {
        let results = engine.evaluateDocument("@2\n5")
        XCTAssertEqual(results[0].value, .undefined)
        XCTAssertEqual(results[1].value, .number(5))
    }

    func testZeroAndNegativeAreUndefined() {
        XCTAssertEqual(engine.evaluateLine("@0").value, .undefined)
    }

    func testReferenceSkipsEmptyAndComment() {
        let results = engine.evaluateDocument("10\n// note\n\n@1 * 2")
        XCTAssertEqual(results[3].value, .number(20))
    }

    func testLoneAtIsIgnored() {
        XCTAssertEqual(tokenizer.tokenize("@"), [])
    }
}
