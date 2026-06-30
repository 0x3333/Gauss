/// Definition of a single unit variant with its conversion coefficients or formulas.
public struct UnitDefinition: Codable, Equatable {
    /// Canonical identifier for this unit (e.g., "km", "celsius").
    public let id: String

    /// All string variants that map to this unit (e.g., ["km", "kilometer", "kilometres"]).
    public let variants: [String]

    /// Display format string used when rendering results (e.g., "km", "°C").
    public let format: String

    /// Multiplicative factor to convert this unit to the category base unit.
    /// Nil when a formula is required instead.
    public let toBase: Double?

    /// Expression string for non-linear to-base conversion (e.g., "(x + 273.15)" for celsius→kelvin).
    public let toBaseFormula: String?

    /// Expression string for non-linear from-base conversion (e.g., "(x - 273.15)" for kelvin→celsius).
    public let fromBaseFormula: String?

    public init(
        id: String,
        variants: [String],
        format: String,
        toBase: Double? = nil,
        toBaseFormula: String? = nil,
        fromBaseFormula: String? = nil
    ) {
        self.id = id
        self.variants = variants
        self.format = format
        self.toBase = toBase
        self.toBaseFormula = toBaseFormula
        self.fromBaseFormula = fromBaseFormula
    }
}

/// A logical grouping of units that share a common base.
public struct UnitCategory: Codable, Equatable {
    /// Category name (e.g., "length", "temperature").
    public let category: String

    /// The canonical base unit id for this category (e.g., "m" for length).
    public let base: String

    /// All unit definitions belonging to this category.
    public let units: [UnitDefinition]

    public init(category: String, base: String, units: [UnitDefinition]) {
        self.category = category
        self.base = base
        self.units = units
    }
}
