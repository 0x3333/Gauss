import Foundation

public struct ValueFormatter {
    private let definitions: DefinitionLoader?

    /// Maximum number of decimal places for formatted numbers (default 2).
    /// Set from the app's Settings manager.
    public var maxDecimalPlaces: Int = 2

    /// Date format string used when formatting date values (default "MMM d, yyyy").
    /// Set from the app's Settings manager.
    public var dateFormatString: String = "MMM d, yyyy"

    public init(definitions: DefinitionLoader? = nil) {
        self.definitions = definitions
    }

    public func format(_ value: Value) -> String {
        switch value {
        case .number(let n):
            return formatNumber(n)
        case .currency(let amount, let code):
            return formatCurrency(amount, code: code)
        case .unit(let amount, let unitId, _):
            // Look up the unit's format string from definitions
            let displayId = unitFormatString(unitId: unitId)
            return "\(formatNumber(amount)) \(displayId)"
        case .date(let date):
            return formatDate(date)
        case .duration(let amount, let unit):
            // Use plural/singular for common time units
            let displayUnit = formatTimeUnit(amount, unit: unit)
            return "\(formatNumber(amount)) \(displayUnit)"
        case .dateDifference(let months, let weeks, let days):
            return formatDateDifference(months: months, weeks: weeks, days: days)
        case .color(let colorValue):
            return formatColor(colorValue)
        case .string(let s):
            return s
        case .percentage(let p):
            return "\(formatNumber(p)) %"
        case .undefined:
            return ""
        case .infinity(let negative):
            return negative ? "-∞" : "∞"
        case .circular:
            return "circular"
        }
    }

    // MARK: - Unit Format Lookup

    /// Returns the display format string for a unit id, falling back to the id itself.
    private func unitFormatString(unitId: String) -> String {
        guard let defs = definitions else { return unitId }
        for category in defs.unitCategories {
            for unit in category.units {
                if unit.id == unitId {
                    return unit.format
                }
            }
        }
        return unitId
    }

    // MARK: - Number Formatting

    private func formatNumber(_ n: Double) -> String {
        if n == n.rounded() && abs(n) < 1e15 {
            // Integer — no decimal point
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.decimalSeparator = "."
            return formatter.string(from: NSNumber(value: n)) ?? String(Int(n))
        }
        // Decimal — up to maxDecimalPlaces digits, trim trailing zeros
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maxDecimalPlaces
        formatter.minimumFractionDigits = 0  // trim trailing zeros
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }

    // MARK: - Currency Formatting

    private func formatCurrency(_ amount: Double, code: String) -> String {
        let symbol = currencySymbol(for: code)
        if amount == amount.rounded() && abs(amount) < 1e15 {
            // Integer amount — no decimals (strip .00)
            return "\(symbol)\(formatWithCommas(Int(amount)))"
        }
        // Up to 2 decimal places, keep trailing zeros in tenths (e.g., $7.30 stays $7.30)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(amount)
        let result = "\(symbol)\(formatted)"
        // Strip trailing .00 but keep .30, .31 etc.
        if result.hasSuffix(".00") {
            return String(result.dropLast(3))
        }
        return result
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormatString
        return formatter.string(from: date)
    }

    // MARK: - Color Formatting

    private func formatColor(_ colorValue: ColorValue) -> String {
        switch colorValue {
        case .hex(let hex):
            return "#\(hex.uppercased())"
        case .rgb(let r, let g, let b):
            return "rgb(\(r), \(g), \(b))"
        case .hsl(let h, let s, let l):
            return "hsl(\(h), \(Int(s * 100))%, \(Int(l * 100))%)"
        }
    }

    // MARK: - Date Difference Formatting

    private func formatDateDifference(months: Int, weeks: Int, days: Int) -> String {
        var parts: [String] = []
        if months > 0 {
            parts.append("\(months) \(months == 1 ? "month" : "months")")
        }
        if weeks > 0 {
            parts.append("\(weeks) \(weeks == 1 ? "week" : "weeks")")
        }
        if days > 0 {
            parts.append("\(days) \(days == 1 ? "day" : "days")")
        }
        if parts.isEmpty {
            return "0 days"
        }
        return parts.joined(separator: " ")
    }

    /// Returns a human-readable unit string with singular/plural for durations.
    private func formatTimeUnit(_ amount: Double, unit: String) -> String {
        let singular = amount == 1
        switch unit {
        case "wk":    return singular ? "week" : "weeks"
        case "day":   return singular ? "day" : "days"
        case "mo":    return singular ? "month" : "months"
        case "yr":    return singular ? "year" : "years"
        case "hr":    return singular ? "hour" : "hours"
        case "min":   return singular ? "minute" : "minutes"
        case "s":     return singular ? "second" : "seconds"
        case "workday": return singular ? "workday" : "workdays"
        default:      return unit
        }
    }

    // MARK: - Helpers

    private func currencySymbol(for code: String) -> String {
        // Look up symbol from definitions first
        if let defs = definitions,
           let currencyDef = defs.currencyByCode[code.uppercased()] {
            return currencyDef.symbol
        }
        // Fallback to common symbols
        switch code.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "¥"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "CHF": return "Fr"
        case "HKD": return "HK$"
        case "SGD": return "S$"
        case "KRW": return "₩"
        case "TWD": return "NT$"
        case "INR": return "₹"
        case "BRL": return "R$"
        case "MXN": return "MX$"
        default: return code
        }
    }

    private func formatWithCommas(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: n)) ?? String(n)
    }
}
