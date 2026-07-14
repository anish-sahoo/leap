import AppKit

enum CheatsheetOrientation: String {
    case vertical, horizontal
    init(_ raw: String?) {
        self = raw.flatMap { CheatsheetOrientation(rawValue: $0.lowercased()) } ?? .vertical
    }
}

/// Frosted-glass cheat sheet: a title, one clickable entry per slot
/// (icon · name … shortcut), and a footer (the Settings shortcut).
/// Entries highlight on hover and invoke `onSelect` / `onSettings` on click.
@MainActor
final class CheatsheetView: NSVisualEffectView {
    struct Entry {
        let icon: NSImage
        let symbols: String
        let label: String
    }

    private let iconSize: CGFloat = 22
    private let verticalWidth: CGFloat = 240

    init(
        slots: [Slot],
        orientation: CheatsheetOrientation,
        footer: Entry?,
        onSelect: @escaping (Int) -> Void,
        onSettings: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        configureAppearance()

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.addArrangedSubview(titleLabel())

        let entries = slots.map(entry(for:))
        root.addArrangedSubview(bodyView(entries, orientation: orientation, onSelect: onSelect))

        var fullWidth: [NSView] = []
        if let footer {
            let separator = separatorLine()
            let button = HoverButton(content: rowContent(footer, dimmed: true), onClick: onSettings)
            root.addArrangedSubview(separator)
            root.addArrangedSubview(button)
            fullWidth = [separator, button]
        }

        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            root.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            root.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
        fullWidth.forEach { $0.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    private func configureAppearance() {
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        isEmphasized = true
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
    }

    private func bodyView(
        _ entries: [Entry],
        orientation: CheatsheetOrientation,
        onSelect: @escaping (Int) -> Void
    ) -> NSView {
        if orientation == .horizontal {
            let cells = entries.enumerated().map { index, entry in
                HoverButton(content: cellContent(entry)) { onSelect(index) }
            }
            let row = NSStackView(views: cells)
            row.orientation = .horizontal
            row.alignment = .top
            row.spacing = 14
            return row
        }
        let rows = entries.enumerated().map { index, entry in
            HoverButton(content: rowContent(entry, dimmed: false)) { onSelect(index) }
        }
        let body = NSStackView(views: rows)
        body.orientation = .vertical
        body.alignment = .leading
        body.spacing = 3
        body.widthAnchor.constraint(equalToConstant: verticalWidth).isActive = true
        rows.forEach { $0.widthAnchor.constraint(equalTo: body.widthAnchor).isActive = true }
        return body
    }

    // MARK: - Row layouts

    /// Vertical list row: icon · name … shortcut (shortcut pinned right).
    private func rowContent(_ entry: Entry, dimmed: Bool) -> NSView {
        let label = labelField(entry.label)
        label.textColor = dimmed ? .secondaryLabelColor : .labelColor
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let key = keyField(entry.symbols)
        key.textColor = dimmed ? .tertiaryLabelColor : .secondaryLabelColor
        key.setContentHuggingPriority(.required, for: .horizontal)

        let row = NSStackView(views: [imageView(entry.icon, size: iconSize), label, key])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.distribution = .fill
        return row
    }

    /// Horizontal grid cell: icon over name over shortcut.
    private func cellContent(_ entry: Entry) -> NSView {
        let cell = NSStackView(views: [
            imageView(entry.icon, size: 30),
            labelField(entry.label),
            keyField(entry.symbols),
        ])
        cell.orientation = .vertical
        cell.alignment = .centerX
        cell.spacing = 4
        return cell
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
        field.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
        field.alignment = .right
        return field
    }

    private func labelField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 15)
        return field
    }

    private func imageView(_ image: NSImage, size: CGFloat) -> NSImageView {
        let view = NSImageView(image: image)
        view.imageScaling = .scaleProportionallyUpOrDown
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.widthAnchor.constraint(equalToConstant: size).isActive = true
        view.heightAnchor.constraint(equalToConstant: size).isActive = true
        return view
    }

    private func separatorLine() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        return box
    }
}
