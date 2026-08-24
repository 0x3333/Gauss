import Cocoa
import GaussEngine
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleGauss = Self("toggleGauss", default: .init(.space, modifiers: .control))
}


class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController!
    private var calculatorWindow: CalculatorWindowController!
    private var currencyUpdater: CurrencyUpdater!
    private var preferencesWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("applicationDidFinishLaunching START")

        // Initialize the engine
        let engine: GaussEngine
        do {
            engine = try GaussEngine()
        } catch {
            debugLog("Failed to initialize GaussEngine: \(error)")
            // Show alert so user sees the error
            let alert = NSAlert()
            alert.messageText = "Failed to start Gauss"
            alert.informativeText = "\(error)"
            alert.alertStyle = .critical
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        debugLog("GaussEngine initialized successfully")

        // Create the menu bar controller FIRST (so it shows even if window setup fails)
        menuBarController = MenuBarController()
        debugLog("MenuBarController created")

        // Create the calculator window controller
        calculatorWindow = CalculatorWindowController(engine: engine)
        debugLog("CalculatorWindowController created")

        // Create the currency updater and hook it up to the menu bar
        currencyUpdater = CurrencyUpdater(currencyConverter: engine.currencyConverter)
        currencyUpdater.onRatesUpdated = { [weak self] statusText in
            self?.menuBarController.updateCurrencyStatus(statusText)
        }
        debugLog("CurrencyUpdater created")

        menuBarController.onToggleWindow = { [weak self] in
            self?.toggleWindow()
        }
        menuBarController.onNewCalculation = { [weak self] in
            self?.newCalculation()
        }
        menuBarController.onShowPreferences = { [weak self] in
            self?.showPreferences()
        }
        menuBarController.isWindowVisible = { [weak self] in
            self?.calculatorWindow.window?.isVisible ?? false
        }

        // Register global hotkey
        KeyboardShortcuts.onKeyUp(for: .toggleGauss) { [weak self] in
            self?.toggleWindow()
        }

        // Apply initial settings to engine formatter
        applyFormatterSettings(engine: engine)

        // Apply initial appearance mode
        applyAppearance()

        // Apply initial always-on-top setting
        if Settings.shared.alwaysOnTop {
            calculatorWindow.window?.level = .floating
        }

        // Apply initial currency update interval
        currencyUpdater.updateInterval = Settings.shared.currencyUpdateInterval

        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: Settings.didChangeNotification,
            object: nil
        )

        // Show the calculator window
        calculatorWindow.showWindow(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            calculatorWindow.showWindow(nil)
        }
        return true
    }

    // MARK: - Window Management

    func toggleWindow() {
        guard let window = calculatorWindow.window else { return }
        switch WindowTogglePolicy.action(
            isVisible: window.isVisible,
            isKey: window.isKeyWindow,
            isAppActive: NSApp.isActive
        ) {
        case .hide:
            window.orderOut(nil)
        case .show:
            calculatorWindow.showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func newCalculation() {
        calculatorWindow.clearDocument()
        calculatorWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Preferences

    func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Settings

    @objc private func settingsDidChange() {
        let settings = Settings.shared

        // Update window level
        calculatorWindow.window?.level = settings.alwaysOnTop ? .floating : .normal

        // Update formatter on the engine
        calculatorWindow.applySettings()

        // Update currency update interval
        currencyUpdater.updateInterval = settings.currencyUpdateInterval

        // Apply appearance mode
        applyAppearance()
    }

    private func applyAppearance() {
        let mode = Settings.shared.appearanceMode
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil // follow system
        }
    }

    private func applyFormatterSettings(engine: GaussEngine) {
        engine.formatter.maxDecimalPlaces = Settings.shared.precision
        engine.formatter.dateFormatString = Settings.shared.dateFormat
    }
}

enum WindowTogglePolicy {
    enum Action {
        case hide
        case show
    }

    static func action(isVisible: Bool, isKey: Bool, isAppActive: Bool) -> Action {
        isVisible && isKey && isAppActive ? .hide : .show
    }
}
