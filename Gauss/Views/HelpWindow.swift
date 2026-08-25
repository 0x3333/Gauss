import Cocoa

final class HelpWindowController: NSWindowController {

    init() {
        let window = HelpPanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Gauss Help"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 560, height: 360)
        window.center()

        super.init(window: window)
        setupContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContentView() {
        guard let window = window else { return }

        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.material = .sidebar
        visualEffect.state = .active
        window.contentView = visualEffect

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        visualEffect.addSubview(scrollView)

        let columns = HelpColumnsView()
        scrollView.documentView = columns
        if let helpWindow = window as? HelpPanelWindow {
            helpWindow.columns = columns
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])
    }
}

/// No Edit menu in this LSUIElement app — handle Cmd+C / Cmd+A on the window.
private final class HelpPanelWindow: NSWindow {
    weak var columns: HelpColumnsView?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if columns?.handleCommand(event) == true { return true }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if columns?.handleCommand(event) == true { return }
        super.keyDown(with: event)
    }
}

private final class HelpColumnsView: NSView {
    private let leftText = HelpTextView.makeColumn(HelpContent.attributedString(for: HelpContent.leftSections))
    private let rightText = HelpTextView.makeColumn(HelpContent.attributedString(for: HelpContent.rightSections))

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(leftText)
        addSubview(rightText)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handleCommand(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command), !flags.contains(.shift),
              let key = event.charactersIgnoringModifiers?.lowercased() else {
            return false
        }
        let target = textViewForCommand()
        switch key {
        case "c":
            target.copy(nil)
            return true
        case "a":
            target.selectAll(nil)
            return true
        default:
            return false
        }
    }

    private func textViewForCommand() -> NSTextView {
        if leftText.selectedRange().length > 0 { return leftText }
        if rightText.selectedRange().length > 0 { return rightText }
        if window?.firstResponder === rightText { return rightText }
        return leftText
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let clip = superview {
            setFrameSize(NSSize(width: clip.bounds.width, height: bounds.height))
            autoresizingMask = [.width]
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let inset: CGFloat = 16
        let gutter: CGFloat = 28
        let width = bounds.width
        let colW = max(120, (width - inset * 2 - gutter) / 2)

        let leftH = measuredHeight(leftText, width: colW)
        let rightH = measuredHeight(rightText, width: colW)
        let contentH = max(leftH, rightH) + inset * 2

        leftText.frame = NSRect(x: inset, y: inset, width: colW, height: leftH)
        rightText.frame = NSRect(x: inset + colW + gutter, y: inset, width: colW, height: rightH)

        if abs(bounds.height - contentH) > 0.5 {
            setFrameSize(NSSize(width: width, height: contentH))
        }
    }

    private func measuredHeight(_ textView: NSTextView, width: CGFloat) -> CGFloat {
        guard let container = textView.textContainer, let layout = textView.layoutManager else {
            return 0
        }
        container.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        layout.ensureLayout(for: container)
        return ceil(layout.usedRect(for: container).height) + textView.textContainerInset.height * 2
    }
}

private final class HelpTextView: NSTextView {
    static func makeColumn(_ content: NSAttributedString) -> HelpTextView {
        let textView = HelpTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.textContainer?.lineFragmentPadding = 4
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.heightTracksTextView = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.textStorage?.setAttributedString(content)
        return textView
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}
