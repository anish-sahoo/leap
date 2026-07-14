# AGENTS.md

Context for AI coding agents working in this repo. Humans: see
[CONTRIBUTING.md](CONTRIBUTING.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

## What this is

Leap — a macOS menu-bar hotkey launcher. Swift 6 + AppKit, SwiftPM, macOS 14+.
Runs as a menu-bar accessory (no Dock icon).

## Commands

```sh
mise run build      # swift build
mise run test       # swift test  (Swift Testing)
mise run check      # SwiftFormat --lint + SwiftLint --strict  (must pass)
mise run open       # bundle + launch Leap.app
```

Prefer `mise run …`; the raw equivalents (`swift build`/`test`) also work.

## Hard rules

- **Never add an AI co-author trailer** (e.g. `Co-Authored-By: …`) to commits.
- **Conventional Commits** are enforced by a `commit-msg` hook (run `mise run setup`).
- **`mise run check` and `swift test` must pass** before you commit.
- **Swift 6 strict concurrency** — keep it building without warnings.
- **Respect the layering** (see below). Don't import AppKit/Carbon into `Core/`.

## Layout

```
Sources/Leap/
  App/         AppDelegate, LoginItem, AppVersion
  UI/          Cheatsheet/, Settings/, Logs/   (AppKit)
  Logging/     swift-log facade + LogStore
  Core/        Config/ (model, store, validator), Actions/ (dispatch, runner, terminal)
  Platform/    Hotkeys/ (Carbon), Windows/ (Accessibility)
Tests/LeapTests/   pure-logic tests (hotkey parsing, config validation)
```

- `Core/` is pure (no OS frameworks). `ActionDispatcher` talks to the platform
  only through the `WindowSwitching` protocol.
- Config is TOML at `~/.config/leap/config.toml`; the model is `Config`
  (Codable). Add new fields there **and** in `ConfigValidator` (allowed keys).

## Gotchas

- **Window control needs the Accessibility permission**; hotkeys (Carbon) don't.
- **Commands run in a terminal.** Terminal.app/iTerm2 use AppleScript; Ghostty
  et al. use activate + ⌘N + typed keystrokes (timing-based; no scripting API).
- **Offscreen rendering can't show AppKit controls** (tables, popups) — the
  gated render tests (`LEAP_RENDER_*` env) only faithfully capture text/views.
- Adding a hotkey key → `Platform/Hotkeys/Hotkey.swift`. New action type →
  `Core/Actions/ActionDispatcher.swift` + validator + `SlotEditorSheet`.
