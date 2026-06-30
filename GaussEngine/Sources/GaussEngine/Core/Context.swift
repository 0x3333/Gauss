import Foundation

/// Stores variables, line results, and provides aggregate values (prev, sum, avg)
/// for the evaluator to reference during expression evaluation.
public final class Context {
    /// User-defined variables (case-insensitive keys).
    private var variableStore: [String: Value] = [:]

    /// Set a variable (case-insensitive).
    public func setVariable(_ name: String, _ value: Value) {
        variableStore[name.lowercased()] = value
    }

    /// Get a variable (case-insensitive).
    public func getVariable(_ name: String) -> Value? {
        variableStore[name.lowercased()]
    }

    /// Results for each line index.
    public var lineResults: [Int: Value] = [:]

    /// The index of the line currently being evaluated.
    public var currentLineIndex: Int = 0

    public init() {}

    /// The result of the previous line (currentLineIndex - 1), or nil if none.
    public var prev: Value? {
        lineResults[currentLineIndex - 1]
    }

    /// Sum all numeric values in lineResults for indices 0..<currentLineIndex.
    /// Numbers are summed together. Currencies of the same code are summed.
    /// Incompatible types are silently excluded.
    public var sum: Value {
        let indices = (0..<currentLineIndex).filter { lineResults[$0] != nil }
        guard !indices.isEmpty else { return .number(0) }

        var numericSum: Double = 0
        var currencySums: [String: Double] = [:]
        var hasNumeric = false
        var hasCurrency = false

        for i in indices {
            guard let val = lineResults[i] else { continue }
            switch val {
            case .number(let v):
                numericSum += v
                hasNumeric = true
            case .currency(let v, let code):
                currencySums[code, default: 0] += v
                hasCurrency = true
            case .unit(let v, _, _):
                numericSum += v
                hasNumeric = true
            case .percentage:
                // Percentages are not summable amounts — skip them
                break
            default:
                break
            }
        }

        // If we only have currency of a single type, return that
        if hasCurrency && !hasNumeric && currencySums.count == 1 {
            let (code, amount) = currencySums.first!
            return .currency(amount, code)
        }

        // If we have only numbers (and possibly compatible types), return number
        if hasNumeric && !hasCurrency {
            return .number(numericSum)
        }

        // Mixed: just sum everything numerically
        let totalCurrency = currencySums.values.reduce(0, +)
        return .number(numericSum + totalCurrency)
    }

    /// Average of all summable values for indices 0..<currentLineIndex.
    public var avg: Value {
        let indices = (0..<currentLineIndex).filter { lineResults[$0] != nil }
        guard !indices.isEmpty else { return .number(0) }

        var values: [Double] = []
        var currencyCode: String?
        var allSameCurrency = true

        for i in indices {
            guard let val = lineResults[i] else { continue }
            switch val {
            case .number(let v):
                values.append(v)
                allSameCurrency = false
            case .currency(let v, let code):
                values.append(v)
                if let existing = currencyCode {
                    if existing != code { allSameCurrency = false }
                } else {
                    currencyCode = code
                }
            case .unit(let v, _, _):
                values.append(v)
                allSameCurrency = false
            case .percentage(let v):
                values.append(v)
                allSameCurrency = false
            default:
                break
            }
        }

        guard !values.isEmpty else { return .number(0) }
        let average = values.reduce(0, +) / Double(values.count)

        if allSameCurrency, let code = currencyCode {
            return .currency(average, code)
        }
        return .number(average)
    }

    /// Clears all state.
    public func reset() {
        variableStore.removeAll()
        lineResults.removeAll()
        currentLineIndex = 0
    }
}
