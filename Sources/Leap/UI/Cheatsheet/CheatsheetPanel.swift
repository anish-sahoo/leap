import AppKit

/// Floating, non-activating, click-through panel that lists the bound hotkeys.
/// Critically it never becomes key or activates the app, so showing it does not
/// change which app is frontmost (window cycling depends on that).
@MainActor
final class CheatsheetPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    func present(slots: [Slot]) {
        let content = CheatsheetView(slots: slots)
        contentView = content
        setContentSize(content.fittingSize)
        centerOnActiveScreen()
        orderFrontRegardless()
    }

    private func centerOnActiveScreen() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = frame.size
        setFrameOrigin(NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        ))
    }
}
