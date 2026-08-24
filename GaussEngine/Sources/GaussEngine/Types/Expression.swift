/// An AST node representing a parsed expression.
public indirect enum Expression: Equatable {
    /// A literal value (number, currency, etc.).
    case literal(Value)

    /// A binary arithmetic or bitwise operation.
    case arithmetic(Expression, Operator, Expression)

    /// Negation of an expression.
    case unaryMinus(Expression)

    /// `20% of $150` — percentage of a value.
    case percentOf(Double, Expression)

    /// `15% on $20` — add a percentage on top.
    case percentOn(Double, Expression)

    /// `20% off $50` — subtract a percentage.
    case percentOff(Double, Expression)

    /// `20% of what is 30cm` — reverse percentage lookup.
    case percentOfWhatIs(Double, Expression)

    /// `75 is what % of 600` — what percentage is X of Y.
    case whatPercentOf(Expression, Expression)

    /// `90 is 10% off what` — reverse percentage off lookup.
    case isPercentOffWhat(Expression, Double)

    /// `random between 2 and 30` — random number in range.
    case randomBetween(Expression, Expression)

    /// `midpoint between 50 and 150` — average of two values.
    case midpointBetween(Expression, Expression)

    /// `March 20 to June 5` — date range producing compound duration.
    case dateRange(Expression, Expression)

    /// `weeks between October 21 and December 2` — difference in a specific time unit.
    case unitBetweenDates(String, Expression, Expression)

    /// Variable-based percentage: `tax on price` where tax is a % variable.
    case dynamicPercentOf(Expression, Expression)
    case dynamicPercentOn(Expression, Expression)
    case dynamicPercentOff(Expression, Expression)

    /// Unit / currency conversion: `expr in km` or `expr to USD`.
    case conversion(Expression, String)

    /// Variable assignment: `price = 100`.
    case assignment(String, Expression)

    /// Compound assignment: `price += 10`.
    case compoundAssignment(String, Operator, Expression)

    /// Function call: `sqrt(144)`.
    case functionCall(String, [Expression])

    /// Reference to a previously defined variable.
    case variableRef(String)

    /// Reference to another line's result (`@1` is 1-based).
    case lineRef(Int)

    /// A special aggregate or reference token.
    case specialToken(SpecialToken)
}

/// Aggregate and reference keywords that evaluate relative to the current context.
public enum SpecialToken: String, Equatable, CaseIterable {
    case sum
    case total
    case avg
    case average
    case prev
    // Date literals
    case today
    case tomorrow
    case yesterday
    case now
}
