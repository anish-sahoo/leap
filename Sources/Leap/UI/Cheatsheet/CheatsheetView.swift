import AppKit

/// Frosted-glass content for the cheat sheet: a title plus a two-column grid of
/// hotkey symbols and their labels.
@MainActor
final class CheatsheetView: NSVisualEffectView {
    init(slots: [Slot]) {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        build(slots: slots)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    private func build(slots: [Slot]) {
        let title = NSTextField(labelWithString: "Leap")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .secondaryLabelColor

        let rows: [[NSView]] = slots.map { slot in
            [keyField(Hotkey.symbols(for: slot.hotkey)), labelField(slot.label)]
        }
        let grid = NSGridView(views: rows)
        grid.rowSpacing = 8
        grid.columnSpacing = 18
        grid.column(at: 0).xPlacement = .trailing

        let stack = NSStackView(views: [title, grid])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
        ])
    }

    private func keyField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        field.textColor = .labelColor
        return field
    }

    private func labelField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 15)
        field.textColor = .labelColor
        return field
    }
}
