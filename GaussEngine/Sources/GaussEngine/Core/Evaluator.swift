import Foundation

/// Computes a ``Value`` result from an ``Expression`` AST node.
///
/// This is the third and final stage of the GaussEngine pipeline:
///   raw string -> Tokenizer -> [Token] -> Matcher -> Expression -> **Evaluator** -> Value
public struct Evaluator {
    private let definitions: DefinitionLoader
    private let unitConverter: UnitConverter
    private let currencyConverter: CurrencyConverter
    private let colorConverter: ColorConverter
    private let base64Converter: Base64Converter
    private let timestampConverter: TimestampConverter

    public init(definitions: DefinitionLoader, currencyConverter: CurrencyConverter = CurrencyConverter()) {
        self.definitions = definitions
        self.unitConverter = UnitConverter(definitions: definitions)
        self.currencyConverter = currencyConverter
        self.colorConverter = ColorConverter()
        self.base64Converter = Base64Converter()
        self.timestampConverter = TimestampConverter()
    }

    /// Evaluate an expression AST node in the given context, producing a Value.
    public func evaluate(_ expression: Expression, context: Context) -> Value {
        switch expression {
        case .literal(let value):
            return value

        case .arithmetic(let left, let op, let right):
            let l = evaluate(left, context: context)
            let r = evaluate(right, context: context)
            return evaluateArithmetic(l, op, r)

        case .unaryMinus(let expr):
            let val = evaluate(expr, context: context)
            return negateValue(val)

        case .assignment(let name, let expr):
            let value = evaluate(expr, context: context)
            context.setVariable(name, value)
            return value

        case .compoundAssignment(let name, let op, let expr):
            let current = context.getVariable(name) ?? .number(0)
            let delta = evaluate(expr, context: context)
            let result = evaluateArithmetic(current, op, delta)
            context.setVariable(name, result)
            return result

        case .percentOf(let pct, let expr):
            let base = evaluate(expr, context: context)
            return applyPercent(pct / 100.0, to: base, mode: .of)

        case .percentOn(let pct, let expr):
            let base = evaluate(expr, context: context)
            return applyPercent(pct / 100.0, to: base, mode: .on)

        case .percentOff(let pct, let expr):
            let base = evaluate(expr, context: context)
            return applyPercent(pct / 100.0, to: base, mode: .off)

        case .conversion(let expr, let target):
            let source = evaluate(expr, context: context)
            return convert(source, to: target)

        case .functionCall(let name, let args):
            let evaluatedArgs = args.map { evaluate($0, context: context) }
            return evaluateFunction(name, args: evaluatedArgs)

        case .variableRef(let name):
            return context.getVariable(name) ?? .undefined

        case .lineRef(let n):
            guard n >= 1 else { return .undefined }
            let targetIndex = n - 1
            if targetIndex == context.currentLineIndex {
                return .circular
            }
            return context.lineResults[targetIndex] ?? .undefined

        case .specialToken(let token):
            switch token {
            case .sum, .total:
                return context.sum
            case .avg, .average:
                return context.avg
            case .prev:
                return context.prev ?? .undefined
            case .today:
                return .date(Calendar.current.startOfDay(for: Date()))
            case .tomorrow:
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                return .date(Calendar.current.startOfDay(for: tomorrow))
            case .yesterday:
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                return .date(Calendar.current.startOfDay(for: yesterday))
            case .now:
                return .date(Date())
            }

        case .percentOfWhatIs(let pct, let expr):
            // X% of what is Y -> Y / (X/100)
            let val = evaluate(expr, context: context)
            guard let n = val.numericValue, pct != 0 else { return .undefined }
            let result = n / (pct / 100.0)
            return preserveType(result, from: val)

        case .whatPercentOf(let xExpr, let yExpr):
            // X is what % of Y -> (X / Y) * 100
            let xVal = evaluate(xExpr, context: context)
            let yVal = evaluate(yExpr, context: context)
            guard let x = xVal.numericValue, let y = yVal.numericValue, y != 0 else { return .undefined }
            return .percentage(x / y * 100.0)

        case .isPercentOffWhat(let resultExpr, let pct):
            // X is Y% off what -> X / (1 - Y/100)
            let val = evaluate(resultExpr, context: context)
            guard let n = val.numericValue else { return .undefined }
            let divisor = 1.0 - pct / 100.0
            guard divisor != 0 else { return .undefined }
            let result = n / divisor
            return preserveType(result, from: val)

        case .randomBetween(let lowExpr, let highExpr):
            let lowVal = evaluate(lowExpr, context: context)
            let highVal = evaluate(highExpr, context: context)
            guard let low = lowVal.numericValue, let high = highVal.numericValue else { return .undefined }
            let lo = Int(min(low, high))
            let hi = Int(max(low, high))
            guard lo <= hi else { return .undefined }
            return .number(Double(Int.random(in: lo...hi)))

        case .midpointBetween(let aExpr, let bExpr):
            let aVal = evaluate(aExpr, context: context)
            let bVal = evaluate(bExpr, context: context)
            guard let a = aVal.numericValue, let b = bVal.numericValue else { return .undefined }
            let result = (a + b) / 2.0
            return preserveType(result, from: aVal)

        case .dateRange(let startExpr, let endExpr):
            let startVal = evaluate(startExpr, context: context)
            let endVal = evaluate(endExpr, context: context)
            guard case .date(let startDate) = startVal,
                  case .date(let endDate) = endVal else { return .undefined }
            return computeDateDifference(from: startDate, to: endDate)

        case .unitBetweenDates(let unitName, let aExpr, let bExpr):
            let aVal = evaluate(aExpr, context: context)
            let bVal = evaluate(bExpr, context: context)
            guard case .date(let dateA) = aVal,
                  case .date(let dateB) = bVal else { return .undefined }
            return computeUnitBetween(unitName: unitName, from: dateA, to: dateB)

        // Dynamic percentage: variable-based (e.g., "tax on price" where tax = 8.5%)
        case .dynamicPercentOf(let pctExpr, let baseExpr):
            let pctVal = evaluate(pctExpr, context: context)
            let baseVal = evaluate(baseExpr, context: context)
            guard let pct = pctVal.numericValue, let base = baseVal.numericValue else { return .undefined }
            return preserveType(base * pct / 100.0, from: baseVal)

        case .dynamicPercentOn(let pctExpr, let baseExpr):
            let pctVal = evaluate(pctExpr, context: context)
            let baseVal = evaluate(baseExpr, context: context)
            guard let pct = pctVal.numericValue, let base = baseVal.numericValue else { return .undefined }
            return preserveType(base * (1 + pct / 100.0), from: baseVal)

        case .dynamicPercentOff(let pctExpr, let baseExpr):
            let pctVal = evaluate(pctExpr, context: context)
            let baseVal = evaluate(baseExpr, context: context)
            guard let pct = pctVal.numericValue, let base = baseVal.numericValue else { return .undefined }
            return preserveType(base * (1 - pct / 100.0), from: baseVal)
        }
    }

