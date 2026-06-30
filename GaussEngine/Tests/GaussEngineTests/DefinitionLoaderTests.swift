import XCTest
@testable import GaussEngine

final class DefinitionLoaderTests: XCTestCase {

    // Shared loader — loaded once per test run.
    private var loader: DefinitionLoader!

    override func setUp() {
        super.setUp()
        do {
            loader = try DefinitionLoader()
        } catch {
            XCTFail("DefinitionLoader init threw: \(error)")
        }
    }

    // MARK: - Unit Categories

    func testUnitCategoriesCount() {
        XCTAssertEqual(loader.unitCategories.count, 8,
                       "Expected 8 unit categories (length, weight, volume, area, temperature, angle, data, time)")
    }

    func testEachCategoryHasAtLeastOneUnit() {
        for category in loader.unitCategories {
            XCTAssertFalse(category.units.isEmpty,
                           "Category '\(category.category)' has no units")
        }
    }

    func testAllExpectedCategoriesPresent() {
        let names = Set(loader.unitCategories.map { $0.category })
        let expected: Set<String> = ["length", "weight", "volume", "area", "temperature", "angle", "data", "time"]
        XCTAssertEqual(names, expected)
    }

    func testLengthCategoryBaseUnit() {
        let cat = loader.unitCategories.first { $0.category == "length" }
        XCTAssertNotNil(cat)
        XCTAssertEqual(cat?.base, "meter")
    }

    func testTemperatureCategoryBaseUnit() {
        let cat = loader.unitCategories.first { $0.category == "temperature" }
        XCTAssertNotNil(cat)
        XCTAssertEqual(cat?.base, "kelvin")
    }

    func testTimeCategoryHasExpectedUnits() {
        let cat = loader.unitCategories.first { $0.category == "time" }
        XCTAssertNotNil(cat)
        let ids = Set(cat!.units.map { $0.id })
        let expected: Set<String> = ["second", "minute", "hour", "day", "week", "month", "year", "millisecond", "microsecond", "workday"]
        XCTAssertEqual(ids, expected)
    }

    // MARK: - Temperature formulas

    func testCelsiusHasFormulas() {
        let cat = loader.unitCategories.first { $0.category == "temperature" }!
        let celsius = cat.units.first { $0.id == "celsius" }
        XCTAssertNotNil(celsius, "celsius unit missing")
        XCTAssertNotNil(celsius?.toBaseFormula)
        XCTAssertNotNil(celsius?.fromBaseFormula)
        XCTAssertNil(celsius?.toBase, "celsius should use formula, not toBase ratio")
    }

    func testFahrenheitHasFormulas() {
        let cat = loader.unitCategories.first { $0.category == "temperature" }!
        let f = cat.units.first { $0.id == "fahrenheit" }
        XCTAssertNotNil(f, "fahrenheit unit missing")
        XCTAssertNotNil(f?.toBaseFormula)
        XCTAssertNotNil(f?.fromBaseFormula)
    }

    func testKelvinHasToBaseRatio() {
        let cat = loader.unitCategories.first { $0.category == "temperature" }!
        let k = cat.units.first { $0.id == "kelvin" }
        XCTAssertNotNil(k, "kelvin unit missing")
        XCTAssertEqual(k?.toBase, 1.0)
    }

    // MARK: - unitsByVariant cache

    func testUnitsByVariantInchLookup() {
        let result = loader.unitsByVariant["inches"]
        XCTAssertNotNil(result, "'inches' should be in unitsByVariant")
        XCTAssertEqual(result?.0.id, "inch")
        XCTAssertEqual(result?.1.category, "length")
    }

    func testUnitsByVariantCaseInsensitive() {
        // "Meter", "METER", "meter" should all resolve
        XCTAssertNotNil(loader.unitsByVariant["meter"])
        XCTAssertNotNil(loader.unitsByVariant["Meter".lowercased()])
        XCTAssertNotNil(loader.unitsByVariant["METER".lowercased()])
    }

    func testUnitsByVariantKilogramLookup() {
        let result = loader.unitsByVariant["kg"]
        XCTAssertNotNil(result, "'kg' should be in unitsByVariant")
        XCTAssertEqual(result?.0.id, "kilogram")
        XCTAssertEqual(result?.1.category, "weight")
    }

    func testUnitsByVariantCelsiusLookup() {
        let result = loader.unitsByVariant["°c"]
        XCTAssertNotNil(result, "'°C' should be in unitsByVariant")
        XCTAssertEqual(result?.0.id, "celsius")
    }

    func testUnitsByVariantGiBLookup() {
        let result = loader.unitsByVariant["gib"]
        XCTAssertNotNil(result, "'GiB' should be in unitsByVariant")
        XCTAssertEqual(result?.0.id, "gibibyte")
        XCTAssertEqual(result?.1.category, "data")
    }

    func testUnitsByVariantSqMeterLookup() {
        let result = loader.unitsByVariant["m²"]
        XCTAssertNotNil(result, "'m²' should be in unitsByVariant")
        XCTAssertEqual(result?.0.id, "sq_meter")
    }

    // MARK: - No duplicate variants within same category

