import AppKit

/// A lightweight clickable row: highlights on hover and invokes `onClick` when
/// released inside its bounds. `acceptsFirstMouse` is true so a click registers
/// even though the panel never becomes active.
@MainActor
final class HoverButton: NSView {
    private let onClick: () -> Void
    private var trackingAreaRef: NSTrackingArea?

    init(content: NSView, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        translatesAutoresizingMaskIntoConstraints = false

        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with _: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.16).cgColor
    }

    override func mouseExited(with _: NSEvent) {
        layer?.backgroundColor = nil
    }

    override func mouseDown(with _: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.26).cgColor
    }

    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.16).cgColor
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onClick()
        }
    }
}