    // MARK: - Arithmetic

    /// Evaluate a binary arithmetic operation on two values.
    private func evaluateArithmetic(_ left: Value, _ op: Operator, _ right: Value) -> Value {
        // Check division by zero first
        if op == .divide, let r = right.numericValue, r == 0 {
            if let l = left.numericValue {
                return .infinity(l < 0)
            }
            return .infinity(false)
        }

        switch (left, right) {

        // number op number
        case (.number(let l), .number(let r)):
            return wrapResult(applyOp(l, op, r))

        // currency op currency (same code)
        case (.currency(let l, let lCode), .currency(let r, let rCode)):
            if lCode == rCode {
                return wrapResult(applyOp(l, op, r), asCurrency: lCode)
            }
            return wrapResult(applyOp(l, op, r), asCurrency: lCode)

        // currency op number
        case (.currency(let l, let code), .number(let r)):
            return wrapResult(applyOp(l, op, r), asCurrency: code)

        // number op currency
        case (.number(let l), .currency(let r, let code)):
            return wrapResult(applyOp(l, op, r), asCurrency: code)

        // unit op unit (same category)
        case (.unit(let l, let lId, let lCat), .unit(let r, _, let rCat)):
            if lCat == rCat {
                return wrapResult(applyOp(l, op, r), asUnit: lId, category: lCat)
            }
            return wrapResult(applyOp(l, op, r))

        // unit op number
        case (.unit(let l, let id, let cat), .number(let r)):
            return wrapResult(applyOp(l, op, r), asUnit: id, category: cat)

        // number op unit
        case (.number(let l), .unit(let r, let id, let cat)):
            return wrapResult(applyOp(l, op, r), asUnit: id, category: cat)

        // number/currency +/- percentage → percentage of the number
        // e.g., 45 - 20% = 45 * (1 - 0.20) = 36
        //        45 + 20% = 45 * (1 + 0.20) = 54
        //        45 * 20% = 45 * 0.20 = 9
        //        45 / 20% = 45 / 0.20 = 225
        case (.number(let l), .percentage(let r)):
            return .number(applyPercentArithmetic(l, op, r))
        case (.percentage(let l), .number(let r)):
            if op == .multiply || op == .divide {
                return .number(applyPercentArithmetic(r, op, l))
            }
            return .percentage(applyOp(l, op, r))
        case (.currency(let l, let code), .percentage(let r)):
            return .currency(applyPercentArithmetic(l, op, r), code)
        case (.percentage(let l), .currency(let r, let code)):
            if op == .multiply || op == .divide {
                return .currency(applyPercentArithmetic(r, op, l), code)
            }
            return .currency(applyOp(l, op, r), code)
        case (.unit(let l, let id, let cat), .percentage(let r)):
            return .unit(applyPercentArithmetic(l, op, r), id, cat)

        // date + time unit  or  date - time unit
        case (.date(let d), .unit(let v, let unitId, let cat)) where cat == "time":
            // Special handling for workdays (skip weekends)
            if unitId == "workday" {
                if op == .add {
                    return .date(addWorkdays(Int(v), to: d))
                } else if op == .subtract {
                    return .date(addWorkdays(-Int(v), to: d))
                }
                return .undefined
            }
            let seconds = secondsFromTimeUnit(v, unitId: unitId)
            if op == .add {
                let newDate = d.addingTimeInterval(seconds)
                return .date(newDate)
            } else if op == .subtract {
                let newDate = d.addingTimeInterval(-seconds)
                return .date(newDate)
            }
            return .undefined

        // date + number (treated as days)
        case (.date(let d), .number(let days)):
            let seconds = days * 86400
            if op == .add {
                return .date(d.addingTimeInterval(seconds))
            } else if op == .subtract {
                return .date(d.addingTimeInterval(-seconds))
            }
            return .undefined

        // date - date = number of days
        case (.date(let d1), .date(let d2)):
            if op == .subtract {
                let diff = d1.timeIntervalSince(d2)
                return .number(diff / 86400)
            }
            return .undefined

        // infinity handling
        case (.infinity, _), (_, .infinity):
            return handleInfinityArithmetic(left, op, right)

        default:
            // Try numeric fallback
            if let l = left.numericValue, let r = right.numericValue {
                return wrapResult(applyOp(l, op, r))
            }
            return .undefined
        }
    }

