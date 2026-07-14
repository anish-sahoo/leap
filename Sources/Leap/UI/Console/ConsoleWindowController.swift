import AppKit

/// A simple log console: a read-only, monospaced NSTextView fed by LogStore.
@MainActor
final class ConsoleWindowController: NSWindowController {
    private var textView: NSTextView!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Leap Console"
        window.isReleasedWhenClosed = false // reuse across open/close
        self.init(window: window)
        window.center()
        setupTextView()
        reload()

        LogStore.shared.onAppend = { [weak self] line in
            self?.appendLine(line)
        }
    }

    private func setupTextView() {
        guard let content = window?.contentView else { return }
        let scroll = NSScrollView(frame: content.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = false
        tv.isRichText = false
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.textContainerInset = NSSize(width: 8, height: 8)

        scroll.documentView = tv
        content.addSubview(scroll)
        textView = tv
    }

    private func reload() {
        textView.string = LogStore.shared.lines.joined(separator: "\n")
        textView.scrollToEndOfDocument(nil)
    }

    private func appendLine(_ line: String) {
        // Empty line is the "cleared" signal from LogStore.
        if line.isEmpty {
            reload()
            return
        }
        let prefix = textView.string.isEmpty ? "" : "\n"
        textView.textStorage?.append(NSAttributedString(
            string: prefix + line,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.textColor,
            ]
        ))
        textView.scrollToEndOfDocument(nil)
    }
}
