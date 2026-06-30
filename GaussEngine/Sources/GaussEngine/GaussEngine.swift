import Foundation

public final class GaussEngine {
    public let definitions: DefinitionLoader
    private let tokenizer: Tokenizer
    private let matcher: Matcher
    private let evaluator: Evaluator
    public var formatter: ValueFormatter
    public let context: Context
    public let currencyConverter: CurrencyConverter
    public let completionProvider: CompletionProvider

    public init() throws {
        let defs = try DefinitionLoader()
        self.definitions = defs
        self.tokenizer = Tokenizer(definitions: defs)
        self.matcher = Matcher(definitions: defs)
        let cc = CurrencyConverter()
        self.currencyConverter = cc
        self.evaluator = Evaluator(definitions: defs, currencyConverter: cc)
        self.formatter = ValueFormatter(definitions: defs)
        self.context = Context()
        self.completionProvider = CompletionProvider(definitions: defs)
    }

    public struct LineResult: Equatable {
        public let value: Value
        public let formatted: String
        public let tokens: [Token]
        public let lineType: LineType
    }

    public enum LineType: Equatable {
        case expression
        case header(String)
        case comment(String)
        case label(String)   // the label text
        case empty
    }

    /// Evaluate a single line of input
    public func evaluateLine(_ input: String, lineIndex: Int = 0) -> LineResult {
        let tokens = tokenizer.tokenize(input)

        // Determine line type
        if input.trimmingCharacters(in: .whitespaces).isEmpty {
            return LineResult(value: .undefined, formatted: "", tokens: tokens, lineType: .empty)
        }
        if let first = tokens.first {
            switch first {
            case .header(let text):
                return LineResult(value: .undefined, formatted: "", tokens: tokens, lineType: .header(text))
            case .comment(let text):
                return LineResult(value: .undefined, formatted: "", tokens: tokens, lineType: .comment(text))
            case .label(let text):
                // For labels, evaluate the expression tokens (everything after the label)
                let exprTokens = Array(tokens.dropFirst())
                if let expr = matcher.match(exprTokens) {
                    context.currentLineIndex = lineIndex
                    let value = evaluator.evaluate(expr, context: context)
                    context.lineResults[lineIndex] = value
                    return LineResult(value: value, formatted: formatter.format(value), tokens: tokens, lineType: .label(text))
                }
                return LineResult(value: .undefined, formatted: "", tokens: tokens, lineType: .label(text))
            default:
                break
            }
        }

        // Regular expression
        if let expr = matcher.match(tokens) {
            context.currentLineIndex = lineIndex
            let value = evaluator.evaluate(expr, context: context)
            context.lineResults[lineIndex] = value
            return LineResult(value: value, formatted: formatter.format(value), tokens: tokens, lineType: .expression)
        }

        return LineResult(value: .undefined, formatted: "", tokens: tokens, lineType: .expression)
    }

    /// Evaluate a multi-line document
    public func evaluateDocument(_ input: String) -> [LineResult] {
        context.reset()
        let lines = input.components(separatedBy: "\n")
        return lines.enumerated().map { index, line in
            evaluateLine(line, lineIndex: index)
        }
    }

    /// Re-evaluate all lines (call after variable changes)
    public func reevaluateAll(_ input: String) -> [LineResult] {
        return evaluateDocument(input) // V1: full re-eval
    }
}
