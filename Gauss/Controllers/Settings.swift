import Foundation

/// Central settings manager backed by UserDefaults.
/// Posts `Settings.didChangeNotification` whenever a value is modified.
final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key: String {
        case precision
        case dateFormat
        case fontSize
        case alwaysOnTop
        case launchAtLogin
        case currencyUpdateInterval
        case appearanceMode
        case showLineNumbers
    }

    // MARK: - Properties

    /// Number of decimal places for formatted results (0-10, default 2).
    var precision: Int {
        get { defaults.object(forKey: Key.precision.rawValue) as? Int ?? 2 }
        set { defaults.set(newValue, forKey: Key.precision.rawValue); notify() }
    }

    /// Font size for the calculator text (default 13, range 10-24).
    var fontSize: CGFloat {
        get {
            let val = defaults.double(forKey: Key.fontSize.rawValue)
            return val > 0 ? CGFloat(val) : 13
        }
        set {
            let clamped = max(10, min(24, newValue))
            defaults.set(Double(clamped), forKey: Key.fontSize.rawValue)
            notify()
        }
    }

    /// Date display format string (default "MMM d, yyyy").
    var dateFormat: String {
        get { defaults.string(forKey: Key.dateFormat.rawValue) ?? "MMM d, yyyy" }
        set { defaults.set(newValue, forKey: Key.dateFormat.rawValue); notify() }
    }

    /// Whether the calculator window floats above all others.
    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: Key.alwaysOnTop.rawValue) }
        set { defaults.set(newValue, forKey: Key.alwaysOnTop.rawValue); notify() }
    }

    /// Whether the app should launch at login.
    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Key.launchAtLogin.rawValue) }
        set { defaults.set(newValue, forKey: Key.launchAtLogin.rawValue); notify() }
    }

    /// Interval between currency rate updates, in seconds (default 4 hours).
    var currencyUpdateInterval: TimeInterval {
        get {
            let val = defaults.double(forKey: Key.currencyUpdateInterval.rawValue)
            return val > 0 ? val : 4 * 3600
        }
        set { defaults.set(newValue, forKey: Key.currencyUpdateInterval.rawValue); notify() }
    }

    /// Appearance mode: "system" (default), "light", or "dark".
    var appearanceMode: String {
        get { defaults.string(forKey: Key.appearanceMode.rawValue) ?? "system" }
        set { defaults.set(newValue, forKey: Key.appearanceMode.rawValue); notify() }
    }

    var showLineNumbers: Bool {
        get { defaults.object(forKey: Key.showLineNumbers.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.showLineNumbers.rawValue); notify() }
    }

    // MARK: - Notification

    static let didChangeNotification = Notification.Name("SettingsDidChange")

    private func notify() {
        NotificationCenter.default.post(name: Settings.didChangeNotification, object: nil)
    }
}
