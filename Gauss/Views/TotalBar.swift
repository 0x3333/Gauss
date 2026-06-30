import Cocoa

/// Bottom bar showing the running total of all calculated results.
final class TotalBar: NSView {

    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true

        label.font = Theme.totalBarFont
        label.textColor = Theme.totalBarText
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Accessibility
        setAccessibilityIdentifier("totalBar")
        setAccessibilityLabel("Total")
        setAccessibilityRole(.staticText)
    }

    override func updateLayer() {
        layer?.backgroundColor = Theme.totalBarBackground.cgColor
    }

    func update(totalText: String) {
        if totalText.isEmpty || totalText == "0" {
            label.stringValue = ""
            setAccessibilityValue("")
        } else {
            label.stringValue = "Total: \(totalText)"
            setAccessibilityValue("Total: \(totalText)")
        }
        label.textColor = Theme.totalBarText
    }
}
