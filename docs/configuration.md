# Configuration

Leap reads a TOML file at `~/.config/leap/config.toml`. It's created with a
starter config on first launch. Edit it by hand, via **Edit Config…** in the
menu (validates before saving), or share it with **Import/Export**.

## Format

```toml
version = 1

[[slots]]
id     = "chrome"        # unique identifier
hotkey = "alt+1"         # the global hotkey
label  = "Chrome"        # shown in the cheat sheet

[slots.action]
type   = "app"
target = "/Applications/Google Chrome.app"
```

## Fields

### Slot

| Field    | Required | Description                                   |
|----------|----------|-----------------------------------------------|
| `id`     | yes      | Unique identifier for the slot.               |
| `hotkey` | yes      | Combo string, e.g. `alt+1`, `cmd+shift+3`.    |
| `label`  | yes      | Display text (cheat sheet).                   |
| `action` | yes      | What the hotkey does (see below).             |

### Hotkey syntax

`modifier+…+key`, case-insensitive. Modifiers: `alt`/`opt`/`option`,
`cmd`/`command`, `ctrl`/`control`, `shift`. Keys: digits `0`–`9` (more coming).

### Action

| `type`      | Fields used                          | Behavior                                  |
|-------------|--------------------------------------|-------------------------------------------|
| `"app"`     | `target` (bundle path)               | Launch / focus / cycle windows.           |
| `"command"` | `target` (shell command)             | Run a single shell command.               |
| `"script"`  | `body` or `target` (path), `interpreter`, `name` | Run an inline script or a script file.    |

A `script` action runs either an inline `body` or a script **file** at `target`
(a path, `~` allowed). With `interpreter` it runs `env <interpreter> <path>`;
without one it executes the file directly (needs a shebang / executable bit).

```toml
[[slots]]
id = "dev-term"
hotkey = "alt+6"
[slots.action]
type = "script"
target = "~/.config/leap/scripts/open-btop.sh"
```

`action.name` gives command/script actions a display name for the cheat sheet.
The cheat-sheet label for a slot is `label` → `action.name` → app name → `id`,
so `label` on the slot is optional.

```toml
[[slots]]
id = "btop"
hotkey = "alt+6"
label = "btop"

[slots.action]
type = "script"
interpreter = "bash"
body = "open -a Ghostty; sleep 1; osascript -e 'tell app \"System Events\" to keystroke \"btop\\n\"'"
```

## Cheat sheet

Hold the trigger modifier (Option by default) to show the overlay listing every
bound hotkey. Configure it with an optional `[cheatsheet]` table:

```toml
[cheatsheet]
trigger = "alt"          # alt (default) | cmd | ctrl | shift
position = "center"      # center (default) | top | bottom | left | right
                         #   | top-left | top-right | bottom-left | bottom-right
orientation = "vertical" # vertical (default) | horizontal
delayMs = 150            # debounce before showing (default 150)
```

The overlay always includes a Settings shortcut (`⌥,`) that opens the config
editor.

## Notes

- Invalid TOML is never persisted — the editor reports the parse error instead.
- Import backs up your current config to `config.backup.toml` first.
- `version` exists for future migrations.
