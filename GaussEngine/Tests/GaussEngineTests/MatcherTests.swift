import XCTest
@testable import GaussEngine

final class MatcherTests: XCTestCase {

    private var matcher: Matcher!

    override func setUp() {
        super.setUp()
        do {
            let definitions = try DefinitionLoader()
            matcher = Matcher(definitions: definitions)
        } catch {
            XCTFail("Failed to create Matcher: \(error)")
        }
    }

    // MARK: - Basic Arithmetic

    func testBasicAddition() {
        let result = matcher.match([.number(5), .op(.add), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .add,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testOperatorPrecedence() {
        // 2 + 3 * 4 → add(2, mul(3, 4))
        let result = matcher.match([
            .number(2), .op(.add), .number(3), .op(.multiply), .number(4)
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.number(2)),
            .add,
            Expression.arithmetic(
                Expression.literal(.number(3)),
                .multiply,
                Expression.literal(.number(4))
            )
        )
        XCTAssertEqual(result, expected)
    }

    func testParentheses() {
        // (2 + 3) * 4 → mul(add(2, 3), 4)
        let result = matcher.match([
            .leftParen, .number(2), .op(.add), .number(3), .rightParen,
            .op(.multiply), .number(4)
        ])
        let expected = Expression.arithmetic(
            Expression.arithmetic(
                Expression.literal(.number(2)),
                .add,
                Expression.literal(.number(3))
            ),
            .multiply,
            Expression.literal(.number(4))
        )
        XCTAssertEqual(result, expected)
    }

    // MARK: - Assignment

    func testAssignment() {
        // price = $8
        let result = matcher.match([
            .identifier("price"), .assignment, .currency(8, "USD")
        ])
        let expected = Expression.assignment("price", Expression.literal(.currency(8, "USD")))
        XCTAssertEqual(result, expected)
    }

    func testAssignmentWithExpression() {
        // price = $8 times 5
        let result = matcher.match([
            .identifier("price"), .assignment, .currency(8, "USD"),
            .keyword(.times), .number(5)
        ])
        let expected = Expression.assignment("price", Expression.arithmetic(
            Expression.literal(.currency(8, "USD")),
            .multiply,
            Expression.literal(.number(5))
        ))
        XCTAssertEqual(result, expected)
    }

    // MARK: - Percentage Patterns

    func testPercentOf() {
        // 20% of $150
        let result = matcher.match([
            .percentage(20), .keyword(.of), .currency(150, "USD")
        ])
        let expected = Expression.percentOf(20, Expression.literal(.currency(150, "USD")))
        XCTAssertEqual(result, expected)
    }

    func testPercentOn() {
        // 15% on $20
        let result = matcher.match([
            .percentage(15), .keyword(.on), .currency(20, "USD")
        ])
        let expected = Expression.percentOn(15, Expression.literal(.currency(20, "USD")))
        XCTAssertEqual(result, expected)
    }

    func testPercentOff() {
        // 20% off $50
        let result = matcher.match([
            .percentage(20), .keyword(.off), .currency(50, "USD")
        ])
        let expected = Expression.percentOff(20, Expression.literal(.currency(50, "USD")))
        XCTAssertEqual(result, expected)
    }

    // MARK: - Conversions

    func testUnitConversion() {
        // 5 inches in cm → conversion(.literal(.unit(5, "inch", "length")), "cm")
        let result = matcher.match([
            .number(5), .identifier("inches"), .keyword(.in), .identifier("cm")
        ])
        let expected = Expression.conversion(
            Expression.literal(.unit(5, "inch", "length")),
            "cm"
        )
        XCTAssertEqual(result, expected)
    }

    func testCurrencyConversion() {
        // $20 in EUR
        let result = matcher.match([
            .currency(20, "USD"), .keyword(.in), .identifier("EUR")
        ])
        let expected = Expression.conversion(
            Expression.literal(.currency(20, "USD")),
            "EUR"
        )
        XCTAssertEqual(result, expected)
    }

    func testHexColorConversion() {
        // #FF5733 in rgb
        let result = matcher.match([
            .hexColor("FF5733"), .keyword(.in), .identifier("rgb")
        ])
        let expected = Expression.conversion(
            Expression.literal(.color(.hex("FF5733"))),
            "rgb"
        )
        XCTAssertEqual(result, expected)
    }

    // MARK: - Function Calls

    func testFunctionCall() {
        // sqrt(144)
        let result = matcher.match([
            .identifier("sqrt"), .leftParen, .number(144), .rightParen
        ])
        let expected = Expression.functionCall("sqrt", [Expression.literal(.number(144))])
        XCTAssertEqual(result, expected)
    }

    func testFunctionCallWithDecimal() {
        // round(3.7)
        let result = matcher.match([
            .identifier("round"), .leftParen, .number(3.7), .rightParen
        ])
        let expected = Expression.functionCall("round", [Expression.literal(.number(3.7))])
        XCTAssertEqual(result, expected)
    }

    // MARK: - Variable Reference

    func testVariableReference() {
        // price (not a keyword, not a function, not a unit)
        let result = matcher.match([.identifier("price")])
        let expected = Expression.variableRef("price")
        XCTAssertEqual(result, expected)
    }

    // MARK: - Special Tokens

    func testSpecialTokenSum() {
        let result = matcher.match([.identifier("sum")])
        let expected = Expression.specialToken(.sum)
        XCTAssertEqual(result, expected)
    }

    func testSpecialTokenAvg() {
        let result = matcher.match([.identifier("avg")])
        let expected = Expression.specialToken(.avg)
        XCTAssertEqual(result, expected)
    }

    func testSpecialTokenPrev() {
        let result = matcher.match([.identifier("prev")])
        let expected = Expression.specialToken(.prev)
        XCTAssertEqual(result, expected)
    }

    // MARK: - Natural Language Operators

    func testNaturalLanguageTimes() {
        // $6 times 5
        let result = matcher.match([
            .currency(6, "USD"), .keyword(.times), .number(5)
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.currency(6, "USD")),
            .multiply,
            Expression.literal(.number(5))
        )
        XCTAssertEqual(result, expected)
    }

    // MARK: - Compound Assignment

    func testCompoundAssignment() {
        // total += $20
        let result = matcher.match([
            .identifier("total"), .compoundAssignment(.add), .currency(20, "USD")
        ])
        let expected = Expression.compoundAssignment("total", .add, Expression.literal(.currency(20, "USD")))
        XCTAssertEqual(result, expected)
    }

    // MARK: - Unary Minus

    func testUnaryMinus() {
        // -5
        let result = matcher.match([.op(.subtract), .number(5)])
        let expected = Expression.unaryMinus(Expression.literal(.number(5)))
        XCTAssertEqual(result, expected)
    }

    // MARK: - Power (Right-Associative)

    func testPowerRightAssociative() {
        // 2 ^ 3 ^ 2 → power(2, power(3, 2))
        let result = matcher.match([
            .number(2), .op(.power), .number(3), .op(.power), .number(2)
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.number(2)),
            .power,
            Expression.arithmetic(
                Expression.literal(.number(3)),
                .power,
                Expression.literal(.number(2))
            )
        )
        XCTAssertEqual(result, expected)
    }

    // MARK: - Structure Tokens (nil results)

    func testHeaderReturnsNil() {
        let result = matcher.match([.header("Title")])
        XCTAssertNil(result)
    }

    func testCommentReturnsNil() {
        let result = matcher.match([.comment("note")])
        XCTAssertNil(result)
    }

    func testEmptyReturnsNil() {
        let result = matcher.match([])
        XCTAssertNil(result)
    }

    // MARK: - Percentage as Literal

    func testPercentageAsLiteral() {
        // Standalone 8.5%
        let result = matcher.match([.percentage(8.5)])
        let expected = Expression.literal(.percentage(8.5))
        XCTAssertEqual(result, expected)
    }

    // MARK: - Additional Edge Cases

    func testSubtractionPrecedence() {
        // 10 - 2 * 3 → sub(10, mul(2, 3))
        let result = matcher.match([
            .number(10), .op(.subtract), .number(2), .op(.multiply), .number(3)
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.number(10)),
            .subtract,
            Expression.arithmetic(
                Expression.literal(.number(2)),
                .multiply,
                Expression.literal(.number(3))
            )
        )
        XCTAssertEqual(result, expected)
    }

    func testDivision() {
        // 10 / 2
        let result = matcher.match([.number(10), .op(.divide), .number(2)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(10)),
            .divide,
            Expression.literal(.number(2))
        )
        XCTAssertEqual(result, expected)
    }

    func testModulo() {
        // 10 mod 3
        let result = matcher.match([.number(10), .op(.mod), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(10)),
            .mod,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testHexNumberLiteral() {
        let result = matcher.match([.hexNumber(255)])
        let expected = Expression.literal(.number(255))
        XCTAssertEqual(result, expected)
    }

    func testBinaryNumberLiteral() {
        let result = matcher.match([.binaryNumber(10)])
        let expected = Expression.literal(.number(10))
        XCTAssertEqual(result, expected)
    }

    func testOctalNumberLiteral() {
        let result = matcher.match([.octalNumber(8)])
        let expected = Expression.literal(.number(8))
        XCTAssertEqual(result, expected)
    }

    func testStringLiteral() {
        let result = matcher.match([.string("hello")])
        let expected = Expression.literal(.string("hello"))
        XCTAssertEqual(result, expected)
    }

    func testRgbColorLiteral() {
        let result = matcher.match([.rgbColor(255, 87, 51)])
        let expected = Expression.literal(.color(.rgb(255, 87, 51)))
        XCTAssertEqual(result, expected)
    }

    func testHexColorLiteral() {
        let result = matcher.match([.hexColor("FF5733")])
        let expected = Expression.literal(.color(.hex("FF5733")))
        XCTAssertEqual(result, expected)
    }

    func testNaturalLanguagePlus() {
        // 5 plus 3
        let result = matcher.match([.number(5), .keyword(.plus), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .add,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testNaturalLanguageMinus() {
        // 10 minus 3
        let result = matcher.match([.number(10), .keyword(.minus), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(10)),
            .subtract,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testNaturalLanguageDivide() {
        // 10 divide 2
        let result = matcher.match([.number(10), .keyword(.divide), .number(2)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(10)),
            .divide,
            Expression.literal(.number(2))
        )
        XCTAssertEqual(result, expected)
    }

    func testNestedParentheses() {
        // ((2 + 3))
        let result = matcher.match([
            .leftParen, .leftParen, .number(2), .op(.add), .number(3),
            .rightParen, .rightParen
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.number(2)),
            .add,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testConversionWithKeywordTo() {
        // $20 to EUR
        let result = matcher.match([
            .currency(20, "USD"), .keyword(.to), .identifier("EUR")
        ])
        let expected = Expression.conversion(
            Expression.literal(.currency(20, "USD")),
            "EUR"
        )
        XCTAssertEqual(result, expected)
    }

    func testConversionWithKeywordAs() {
        // $20 as EUR
        let result = matcher.match([
            .currency(20, "USD"), .keyword(.as), .identifier("EUR")
        ])
        let expected = Expression.conversion(
            Expression.literal(.currency(20, "USD")),
            "EUR"
        )
        XCTAssertEqual(result, expected)
    }

    func testBitwiseAnd() {
        let result = matcher.match([.number(5), .op(.band), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .band,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testBitwiseOr() {
        let result = matcher.match([.number(5), .op(.bor), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .bor,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testSpecialTokenTotal() {
        let result = matcher.match([.identifier("total")])
        let expected = Expression.specialToken(.total)
        XCTAssertEqual(result, expected)
    }

    func testSpecialTokenAverage() {
        let result = matcher.match([.identifier("average")])
        let expected = Expression.specialToken(.average)
        XCTAssertEqual(result, expected)
    }

    func testLabelWithExpression() {
        // Label tokens are passed through; the matcher should skip label and parse the rest
        let result = matcher.match([.label("Tax"), .number(5), .op(.add), .number(3)])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .add,
            Expression.literal(.number(3))
        )
        XCTAssertEqual(result, expected)
    }

    func testLabelOnly() {
        // A label with nothing after should return nil
        let result = matcher.match([.label("Title")])
        XCTAssertNil(result)
    }

    func testUnaryMinusInExpression() {
        // 5 + -3 → add(5, unaryMinus(3))
        let result = matcher.match([
            .number(5), .op(.add), .op(.subtract), .number(3)
        ])
        let expected = Expression.arithmetic(
            Expression.literal(.number(5)),
            .add,
            Expression.unaryMinus(Expression.literal(.number(3)))
        )
        XCTAssertEqual(result, expected)
    }

    func testComplexExpression() {
        // 2 * 3 + 4 * 5 → add(mul(2, 3), mul(4, 5))
        let result = matcher.match([
            .number(2), .op(.multiply), .number(3),
            .op(.add),
            .number(4), .op(.multiply), .number(5)
        ])
        let expected = Expression.arithmetic(
            Expression.arithmetic(
                Expression.literal(.number(2)),
                .multiply,
                Expression.literal(.number(3))
            ),
            .add,
            Expression.arithmetic(
                Expression.literal(.number(4)),
                .multiply,
                Expression.literal(.number(5))
            )
        )
        XCTAssertEqual(result, expected)
    }
}
