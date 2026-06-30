import Cocoa

func debugLog(_ message: String) {
    let logFile = NSHomeDirectory() + "/gauss-debug.log"
    let line = "\(Date()): \(message)\n"
    if let handle = FileHandle(forWritingAtPath: logFile) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? line.write(toFile: logFile, atomically: true, encoding: .utf8)
    }
}

/// Manages the menu bar status item and its dropdown menu.
final class MenuBarController: NSObject {

    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    /// Called when the user selects "Show Gauss" / "Hide Gauss".
    var onToggleWindow: (() -> Void)?
    /// Called when the user selects "New Calculation".
    var onNewCalculation: (() -> Void)?
    /// Called when the user selects "Preferences...".
    var onShowPreferences: (() -> Void)?
    /// Returns whether the calculator window is currently visible.
    var isWindowVisible: (() -> Bool)?

    override init() {
        super.init()
        setupStatusItem()
        buildMenu()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Use custom G logo from asset catalog
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true // adapts to menu bar light/dark automatically
                image.size = NSSize(width: 22, height: 22)
                button.image = image
            } else {
                // Fallback to text
                button.title = "G"
                button.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
            }
            debugLog("✅ StatusItem button configured")
        } else {
            debugLog("❌ StatusItem button is nil!")
        }
        debugLog("StatusItem isVisible=\(statusItem.isVisible), length=\(statusItem.length)")
    }

    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self

        let toggleItem = NSMenuItem(
            title: "Show Gauss",
            action: #selector(toggleWindowAction),
            keyEquivalent: " "
        )
        toggleItem.keyEquivalentModifierMask = .control
        toggleItem.target = self
        toggleItem.tag = 100 // tag for dynamic title updates
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let newCalcItem = NSMenuItem(
            title: "New Calculation",
            action: #selector(newCalculationAction),
            keyEquivalent: "n"
        )
        newCalcItem.keyEquivalentModifierMask = .command
        newCalcItem.target = self
        menu.addItem(newCalcItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(preferencesAction),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = .command
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        // Informational currency rate status item (non-clickable)
        let currencyItem = NSMenuItem(title: "Currency Rates: —", action: nil, keyEquivalent: "")
        currencyItem.isEnabled = false
        currencyItem.tag = 200
        menu.addItem(currencyItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Gauss",
            action: #selector(quitAction),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// Update the currency rate status shown in the dropdown menu.
    func updateCurrencyStatus(_ status: String) {
        if let item = menu.item(withTag: 200) {
            item.title = "Currency Rates: \(status)"
        }
    }

    // MARK: - Actions

    @objc private func toggleWindowAction() {
        onToggleWindow?()
    }

    @objc private func newCalculationAction() {
        onNewCalculation?()
    }

    @objc private func preferencesAction() {
        onShowPreferences?()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension MenuBarController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Update the toggle item title based on window visibility
        if let item = menu.item(withTag: 100) {
            let visible = isWindowVisible?() ?? false
            item.title = visible ? "Hide Gauss" : "Show Gauss"
        }
    }
}
