import AppKit

/// Settings window with three tabs: a form editor, a raw-TOML editor, and a
/// live log view. Switching between form and TOML syncs the config both ways;
/// leaving the TOML tab is blocked while the TOML is invalid.
@MainActor
final class SettingsWindowController: NSWindowController {
    /// Called after a successful save so the app can re-bind hotkeys.
    var onSaved: (() -> Void)?

    private enum Tab: Int { case form, toml, logs }

    private let segmented = NSSegmentedControl(
        labels: ["Settings", "TOML", "Logs"],
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let container = NSView()
    private let formView = SettingsFormView()
    private let tomlView = TOMLTabView()
    private let logsView = LogTextView()
    private let statusLabel = NSTextField(labelWithString: "")
    private var current: Tab = .form

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Leap Settings"
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.center()
        build()
        loadFromDisk()
    }

    // MARK: - Layout

    private func build() {
        guard let content = window?.contentView else { return }
        segmented.selectedSegment = 0
        segmented.target = self
        segmented.action = #selector(tabChanged)

        let save = NSButton(title: "Save", target: self, action: #selector(save))
        save.keyEquivalent = "\r"
        let revert = NSButton(title: "Revert", target: self, action: #selector(loadFromDisk))
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor

        for view in [segmented, container, formView, tomlView, logsView, save, revert,
                     statusLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        content.addSubview(segmented)
        content.addSubview(container)
        content.addSubview(statusLabel)
        content.addSubview(revert)
        content.addSubview(save)
        for tab in [formView, tomlView, logsView] {
            container.addSubview(tab)
            pin(tab, to: container)
        }
        tomlView.isHidden = true
        logsView.isHidden = true

        layoutChrome(content: content, save: save, revert: revert)
    }

    private func layoutChrome(content: NSView, save: NSView, revert: NSView) {
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            segmented.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            container.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            save.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
            save.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
            revert.centerYAnchor.constraint(equalTo: save.centerYAnchor),
            revert.trailingAnchor.constraint(equalTo: save.leadingAnchor, constant: -8),
            statusLabel.centerYAnchor.constraint(equalTo: save.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
            container.bottomAnchor.constraint(equalTo: save.topAnchor, constant: -10),
        ])
    }

    private func pin(_ view: NSView, to parent: NSView) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parent.topAnchor),
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 8),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -8),
            view.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }

    // MARK: - Sync

    @objc private func loadFromDisk() {
        let config = ConfigStore.load()
        formView.load(config)
        tomlView.setText(ConfigStore.rawText())
        segmented.selectedSegment = 0
        showTab(.form)
        setStatus("", isError: false)
    }

    @objc private func tabChanged() {
        let target = Tab(rawValue: segmented.selectedSegment) ?? .form
        guard target != current else { return }

        // Leaving the TOML tab: parse it back into the (canonical) form; block
        // the switch if the TOML is invalid.
        if current == .toml {
            do {
                try formView.load(ConfigStore.validate(tomlView.text))
            } catch {
                segmented.selectedSegment = Tab.toml.rawValue
                setStatus("Fix TOML errors before switching tabs", isError: true)
                return
            }
        }
        // Entering the TOML tab: regenerate it from the form.
        if target == .toml, let text = try? ConfigStore.serialize(formView.currentConfig()) {
            tomlView.setText(text)
        }
        showTab(target)
    }

    private func showTab(_ tab: Tab) {
        current = tab
        formView.isHidden = tab != .form
        tomlView.isHidden = tab != .toml
        logsView.isHidden = tab != .logs
    }

    // MARK: - Save

    @objc private func save() {
        do {
            if current == .toml {
                try ConfigStore.writeRaw(tomlView.text)
            } else {
                try ConfigStore.save(formView.currentConfig())
            }
            setStatus("Saved ✓  bindings reloaded", isError: false)
            onSaved?()
        } catch {
            setStatus("✗ \(error.localizedDescription)", isError: true)
        }
    }

    private func setStatus(_ text: String, isError: Bool) {
        statusLabel.stringValue = text
        statusLabel.textColor = isError ? .systemRed : .secondaryLabelColor
    }
}