    /// Wrap a Double result, converting infinity to .infinity(Bool).
    private func wrapResult(_ result: Double) -> Value {
        if result == .infinity { return .infinity(false) }
        if result == -.infinity { return .infinity(true) }
        return .number(result)
    }

    private func wrapResult(_ result: Double, asCurrency code: String) -> Value {
        if result == .infinity { return .infinity(false) }
        if result == -.infinity { return .infinity(true) }
        return .currency(result, code)
    }

    private func wrapResult(_ result: Double, asUnit id: String, category: String) -> Value {
        if result == .infinity { return .infinity(false) }
        if result == -.infinity { return .infinity(true) }
        return .unit(result, id, category)
    }

    /// Apply a binary operator to two Doubles. Returns the result or infinity for division by zero.
    /// Apply percentage in arithmetic context:
    /// base + pct% = base * (1 + pct/100)
    /// base - pct% = base * (1 - pct/100)
    /// base * pct% = base * pct/100
    /// base / pct% = base / (pct/100)
    private func applyPercentArithmetic(_ base: Double, _ op: Operator, _ pct: Double) -> Double {
        let fraction = pct / 100.0
        switch op {
        case .add:
            return base * (1 + fraction)
        case .subtract:
            return base * (1 - fraction)
        case .multiply:
            return base * fraction
        case .divide:
            guard fraction != 0 else { return base >= 0 ? Double.infinity : -Double.infinity }
            return base / fraction
        default:
            return applyOp(base, op, pct)
        }
    }