    func testNoDuplicateVariantsWithinEachCategory() {
        for category in loader.unitCategories {
            var seen: [String: String] = [:]  // variant → unit id
            for unit in category.units {
                for variant in unit.variants {
                    let lower = variant.lowercased()
                    if let existing = seen[lower] {
                        XCTFail("Duplicate variant '\(lower)' in category '\(category.category)': found in '\(existing)' and '\(unit.id)'")
                    } else {
                        seen[lower] = unit.id
                    }
                }
            }
        }
    }

    // MARK: - Operators

    func testOperatorsContainExpectedEntries() {
        let ops = loader.operators
        XCTAssertEqual(ops["plus"],          .add)
        XCTAssertEqual(ops["with"],          .add)
        XCTAssertEqual(ops["minus"],         .subtract)
        XCTAssertEqual(ops["without"],       .subtract)
        XCTAssertEqual(ops["subtract"],      .subtract)
        XCTAssertEqual(ops["times"],         .multiply)
        XCTAssertEqual(ops["multiplied by"], .multiply)
        XCTAssertEqual(ops["divided by"],    .divide)
        XCTAssertEqual(ops["mod"],           .mod)
        XCTAssertEqual(ops["band"],          .band)
        XCTAssertEqual(ops["bor"],           .bor)
        XCTAssertEqual(ops["bxor"],          .bxor)
        XCTAssertEqual(ops["lshift"],        .lshift)
        XCTAssertEqual(ops["rshift"],        .rshift)
    }

    func testOperatorsCount() {
        XCTAssertEqual(loader.operators.count, 14)
    }

    // MARK: - Functions

    func testFunctionsContainExpectedEntries() {
        let fns = loader.functions
        let expected: Set<String> = [
            "sin", "cos", "tan", "asin", "acos", "atan",
            "sinh", "cosh", "tanh",
            "sqrt", "cbrt", "root", "log", "ln",
            "abs", "ceil", "floor", "round", "fact"
        ]
        XCTAssertEqual(fns, expected)
    }

    func testFunctionsCount() {
        XCTAssertEqual(loader.functions.count, 19)
    }

    // MARK: - Scales

    func testScalesContainExpectedEntries() {
        let s = loader.scales
        XCTAssertEqual(s["k"],        1_000)
        XCTAssertEqual(s["thousand"], 1_000)
        XCTAssertEqual(s["M"],        1_000_000)
        XCTAssertEqual(s["million"],  1_000_000)
        XCTAssertEqual(s["billion"],  1_000_000_000)
        XCTAssertEqual(s["trillion"], 1_000_000_000_000)
    }

    func testScalesCount() {
        XCTAssertEqual(loader.scales.count, 6)
    }

    // MARK: - Currencies

    func testCurrenciesLoadWithMinimumCount() {
        XCTAssertGreaterThanOrEqual(loader.currencies.count, 30,
                                    "Expected at least 30 currencies")
    }

    func testCurrencyByCode() {
        let usd = loader.currencyByCode["USD"]
        XCTAssertNotNil(usd, "USD should be in currencyByCode")
        XCTAssertEqual(usd?.symbol, "$")
    }

    func testCurrencyBySymbol() {
        let eur = loader.currencyBySymbol["€"]
        XCTAssertNotNil(eur, "€ should be in currencyBySymbol")
        XCTAssertEqual(eur?.code, "EUR")
    }

    func testMandatoryCurrenciesPresent() {
        let codes: [String] = [
            "USD", "EUR", "GBP", "JPY", "CNY",
            "AUD", "CAD", "CHF", "HKD", "SGD",
            "KRW", "TWD", "INR", "BRL", "MXN",
            "RUB", "SEK", "NOK", "DKK", "NZD",
            "ZAR", "THB", "PHP", "MYR", "IDR",
            "VND", "AED", "SAR", "TRY", "PLN"
        ]
        for code in codes {
            XCTAssertNotNil(loader.currencyByCode[code], "Currency '\(code)' missing from currencyByCode")
        }
    }

    func testCurrencyVariantsIncludeCode() {
        for currency in loader.currencies {
            XCTAssertTrue(
                currency.variants.contains { $0.uppercased() == currency.code.uppercased() },
                "Currency \(currency.code) variants should include its own code"
            )
        }
    }

    // MARK: - Error handling

    func testDefaultInitDoesNotThrow() {
        XCTAssertNoThrow(try DefinitionLoader(), "Default init should not throw")
    }

    // MARK: - Unit conversion ratios sanity check

    func testLengthConversionRatios() {
        let cat = loader.unitCategories.first { $0.category == "length" }!
        let meter = cat.units.first { $0.id == "meter" }
        let km    = cat.units.first { $0.id == "kilometer" }
        let inch  = cat.units.first { $0.id == "inch" }

        XCTAssertEqual(meter?.toBase, 1.0)
        XCTAssertEqual(km?.toBase, 1000.0)
        XCTAssertNotNil(inch?.toBase)
        if let inchToBase = inch?.toBase {
            XCTAssertEqual(inchToBase, 0.0254, accuracy: 1e-10)
        }
    }

    func testDataCategoryIECUnits() {
        let cat = loader.unitCategories.first { $0.category == "data" }!
        let kib = cat.units.first { $0.id == "kibibyte" }
        let mib = cat.units.first { $0.id == "mebibyte" }
        XCTAssertEqual(kib?.toBase, 1024.0)
        XCTAssertEqual(mib?.toBase, 1048576.0)
    }
}
