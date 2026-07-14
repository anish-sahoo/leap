import AppKit

/// Where the overlay appears on the active screen.
enum CheatsheetPosition: String {
    case center
    case top, bottom, left, right
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"

    init(_ raw: String?) {
        self = raw.flatMap { CheatsheetPosition(rawValue: $0.lowercased()) } ?? .center
    }
}

/// Floating, non-activating, click-through panel that hosts the cheat sheet.
/// It never becomes key or activates the app, so showing it does not change
/// which app is frontmost (window cycling depends on that).
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

    func present(_ content: NSView, at position: CheatsheetPosition) {
        contentView = content
        setContentSize(content.fittingSize)
        setFrameOrigin(origin(for: position))
        orderFrontRegardless()
    }

    private func origin(for position: CheatsheetPosition) -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let area = screen.visibleFrame
        let size = frame.size
        let margin: CGFloat = 28

        let minX = area.minX + margin
        let maxX = area.maxX - size.width - margin
        let midX = area.midX - size.width / 2
        let minY = area.minY + margin
        let maxY = area.maxY - size.height - margin
        let midY = area.midY - size.height / 2

        switch position {
        case .center: return NSPoint(x: midX, y: midY)
        case .top: return NSPoint(x: midX, y: maxY)
        case .bottom: return NSPoint(x: midX, y: minY)
        case .left: return NSPoint(x: minX, y: midY)
        case .right: return NSPoint(x: maxX, y: midY)
        case .topLeft: return NSPoint(x: minX, y: maxY)
        case .topRight: return NSPoint(x: maxX, y: maxY)
        case .bottomLeft: return NSPoint(x: minX, y: minY)
        case .bottomRight: return NSPoint(x: maxX, y: minY)
        }
    }
}
