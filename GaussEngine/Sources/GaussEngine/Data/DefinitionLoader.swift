import Foundation

// MARK: - CurrencyDefinition

/// A currency definition loaded from currencies.json.
public struct CurrencyDefinition: Codable, Equatable {
    public let code: String
    public let symbol: String
    public let variants: [String]
    public let format: String

    public init(code: String, symbol: String, variants: [String], format: String) {
        self.code = code
        self.symbol = symbol
        self.variants = variants
        self.format = format
    }
}

// MARK: - DefinitionLoaderError

public enum DefinitionLoaderError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case invalidOperator(String)

    public var description: String {
        switch self {
        case .fileNotFound(let name):
            return "Definition file not found: \(name)"
        case .decodingFailed(let name, let error):
            return "Failed to decode \(name): \(error)"
        case .invalidOperator(let raw):
            return "Unknown operator string '\(raw)' in operators.json"
        }
    }
}

// MARK: - Private Codable helpers

private struct UnitCategoriesFile: Decodable {
    let categories: [UnitCategory]
}

private struct OperatorEntry: Decodable {
    let word: String
    let op: String
}

private struct OperatorsFile: Decodable {
    let operators: [OperatorEntry]
}

private struct FunctionsFile: Decodable {
    let functions: [String]
}

private struct ScaleEntry: Decodable {
    let word: String
    let multiplier: Double
}

private struct ScalesFile: Decodable {
    let scales: [ScaleEntry]
}

private struct CurrenciesFile: Decodable {
    let currencies: [CurrencyDefinition]
}

// MARK: - DefinitionLoader

/// Loads and indexes all JSON definition files for the Gauss calculation engine.
public final class DefinitionLoader {

    // MARK: Loaded data

    /// All unit categories with their unit definitions.
    public let unitCategories: [UnitCategory]

    /// Map from natural-language words to operator IDs (e.g. "plus" → .add).
    public let operators: [String: Operator]

    /// Set of known function names (e.g. "sin", "cos").
    public let functions: Set<String>

    /// Map from scale words to multipliers (e.g. "k" → 1000).
    public let scales: [String: Double]

    /// All currency definitions.
    public let currencies: [CurrencyDefinition]

    // MARK: Lookup caches

    /// Case-insensitive map from any variant string to its (UnitDefinition, UnitCategory) pair.
    public let unitsByVariant: [String: (UnitDefinition, UnitCategory)]

    /// Map from currency symbol to its CurrencyDefinition.
    public let currencyBySymbol: [String: CurrencyDefinition]

    /// Map from currency code (uppercase) to its CurrencyDefinition.
    public let currencyByCode: [String: CurrencyDefinition]

    /// Case-insensitive map from any currency variant string to its CurrencyDefinition.
    public let currencyByVariant: [String: CurrencyDefinition]

    // MARK: Init

    /// Creates a DefinitionLoader by reading all JSON files from the given bundle.
    /// Uses the GaussEngine module bundle by default.
    public convenience init() throws {
        try self.init(bundle: .module)
    }

    /// Creates a DefinitionLoader by reading all JSON files from the given bundle.
    /// - Parameter bundle: The bundle that contains the Resources/definitions/ directory.
    public init(bundle: Bundle) throws {
        let unitCategories = try DefinitionLoader.loadUnitCategories(bundle: bundle)
        let operators      = try DefinitionLoader.loadOperators(bundle: bundle)
        let functions      = try DefinitionLoader.loadFunctions(bundle: bundle)
        let scales         = try DefinitionLoader.loadScales(bundle: bundle)
        let currencies     = try DefinitionLoader.loadCurrencies(bundle: bundle)

        self.unitCategories = unitCategories
        self.operators      = operators
        self.functions      = functions
        self.scales         = scales
        self.currencies     = currencies

        // Build unitsByVariant cache (case-insensitive)
        var byVariant: [String: (UnitDefinition, UnitCategory)] = [:]
        for category in unitCategories {
            for unit in category.units {
                for variant in unit.variants {
                    byVariant[variant.lowercased()] = (unit, category)
                }
            }
        }
        self.unitsByVariant = byVariant

        // Build currency caches
        var bySymbol: [String: CurrencyDefinition] = [:]
        var byCode: [String: CurrencyDefinition] = [:]
        var byCurrencyVariant: [String: CurrencyDefinition] = [:]
        for currency in currencies {
            bySymbol[currency.symbol] = currency
            byCode[currency.code.uppercased()] = currency
            for variant in currency.variants {
                byCurrencyVariant[variant.lowercased()] = currency
            }
        }
        self.currencyBySymbol = bySymbol
        self.currencyByCode   = byCode
        self.currencyByVariant = byCurrencyVariant
    }

    // MARK: - Private Loaders

    private static func loadUnitCategories(bundle: Bundle) throws -> [UnitCategory] {
        let data = try loadData(named: "units", bundle: bundle)
        do {
            let file = try JSONDecoder().decode(UnitCategoriesFile.self, from: data)
            return file.categories
        } catch {
            throw DefinitionLoaderError.decodingFailed("units.json", error)
        }
    }

    private static func loadOperators(bundle: Bundle) throws -> [String: Operator] {
        let data = try loadData(named: "operators", bundle: bundle)
        let file: OperatorsFile
        do {
            file = try JSONDecoder().decode(OperatorsFile.self, from: data)
        } catch {
            throw DefinitionLoaderError.decodingFailed("operators.json", error)
        }

        var result: [String: Operator] = [:]
        for entry in file.operators {
            guard let op = Operator(rawValue: entry.op) else {
                throw DefinitionLoaderError.invalidOperator(entry.op)
            }
            result[entry.word] = op
        }
        return result
    }

    private static func loadFunctions(bundle: Bundle) throws -> Set<String> {
        let data = try loadData(named: "functions", bundle: bundle)
        do {
            let file = try JSONDecoder().decode(FunctionsFile.self, from: data)
            return Set(file.functions)
        } catch {
            throw DefinitionLoaderError.decodingFailed("functions.json", error)
        }
    }

    private static func loadScales(bundle: Bundle) throws -> [String: Double] {
        let data = try loadData(named: "scales", bundle: bundle)
        let file: ScalesFile
        do {
            file = try JSONDecoder().decode(ScalesFile.self, from: data)
        } catch {
            throw DefinitionLoaderError.decodingFailed("scales.json", error)
        }

        var result: [String: Double] = [:]
        for entry in file.scales {
            result[entry.word] = entry.multiplier
        }
        return result
    }

    private static func loadCurrencies(bundle: Bundle) throws -> [CurrencyDefinition] {
        let data = try loadData(named: "currencies", bundle: bundle)
        do {
            let file = try JSONDecoder().decode(CurrenciesFile.self, from: data)
            return file.currencies
        } catch {
            throw DefinitionLoaderError.decodingFailed("currencies.json", error)
        }
    }

    /// Loads raw Data for a JSON definition file from the bundle.
    /// SPM's `.process("Resources")` flattens subdirectories, so files land at the bundle root.
    private static func loadData(named name: String, bundle: Bundle) throws -> Data {
        // First try without subdirectory (SPM .process flattens Resources/)
        if let url = bundle.url(forResource: name, withExtension: "json") {
            return try Data(contentsOf: url)
        }
        // Fallback: try with explicit subdirectory (useful for custom test bundles)
        if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "definitions") {
            return try Data(contentsOf: url)
        }
        throw DefinitionLoaderError.fileNotFound("\(name).json")
    }
}
