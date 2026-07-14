# Changelog

All notable changes to Leap are documented here. This project follows
[Semantic Versioning](https://semver.org) (`x.y.z`) and
[Conventional Commits](https://www.conventionalcommits.org).

## Unreleased

### Features
- Menu-bar app that binds global hotkeys to apps/scripts.
- Launch / focus / cycle-windows behavior via the Accessibility API.
- Cheat-sheet overlay: hold the trigger modifier to see all bound hotkeys in a
  floating, non-activating panel (debounced so a quick `⌥1` doesn't flash it).
  Shows app icons, a Settings shortcut (`⌥,`), and is configurable via
  `[cheatsheet]` (trigger, position, vertical/horizontal orientation, delay).
- Colored, human-readable stdout logs (ANSI, TTY-aware, honors `NO_COLOR`).
- Settings window with two tabs: a form editor (cheat-sheet prefs + an editable
  slots table) and a raw-TOML editor with live syntax highlighting. Switching
  tabs syncs changes both ways.
- Config validation: syntax, unknown keys, invalid/duplicate hotkeys, action
  rules, and cheat-sheet enum values are reported (in the editor and on save).
- TOML config at `~/.config/leap/config.toml`, with an in-app editor and
  import/export.
- Log console window (swift-log facade).
- Start-at-login (`SMAppService`) and `.app` bundling.
