import Cocoa

final class LineNumberView: NSView {

    var scrollOffset: NSPoint = .zero

    private var lineMetrics: [(y: CGFloat, height: CGFloat, number: Int?)] = []
    private var textContainerInset: NSSize = NSSize(width: 8, height: 8)
    private var lineCount: Int = 1
    private var widthConstraint: NSLayoutConstraint?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(false)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(false)
        clipsToBounds = true
    }

    func attachWidthConstraint() {
        let constraint = widthAnchor.constraint(equalToConstant: Self.width(forLineCount: lineCount))
        constraint.isActive = true
        widthConstraint = constraint
    }

    func setVisible(_ visible: Bool) {
        isHidden = !visible
        widthConstraint?.constant = visible ? Self.width(forLineCount: lineCount) : 0
        needsDisplay = true
    }

    func update(textView: CalcTextView) {
        lineMetrics = textView.gutterMetrics()
        textContainerInset = textView.textContainerInset
        lineCount = max(1, lineMetrics.compactMap(\.number).max() ?? 1)
        if !isHidden {
            widthConstraint?.constant = Self.width(forLineCount: lineCount)
        }
        needsDisplay = true
    }

    private static func width(forLineCount count: Int) -> CGFloat {
        let digits = max(2, String(max(1, count)).count)
        let sample = String(repeating: "0", count: digits)
        let textWidth = NSAttributedString(
            string: sample,
            attributes: [.font: Theme.monoFontSmall]
        ).size().width
        return ceil(textWidth) + 16
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Theme.monoFontSmall,
            .foregroundColor: Theme.textSecondary,
            .paragraphStyle: paragraphStyle,
        ]

        if lineMetrics.isEmpty {
            let drawRect = NSRect(
                x: 0,
                y: textContainerInset.height,
                width: bounds.width - 6,
                height: Theme.monoFont.ascender - Theme.monoFont.descender + Theme.monoFont.leading
            )
            NSAttributedString(string: "1", attributes: attrs).draw(in: drawRect)
            return
        }

        for metric in lineMetrics {
            guard let number = metric.number else { continue }

            let y = metric.y + textContainerInset.height - scrollOffset.y
            guard y + metric.height > 0, y < bounds.height else { continue }

            let drawRect = NSRect(
                x: 0,
                y: y,
                width: bounds.width - 6,
                height: metric.height
            )
            NSAttributedString(string: "\(number)", attributes: attrs).draw(in: drawRect)
        }
    }
}
