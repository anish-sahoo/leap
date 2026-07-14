# Changelog

All notable changes to Leap are documented here. This project follows
[Semantic Versioning](https://semver.org) (`x.y.z`) and
[Conventional Commits](https://www.conventionalcommits.org).

## Unreleased

### Features
- Menu-bar app that binds global hotkeys to apps/scripts.
- Launch / focus / cycle-windows behavior via the Accessibility API.
- `command` actions run in a new terminal window (so TUIs like `btop` work),
  with a configurable terminal (`auto`/Terminal/iTerm2/Ghostty/…/`custom`).
- Cheat-sheet overlay: hold the trigger modifier to see all bound hotkeys in a
  floating, non-activating panel (debounced so a quick `⌥1` doesn't flash it).
  Shows app icons, a Settings shortcut (`⌥,`), and is configurable via
  `[cheatsheet]` (trigger, position, vertical/horizontal orientation, delay).
- Colored, human-readable stdout logs (ANSI, TTY-aware, honors `NO_COLOR`).
- Settings window with three tabs: a form editor (cheat-sheet prefs + a slots
  table), a raw-TOML editor with live syntax highlighting, and a live Logs view.
  Switching between form and TOML syncs changes both ways. The Logs view is
  colored by level.
- Add/edit slots via a dialog (name, hotkey, type, target + Browse…) instead of
  editing a blank table row; double-click a row to edit it.
- Config validation: syntax, unknown keys, invalid/duplicate hotkeys, action
  rules, and cheat-sheet enum values are reported (in the editor and on save).
- TOML config at `~/.config/leap/config.toml`, with an in-app editor and
  import/export.
- Log console window (swift-log facade).
- Start-at-login (`SMAppService`) and `.app` bundling.
