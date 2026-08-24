import Foundation

/// Converts a stream of ``Token``s into an ``Expression`` AST.
///
/// This is the second stage of the GaussEngine pipeline:
///   raw string → Tokenizer → [Token] → **Matcher** → Expression? → Evaluator → Value
///
/// The matcher uses precedence climbing for arithmetic and handles special
/// patterns (assignment, percentage, conversion) before falling through to
/// general expression parsing.
public struct Matcher {
    private let definitions: DefinitionLoader

    public init(definitions: DefinitionLoader) {
        self.definitions = definitions
    }

    // MARK: - Public API

    /// Parse a token array into an expression AST, or nil for empty / structural lines.
    public func match(_ tokens: [Token]) -> Expression? {
        guard !tokens.isEmpty else { return nil }

        // Strip leading label token if present
        var working = tokens
        if case .label = working[0] {
            working = Array(working.dropFirst())
            guard !working.isEmpty else { return nil }
        }

        // 1. Structure tokens — headers and comments produce no expression.
        if case .header = working[0] { return nil }
        if case .comment = working[0] { return nil }

        // 2. Assignment: identifier = expr
        if working.count >= 3,
           case .identifier(let name) = working[0],
           case .assignment = working[1] {
            let rhsTokens = Array(working.dropFirst(2))
            var parser = ExpressionParser(tokens: rhsTokens, definitions: definitions)
            guard let rhs = parser.parseExpression(minPrecedence: 0) else { return nil }
            return .assignment(name, rhs)
        }

        // 3. Compound assignment: identifier += expr
        if working.count >= 3,
           case .identifier(let name) = working[0],
           case .compoundAssignment(let op) = working[1] {
            let rhsTokens = Array(working.dropFirst(2))
            var parser = ExpressionParser(tokens: rhsTokens, definitions: definitions)
            guard let rhs = parser.parseExpression(minPrecedence: 0) else { return nil }
            return .compoundAssignment(name, op, rhs)
        }

        // 4. Reverse percentage patterns (before conversion/percentage to avoid conflicts)
        if let revPctExpr = tryReversePercentage(working) {
            return revPctExpr
        }

        // 5. "between...and" patterns: random, midpoint, unit between dates
        if let betweenExpr = tryBetweenPattern(working) {
            return betweenExpr
        }

        // 6. Date range: date TO date (before conversion to avoid "today to tomorrow" being a conversion)
        if let dateRangeExpr = tryDateRange(working) {
            return dateRangeExpr
        }

        // 7. Conversion suffix: ... in/to/as identifier (at the end)
        if let convExpr = tryConversion(working) {
            return convExpr
        }

        // 8. Percentage patterns: percentage of/on/off expr
        if let pctExpr = tryPercentagePattern(working) {
            return pctExpr
        }

        // 9. General expression (arithmetic, literals, functions, etc.)
        var parser = ExpressionParser(tokens: working, definitions: definitions)
        let expr = parser.parseExpression(minPrecedence: 0)
        // Make sure we consumed all tokens; if not, something is wrong,
        // but we still return what we got.
        return expr
    }

    // MARK: - Conversion Suffix

    /// Checks if the token list ends with `keyword(in/to/as) identifier` and peels
    /// off the suffix, parsing the prefix as the source expression.
    private func tryConversion(_ tokens: [Token]) -> Expression? {
        guard tokens.count >= 3 else { return nil }
        let last = tokens[tokens.count - 1]
        let secondLast = tokens[tokens.count - 2]

        guard case .identifier(let target) = last else { return nil }

        let isConversionKeyword: Bool
        switch secondLast {
        case .keyword(.in), .keyword(.to), .keyword(.as):
            isConversionKeyword = true
        default:
            isConversionKeyword = false
        }

        guard isConversionKeyword else { return nil }

        let prefixTokens = Array(tokens.dropLast(2))
        guard !prefixTokens.isEmpty else { return nil }

        var parser = ExpressionParser(tokens: prefixTokens, definitions: definitions)
        guard let source = parser.parseExpression(minPrecedence: 0) else { return nil }
        return .conversion(source, target)
    }

    // MARK: - Reverse Percentage Patterns

