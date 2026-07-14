import AppKit

/// Form-based settings tab: cheat-sheet preferences plus an editable table of
/// slots. Holds a working copy of the config; `load` / `currentConfig` sync it
/// with the TOML tab.
@MainActor
final class SettingsFormView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private var version = 1
    private var slots: [Slot] = []
    private var activeSheet: SlotEditorSheet?

    private let table = NSTableView()
    private let terminalPopup = NSPopUpButton()
    private let terminalCommandField = NSTextField()
    private let triggerPopup = NSPopUpButton()
    private let positionPopup = NSPopUpButton()
    private let orientationPopup = NSPopUpButton()
    private let delayField = NSTextField()

    private let triggers = ["alt", "cmd", "ctrl", "shift"]
    private let positions = [
        "center", "top", "bottom", "left", "right",
        "top-left", "top-right", "bottom-left", "bottom-right",
    ]
    private let orientations = ["vertical", "horizontal"]

    private struct Column { let id, title: String; let width: CGFloat }
    private let columns: [Column] = [
        Column(id: "hotkey", title: "Hotkey", width: 90),
        Column(id: "name", title: "Name", width: 130),
        Column(id: "type", title: "Type", width: 80),
        Column(id: "target", title: "Target / path / command", width: 240),
    ]

    override init(frame: NSRect) {
        super.init(frame: frame)
        build()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    // MARK: - Sync

    func load(_ config: Config) {
        version = config.version
        slots = config.slots
        terminalPopup.selectItem(withTitle: config.terminal ?? "auto")
        terminalCommandField.stringValue = config.terminalCommand ?? ""
        triggerPopup.selectItem(withTitle: config.cheatsheet?.trigger ?? "alt")
        positionPopup.selectItem(withTitle: config.cheatsheet?.position ?? "center")
        orientationPopup.selectItem(withTitle: config.cheatsheet?.orientation ?? "vertical")
        delayField.stringValue = String(config.cheatsheet?.delayMs ?? 150)
        table.reloadData()
    }

    func currentConfig() -> Config {
        let cheatsheet = CheatsheetConfig(
            trigger: triggerPopup.titleOfSelectedItem,
            position: positionPopup.titleOfSelectedItem,
            orientation: orientationPopup.titleOfSelectedItem,
            delayMs: Int(delayField.stringValue) ?? 150
        )
        let custom = terminalCommandField.stringValue.trimmingCharacters(in: .whitespaces)
        return Config(
            version: version,
            slots: slots,
            cheatsheet: cheatsheet,
            terminal: terminalPopup.titleOfSelectedItem,
            terminalCommand: custom.isEmpty ? nil : custom
        )
    }

    // MARK: - Layout

    private func build() {
        for popup in [terminalPopup, triggerPopup, positionPopup, orientationPopup] {
            popup.translatesAutoresizingMaskIntoConstraints = false
        }
        terminalPopup.addItems(withTitles: TerminalApp.allCases.map(\.rawValue))
        triggerPopup.addItems(withTitles: triggers)
        positionPopup.addItems(withTitles: positions)
        orientationPopup.addItems(withTitles: orientations)
        delayField.translatesAutoresizingMaskIntoConstraints = false
        delayField.placeholderString = "150"
        delayField.widthAnchor.constraint(equalToConstant: 60).isActive = true
        terminalCommandField.translatesAutoresizingMaskIntoConstraints = false
        terminalCommandField.placeholderString = "custom: … {cmd} …"
        terminalCommandField.widthAnchor.constraint(equalToConstant: 260).isActive = true

        let generalRow = row([
            labeled("Run commands in", terminalPopup),
            labeled("Custom command", terminalCommandField),
        ])
        let cheatsheetRow = row([
            labeled("Trigger", triggerPopup), labeled("Position", positionPopup),
            labeled("Layout", orientationPopup), labeled("Delay (ms)", delayField),
        ])

        let sections: [NSView] = [
            sectionTitle("General"), generalRow,
            sectionTitle("Cheat sheet"), cheatsheetRow,
            sectionTitle("Slots"),
        ]
        let scroll = buildTable()
        let buttons = buildButtons()
        (sections + [scroll, buttons]).forEach(addSubview)
        layoutSections(sections + [scroll, buttons])
    }

    private func row(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.spacing = 16
        stack.alignment = .bottom
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func buildTable() -> NSScrollView {
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.rowHeight = 22
        table.target = self
        table.doubleAction = #selector(editSelected)
        for column in columns {
            let col = NSTableColumn(identifier: .init(column.id))
            col.title = column.title
            col.width = column.width
            table.addTableColumn(col)
        }
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = table
        return scroll
    }

    private func buildButtons() -> NSStackView {
        let add = NSButton(title: "+", target: self, action: #selector(addSlot))
        let remove = NSButton(title: "−", target: self, action: #selector(removeSlot))
        let stack = NSStackView(views: [add, remove])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 6
        return stack
    }

    /// Stacks the ordered views top-to-bottom; the second-to-last (the table
    /// scroll view) stretches to fill, and the last (buttons) pins to the bottom.
    private func layoutSections(_ views: [NSView]) {
        guard let scroll = views.dropLast().last, let buttons = views.last else { return }
        let inset: CGFloat = 16
        var constraints: [NSLayoutConstraint] = []
        var previousBottom = topAnchor
        var topSpacing: CGFloat = inset
        for view in views.dropLast() {
            constraints.append(view.topAnchor.constraint(
                equalTo: previousBottom,
                constant: topSpacing
            ))
            constraints.append(view.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: inset
            ))
            previousBottom = view.bottomAnchor
            topSpacing = 8
        }
        constraints += [
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            buttons.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            buttons.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 8),
            buttons.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func sectionTitle(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: 13, weight: .semibold)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }

    private func labeled(_ title: String, _ control: NSView) -> NSStackView {
        let caption = NSTextField(labelWithString: title)
        caption.font = .systemFont(ofSize: 10)
        caption.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [caption, control])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        return stack
    }

    // MARK: - Row editing

    @objc private func addSlot() {
        presentEditor(slot: nil) { [weak self] new in
            guard let self, let new else { return }
            slots.append(new)
            table.reloadData()
        }
    }

    @objc private func editSelected() {
        let row = table.clickedRow >= 0 ? table.clickedRow : table.selectedRow
        guard slots.indices.contains(row) else { return }
        presentEditor(slot: slots[row]) { [weak self] edited in
            guard let self, let edited else { return }
            slots[row] = edited
            table.reloadData()
        }
    }

    @objc private func removeSlot() {
        guard table.selectedRow >= 0 else { return }
        slots.remove(at: table.selectedRow)
        table.reloadData()
    }

    private func presentEditor(slot: Slot?, completion: @escaping (Slot?) -> Void) {
        guard let window else { return }
        let sheet = SlotEditorSheet(slot: slot)
        activeSheet = sheet
        sheet.present(over: window) { [weak self] result in
            self?.activeSheet = nil
            completion(result)
        }
    }

    func numberOfRows(in _: NSTableView) -> Int {
        slots.count
    }

    func tableView(_: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        guard let id = column?.identifier.rawValue, slots.indices.contains(row) else { return nil }
        let field = NSTextField(labelWithString: value(id, row: row))
        field.font = .systemFont(ofSize: 12)
        field.lineBreakMode = .byTruncatingTail
        return field
    }

    private func value(_ columnID: String, row: Int) -> String {
        let slot = slots[row]
        switch columnID {
        case "hotkey": return slot.hotkey
        case "name": return slot.displayName
        case "type": return slot.action.type
        case "target": return slot.action.target ?? slot.action.body ?? ""
        default: return ""
        }
    }
}
