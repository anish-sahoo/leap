import AppKit

/// Read-only, monospaced, colored view of the log buffer. Observes LogStore and
/// appends live. Used by both the standalone console window and the Logs tab.
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
        textView.isRichText = true
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
        let full = NSMutableAttributedString()
        for line in LogStore.shared.lines {
            full.append(attributed(line))
            full.append(NSAttributedString(string: "\n"))
        }
        textView.textStorage?.setAttributedString(full)
        textView.scrollToEndOfDocument(nil)
    }

    private func appendLine(_ line: String) {
        let prefix = (textView.textStorage?.length ?? 0) == 0 ? "" : "\n"
        textView.textStorage?.append(NSAttributedString(string: prefix))
        textView.textStorage?.append(attributed(line))
        textView.scrollToEndOfDocument(nil)
    }

    /// Color a "TAG [subsystem] message" line: tag by level, subsystem teal.
    private func attributed(_ line: String) -> NSAttributedString {
        let base: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.textColor]
        let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count == 3 else {
            return NSAttributedString(string: line, attributes: base)
        }
        let tag = String(parts[0])
        let rest = String(parts[1])

        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: tag + " ",
            attributes: [.font: font, .foregroundColor: color(forTag: tag)]
        ))
        if rest.hasPrefix("["), let close = rest.firstIndex(of: "]") {
            result.append(NSAttributedString(
                string: String(rest[...close]),
                attributes: [.font: font, .foregroundColor: NSColor.systemTeal]
            ))
            result.append(NSAttributedString(
                string: String(rest[rest.index(after: close)...]),
                attributes: base
            ))
        } else {
            result.append(NSAttributedString(string: rest, attributes: base))
        }
        return result
    }

    private func color(forTag tag: String) -> NSColor {
        switch tag {
        case "TRC", "DBG": .tertiaryLabelColor
        case "INF": .systemGreen
        case "NOT": .systemBlue
        case "WRN": .systemOrange
        case "ERR", "CRT": .systemRed
        default: .textColor
        }
    }
}
