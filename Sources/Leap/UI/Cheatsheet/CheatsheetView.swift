import AppKit

enum CheatsheetOrientation: String {
    case vertical, horizontal
    init(_ raw: String?) {
        self = raw.flatMap { CheatsheetOrientation(rawValue: $0.lowercased()) } ?? .vertical
    }
}

/// Frosted-glass cheat-sheet content: a title, one entry per slot (icon +
/// hotkey symbols + label), and an optional footer (e.g. the Settings shortcut).
@MainActor
final class CheatsheetView: NSVisualEffectView {
    struct Entry {
        let icon: NSImage
        let symbols: String
        let label: String
    }

    private let iconSize: CGFloat = 22

    init(slots: [Slot], orientation: CheatsheetOrientation, footer: Entry?) {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        isEmphasized = true
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor

        let entries = slots.map(entry(for:))
        let body = orientation == .horizontal
            ? buildHorizontal(entries)
            : buildVertical(entries)

        let root = NSStackView(views: [titleLabel()] + [body])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14

        if let footer {
            root.addArrangedSubview(separator())
            root.addArrangedSubview(entryRow(footer, dimmed: true))
        }

        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            root.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            root.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    // MARK: - Layouts

    private func buildVertical(_ entries: [Entry]) -> NSView {
        let stack = NSStackView(views: entries.map { entryRow($0, dimmed: false) })
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        return stack
    }

    private func buildHorizontal(_ entries: [Entry]) -> NSView {
        let cells = entries.map { entry -> NSView in
            let cell = NSStackView(views: [
                imageView(entry.icon, size: 30),
                keyField(entry.symbols),
                labelField(entry.label),
            ])
            cell.orientation = .vertical
            cell.alignment = .centerX
            cell.spacing = 5
            return cell
        }
        let row = NSStackView(views: cells)
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 22
        return row
    }

    /// One horizontal row: icon · hotkey · label.
    private func entryRow(_ entry: Entry, dimmed: Bool) -> NSView {
        let key = keyField(entry.symbols)
        key.textColor = dimmed ? .tertiaryLabelColor : .labelColor
        key.widthAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
        let label = labelField(entry.label)
        label.textColor = dimmed ? .secondaryLabelColor : .labelColor
        let row = NSStackView(views: [imageView(entry.icon, size: iconSize), key, label])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        return row
    }

    // MARK: - Entry building

    private func entry(for slot: Slot) -> Entry {
        Entry(
            icon: icon(for: slot),
            symbols: Hotkey.symbols(for: slot.hotkey),
            label: slot.displayName
        )
    }

    private func icon(for slot: Slot) -> NSImage {
        if slot.action.type == "app", let path = slot.action.target,
           FileManager.default.fileExists(atPath: path) {
            let image = NSWorkspace.shared.icon(forFile: path)
            image.size = NSSize(width: iconSize, height: iconSize)
            return image
        }
        let symbol = slot.action.type == "app" ? "app.dashed" : "terminal"
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage()
    }

    // MARK: - Fields

    private func titleLabel() -> NSTextField {
        let field = NSTextField(labelWithString: "Leap")
        field.font = .systemFont(ofSize: 13, weight: .semibold)
        field.textColor = .secondaryLabelColor
        return field
    }

    private func keyField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        field.textColor = .labelColor
        field.alignment = .right
        return field
    }

    private func labelField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 15)
        field.textColor = .labelColor
        return field
    }

    private func imageView(_ image: NSImage, size: CGFloat) -> NSImageView {
        let view = NSImageView(image: image)
        view.imageScaling = .scaleProportionallyUpOrDown
        view.widthAnchor.constraint(equalToConstant: size).isActive = true
        view.heightAnchor.constraint(equalToConstant: size).isActive = true
        return view
    }

    private func separator() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        return box
    }
}
