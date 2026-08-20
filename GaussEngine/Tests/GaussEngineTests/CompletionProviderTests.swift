import XCTest
@testable import GaussEngine

final class CompletionProviderTests: XCTestCase {
    private var provider: CompletionProvider!

    override func setUp() {
        let definitions = try! DefinitionLoader()
        provider = CompletionProvider(definitions: definitions)
    }

    func testCompletesSingleWordPrefix() {
        XCTAssertEqual(provider.completionSuffix(for: "Braz"), "ilian real")
    }

    func testCompletesLongestKnownCurrencyPhrase() {
        XCTAssertEqual(provider.completionSuffix(for: "Brazilian re"), "al")
        XCTAssertEqual(provider.completionSuffix(for: "$5 in Brazilian re"), "al")
    }

    func testPrefersSingularCurrencyPhrase() {
        XCTAssertEqual(provider.completionSuffix(for: "US doll"), "ar")
        XCTAssertEqual(provider.completionSuffix(for: "Australian doll"), "ar")
    }

    func testDoesNotExtendExactCurrencyPhraseToPlural() {
        XCTAssertNil(provider.completionSuffix(for: "US dollar"))
        XCTAssertNil(provider.completionSuffix(for: "Australian dollar"))
    }

    func testCompletesLongestKnownUnitPhrase() {
        XCTAssertEqual(provider.completionSuffix(for: "nautical mi"), "le")
    }
}
