import Foundation

/// Converts values between units within the same category using definitions
/// loaded from units.json.
public struct UnitConverter {
    private let definitions: DefinitionLoader

    public init(definitions: DefinitionLoader) {
        self.definitions = definitions
    }

    /// Convert a value from one unit to another within the same category.
    ///
    /// - Parameters:
    ///   - value: The numeric value to convert.
    ///   - fromUnitId: The canonical id of the source unit (e.g., "inch").
    ///   - toVariant: A variant string for the target unit (e.g., "cm").
    /// - Returns: A tuple of (convertedValue, targetUnitId, categoryName) or nil if incompatible.
    public func convert(_ value: Double, fromUnitId: String, toVariant: String) -> (Double, String, String)? {
        // 1. Find source unit and its category
        guard let (fromUnit, fromCategory) = findUnit(byId: fromUnitId) else { return nil }

        // 2. Find target unit — try variant lookup first (case-insensitive)
        let targetLower = toVariant.lowercased()
        guard let (toUnit, toCategory) = definitions.unitsByVariant[targetLower] else { return nil }

        // 3. Must be in the same category
        guard fromCategory.category == toCategory.category else { return nil }

        // 4. Convert: source → base → target
        let baseValue = convertToBase(value: value, unit: fromUnit)
        let result = convertFromBase(value: baseValue, unit: toUnit)

        return (result, toUnit.id, fromCategory.category)
    }

    // MARK: - Private Helpers

    /// Find a unit by its canonical id across all categories.
    private func findUnit(byId id: String) -> (UnitDefinition, UnitCategory)? {
        for category in definitions.unitCategories {
            for unit in category.units {
                if unit.id == id {
                    return (unit, category)
                }
            }
        }
        return nil
    }

    /// Convert a value to the base unit of its category.
    private func convertToBase(value: Double, unit: UnitDefinition) -> Double {
        if let toBase = unit.toBase {
            return value * toBase
        }
        if let formula = unit.toBaseFormula {
            return evaluateFormula(formula, value: value)
        }
        return value
    }

    /// Convert a value from the base unit to the target unit.
    private func convertFromBase(value: Double, unit: UnitDefinition) -> Double {
        if let toBase = unit.toBase {
            return value / toBase
        }
        if let formula = unit.fromBaseFormula {
            return evaluateFormula(formula, value: value)
        }
        return value
    }

    /// Evaluate a simple formula string, replacing "value" with the given number.
    /// Supports: +, -, *, /, parentheses, and numeric literals.
    private func evaluateFormula(_ formula: String, value: Double) -> Double {
        // Replace "value" with the actual number and evaluate
        // We use a simple recursive descent parser for safety
        let substituted = formula.replacingOccurrences(of: "value", with: String(value))
        var parser = FormulaParser(input: substituted)
        return parser.parseExpression()
    }
}

// MARK: - Simple Formula Parser

/// A minimal expression parser for unit conversion formulas.
/// Supports: +, -, *, /, parentheses, and decimal numbers (including negative).
private struct FormulaParser {
    private let chars: [Character]
    private var pos: Int

    init(input: String) {
        self.chars = Array(input)
        self.pos = 0
    }

    // MARK: - Parsing

    mutating func parseExpression() -> Double {
        var result = parseTerm()
        skipWhitespace()
        while pos < chars.count {
            skipWhitespace()
            guard pos < chars.count else { break }
            if chars[pos] == "+" {
                pos += 1
                result += parseTerm()
            } else if chars[pos] == "-" {
                pos += 1
                result -= parseTerm()
            } else {
                break
            }
        }
        return result
    }

    private mutating func parseTerm() -> Double {
        var result = parseFactor()
        skipWhitespace()
        while pos < chars.count {
            skipWhitespace()
            guard pos < chars.count else { break }
            if chars[pos] == "*" {
                pos += 1
                result *= parseFactor()
            } else if chars[pos] == "/" {
                pos += 1
                let divisor = parseFactor()
                if divisor != 0 { result /= divisor }
            } else {
                break
            }
        }
        return result
    }

    private mutating func parseFactor() -> Double {
        skipWhitespace()
        guard pos < chars.count else { return 0 }

        // Unary minus
        if chars[pos] == "-" {
            pos += 1
            return -parseFactor()
        }

        // Parenthesized expression
        if chars[pos] == "(" {
            pos += 1 // consume '('
            let result = parseExpression()
            skipWhitespace()
            if pos < chars.count && chars[pos] == ")" {
                pos += 1 // consume ')'
            }
            return result
        }

        // Number
        return parseNumber()
    }

    private mutating func parseNumber() -> Double {
        skipWhitespace()
        var str = ""
        // Optional leading minus already handled by parseFactor

        while pos < chars.count && (chars[pos].isNumber || chars[pos] == "." || chars[pos] == "e" || chars[pos] == "E"
            || ((chars[pos] == "-" || chars[pos] == "+") && !str.isEmpty && (str.last == "e" || str.last == "E"))) {
            str.append(chars[pos])
            pos += 1
        }
        return Double(str) ?? 0
    }

    private mutating func skipWhitespace() {
        while pos < chars.count && chars[pos].isWhitespace {
            pos += 1
        }
    }
}
