# Leap

[![CI](https://github.com/anish-sahoo/leap/actions/workflows/ci.yml/badge.svg)](https://github.com/anish-sahoo/leap/actions/workflows/ci.yml)
[![Tests](https://github.com/anish-sahoo/leap/actions/workflows/test.yml/badge.svg)](https://github.com/anish-sahoo/leap/actions/workflows/test.yml)

A macOS menu-bar hotkey launcher. Bind global hotkeys to apps, shell commands,
or scripts; launch / focus / cycle app windows; and see a cheat-sheet overlay of
your bindings. Configured with a simple TOML file or an in-app settings window.

**Stack:** Swift 6 + AppKit, built with SwiftPM.

## Features

- **Menu-bar app** (no Dock icon).
- **Global hotkeys** (Carbon) bound to per-slot actions:
  - **app** — launch, focus, or cycle its windows (Accessibility API).
  - **command** — run in a new terminal window (Ghostty / iTerm2 / Terminal / …).
  - **script** — run an inline script or a script file.
- **Cheat-sheet overlay** — hold the trigger key (default ⌥) to see all bindings;
  entries are clickable. Position/orientation/trigger are configurable.
- **Settings window** — a form editor, a raw-TOML editor with syntax highlighting
  and validation, and a live Logs tab (kept in sync).
- **Config** at `~/.config/leap/config.toml` with import/export for sharing.
- **Start-at-login** (`SMAppService`) and `.app` bundling.

## Requirements

- macOS 14+
- Xcode (Swift 6 toolchain)
- [mise](https://mise.jdx.dev/) (recommended, for tasks)

## Install

Download `Leap.app` from the [latest release](https://github.com/anish-sahoo/leap/releases/latest)
(unzip, or open the `.dmg` and drag it to `/Applications`).

The app is ad-hoc signed (not notarized), so macOS Gatekeeper will refuse to
open it with *"Apple could not verify Leap.app is free of malware."* Clear the
quarantine flag once:

```sh
xattr -dr com.apple.quarantine /Applications/Leap.app
```

Then open it normally. (Alternatively: **System Settings → Privacy & Security →
Open Anyway**.)

## Quick start (from source)

```sh
mise run setup    # install dev tools + git hooks (first time)
mise run open     # build, bundle, and launch Leap.app
```

Grant **Accessibility** permission when prompted (needed to control other apps'
windows), then press `⌥1`–`⌥5`, or hold `⌥` for the cheat sheet. Open **Settings…**
from the menu bar (or `⌥,`) to edit bindings.

## Uninstall

Leap only touches three places. To remove it completely:

1. **Quit** Leap and turn off **Start at Login** first (menu bar → the toggle),
   so no login item is left behind.
2. **Delete the app:** `rm -rf /Applications/Leap.app` (or wherever you put it,
   e.g. `dist/Leap.app`).
3. **Delete the config:** `rm -rf ~/.config/leap`.
4. **Revoke permissions (optional):** System Settings → Privacy & Security →
   **Accessibility** (and **Input Monitoring**) → remove Leap.

That's everything — no other files, caches, or hidden state.

## Docs

- [Configuration](docs/configuration.md) — the TOML format and every option.

For contributors: [CONTRIBUTING.md](CONTRIBUTING.md) ·
[ARCHITECTURE.md](ARCHITECTURE.md) · [RELEASING.md](RELEASING.md) ·
[AGENTS.md](AGENTS.md)

## License

See [LICENSE](LICENSE).
