import XCTest
@testable import GaussEngine

final class TokenTests: XCTestCase {

    // MARK: - Number tokens

    func testNumberEquality() {
        XCTAssertEqual(Token.number(3.14), Token.number(3.14))
        XCTAssertNotEqual(Token.number(1.0), Token.number(2.0))
    }

    func testHexNumberEquality() {
        XCTAssertEqual(Token.hexNumber(0xFF), Token.hexNumber(255))
        XCTAssertNotEqual(Token.hexNumber(0x0A), Token.hexNumber(0x0B))
    }

    func testBinaryNumberEquality() {
        XCTAssertEqual(Token.binaryNumber(0b1010), Token.binaryNumber(10))
        XCTAssertNotEqual(Token.binaryNumber(0b0001), Token.binaryNumber(0b0010))
    }

    func testOctalNumberEquality() {
        XCTAssertEqual(Token.octalNumber(0o17), Token.octalNumber(15))
        XCTAssertNotEqual(Token.octalNumber(0o7), Token.octalNumber(0o10))
    }

    func testPercentageEquality() {
        XCTAssertEqual(Token.percentage(20.0), Token.percentage(20.0))
        XCTAssertNotEqual(Token.percentage(10.0), Token.percentage(20.0))
    }

    // MARK: - Currency token

    func testCurrencyEquality() {
        XCTAssertEqual(Token.currency(8.0, "USD"), Token.currency(8.0, "USD"))
        XCTAssertNotEqual(Token.currency(8.0, "USD"), Token.currency(8.0, "EUR"))
        XCTAssertNotEqual(Token.currency(8.0, "USD"), Token.currency(9.0, "USD"))
    }

    // MARK: - Operator tokens

    func testOpEquality() {
        XCTAssertEqual(Token.op(.add), Token.op(.add))
        XCTAssertNotEqual(Token.op(.add), Token.op(.subtract))
    }

    func testAssignmentEquality() {
        XCTAssertEqual(Token.assignment, Token.assignment)
        XCTAssertNotEqual(Token.assignment, Token.op(.add))
    }

    func testCompoundAssignmentEquality() {
        XCTAssertEqual(Token.compoundAssignment(.add), Token.compoundAssignment(.add))
        XCTAssertNotEqual(Token.compoundAssignment(.add), Token.compoundAssignment(.subtract))
    }

    // MARK: - Identifier / keyword tokens

    func testIdentifierEquality() {
        XCTAssertEqual(Token.identifier("price"), Token.identifier("price"))
        XCTAssertNotEqual(Token.identifier("price"), Token.identifier("cost"))
    }

    func testKeywordEquality() {
        XCTAssertEqual(Token.keyword(.in), Token.keyword(.in))
        XCTAssertNotEqual(Token.keyword(.to), Token.keyword(.from))
    }

    func testLineRefEquality() {
        XCTAssertEqual(Token.lineRef(1), Token.lineRef(1))
        XCTAssertNotEqual(Token.lineRef(1), Token.lineRef(2))
    }

    func testAllKeywordsAreUnique() {
        let all = Keyword.allCases
        let unique = Set(all.map(\.rawValue))
        XCTAssertEqual(all.count, unique.count, "Keyword raw values must be unique")
    }

    // MARK: - Structure tokens

    func testHeaderEquality() {
        XCTAssertEqual(Token.header("My Section"), Token.header("My Section"))
        XCTAssertNotEqual(Token.header("A"), Token.header("B"))
    }

    func testCommentEquality() {
        XCTAssertEqual(Token.comment("// note"), Token.comment("// note"))
        XCTAssertNotEqual(Token.comment("a"), Token.comment("b"))
    }

    func testLabelEquality() {
        XCTAssertEqual(Token.label("Total"), Token.label("Total"))
        XCTAssertNotEqual(Token.label("A"), Token.label("B"))
    }

    func testParenEquality() {
        XCTAssertEqual(Token.leftParen, Token.leftParen)
        XCTAssertEqual(Token.rightParen, Token.rightParen)
        XCTAssertNotEqual(Token.leftParen, Token.rightParen)
    }

    // MARK: - Special tokens

    func testStringEquality() {
        XCTAssertEqual(Token.string("hello"), Token.string("hello"))
        XCTAssertNotEqual(Token.string("a"), Token.string("b"))
    }

    func testHexColorEquality() {
        XCTAssertEqual(Token.hexColor("FF5733"), Token.hexColor("FF5733"))
        XCTAssertNotEqual(Token.hexColor("FF5733"), Token.hexColor("000000"))
    }