    private func applyOp(_ l: Double, _ op: Operator, _ r: Double) -> Double {
        switch op {
        case .add:
            return l + r
        case .subtract:
            return l - r
        case .multiply:
            return l * r
        case .divide:
            guard r != 0 else {
                // Will be handled by the caller for proper infinity wrapping
                return l >= 0 ? Double.infinity : -Double.infinity
            }
            return l / r
        case .power:
            return pow(l, r)
        case .mod:
            guard r != 0 else { return .nan }
            return l.truncatingRemainder(dividingBy: r)
        case .band:
            return Double(Int(l) & Int(r))
        case .bor:
            return Double(Int(l) | Int(r))
        case .bxor:
            return Double(Int(l) ^ Int(r))
        case .lshift:
            return Double(Int(l) << Int(r))
        case .rshift:
            return Double(Int(l) >> Int(r))
        }
    }

    /// Handle infinity in arithmetic. Simplified handling.
    private func handleInfinityArithmetic(_ left: Value, _ op: Operator, _ right: Value) -> Value {
        // Basic infinity propagation
        switch (left, right) {
        case (.infinity(let neg), _):
            if op == .multiply || op == .divide {
                if let r = right.numericValue, r < 0 { return .infinity(!neg) }
            }
            return .infinity(neg)
        case (_, .infinity(let neg)):
            if op == .multiply {
                if let l = left.numericValue, l < 0 { return .infinity(!neg) }
            }
            return .infinity(neg)
        default:
            return .infinity(false)
        }
    }

    // MARK: - Negation

    /// Negate a value.
    private func negateValue(_ val: Value) -> Value {
        switch val {
        case .number(let v):
            return .number(-v)
        case .currency(let v, let code):
            return .currency(-v, code)
        case .unit(let v, let id, let cat):
            return .unit(-v, id, cat)
        case .percentage(let v):
            return .percentage(-v)
        case .infinity(let isNeg):
            return .infinity(!isNeg)
        default:
            return val
        }
    }

    // MARK: - Percentage Application

    private enum PercentMode {
        case of   // X% of Y -> Y * X
        case on   // X% on Y -> Y + Y * X
        case off  // X% off Y -> Y - Y * X
    }

    private func applyPercent(_ fraction: Double, to base: Value, mode: PercentMode) -> Value {
        guard let baseNum = base.numericValue else { return .undefined }

        let amount = baseNum * fraction
        let result: Double
        switch mode {
        case .of:
            result = amount
        case .on:
            result = baseNum + amount
        case .off:
            result = baseNum - amount
        }

        return preserveType(result, from: base)
    }

    // MARK: - Type Preservation

    /// Creates a new Value with the given numeric result, preserving the type of the source.
    private func preserveType(_ result: Double, from source: Value) -> Value {
        switch source {
        case .currency(_, let code):
            return .currency(result, code)
        case .unit(_, let id, let cat):
            return .unit(result, id, cat)
        default:
            return .number(result)
        }
    }

    // MARK: - Conversion