    /// Matches reverse percentage patterns:
    ///  - `X is what % of Y` → whatPercentOf
    ///  - `X is Y% off what` → isPercentOffWhat
    ///  - `X% of what is Y` → percentOfWhatIs
    private func tryReversePercentage(_ tokens: [Token]) -> Expression? {
        // Pattern 1: "X% of what is Y"
        // Tokens: percentage(X), keyword(.of), identifier("what"), identifier("is"), ...expr...
        if tokens.count >= 5,
           case .percentage(let pct) = tokens[0],
           case .keyword(.of) = tokens[1],
           case .identifier(let w2) = tokens[2], w2.lowercased() == "what",
           case .identifier(let w3) = tokens[3], w3.lowercased() == "is" {
            let restTokens = Array(tokens.dropFirst(4))
            var parser = ExpressionParser(tokens: restTokens, definitions: definitions)
            guard let expr = parser.parseExpression(minPrecedence: 0) else { return nil }
            return .percentOfWhatIs(pct, expr)
        }

        // Find "is" token position for the next two patterns
        var isIndex: Int? = nil
        for i in 0..<tokens.count {
            if case .identifier(let w) = tokens[i], w.lowercased() == "is" {
                isIndex = i
                break
            }
        }
        guard let isIdx = isIndex, isIdx > 0 else { return nil }

        // Pattern 2: "X is what % of Y"
        // Tokens: ...expr..., identifier("is"), identifier("what"), op(.mod), keyword(.of), ...expr...
        if isIdx + 4 <= tokens.count,
           case .identifier(let w1) = tokens[isIdx + 1], w1.lowercased() == "what",
           case .op(.mod) = tokens[isIdx + 2],
           case .keyword(.of) = tokens[isIdx + 3] {
            let lhsTokens = Array(tokens[0..<isIdx])
            let rhsTokens = Array(tokens[(isIdx + 4)...])
            guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return nil }
            var lhsParser = ExpressionParser(tokens: lhsTokens, definitions: definitions)
            var rhsParser = ExpressionParser(tokens: rhsTokens, definitions: definitions)
            guard let lhs = lhsParser.parseExpression(minPrecedence: 0),
                  let rhs = rhsParser.parseExpression(minPrecedence: 0) else { return nil }
            return .whatPercentOf(lhs, rhs)
        }

        // Pattern 3: "X is Y% off what"
        // Tokens: ...expr..., identifier("is"), percentage(Y), keyword(.off), identifier("what")
        if isIdx + 3 < tokens.count,
           case .percentage(let pct) = tokens[isIdx + 1],
           case .keyword(.off) = tokens[isIdx + 2],
           case .identifier(let w1) = tokens[isIdx + 3], w1.lowercased() == "what" {
            let lhsTokens = Array(tokens[0..<isIdx])
            guard !lhsTokens.isEmpty else { return nil }
            var lhsParser = ExpressionParser(tokens: lhsTokens, definitions: definitions)
            guard let lhs = lhsParser.parseExpression(minPrecedence: 0) else { return nil }
            return .isPercentOffWhat(lhs, pct)
        }

