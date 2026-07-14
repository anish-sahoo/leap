# Architecture

Leap is a Swift 6 menu-bar app built with SwiftPM. The code is split so the
OS-specific parts are quarantined behind protocols and the rest stays portable
and testable.

## Layers

```
UI (AppKit)         App/, UI/       menu bar, cheat sheet, settings, logs
      │
Domain (pure)       Core/           Config, validation, action dispatch
      │  protocols
Platform (macOS)    Platform/       hotkeys (Carbon), windows (Accessibility)
```

- **Core** has no AppKit/Carbon imports. `ActionDispatcher` depends only on the
  `WindowSwitching` protocol, so it's unit-testable and a future port would only
  reimplement the platform layer.
- **Platform** holds the two privileged capabilities:
  - `HotkeyManager` — global hotkeys via Carbon `RegisterEventHotKey`.
  - `AXWindowController` — launch/focus/cycle via the Accessibility API.
- **Logging** — a swift-log facade with two backends: a colored stdout handler
  and the in-app log views (`LogStore` + `ConsoleLogHandler`).

## Source layout

```
Sources/Leap/
├── main.swift
├── App/            AppDelegate, LoginItem, AppVersion
├── UI/
│   ├── Cheatsheet/ overlay panel, view, hover button
│   ├── Settings/   window (form + TOML + logs tabs), slot editor, TOML highlighter
│   └── Logs/       LogTextView, ConsoleWindowController
├── Logging/        Logging (facade + handlers), LogStore
├── Core/
│   ├── Config/     Config model, ConfigStore, ConfigValidator (TOML)
│   └── Actions/    ActionDispatcher, ActionRunner, TerminalLauncher
└── Platform/
    ├── Hotkeys/    Hotkey (parser), HotkeyManager
    └── Windows/    WindowSwitching, AXWindowController, Accessibility
```

## The switching state machine

`AXWindowController.handle(_:)` ports the Hammerspoon prototype's behavior:

1. Not running → launch.
2. Running, no standard windows → open a new window (Cmd-N).
3. Running, has windows, not frontmost → focus + raise the front window.
4. Already frontmost → cycle to the next window (windows sorted by position for
   a stable cycle order).

## Permissions

Window control requires the **Accessibility** permission. Hotkey registration
does not (Carbon `RegisterEventHotKey` needs no entitlement, unlike a
`CGEventTap`). See `Platform/Windows/Accessibility.swift`.