    func testRgbColorEquality() {
        XCTAssertEqual(Token.rgbColor(255, 87, 51), Token.rgbColor(255, 87, 51))
        XCTAssertNotEqual(Token.rgbColor(255, 87, 51), Token.rgbColor(0, 0, 0))
    }

    // MARK: - Operator CaseIterable

    func testAllOperatorsAreUnique() {
        let all = Operator.allCases
        let unique = Set(all.map(\.rawValue))
        XCTAssertEqual(all.count, unique.count, "Operator raw values must be unique")
    }
}

// MARK: -

final class ValueTests: XCTestCase {

    // MARK: - numericValue

    func testNumberNumericValue() {
        XCTAssertEqual(Value.number(42.0).numericValue, 42.0)
    }

    func testCurrencyNumericValue() {
        XCTAssertEqual(Value.currency(99.99, "USD").numericValue, 99.99)
    }

    func testUnitNumericValue() {
        XCTAssertEqual(Value.unit(5.0, "km", "length").numericValue, 5.0)
    }

    func testPercentageNumericValue() {
        XCTAssertEqual(Value.percentage(15.0).numericValue, 15.0)
    }

    func testDurationNumericValue() {
        XCTAssertEqual(Value.duration(90.0, "min").numericValue, 90.0)
    }

    func testDateNumericValueIsNil() {
        XCTAssertNil(Value.date(Date()).numericValue)
    }

    func testColorNumericValueIsNil() {
        XCTAssertNil(Value.color(.hex("FF0000")).numericValue)
    }

    func testStringNumericValueIsNil() {
        XCTAssertNil(Value.string("hello").numericValue)
    }

    func testUndefinedNumericValueIsNil() {
        XCTAssertNil(Value.undefined.numericValue)
    }

    func testInfinityNumericValueIsNil() {
        XCTAssertNil(Value.infinity(false).numericValue)
        XCTAssertNil(Value.infinity(true).numericValue)
    }

    func testCircularNumericValueIsNil() {
        XCTAssertNil(Value.circular.numericValue)
    }

    // MARK: - isNumeric

    func testIsNumericForNumericVariants() {
        XCTAssertTrue(Value.number(1.0).isNumeric)
        XCTAssertTrue(Value.currency(1.0, "EUR").isNumeric)
        XCTAssertTrue(Value.unit(1.0, "m", "length").isNumeric)
        XCTAssertTrue(Value.percentage(50.0).isNumeric)
        XCTAssertTrue(Value.duration(60.0, "s").isNumeric)
    }

    func testIsNumericFalseForNonNumericVariants() {
        XCTAssertFalse(Value.date(Date()).isNumeric)
        XCTAssertFalse(Value.color(.rgb(0, 0, 0)).isNumeric)
        XCTAssertFalse(Value.string("x").isNumeric)
        XCTAssertFalse(Value.undefined.isNumeric)
        XCTAssertFalse(Value.infinity(false).isNumeric)
        XCTAssertFalse(Value.circular.isNumeric)
    }

    // MARK: - Equality

    func testValueEquality() {
        XCTAssertEqual(Value.number(3.14), Value.number(3.14))
        XCTAssertNotEqual(Value.number(1.0), Value.number(2.0))
    }

    func testCurrencyEquality() {
        XCTAssertEqual(Value.currency(10.0, "USD"), Value.currency(10.0, "USD"))
        XCTAssertNotEqual(Value.currency(10.0, "USD"), Value.currency(10.0, "GBP"))
    }

    func testUnitEquality() {
        XCTAssertEqual(Value.unit(1.0, "km", "length"), Value.unit(1.0, "km", "length"))
        XCTAssertNotEqual(Value.unit(1.0, "km", "length"), Value.unit(1.0, "m", "length"))
    }

    func testColorEquality() {
        XCTAssertEqual(Value.color(.hex("FFFFFF")), Value.color(.hex("FFFFFF")))
        XCTAssertNotEqual(Value.color(.hex("000000")), Value.color(.hex("FFFFFF")))
    }

    func testHslColorEquality() {
        XCTAssertEqual(ColorValue.hsl(120, 0.5, 0.5), ColorValue.hsl(120, 0.5, 0.5))
        XCTAssertNotEqual(ColorValue.hsl(120, 0.5, 0.5), ColorValue.hsl(180, 0.5, 0.5))
    }

    func testInfinityEquality() {
        XCTAssertEqual(Value.infinity(true), Value.infinity(true))
        XCTAssertNotEqual(Value.infinity(true), Value.infinity(false))
    }
}

// MARK: -

final class UnitDefinitionTests: XCTestCase {