    /// Convert a source value to a target unit or currency.
    private func convert(_ source: Value, to target: String) -> Value {
        let targetUpper = target.uppercased()
        let targetLower = target.lowercased()

        switch source {
        // Currency conversion: $100 in EUR / $9 in Euro
        case .currency(let amount, let fromCode):
            // Resolve target to a currency code: check direct code match first,
            // then fall back to variant lookup (handles "Euro", "euro", "euros", etc.)
            let resolvedCode: String?
            if definitions.currencyByCode[targetUpper] != nil {
                resolvedCode = targetUpper
            } else if let currencyDef = definitions.currencyByVariant[targetLower] {
                resolvedCode = currencyDef.code
            } else {
                resolvedCode = nil
            }
            if let toCode = resolvedCode {
                if let converted = currencyConverter.convert(amount, from: fromCode, to: toCode) {
                    return .currency(converted, toCode)
                }
            }
            return .undefined

        // Unit conversion: 5 inches in cm
        case .unit(let value, let fromId, _):
            if let (convertedVal, toId, category) = unitConverter.convert(value, fromUnitId: fromId, toVariant: target) {
                return .unit(convertedVal, toId, category)
            }
            return .undefined

        // Plain number — timestamp to date conversion, scientific notation
        case .number(let n):
            if targetLower == "date" || targetLower == "datetime" {
                let date = timestampConverter.toDate(n)
                return .date(date)
            }
            if targetLower == "sci" || targetLower == "scientific" {
                // Format as scientific notation string
                let formatted = String(format: "%e", n)
                return .string(formatted)
            }
            // Try to interpret as unit conversion if target is a known unit
            if let (_, _) = definitions.unitsByVariant[targetLower] {
                // This would need a source unit context — just return undefined
                return .undefined
            }
            // Try currency conversion
            if let _ = definitions.currencyByCode[targetUpper] {
                return .undefined
            }
            return .undefined

        // Color conversion
        case .color(let colorValue):
            switch targetLower {
            case "rgb":
                if let result = colorConverter.toRgb(colorValue) {
                    return .color(result)
                }
                return .undefined
            case "hex":
                if let result = colorConverter.toHex(colorValue) {
                    return .color(result)
                }
                return .undefined
            case "hsl":
                if let result = colorConverter.toHsl(colorValue) {
                    return .color(result)
                }
                return .undefined
            default:
                return .undefined
            }

        // String conversions: base64 encode, and date from unix
        case .string(let s):
            switch targetLower {
            case "base64":
                if let encoded = base64Converter.encode(s) {
                    return .string(encoded)
                }
                return .undefined
            case "frombase64", "decoded":
                if let decoded = base64Converter.decode(s) {
                    return .string(decoded)
                }
                return .undefined
            default:
                return .undefined
            }

        // Date to unix timestamp
        case .date(let d):
            if targetLower == "unix" || targetLower == "timestamp" {
                let ts = timestampConverter.toUnix(d)
                return .number(ts)
            }
            return .undefined

        default:
            return .undefined
        }
    }

    // MARK: - Function Evaluation

    /// Evaluate a built-in math function.
    private func evaluateFunction(_ name: String, args: [Value]) -> Value {
        guard let first = args.first, let x = first.numericValue else { return .undefined }
        let lowerName = name.lowercased()

        switch lowerName {
        // Trigonometric
        case "sin":
            return .number(sin(x))
        case "cos":
            return .number(cos(x))
        case "tan":
            return .number(tan(x))
        case "asin":
            return .number(asin(x))
        case "acos":
            return .number(acos(x))
        case "atan":
            return .number(atan(x))

        // Hyperbolic
        case "sinh":
            return .number(sinh(x))
        case "cosh":
            return .number(cosh(x))
        case "tanh":
            return .number(tanh(x))

        // Root
        case "sqrt":
            return .number(sqrt(x))
        case "cbrt":
            return .number(cbrt(x))

        // Logarithm
        case "log":
            return .number(log10(x))
        case "ln":
            return .number(Foundation.log(x))

        // Rounding
        case "abs":
            return .number(abs(x))
        case "ceil":
            return .number(ceil(x))
        case "floor":
            return .number(floor(x))
        case "round":
            return .number(Foundation.round(x))

        // Factorial
        case "fact":
            return .number(factorial(Int(x)))

        // Root with two args: root(n, x) = x^(1/n)
        case "root":
            if args.count >= 2, let n = args[0].numericValue, let val = args[1].numericValue, n != 0 {
                return .number(pow(val, 1.0 / n))
            }
            // Single arg: same as sqrt
            return .number(sqrt(x))

        default:
            return .undefined
        }
    }