        return nil
    }

    // MARK: - Between Patterns

    /// Matches "random [number] between X and Y", "midpoint between X and Y",
    /// and "UNIT between DATE and DATE" (e.g. "weeks between October 21 and December 2").
    private func tryBetweenPattern(_ tokens: [Token]) -> Expression? {
        guard tokens.count >= 4 else { return nil }
        guard case .identifier(let firstWord) = tokens[0] else { return nil }

        let lower = firstWord.lowercased()

        // Determine pattern type
        let isRandom = lower == "random"
        let isMidpoint = lower == "midpoint"
        let isTimeUnit: Bool = {
            if let (_, cat) = definitions.unitsByVariant[lower] {
                return cat.category == "time"
            }
            return false
        }()

        guard isRandom || isMidpoint || isTimeUnit else { return nil }

        // Find "between" — may be at index 1 or 2 (if "random number between")
        var betweenIdx: Int? = nil
        let searchLimit = min(3, tokens.count)
        for i in 1..<searchLimit {
            if case .identifier(let w) = tokens[i], w.lowercased() == "between" {
                betweenIdx = i
                break
            }
        }
        guard let bIdx = betweenIdx else { return nil }

        // Find "and" after "between"
        var andIdx: Int? = nil
        for i in (bIdx + 1)..<tokens.count {
            if case .identifier(let w) = tokens[i], w.lowercased() == "and" {
                andIdx = i
                break
            }
        }
        guard let aIdx = andIdx else { return nil }

        let lhsTokens = Array(tokens[(bIdx + 1)..<aIdx])
        let rhsTokens = Array(tokens[(aIdx + 1)...])
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return nil }

        var lhsParser = ExpressionParser(tokens: lhsTokens, definitions: definitions)
        var rhsParser = ExpressionParser(tokens: rhsTokens, definitions: definitions)
        guard let lhs = lhsParser.parseExpression(minPrecedence: 0),
              let rhs = rhsParser.parseExpression(minPrecedence: 0) else { return nil }

        if isRandom { return .randomBetween(lhs, rhs) }
        if isMidpoint { return .midpointBetween(lhs, rhs) }
        if isTimeUnit { return .unitBetweenDates(lower, lhs, rhs) }

        return nil
    }

    // MARK: - Date Range

    /// Matches "date TO date" patterns like "March 20 to June 5" or "today to tomorrow".
    private func tryDateRange(_ tokens: [Token]) -> Expression? {
        // Find keyword(.to) in the token stream
        var toIdx: Int? = nil
        for i in 0..<tokens.count {
            if case .keyword(.to) = tokens[i] {
                toIdx = i
                break
            }
        }
        guard let tIdx = toIdx, tIdx > 0, tIdx < tokens.count - 1 else { return nil }

        let lhsTokens = Array(tokens[0..<tIdx])
        let rhsTokens = Array(tokens[(tIdx + 1)...])

        // Both sides must contain date-like tokens (month names or date keywords)
        guard containsDatePattern(lhsTokens) && containsDatePattern(rhsTokens) else {
            return nil
        }

        var lhsParser = ExpressionParser(tokens: lhsTokens, definitions: definitions)
        var rhsParser = ExpressionParser(tokens: rhsTokens, definitions: definitions)
        guard let lhs = lhsParser.parseExpression(minPrecedence: 0),
              let rhs = rhsParser.parseExpression(minPrecedence: 0) else { return nil }

        return .dateRange(lhs, rhs)
    }

    /// Checks if a token sequence contains date-like elements (month names or date keywords).
    private func containsDatePattern(_ tokens: [Token]) -> Bool {
        for (i, token) in tokens.enumerated() {
            if case .identifier(let name) = token {
                let lower = name.lowercased()
                // Month name followed by a number (e.g. "March 20")
                if monthNumber(for: lower) != nil {
                    if i + 1 < tokens.count, case .number(let n) = tokens[i + 1], n >= 1, n <= 31 {
                        return true
                    }
                }
                // Special date keywords
                if lower == "today" || lower == "tomorrow" || lower == "yesterday" || lower == "now" {
                    return true
                }
            }
            // Number followed by month name (e.g. "10 June")
            if case .number(let n) = token, n >= 1, n <= 31 {
                if i + 1 < tokens.count, case .identifier(let name) = tokens[i + 1] {
                    if monthNumber(for: name) != nil { return true }
                }
            }
        }
        return false
    }

    // MARK: - Percentage Patterns

    /// Matches `percentage of/on/off expr` or `variable of/on/off expr` at the start.
    private func tryPercentagePattern(_ tokens: [Token]) -> Expression? {
        guard tokens.count >= 3 else { return nil }

        let keyword: Keyword
        switch tokens[1] {
        case .keyword(.of):  keyword = .of
        case .keyword(.on):  keyword = .on
        case .keyword(.off): keyword = .off
        default: return nil
        }

        let restTokens = Array(tokens.dropFirst(2))
        var parser = ExpressionParser(tokens: restTokens, definitions: definitions)
        guard let expr = parser.parseExpression(minPrecedence: 0) else { return nil }

        // Literal percentage: 20% of $150
        if case .percentage(let pct) = tokens[0] {
            switch keyword {
            case .of:  return .percentOf(pct, expr)
            case .on:  return .percentOn(pct, expr)
            case .off: return .percentOff(pct, expr)
            default:   return nil
            }
        }

        // Variable/expression-based: tax on price (where tax may be a percentage)
        if case .identifier(let name) = tokens[0] {
            let leftExpr = Expression.variableRef(name)
            switch keyword {
            case .of:  return .dynamicPercentOf(leftExpr, expr)
            case .on:  return .dynamicPercentOn(leftExpr, expr)
            case .off: return .dynamicPercentOff(leftExpr, expr)
            default:   return nil
            }
        }

        return nil
    }
}

// MARK: - Month Name Helpers (file-private)

/// Maps month names and abbreviations to their month number (1-12).
private let _monthNumbers: [String: Int] = [
    "january": 1, "jan": 1,
    "february": 2, "feb": 2,
    "march": 3, "mar": 3,
    "april": 4, "apr": 4,
    "may": 5,
    "june": 6, "jun": 6,
    "july": 7, "jul": 7,
    "august": 8, "aug": 8,
    "september": 9, "sep": 9, "sept": 9,
    "october": 10, "oct": 10,
    "november": 11, "nov": 11,
    "december": 12, "dec": 12,
]

