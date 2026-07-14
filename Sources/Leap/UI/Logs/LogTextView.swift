import AppKit

/// Read-only, monospaced view of the log buffer. Observes LogStore and appends
/// live. Used by both the standalone console window and the Settings Logs tab.
@MainActor
final class LogTextView: NSView {
    private let textView = NSTextView()
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    override init(frame: NSRect) {
        super.init(frame: frame)
        build()
        reload()
        LogStore.shared.addObserver { [weak self] line in self?.handle(line) }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    private func build() {
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        textView.isEditable = false
        textView.isRichText = false
        textView.font = font
        textView.textContainerInset = NSSize(width: 8, height: 8)
        scroll.documentView = textView

        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func handle(_ line: String) {
        if line.isEmpty {
            reload()
        } else {
            appendLine(line)
        }
    }

    private func reload() {
        textView.string = LogStore.shared.lines.joined(separator: "\n")
        textView.scrollToEndOfDocument(nil)
    }

    private func appendLine(_ line: String) {
        let prefix = textView.string.isEmpty ? "" : "\n"
        textView.textStorage?.append(NSAttributedString(
            string: prefix + line,
            attributes: [.font: font, .foregroundColor: NSColor.textColor]
        ))
        textView.scrollToEndOfDocument(nil)
    }
}
