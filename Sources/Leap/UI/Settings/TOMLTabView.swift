import AppKit

/// Raw-TOML editor tab: a monospaced NSTextView with live syntax highlighting
/// and a validation status line. `onChange` fires whenever the text changes.
@MainActor
final class TOMLTabView: NSView, NSTextViewDelegate {
    var onChange: (() -> Void)?

    private let textView = NSTextView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    override init(frame: NSRect) {
        super.init(frame: frame)
        build()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    var text: String {
        textView.string
    }

    func setText(_ value: String) {
        textView.string = value
        rehighlight()
        validate()
    }

    private func build() {
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder

        textView.delegate = self
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = font
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.autoresizingMask = [.width]
        scroll.documentView = textView

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 3

        addSubview(scroll)
        addSubview(statusLabel)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func textDidChange(_: Notification) {
        rehighlight()
        validate()
        onChange?()
    }

    private func rehighlight() {
        guard let storage = textView.textStorage else { return }
        let selected = textView.selectedRange()
        TOMLHighlighter.apply(to: storage, font: font)
        textView.setSelectedRange(selected)
    }

    private func validate() {
        let problems = ConfigValidator.validate(textView.string)
        if problems.isEmpty {
            statusLabel.textColor = .systemGreen
            statusLabel.stringValue = "Valid ✓"
        } else {
            statusLabel.textColor = .systemRed
            statusLabel.stringValue = "✗ " + problems.prefix(3).joined(separator: "  •  ")
        }
    }
}