    func testCodableRoundTripLinear() throws {
        let def = UnitDefinition(
            id: "km",
            variants: ["km", "kilometer", "kilometres"],
            format: "km",
            toBase: 1000.0
        )
        let data = try JSONEncoder().encode(def)
        let decoded = try JSONDecoder().decode(UnitDefinition.self, from: data)
        XCTAssertEqual(def, decoded)
    }

    func testCodableRoundTripFormula() throws {
        let def = UnitDefinition(
            id: "celsius",
            variants: ["°C", "celsius", "c"],
            format: "°C",
            toBase: nil,
            toBaseFormula: "(x + 273.15)",
            fromBaseFormula: "(x - 273.15)"
        )
        let data = try JSONEncoder().encode(def)
        let decoded = try JSONDecoder().decode(UnitDefinition.self, from: data)
        XCTAssertEqual(def, decoded)
        XCTAssertNil(decoded.toBase)
        XCTAssertEqual(decoded.toBaseFormula, "(x + 273.15)")
        XCTAssertEqual(decoded.fromBaseFormula, "(x - 273.15)")
    }

    func testCodableRoundTripNoOptionalFields() throws {
        let def = UnitDefinition(
            id: "m",
            variants: ["m", "meter", "metre"],
            format: "m"
        )
        let data = try JSONEncoder().encode(def)
        let decoded = try JSONDecoder().decode(UnitDefinition.self, from: data)
        XCTAssertEqual(def, decoded)
        XCTAssertNil(decoded.toBase)
        XCTAssertNil(decoded.toBaseFormula)
        XCTAssertNil(decoded.fromBaseFormula)
    }

    func testEquality() {
        let a = UnitDefinition(id: "km", variants: ["km"], format: "km", toBase: 1000.0)
        let b = UnitDefinition(id: "km", variants: ["km"], format: "km", toBase: 1000.0)
        let c = UnitDefinition(id: "km", variants: ["km"], format: "km", toBase: 999.0)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}

final class UnitCategoryTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let category = UnitCategory(
            category: "length",
            base: "m",
            units: [
                UnitDefinition(id: "m", variants: ["m", "meter"], format: "m", toBase: 1.0),
                UnitDefinition(id: "km", variants: ["km", "kilometer"], format: "km", toBase: 1000.0),
            ]
        )
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(UnitCategory.self, from: data)
        XCTAssertEqual(category, decoded)
        XCTAssertEqual(decoded.units.count, 2)
    }

    func testEquality() {
        let a = UnitCategory(category: "length", base: "m", units: [])
        let b = UnitCategory(category: "length", base: "m", units: [])
        let c = UnitCategory(category: "weight", base: "kg", units: [])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}

// MARK: -

final class ExpressionTests: XCTestCase {

    // MARK: - Literal

    func testLiteralEquality() {
        XCTAssertEqual(Expression.literal(.number(1.0)), Expression.literal(.number(1.0)))
        XCTAssertNotEqual(Expression.literal(.number(1.0)), Expression.literal(.number(2.0)))
    }

    // MARK: - Arithmetic

    func testArithmeticEquality() {
        let lhs = Expression.literal(.number(2.0))
        let rhs = Expression.literal(.number(3.0))
        let expr1 = Expression.arithmetic(lhs, .add, rhs)
        let expr2 = Expression.arithmetic(lhs, .add, rhs)
        XCTAssertEqual(expr1, expr2)
    }

    func testArithmeticOperatorDifference() {
        let lhs = Expression.literal(.number(2.0))
        let rhs = Expression.literal(.number(3.0))
        let add = Expression.arithmetic(lhs, .add, rhs)
        let sub = Expression.arithmetic(lhs, .subtract, rhs)
        XCTAssertNotEqual(add, sub)
    }

    // MARK: - UnaryMinus

    func testUnaryMinusEquality() {
        let inner = Expression.literal(.number(5.0))
        XCTAssertEqual(Expression.unaryMinus(inner), Expression.unaryMinus(inner))
        XCTAssertNotEqual(
            Expression.unaryMinus(Expression.literal(.number(1.0))),
            Expression.unaryMinus(Expression.literal(.number(2.0)))
        )
    }

    // MARK: - Percent variants

    func testPercentOfEquality() {
        let base = Expression.literal(.currency(150.0, "USD"))
        XCTAssertEqual(Expression.percentOf(20.0, base), Expression.percentOf(20.0, base))
        XCTAssertNotEqual(Expression.percentOf(20.0, base), Expression.percentOf(10.0, base))
    }

    func testPercentOnEquality() {
        let base = Expression.literal(.number(20.0))
        XCTAssertEqual(Expression.percentOn(15.0, base), Expression.percentOn(15.0, base))
        XCTAssertNotEqual(Expression.percentOn(15.0, base), Expression.percentOn(5.0, base))
    }