    /// Convert a time-unit value to seconds for date arithmetic.
    /// Uses the unit's toBase factor from definitions (time base = seconds).
    private func secondsFromTimeUnit(_ value: Double, unitId: String) -> TimeInterval {
        // Time category base unit is seconds; toBase gives factor relative to seconds.
        for category in definitions.unitCategories {
            if category.category == "time" {
                for unit in category.units {
                    if unit.id == unitId {
                        if let factor = unit.toBase {
                            return value * factor
                        }
                    }
                }
            }
        }
        // Fallback: assume days
        return value * 86400
    }

    /// Compute factorial iteratively. Returns Double to handle large values.
    private func factorial(_ n: Int) -> Double {
        guard n >= 0 else { return .nan }
        guard n > 1 else { return 1 }
        var result: Double = 1
        for i in 2...n {
            result *= Double(i)
        }
        return result
    }

    // MARK: - Date Difference

    /// Compute the difference between two dates as a compound duration (months, weeks, days).
    private func computeDateDifference(from startDate: Date, to endDate: Date) -> Value {
        let calendar = Calendar.current
        let (earlier, later) = startDate < endDate ? (startDate, endDate) : (endDate, startDate)

        let components = calendar.dateComponents([.month, .day], from: earlier, to: later)
        let totalMonths = components.month ?? 0
        let remainingDays = components.day ?? 0
        let weeks = remainingDays / 7
        let days = remainingDays % 7

        return .dateDifference(totalMonths, weeks, days)
    }

    /// Compute the difference between two dates in a specific time unit.
    private func computeUnitBetween(unitName: String, from dateA: Date, to dateB: Date) -> Value {
        let calendar = Calendar.current
        let (earlier, later) = dateA < dateB ? (dateA, dateB) : (dateB, dateA)

        // Resolve the unit name to a unit ID via definitions
        let lower = unitName.lowercased()
        let unitId: String
        if let (unitDef, _) = definitions.unitsByVariant[lower] {
            unitId = unitDef.id
        } else {
            unitId = lower
        }

        let calendarComponent: Calendar.Component
        switch unitId {
        case "day", "workday":
            calendarComponent = .day
        case "week":
            calendarComponent = .weekOfYear
        case "month":
            calendarComponent = .month
        case "year":
            calendarComponent = .year
        case "hour":
            calendarComponent = .hour
        case "minute":
            calendarComponent = .minute
        case "second":
            calendarComponent = .second
        default:
            // Fallback: compute in days
            calendarComponent = .day
        }

        let diff = calendar.dateComponents([calendarComponent], from: earlier, to: later)
        let value: Int
        switch calendarComponent {
        case .day:           value = diff.day ?? 0
        case .weekOfYear:    value = diff.weekOfYear ?? 0
        case .month:         value = diff.month ?? 0
        case .year:          value = diff.year ?? 0
        case .hour:          value = diff.hour ?? 0
        case .minute:        value = diff.minute ?? 0
        case .second:        value = diff.second ?? 0
        default:             value = 0
        }

        // Return as a duration with the original unit name for display
        let format = unitFormatString(unitId: unitId)
        return .duration(Double(value), format)
    }

    /// Look up the display format string for a unit, falling back to the id itself.
    private func unitFormatString(unitId: String) -> String {
        for category in definitions.unitCategories {
            for unit in category.units {
                if unit.id == unitId {
                    return unit.format
                }
            }
        }
        return unitId
    }

    // MARK: - Workday Arithmetic

    /// Add (or subtract) N workdays to a date, skipping weekends (Saturday/Sunday).
    private func addWorkdays(_ count: Int, to date: Date) -> Date {
        let calendar = Calendar.current
        var current = date
        var remaining = abs(count)
        let direction = count >= 0 ? 1 : -1

        while remaining > 0 {
            current = calendar.date(byAdding: .day, value: direction, to: current)!
            let weekday = calendar.component(.weekday, from: current)
            // weekday: 1 = Sunday, 7 = Saturday
            if weekday != 1 && weekday != 7 {
                remaining -= 1
            }
        }

        return current
    }
}
