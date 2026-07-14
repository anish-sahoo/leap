import AppKit
import UniformTypeIdentifiers

/// Modal sheet for adding or editing a single slot. Calls `completion` with the
/// resulting slot on save, or nil on cancel.
@MainActor
final class SlotEditorSheet: NSWindowController {
    private let nameField = NSTextField()
    private let hotkeyField = NSTextField()
    private let typePopup = NSPopUpButton()
    private let targetLabel = NSTextField(labelWithString: "Application")
    private let targetField = NSTextField()
    private let browseButton = NSButton()
    private let errorLabel = NSTextField(labelWithString: "")

    private let editingID: String?
    private var completion: ((Slot?) -> Void)?

    convenience init(slot: Slot?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 250),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        self.init(window: window, editingID: slot?.id)
        build()
        populate(from: slot)
        typeChanged()
    }

    private init(window: NSWindow, editingID: String?) {
        self.editingID = editingID
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    func present(over parent: NSWindow, completion: @escaping (Slot?) -> Void) {
        self.completion = completion
        window?.title = editingID == nil ? "Add Slot" : "Edit Slot"
        parent.beginSheet(window!)
    }

    // MARK: - Build

    private func build() {
        guard let content = window?.contentView else { return }
        typePopup.addItems(withTitles: ["app", "command", "script"])
        typePopup.target = self
        typePopup.action = #selector(typeChanged)
        hotkeyField.placeholderString = "alt+1"
        browseButton.title = "Browse…"
        browseButton.bezelStyle = .rounded
        browseButton.target = self
        browseButton.action = #selector(browse)
        errorLabel.font = .systemFont(ofSize: 11)
        errorLabel.textColor = .systemRed

        let targetRow = NSStackView(views: [targetField, browseButton])
        targetRow.orientation = .horizontal
        targetRow.spacing = 8
        targetField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let grid = NSGridView(views: [
            [caption("Name"), nameField],
            [caption("Hotkey"), hotkeyField],
            [caption("Type"), typePopup],
            [targetLabel, targetRow],
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.keyEquivalent = "\u{1b}"
        let save = NSButton(title: "Save", target: self, action: #selector(save))
        save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [errorLabel, cancel, save])
        buttons.spacing = 8
        buttons.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        content.addSubview(grid)
        content.addSubview(buttons)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buttons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            buttons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
        ])
    }

    private func caption(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.alignment = .right
        return field
    }

    private func populate(from slot: Slot?) {
        guard let slot else { return }
        nameField.stringValue = slot.label ?? ""
        hotkeyField.stringValue = slot.hotkey
        typePopup.selectItem(withTitle: slot.action.type)
        targetField.stringValue = slot.action.target ?? slot.action.body ?? ""
    }

    // MARK: - Actions

    @objc private func typeChanged() {
        switch typePopup.titleOfSelectedItem {
        case "command":
            targetLabel.stringValue = "Command (runs in a terminal)"
            targetField.placeholderString = "btop"
            browseButton.isHidden = true
        case "script":
            targetLabel.stringValue = "Script path"
            targetField.placeholderString = "~/.config/leap/scripts/foo.sh"
            browseButton.isHidden = false
        default:
            targetLabel.stringValue = "Application"
            targetField.placeholderString = "/Applications/Safari.app"
            browseButton.isHidden = false
        }
    }

    @objc private func browse() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if typePopup.titleOfSelectedItem == "app" {
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.allowedContentTypes = [.application]
        }
        if panel.runModal() == .OK, let url = panel.url {
            targetField.stringValue = url.path
        }
    }

    @objc private func cancel() {
        finish(with: nil)
    }

    @objc private func save() {
        guard let slot = buildSlot() else { return }
        finish(with: slot)
    }

    private func buildSlot() -> Slot? {
        let hotkey = hotkeyField.stringValue.trimmingCharacters(in: .whitespaces)
        guard Hotkey.parse(hotkey) != nil else {
            errorLabel.stringValue = "Invalid hotkey"
            return nil
        }
        let type = typePopup.titleOfSelectedItem ?? "app"
        let target = targetField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty else {
            errorLabel.stringValue = "This field is required"
            return nil
        }
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let action = SlotAction(type: type, target: target)
        return Slot(
            id: editingID ?? Self.makeID(name: name, hotkey: hotkey),
            hotkey: hotkey,
            label: name.isEmpty ? nil : name,
            action: action
        )
    }

    private func finish(with slot: Slot?) {
        if let window, let parent = window.sheetParent {
            parent.endSheet(window)
        }
        completion?(slot)
        completion = nil
    }

    private static func makeID(name: String, hotkey: String) -> String {
        let base = name.isEmpty ? hotkey : name
        let slug = base.lowercased().filter { $0.isLetter || $0.isNumber }
        return slug.isEmpty ? "slot-\(UInt(bitPattern: hotkey.hashValue) % 100_000)" : slug
    }
}
