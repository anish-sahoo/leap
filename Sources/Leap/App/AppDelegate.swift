import AppKit
import UniformTypeIdentifiers

/// Menu-bar-resident app: loads config, registers global hotkeys, and runs the
/// launch/focus/cycle behavior (or a script/command) when one is pressed.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var config = Config.starter
    private var consoleController: ConsoleWindowController?
    private var editorController: ConfigEditorWindowController?
    private let dispatcher = ActionDispatcher(windows: AXWindowController())
    private let cheatsheet = CheatsheetController()

    func applicationDidFinishLaunching(_: Notification) {
        // Accessory = lives in the menu bar, no Dock icon, doesn't steal focus.
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        HotkeyManager.shared.start()
        cheatsheet.start()

        // Window control needs Accessibility permission; prompt on first launch.
        if Accessibility.requestIfNeeded() {
            Log.app.info("accessibility: granted")
        } else {
            Log.app
                .warning(
                    "accessibility: NOT granted — window switching will not work until you grant it"
                )
        }

        reload()
    }

    // MARK: - Menu bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⌥"

        let menu = NSMenu()
        menu.addItem(withTitle: "Leap \(appVersion)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Edit Config…", action: #selector(editConfig), keyEquivalent: "e")
            .target = self
        menu.addItem(withTitle: "Reload Config", action: #selector(reload), keyEquivalent: "r")
            .target = self
        menu.addItem(
            withTitle: "Open Config Folder",
            action: #selector(openConfigFolder),
            keyEquivalent: ""
        )
        .target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Import Config…",
            action: #selector(importConfig),
            keyEquivalent: ""
        )
        .target = self
        menu.addItem(
            withTitle: "Export Config…",
            action: #selector(exportConfig),
            keyEquivalent: ""
        )
        .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Show Console", action: #selector(showConsole), keyEquivalent: "c")
            .target = self
        menu.addItem(
            withTitle: "Accessibility Permission…",
            action: #selector(openAccessibility),
            keyEquivalent: ""
        )
        .target = self
        menu.addItem(.separator())
        let loginItem = menu.addItem(
            withTitle: "Start at Login",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
            .target = self
        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func reload() {
        HotkeyManager.shared.reset()
        config = ConfigStore.load()

        for slot in config.slots {
            guard let hotkey = Hotkey.parse(slot.hotkey) else {
                Log.app.warning("could not parse hotkey '\(slot.hotkey)' for slot '\(slot.id)'")
                continue
            }
            let label = slot.label
            let combo = slot.hotkey
            let action = slot.action
            let ok = HotkeyManager.shared.register(hotkey) { [weak self] in
                self?.cheatsheet.dismiss()
                Log.app.info("fired \(combo) -> \(label)")
                self?.dispatcher.perform(action, label: label)
            }
            Log.app.info("bound \(combo) -> \(label) \(ok ? "✓" : "✗ (in use?)")")
        }
        cheatsheet.update(slots: config.slots)
        Log.app.info("ready — \(config.slots.count) slots")
    }

    @objc private func openConfigFolder() {
        NSWorkspace.shared.open(ConfigStore.directory)
    }

    @objc private func editConfig() {
        if editorController == nil {
            editorController = ConfigEditorWindowController()
            editorController?.onSaved = { [weak self] in self?.reload() }
        }
        NSApp.activate(ignoringOtherApps: true)
        editorController?.showWindow(nil)
        editorController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "toml")!, .plainText]
        panel.allowsMultipleSelection = false
        panel.message = "Choose a Leap config to import (your current one is backed up)."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ConfigStore.import(from: url)
            reload()
        } catch {
            presentError("Import failed", error)
        }
    }

    @objc private func exportConfig() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "toml")!]
        panel.nameFieldStringValue = "leap-config.toml"
        panel.message = "Export your config to share it."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ConfigStore.export(to: url)
        } catch {
            presentError("Export failed", error)
        }
    }

    private func presentError(_ title: String, _ error: Error) {
        Log.app.error("\(title): \(error.localizedDescription)")
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc private func showConsole() {
        if consoleController == nil {
            consoleController = ConsoleWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        consoleController?.showWindow(nil)
        consoleController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func openAccessibility() {
        if Accessibility.isTrusted {
            Log.app.info("accessibility already granted")
        }
        Accessibility.openSettings()
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        let newValue = !LoginItem.isEnabled
        LoginItem.setEnabled(newValue)
        sender.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
