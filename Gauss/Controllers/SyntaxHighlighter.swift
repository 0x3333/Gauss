import Cocoa
import GaussEngine

/// Applies syntax highlighting colors to the CalcTextView's text storage
/// based on token types from the engine's LineResult.
final class SyntaxHighlighter {

    /// Apply syntax highlighting to the text storage using the given line results.
    func apply(to textStorage: NSTextStorage, results: [GaussEngine.LineResult]) {
        let fullText = textStorage.string as NSString
        let totalLength = fullText.length
        guard totalLength > 0 else { return }

        textStorage.beginEditing()

        // Reset to default text color and font
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: Theme.textPrimary,
            .font: Theme.monoFont,
        ]
        textStorage.setAttributes(defaultAttrs, range: NSRange(location: 0, length: totalLength))

        // Process each line
        var lineStart = 0
        for result in results {
            // Find the range for this line
            let lineRange: NSRange
            if lineStart >= totalLength {
                break
            }
            let foundRange = fullText.lineRange(for: NSRange(location: lineStart, length: 0))
            lineRange = foundRange

            // Apply highlighting based on line type
            switch result.lineType {
            case .header:
                textStorage.addAttribute(.foregroundColor, value: Theme.headerColor, range: lineRange)

            case .comment:
                textStorage.addAttribute(.foregroundColor, value: Theme.commentColor, range: lineRange)

            case .expression, .label, .empty:
                // Highlight individual tokens
                highlightTokens(result.tokens, in: textStorage, lineText: fullText.substring(with: lineRange), lineOffset: lineRange.location)
            }

            // Move to next line
            lineStart = NSMaxRange(lineRange)
        }

        textStorage.endEditing()
    }

    // MARK: - Token-level Highlighting

    private func highlightTokens(_ tokens: [Token], in textStorage: NSTextStorage, lineText: String, lineOffset: Int) {
        let nsLine = lineText as NSString
        var searchStart = 0

        for token in tokens {
            let (text, color) = tokenTextAndColor(token)
            guard let color = color, !text.isEmpty else { continue }

            // Find the token text in the remaining portion of the line
            let searchRange = NSRange(location: searchStart, length: nsLine.length - searchStart)
            let found = nsLine.range(of: text, options: .caseInsensitive, range: searchRange)

            if found.location != NSNotFound {
                let absoluteRange = NSRange(location: lineOffset + found.location, length: found.length)
                textStorage.addAttribute(.foregroundColor, value: color, range: absoluteRange)
                searchStart = NSMaxRange(found)
            }
        }
    }

    /// Returns the text representation and color for a token.
    private func tokenTextAndColor(_ token: Token) -> (String, NSColor?) {
        switch token {
        case .keyword(let kw):
            return (kw.rawValue, Theme.keywordColor)
        case .identifier(let name):
            return (name, Theme.variableColor)
        case .label(let text):
            return (text, Theme.variableColor)
        case .header(let text):
            return (text, Theme.headerColor)
        case .comment(let text):
            return (text, Theme.commentColor)
        default:
            return ("", nil) // Numbers, operators, etc. use default color
        }
    }
}
