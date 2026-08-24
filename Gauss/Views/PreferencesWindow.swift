import Cocoa
import KeyboardShortcuts
import ServiceManagement

/// Preferences window controller for Gauss.
/// Provides UI for precision, date format, hotkey, always-on-top, launch-at-login, and currency update interval.
final class PreferencesWindowController: NSWindowController {

    // MARK: - Controls

    private var precisionPopUp: NSPopUpButton!
    private var fontSizePopUp: NSPopUpButton!
    private var dateFormatPopUp: NSPopUpButton!
    private var appearancePopUp: NSPopUpButton!
    private var alwaysOnTopCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var showLineNumbersCheckbox: NSButton!
    private var currencyIntervalPopUp: NSPopUpButton!

    // MARK: - Date Format Options

    private let dateFormatOptions: [(title: String, format: String)] = [
        ("MMM d, yyyy", "MMM d, yyyy"),
        ("yyyy-MM-dd", "yyyy-MM-dd"),
        ("M/d/yy", "M/d/yy"),
        ("d/M/yy", "d/M/yy"),
    ]

    // MARK: - Appearance Options

    private let appearanceOptions: [(title: String, mode: String)] = [
        ("System", "system"),
        ("Light", "light"),
        ("Dark", "dark"),
    ]

    // MARK: - Currency Interval Options

    private let currencyIntervalOptions: [(title: String, interval: TimeInterval)] = [
        ("Every hour", 3600),
        ("Every 4 hours", 4 * 3600),
        ("Every 12 hours", 12 * 3600),
        ("Daily", 24 * 3600),
    ]

    // MARK: - Init

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Gauss Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        // Prevent resizing
        window.minSize = window.frame.size
        window.maxSize = window.frame.size

        super.init(window: window)

        setupContentView()
        loadCurrentSettings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupContentView() {
        guard let window = window else { return }

        // Visual effect background (Liquid Glass)
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .sidebar
        visualEffect.state = .active
        window.contentView = visualEffect

        // Main vertical stack
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        visualEffect.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        // --- Section 1: Display ---
        mainStack.addArrangedSubview(makeSectionLabel("Display"))

        precisionPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        for i in 0...10 {
            precisionPopUp.addItem(withTitle: "\(i)")
        }
        precisionPopUp.target = self
        precisionPopUp.action = #selector(precisionChanged)
        mainStack.addArrangedSubview(makeRow(label: "Precision:", control: precisionPopUp, controlWidth: 70))

        fontSizePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        for size in stride(from: 10, through: 24, by: 1) {
            fontSizePopUp.addItem(withTitle: "\(size) px")
        }
        fontSizePopUp.target = self
        fontSizePopUp.action = #selector(fontSizeChanged)
        mainStack.addArrangedSubview(makeRow(label: "Font Size:", control: fontSizePopUp, controlWidth: 90))

        dateFormatPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        for option in dateFormatOptions {
            dateFormatPopUp.addItem(withTitle: option.title)
        }
        dateFormatPopUp.target = self
        dateFormatPopUp.action = #selector(dateFormatChanged)
        mainStack.addArrangedSubview(makeRow(label: "Date Format:", control: dateFormatPopUp, controlWidth: 150))

        appearancePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        for option in appearanceOptions {
            appearancePopUp.addItem(withTitle: option.title)
        }
        appearancePopUp.target = self
        appearancePopUp.action = #selector(appearanceChanged)
        mainStack.addArrangedSubview(makeRow(label: "Appearance:", control: appearancePopUp, controlWidth: 120))

        showLineNumbersCheckbox = NSButton(checkboxWithTitle: "Show Line Numbers", target: self, action: #selector(showLineNumbersChanged))
        mainStack.addArrangedSubview(showLineNumbersCheckbox)

        // --- Separator ---
        mainStack.addArrangedSubview(makeSeparator())

        // --- Section 2: Behavior ---
        mainStack.addArrangedSubview(makeSectionLabel("Behavior"))

        // Hotkey recorder
        let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleGauss)
        recorder.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(makeRow(label: "Hotkey:", control: recorder, controlWidth: 160))

        alwaysOnTopCheckbox = NSButton(checkboxWithTitle: "Always on Top", target: self, action: #selector(alwaysOnTopChanged))
        mainStack.addArrangedSubview(alwaysOnTopCheckbox)

        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        mainStack.addArrangedSubview(launchAtLoginCheckbox)

        // --- Separator ---
        mainStack.addArrangedSubview(makeSeparator())

        // --- Section 3: Data ---
        mainStack.addArrangedSubview(makeSectionLabel("Data"))

        currencyIntervalPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
        for option in currencyIntervalOptions {
            currencyIntervalPopUp.addItem(withTitle: option.title)
        }
        currencyIntervalPopUp.target = self
        currencyIntervalPopUp.action = #selector(currencyIntervalChanged)
        mainStack.addArrangedSubview(makeRow(label: "Currency Update:", control: currencyIntervalPopUp, controlWidth: 150))

        // Flexible spacer at bottom
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        mainStack.addArrangedSubview(spacer)
    }

    // MARK: - View Helpers

    private func makeSectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = Theme.textSecondary
        return label
    }

