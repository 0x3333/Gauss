import Foundation

/// Encodes and decodes strings using Base64.
public struct Base64Converter {

    public init() {}

    /// Encode a plain string to Base64.
    public func encode(_ input: String) -> String? {
        let data = Data(input.utf8)
        return data.base64EncodedString()
    }

    /// Decode a Base64 string to a plain string.
    /// Returns nil if the input is not valid Base64.
    public func decode(_ input: String) -> String? {
        // Try standard Base64, then URL-safe variant
        let padded = addPadding(input)
        if let data = Data(base64Encoded: padded),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        // Try URL-safe variant (replace - with + and _ with /)
        let standard = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddedStandard = addPadding(standard)
        if let data = Data(base64Encoded: paddedStandard),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }

    /// Add Base64 padding characters if needed.
    private func addPadding(_ s: String) -> String {
        let remainder = s.count % 4
        if remainder == 0 { return s }
        return s + String(repeating: "=", count: 4 - remainder)
    }
}
