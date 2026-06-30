import Cocoa

/// Floating overlay notification that auto-dismisses after a short delay.
/// Shows a confirmation message when a result is copied to the clipboard.
final class ToastView: NSView {

    private let label = NSTextField(labelWithString: "")
    private var dismissTimer: Timer?

    private static let displayDuration: TimeInterval = 1.5
    private static let animationDuration: TimeInterval = 0.25

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 8

        label.font = Theme.monoFontSmall
        label.textColor = Theme.toastText
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Accessibility
        setAccessibilityIdentifier("toastView")
        setAccessibilityRole(.staticText)
    }

    override func updateLayer() {
        layer?.backgroundColor = Theme.toastBackground.cgColor
    }

    // MARK: - Show Toast

    /// Shows a toast notification in the given parent view.
    static func show(in parentView: NSView, message: String) {
        // Remove any existing toast
        for subview in parentView.subviews where subview is ToastView {
            subview.removeFromSuperview()
        }

        let toast = ToastView()
        toast.label.stringValue = message
        toast.alphaValue = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -50),
            toast.heightAnchor.constraint(equalToConstant: 32),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])

        parentView.layoutSubtreeIfNeeded()

        // Accessibility: set label for VoiceOver
        toast.setAccessibilityLabel(message)

        // Respect the user's "Reduce Motion" accessibility preference
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            // Skip animation — appear and disappear instantly
            toast.alphaValue = 1
            toast.dismissTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { _ in
                toast.removeFromSuperview()
            }
        } else {
            // Fade in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = animationDuration
                toast.animator().alphaValue = 1
            }

            // Schedule auto-dismiss with fade out
            toast.dismissTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { _ in
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = animationDuration
                    toast.animator().alphaValue = 0
                }, completionHandler: {
                    toast.removeFromSuperview()
                })
            }
        }
    }

    deinit {
        dismissTimer?.invalidate()
    }
}
