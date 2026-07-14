# Leap

A macOS menu-bar hotkey launcher — the native successor to a Hammerspoon
app-switcher prototype. Bind global hotkeys to apps, scripts, or shell commands;
launch / focus / cycle windows; and manage it all from a TOML config.

**Stack:** Swift 6 + AppKit, built with SwiftPM. See [`docs/`](docs/) for
architecture, configuration, development, and release docs.

## Features

- Menu-bar-resident (no Dock icon).
- Global hotkeys (Carbon) bound to per-slot actions:
  - **app** — launch / focus / cycle its windows (Accessibility API).
  - **command** / **script** — run shell commands or scripts.
- TOML config at `~/.config/leap/config.toml` with an in-app editor
  (validates before saving) and import/export for sharing.
- Log console window.
- Start-at-login (`SMAppService`) and `.app` bundling.

Roadmap: cheat-sheet overlay, a `leap` CLI, and a richer settings UI.

## Requirements

- macOS 14+
- Xcode (Swift 6 toolchain)
- [mise](https://mise.jdx.dev/) (recommended)

## Quick start

```sh
mise run setup      # install dev tools + git hooks (first time)
mise run open       # build, bundle, and launch Leap.app
```

Grant **Accessibility** permission when prompted (needed to control other apps'
windows), then press `⌥1`–`⌥5`. Edit bindings via **Edit Config…** in the menu.

## Development

```sh
mise run build      # debug build
mise run run        # run in this terminal (watch logs)
mise run test       # run tests
mise run check      # format-check + lint
```

See [docs/development.md](docs/development.md) for the full task list, and
[docs/releasing.md](docs/releasing.md) for cutting versioned releases.