/// Returns the month number (1-12) for a month name, or nil.
private func monthNumber(for name: String) -> Int? {
    _monthNumbers[name.lowercased()]
}

/// Creates a Date from a month and day, using the current year.
private func makeDateFromMonthDay(month: Int, day: Int) -> Date? {
    var components = Calendar.current.dateComponents([.year], from: Date())
    components.month = month
    components.day = day
    components.hour = 0
    components.minute = 0
    components.second = 0
    return Calendar.current.date(from: components)
}

// MARK: - ExpressionParser (Precedence Climbing)

/// A recursive-descent parser with precedence climbing for arithmetic expressions.
private struct ExpressionParser {
    private var tokens: [Token]
    private var pos: Int
    private let definitions: DefinitionLoader

    init(tokens: [Token], definitions: DefinitionLoader) {
        self.tokens = tokens
        self.pos = 0
        self.definitions = definitions
    }

    // MARK: - Token Access

    private var current: Token? {
        pos < tokens.count ? tokens[pos] : nil
    }

    private func peek(offset: Int = 0) -> Token? {
        let idx = pos + offset
        return idx < tokens.count ? tokens[idx] : nil
    }

    @discardableResult
    private mutating func advance() -> Token? {
        guard pos < tokens.count else { return nil }
        let tok = tokens[pos]
        pos += 1
        return tok
    }

    private var isAtEnd: Bool {
        pos >= tokens.count
    }

    // MARK: - Precedence Climbing

    /// Parse an expression with minimum precedence level.
    ///
    /// Precedence levels:
    ///  0 — additive: +, - (and keyword plus, minus)
    ///  1 — multiplicative: *, /, mod (and keyword times, divide)
    ///  2 — power: ^ (right-associative)
    ///  3 — bitwise: band, bor, bxor, lshift, rshift
    mutating func parseExpression(minPrecedence: Int) -> Expression? {
        guard var left = parseAtom() else { return nil }

        while let (op, prec, rightAssoc) = currentBinaryOp(), prec >= minPrecedence {
            advance() // consume operator token
            let nextMin = rightAssoc ? prec : prec + 1
            guard let right = parseExpression(minPrecedence: nextMin) else { return left }
            left = .arithmetic(left, op, right)
        }

        return left
    }

    /// Returns the operator, its precedence, and whether it is right-associative,
    /// if the current token is a binary operator or keyword equivalent.
    private func currentBinaryOp() -> (Operator, Int, Bool)? {
        guard let tok = current else { return nil }
        switch tok {
        // Additive
        case .op(.add):       return (.add, 0, false)
        case .op(.subtract):  return (.subtract, 0, false)
        case .keyword(.plus): return (.add, 0, false)
        case .keyword(.minus):return (.subtract, 0, false)
        // Multiplicative
        case .op(.multiply):  return (.multiply, 1, false)
        case .op(.divide):    return (.divide, 1, false)
        case .op(.mod):       return (.mod, 1, false)
        case .keyword(.times):return (.multiply, 1, false)
        case .keyword(.divide):return (.divide, 1, false)
        // Power (right-associative)
        case .op(.power):     return (.power, 2, true)
        // Bitwise
        case .op(.band):      return (.band, 3, false)
        case .op(.bor):       return (.bor, 3, false)
        case .op(.bxor):      return (.bxor, 3, false)
        case .op(.lshift):    return (.lshift, 3, false)
        case .op(.rshift):    return (.rshift, 3, false)
        default:              return nil
        }
    }

    // MARK: - Atom Parsing

