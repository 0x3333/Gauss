import Foundation

/// Converts between color representations: hex, rgb, and hsl.
public struct ColorConverter {

    public init() {}

    // MARK: - Hex to RGB

    /// Convert a hex color string (without #) to RGB components.
    public func hexToRgb(_ hex: String) -> (Int, Int, Int)? {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: clean).scanHexInt64(&rgb) else { return nil }
        let r = Int((rgb >> 16) & 0xFF)
        let g = Int((rgb >> 8) & 0xFF)
        let b = Int(rgb & 0xFF)
        return (r, g, b)
    }

    // MARK: - RGB to Hex

    /// Convert RGB components to a hex string (without #).
    public func rgbToHex(_ r: Int, _ g: Int, _ b: Int) -> String {
        return String(format: "%02X%02X%02X", r, g, b)
    }

    // MARK: - RGB to HSL

    /// Convert RGB (0–255 each) to HSL.
    /// Returns (hue: 0–360, saturation: 0.0–1.0, lightness: 0.0–1.0).
    public func rgbToHsl(_ r: Int, _ g: Int, _ b: Int) -> (Int, Double, Double) {
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0

        let maxC = max(rf, gf, bf)
        let minC = min(rf, gf, bf)
        let delta = maxC - minC

        let l = (maxC + minC) / 2.0

        let s: Double
        if delta == 0 {
            s = 0
        } else {
            s = delta / (1.0 - abs(2.0 * l - 1.0))
        }

        var h: Double = 0
        if delta != 0 {
            if maxC == rf {
                h = 60.0 * (((gf - bf) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxC == gf {
                h = 60.0 * (((bf - rf) / delta) + 2)
            } else {
                h = 60.0 * (((rf - gf) / delta) + 4)
            }
            if h < 0 { h += 360 }
        }

        return (Int(h.rounded()), s, l)
    }

    // MARK: - HSL to RGB

    /// Convert HSL (h: 0–360, s: 0–1, l: 0–1) to RGB (0–255 each).
    public func hslToRgb(h: Int, s: Double, l: Double) -> (Int, Int, Int) {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((Double(h) / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2

        var rf = 0.0, gf = 0.0, bf = 0.0
        switch h {
        case 0..<60:   (rf, gf, bf) = (c, x, 0)
        case 60..<120: (rf, gf, bf) = (x, c, 0)
        case 120..<180:(rf, gf, bf) = (0, c, x)
        case 180..<240:(rf, gf, bf) = (0, x, c)
        case 240..<300:(rf, gf, bf) = (x, 0, c)
        default:       (rf, gf, bf) = (c, 0, x)
        }

        return (Int(((rf + m) * 255).rounded()),
                Int(((gf + m) * 255).rounded()),
                Int(((bf + m) * 255).rounded()))
    }

    // MARK: - ColorValue conversions

    /// Convert any ColorValue to RGB.
    public func toRgb(_ color: ColorValue) -> ColorValue? {
        switch color {
        case .hex(let hex):
            guard let (r, g, b) = hexToRgb(hex) else { return nil }
            return .rgb(r, g, b)
        case .rgb:
            return color
        case .hsl(let h, let s, let l):
            let (r, g, b) = hslToRgb(h: h, s: s, l: l)
            return .rgb(r, g, b)
        }
    }

    /// Convert any ColorValue to hex.
    public func toHex(_ color: ColorValue) -> ColorValue? {
        switch color {
        case .hex:
            return color
        case .rgb(let r, let g, let b):
            return .hex(rgbToHex(r, g, b))
        case .hsl(let h, let s, let l):
            let (r, g, b) = hslToRgb(h: h, s: s, l: l)
            return .hex(rgbToHex(r, g, b))
        }
    }

    /// Convert any ColorValue to HSL.
    public func toHsl(_ color: ColorValue) -> ColorValue? {
        switch color {
        case .hsl:
            return color
        case .hex(let hex):
            guard let (r, g, b) = hexToRgb(hex) else { return nil }
            let (h, s, l) = rgbToHsl(r, g, b)
            return .hsl(h, s, l)
        case .rgb(let r, let g, let b):
            let (h, s, l) = rgbToHsl(r, g, b)
            return .hsl(h, s, l)
        }
    }
}