    private func makeRow(label text: String, control: NSView, controlWidth: CGFloat) -> NSStackView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = Theme.textPrimary
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 110).isActive = true

        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: controlWidth).isActive = true

        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private func makeSeparator() -> NSView {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }

    // MARK: - Load Current Settings

    private func loadCurrentSettings() {
        let settings = Settings.shared

        precisionPopUp.selectItem(at: settings.precision)

        let fontIdx = Int(settings.fontSize) - 10
        if fontIdx >= 0, fontIdx < fontSizePopUp.numberOfItems {
            fontSizePopUp.selectItem(at: fontIdx)
        }

        if let idx = dateFormatOptions.firstIndex(where: { $0.format == settings.dateFormat }) {
            dateFormatPopUp.selectItem(at: idx)
        }

        if let idx = appearanceOptions.firstIndex(where: { $0.mode == settings.appearanceMode }) {
            appearancePopUp.selectItem(at: idx)
        }

        alwaysOnTopCheckbox.state = settings.alwaysOnTop ? .on : .off
        launchAtLoginCheckbox.state = settings.launchAtLogin ? .on : .off
        showLineNumbersCheckbox.state = settings.showLineNumbers ? .on : .off

        if let idx = currencyIntervalOptions.firstIndex(where: { $0.interval == settings.currencyUpdateInterval }) {
            currencyIntervalPopUp.selectItem(at: idx)
        }
    }

    // MARK: - Actions

    @objc private func precisionChanged() {
        Settings.shared.precision = precisionPopUp.indexOfSelectedItem
    }

    @objc private func fontSizeChanged() {
        Settings.shared.fontSize = CGFloat(fontSizePopUp.indexOfSelectedItem + 10)
    }

    @objc private func dateFormatChanged() {
        let idx = dateFormatPopUp.indexOfSelectedItem
        guard idx >= 0, idx < dateFormatOptions.count else { return }
        Settings.shared.dateFormat = dateFormatOptions[idx].format
    }

    @objc private func appearanceChanged() {
        let idx = appearancePopUp.indexOfSelectedItem
        guard idx >= 0, idx < appearanceOptions.count else { return }
        Settings.shared.appearanceMode = appearanceOptions[idx].mode
    }

    @objc private func showLineNumbersChanged() {
        Settings.shared.showLineNumbers = (showLineNumbersCheckbox.state == .on)
    }

    @objc private func alwaysOnTopChanged() {
        Settings.shared.alwaysOnTop = (alwaysOnTopCheckbox.state == .on)
    }

    @objc private func launchAtLoginChanged() {
        let enabled = (launchAtLoginCheckbox.state == .on)
        Settings.shared.launchAtLogin = enabled

        // Register/unregister with the system
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                debugLog("Launch at login error: \(error)")
            }
        }
    }

    @objc private func currencyIntervalChanged() {
        let idx = currencyIntervalPopUp.indexOfSelectedItem
        guard idx >= 0, idx < currencyIntervalOptions.count else { return }
        Settings.shared.currencyUpdateInterval = currencyIntervalOptions[idx].interval
    }
}
