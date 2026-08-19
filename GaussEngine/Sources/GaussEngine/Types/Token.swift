/// All token types the tokenizer can produce.
public enum Token: Equatable {
    // Numbers
    case number(Double)
    case hexNumber(Int)
    case binaryNumber(Int)
    case octalNumber(Int)
    case percentage(Double)             // e.g., 20% → .percentage(20)

    // Currency
    case currency(Double, String)       // e.g., $8 → .currency(8, "USD")

    // Operators
    case op(Operator)
    case assignment                     // =
    case compoundAssignment(Operator)   // +=

    // Identifiers
    case identifier(String)             // variable name, unit name, function name
    case keyword(Keyword)               // in, to, as, of, on, off, from
    case lineRef(Int)                   // @1 — 1-based line number

    // Structure
    case header(String)                 // # title
    case comment(String)                // // comment or "quoted"
    case label(String)                  // Label: (before colon)
    case leftParen
    case rightParen

    // Special
    case string(String)                 // "quoted string" for base64 etc.
    case hexColor(String)               // #FF5733
    case rgbColor(Int, Int, Int)        // rgb(255, 87, 51)
}

/// Arithmetic and bitwise operators.
public enum Operator: String, Equatable, CaseIterable {
    case add
    case subtract
    case multiply
    case divide
    case power
    case mod
    case band
    case bor
    case bxor
    case lshift
    case rshift
}

/// Reserved keyword tokens.
public enum Keyword: String, Equatable, CaseIterable {
    case `in`
    case to
    case `as`
    case of
    case on
    case off
    case from
    case times
    case plus
    case minus
    case divide
}
