import Foundation

/// The result value of an evaluated expression.
public enum Value: Equatable {
    case number(Double)
    case currency(Double, String)           // amount, currency code
    case unit(Double, String, String)       // amount, unit ID, category
    case date(Date)
    case duration(Double, String)           // amount, time unit
    case color(ColorValue)
    case string(String)                     // for base64 results etc.
    case percentage(Double)
    case dateDifference(Int, Int, Int)     // months, weeks, days
    case undefined
    case infinity(Bool)                     // isNegative
    case circular
}

public extension Value {
    /// Extracts the underlying Double for numeric variants.
    /// Returns nil for date, color, string, undefined, infinity, and circular.
    var numericValue: Double? {
        switch self {
        case .number(let v):
            return v
        case .currency(let v, _):
            return v
        case .unit(let v, _, _):
            return v
        case .percentage(let v):
            return v
        case .duration(let v, _):
            return v
        case .date, .dateDifference, .color, .string, .undefined, .infinity, .circular:
            return nil
        }
    }

    /// True when the value carries a numeric magnitude.
    var isNumeric: Bool {
        numericValue != nil
    }
}

/// A color value in one of several representations.
public enum ColorValue: Equatable {
    case hex(String)                        // "FF5733"
    case rgb(Int, Int, Int)
    case hsl(Int, Double, Double)           // hue, saturation%, lightness%
}
