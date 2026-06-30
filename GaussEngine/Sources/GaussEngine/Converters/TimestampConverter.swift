import Foundation

/// Converts between Unix timestamps and Date values.
public struct TimestampConverter {

    public init() {}

    /// Convert a Unix timestamp (seconds since 1970-01-01 UTC) to a Date.
    public func toDate(_ timestamp: Double) -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Convert a Date to a Unix timestamp.
    public func toUnix(_ date: Date) -> Double {
        return date.timeIntervalSince1970
    }

    /// Format a Date as an ISO-8601 date string (UTC).
    public func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
