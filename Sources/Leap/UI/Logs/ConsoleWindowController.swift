import AppKit

/// Standalone window that shows the log console (a LogTextView).
@MainActor
final class ConsoleWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Leap Console"
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.center()
        window.contentView = LogTextView(frame: window.contentLayoutRect)
    }
}
