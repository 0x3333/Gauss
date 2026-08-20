import Foundation

/// Provides autocomplete suggestions based on the engine's definitions.
public final class CompletionProvider {
    private let definitions: DefinitionLoader
    private var allWords: [(word: String, category: String)] = []

    public init(definitions: DefinitionLoader) {
        self.definitions = definitions
        buildWordList()
    }

    private func buildWordList() {
        // Unit variants (show the most readable variant per unit)
        for category in definitions.unitCategories {
            for unit in category.units {
                // Add the primary format name and key variants
                allWords.append((word: unit.id, category: category.category))
                for variant in unit.variants {
                    // Skip very short variants (1-2 chars) and symbols
                    if variant.count >= 3, variant.rangeOfCharacter(from: .letters) != nil {
                        allWords.append((word: variant, category: category.category))
                    }
                }
            }
        }

        // Currency names
        for currency in definitions.currencies {
            allWords.append((word: currency.code, category: "currency"))
            for variant in currency.variants {
                if variant.count >= 3, variant.rangeOfCharacter(from: .letters) != nil {
                    allWords.append((word: variant, category: "currency"))
                }
            }
        }

        // Functions
        for fn in definitions.functions {
            allWords.append((word: fn, category: "function"))
        }

        // Keywords
        let keywords = ["today", "tomorrow", "yesterday", "now", "sum", "total", "average", "prev"]
        for kw in keywords {
            allWords.append((word: kw, category: "keyword"))
        }

        // Natural language operators
        let operators = ["plus", "minus", "times", "divide", "mod"]
        for op in operators {
            allWords.append((word: op, category: "operator"))
        }

        // Conversion keywords
        let conversionKeywords = ["in", "to", "as", "from", "of", "on", "off"]
        for ck in conversionKeywords {
            allWords.append((word: ck, category: "conversion"))
        }

        // Remove duplicates (keep first occurrence)
        var seen = Set<String>()
        allWords = allWords.filter { entry in
            let lower = entry.word.lowercased()
            if seen.contains(lower) { return false }
            seen.insert(lower)
            return true
        }

        // Sort alphabetically
        allWords.sort { $0.word.lowercased() < $1.word.lowercased() }
    }

    /// Returns completions for a partial word prefix.
    /// - Parameter prefix: The partial text to complete (case-insensitive).
    /// - Parameter limit: Maximum number of suggestions.
    /// - Returns: Array of completion strings.
    public func completions(for prefix: String, limit: Int = 8) -> [String] {
        guard prefix.count >= 2 else { return [] }
        let lower = prefix.lowercased()

        var results: [String] = []
        for entry in allWords {
            if entry.word.lowercased().hasPrefix(lower), entry.word.lowercased() != lower {
                results.append(entry.word)
                if results.count >= limit { break }
            }
        }
        return results
    }

    /// Returns text to append for the longest known phrase ending at the cursor.
    public func completionSuffix(for context: String) -> String? {
        let words = context.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        guard let lastWord = words.last, lastWord.count >= 2 else { return nil }

        let maxWordCount = allWords.lazy
            .map { $0.word.split(separator: " ").count }
            .max() ?? 1

        for wordCount in stride(from: min(words.count, maxWordCount), through: 1, by: -1) {
            let prefix = words.suffix(wordCount).joined(separator: " ")
            let lower = prefix.lowercased()
            let matches = allWords.filter { $0.word.lowercased().hasPrefix(lower) }
            guard !matches.isEmpty else { continue }

            // A complete valid phrase should not be extended to a longer variant.
            if matches.contains(where: { $0.word.lowercased() == lower }) {
                return nil
            }

            let best = matches.min { lhs, rhs in
                if lhs.word.count != rhs.word.count {
                    return lhs.word.count < rhs.word.count
                }
                return lhs.word.lowercased() < rhs.word.lowercased()
            }
            guard let completion = best?.word else { return nil }
            return String(completion.dropFirst(prefix.count))
        }

        return nil
    }
}
