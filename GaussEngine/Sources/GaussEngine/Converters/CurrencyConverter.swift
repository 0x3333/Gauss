import Foundation

/// Converts between currencies using exchange rates relative to USD.
/// Ships with static stub rates; call `updateRates(_:)` to supply live rates.
public final class CurrencyConverter {
    /// Map from currency code (e.g., "USD") to rate relative to USD.
    public var rates: [String: Double]

    public init() {
        // Static rates for testing
        rates = [
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "JPY": 149.5,
            "CNY": 7.29,
            "AUD": 1.53,
            "CAD": 1.36,
            "CHF": 0.88,
            "HKD": 7.82,
            "SGD": 1.34,
            "KRW": 1320,
            "TWD": 31.5,
            "INR": 83.1,
            "BRL": 4.97,
            "MXN": 17.15
        ]
    }

    /// Convert an amount from one currency to another.
    /// Returns nil if either currency code is unknown.
    public func convert(_ amount: Double, from: String, to: String) -> Double? {
        guard let fromRate = rates[from], let toRate = rates[to] else { return nil }
        return amount / fromRate * toRate
    }

    /// Replace all rates with new values.
    public func updateRates(_ newRates: [String: Double]) {
        rates = newRates
    }
}