    func testPercentOffEquality() {
        let base = Expression.literal(.number(50.0))
        XCTAssertEqual(Expression.percentOff(20.0, base), Expression.percentOff(20.0, base))
        XCTAssertNotEqual(Expression.percentOff(20.0, base), Expression.percentOff(30.0, base))
    }

    func testPercentOfWhatIsEquality() {
        let base = Expression.literal(.unit(30.0, "cm", "length"))
        XCTAssertEqual(Expression.percentOfWhatIs(20.0, base), Expression.percentOfWhatIs(20.0, base))
        XCTAssertNotEqual(Expression.percentOfWhatIs(20.0, base), Expression.percentOfWhatIs(50.0, base))
    }

    // MARK: - Conversion

    func testConversionEquality() {
        let inner = Expression.literal(.number(5.0))
        XCTAssertEqual(Expression.conversion(inner, "km"), Expression.conversion(inner, "km"))
        XCTAssertNotEqual(Expression.conversion(inner, "km"), Expression.conversion(inner, "m"))
    }

    // MARK: - Assignment

    func testAssignmentEquality() {
        let val = Expression.literal(.number(100.0))
        XCTAssertEqual(Expression.assignment("price", val), Expression.assignment("price", val))
        XCTAssertNotEqual(Expression.assignment("price", val), Expression.assignment("cost", val))
    }

    func testCompoundAssignmentEquality() {
        let val = Expression.literal(.number(10.0))
        XCTAssertEqual(
            Expression.compoundAssignment("price", .add, val),
            Expression.compoundAssignment("price", .add, val)
        )
        XCTAssertNotEqual(
            Expression.compoundAssignment("price", .add, val),
            Expression.compoundAssignment("price", .subtract, val)
        )
    }

    // MARK: - Function call

    func testFunctionCallEquality() {
        let args = [Expression.literal(.number(144.0))]
        XCTAssertEqual(Expression.functionCall("sqrt", args), Expression.functionCall("sqrt", args))
        XCTAssertNotEqual(Expression.functionCall("sqrt", args), Expression.functionCall("abs", args))
    }

    func testFunctionCallArgCountDifference() {
        let oneArg = [Expression.literal(.number(1.0))]
        let twoArgs = [Expression.literal(.number(1.0)), Expression.literal(.number(2.0))]
        XCTAssertNotEqual(
            Expression.functionCall("max", oneArg),
            Expression.functionCall("max", twoArgs)
        )
    }

    // MARK: - VariableRef

    func testVariableRefEquality() {
        XCTAssertEqual(Expression.variableRef("price"), Expression.variableRef("price"))
        XCTAssertNotEqual(Expression.variableRef("price"), Expression.variableRef("cost"))
    }

    func testLineRefEquality() {
        XCTAssertEqual(Expression.lineRef(1), Expression.lineRef(1))
        XCTAssertNotEqual(Expression.lineRef(1), Expression.lineRef(2))
    }

    // MARK: - SpecialToken

    func testSpecialTokenEquality() {
        XCTAssertEqual(Expression.specialToken(.sum), Expression.specialToken(.sum))
        XCTAssertNotEqual(Expression.specialToken(.sum), Expression.specialToken(.avg))
    }

    func testAllSpecialTokensAreUnique() {
        let all = SpecialToken.allCases
        let unique = Set(all.map(\.rawValue))
        XCTAssertEqual(all.count, unique.count, "SpecialToken raw values must be unique")
    }

    // MARK: - Deeply nested expression equality

    func testNestedArithmeticEquality() {
        // (2 + 3) * sqrt(4)
        let add = Expression.arithmetic(
            .literal(.number(2.0)),
            .add,
            .literal(.number(3.0))
        )
        let sqrt4 = Expression.functionCall("sqrt", [.literal(.number(4.0))])
        let mul1 = Expression.arithmetic(add, .multiply, sqrt4)
        let mul2 = Expression.arithmetic(add, .multiply, sqrt4)
        XCTAssertEqual(mul1, mul2)
    }

    func testNestedArithmeticNotEqual() {
        let a = Expression.arithmetic(
            .literal(.number(1.0)),
            .add,
            .literal(.number(2.0))
        )
        let b = Expression.arithmetic(
            .literal(.number(1.0)),
            .add,
            .literal(.number(3.0))  // different
        )
        XCTAssertNotEqual(a, b)
    }

    func testConversionOfArithmetic() {
        let inner = Expression.arithmetic(
            .variableRef("distance"),
            .add,
            .literal(.number(5.0))
        )
        let conv1 = Expression.conversion(inner, "miles")
        let conv2 = Expression.conversion(inner, "miles")
        XCTAssertEqual(conv1, conv2)
    }
}