    /// Parses a single atomic expression (literal, function call, variable,
    /// parenthesized expression, unary minus, or number+unit combo).
    private mutating func parseAtom() -> Expression? {
        guard let tok = current else { return nil }

        switch tok {

        // Unary minus
        case .op(.subtract):
            advance()
            guard let operand = parseAtom() else { return nil }
            return .unaryMinus(operand)

        // Number — possibly followed by a unit, currency, or month name
        case .number(let n):
            advance()
            if let unitExpr = tryNumberUnit(n) {
                return unitExpr
            }
            if let currencyExpr = tryNumberCurrency(n) {
                return currencyExpr
            }
            // Date pattern: "10 June" (number + month name)
            if let dateExpr = tryNumberMonth(n) {
                return dateExpr
            }
            return .literal(.number(n))

        // Currency
        case .currency(let amount, let code):
            advance()
            return .literal(.currency(amount, code))

        // Percentage (standalone)
        case .percentage(let pct):
            advance()
            return .literal(.percentage(pct))

        // Hex number
        case .hexNumber(let v):
            advance()
            return .literal(.number(Double(v)))

        // Binary number
        case .binaryNumber(let v):
            advance()
            return .literal(.number(Double(v)))

        // Octal number
        case .octalNumber(let v):
            advance()
            return .literal(.number(Double(v)))

        // Hex color
        case .hexColor(let hex):
            advance()
            return .literal(.color(.hex(hex)))

        // RGB color
        case .rgbColor(let r, let g, let b):
            advance()
            return .literal(.color(.rgb(r, g, b)))

        // String
        case .string(let s):
            advance()
            return .literal(.string(s))

        // Parenthesized expression
        case .leftParen:
            advance() // consume '('
            guard let inner = parseExpression(minPrecedence: 0) else { return nil }
            // consume ')'
            if case .rightParen = current {
                advance()
            }
            return inner

        // Line reference: @1
        case .lineRef(let n):
            advance()
            return .lineRef(n)

        // Identifier — could be function call, special token, month name, or variable ref
        case .identifier(let name):
            return parseIdentifier(name)

        default:
            // Skip unknown tokens
            advance()
            return nil
        }
    }

    // MARK: - Number + Unit Combo

    /// If the current token after consuming a number is a unit identifier,
    /// combine them into a `.literal(.unit(...))`.
    private mutating func tryNumberUnit(_ value: Double) -> Expression? {
        guard case .identifier(let name) = current else { return nil }
        let lower = name.lowercased()
        if let (unitDef, category) = definitions.unitsByVariant[lower] {
            advance() // consume the unit identifier
            return .literal(.unit(value, unitDef.id, category.category))
        }
        return nil
    }

    // MARK: - Number + Currency Combo

    /// If the current token after consuming a number is a currency variant name,
    /// combine them into a `.literal(.currency(...))`.
    /// Handles: `200yuan`, `200 usd`, `100 euros`
    private mutating func tryNumberCurrency(_ value: Double) -> Expression? {
        guard case .identifier(let name) = current else { return nil }
        let lower = name.lowercased()
        if let currencyDef = definitions.currencyByVariant[lower] {
            advance() // consume the currency identifier
            return .literal(.currency(value, currencyDef.code))
        }
        return nil
    }

    // MARK: - Number + Month Name (Date Literal)

    /// Matches "10 June" → Date literal.
    private mutating func tryNumberMonth(_ dayValue: Double) -> Expression? {
        guard dayValue >= 1, dayValue <= 31 else { return nil }
        guard case .identifier(let name) = current else { return nil }
        guard let month = monthNumber(for: name) else { return nil }
        advance() // consume month identifier
        if let date = makeDateFromMonthDay(month: month, day: Int(dayValue)) {
            return .literal(.date(date))
        }
        return nil
    }

    // MARK: - Identifier Resolution

    /// Resolves an identifier to a function call, special token, month-day date, or variable reference.
    private mutating func parseIdentifier(_ name: String) -> Expression? {
        let lower = name.lowercased()

        // Check if it's a month name followed by a day number: "March 19"
        if let month = monthNumber(for: lower) {
            if case .number(let day) = peek(offset: 1), day >= 1, day <= 31 {
                advance() // consume month identifier
                advance() // consume day number
                if let date = makeDateFromMonthDay(month: month, day: Int(day)) {
                    return .literal(.date(date))
                }
            }
        }

        // Check if it's a function call: identifier followed by '('
        if case .leftParen = peek(offset: 1) {
            // Check if it's a known function
            if definitions.functions.contains(lower) || definitions.functions.contains(name) {
                advance() // consume identifier
                advance() // consume '('
                var args: [Expression] = []
                while true {
                    if case .rightParen = current {
                        advance()
                        break
                    }
                    if isAtEnd { break }
                    if let arg = parseExpression(minPrecedence: 0) {
                        args.append(arg)
                    }
                    // Skip commas between arguments (if present)
                    // Commas aren't currently a token type, but future-proof
                }
                return .functionCall(name, args)
            }
        }

        // Check if it's a special token (standalone identifier)
        if let special = SpecialToken(rawValue: lower) {
            advance()
            return .specialToken(special)
        }

        // Otherwise, it's a variable reference
        advance()
        return .variableRef(name)
    }
}
