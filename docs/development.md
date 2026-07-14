# Development

## Prerequisites

- macOS 14+
- Xcode (Swift 6 toolchain)
- [mise](https://mise.jdx.dev/)

## First-time setup

```sh
mise run setup     # installs dev tools + git hooks (Conventional Commits)
```

This installs SwiftFormat, SwiftLint, and git-cliff via mise, and points
`core.hooksPath` at `.githooks/` so commit messages are validated.

## Common tasks

| Task                | What it does                                  |
|---------------------|-----------------------------------------------|
| `mise run build`    | Debug build (`swift build`).                  |
| `mise run run`      | Build + run in the terminal (see logs).       |
| `mise run test`     | Run the test suite (`swift test`).            |
| `mise run format`   | Auto-format sources (SwiftFormat).            |
| `mise run lint`     | Lint sources (SwiftLint).                     |
| `mise run check`    | CI-style: format-check + strict lint.         |
| `mise run bundle`   | Build `dist/Leap.app`.                        |
| `mise run open`     | Bundle + launch the app.                      |

## Running the app

- `mise run run` runs the bare binary — good for watching logs, but
  launch-at-login and persisted permissions need the bundled app.
- `mise run open` builds and launches `Leap.app`. Grant **Accessibility**
  permission when prompted (or via the menu's "Accessibility Permission…").

## Tests

Tests use [Swift Testing](https://developer.apple.com/documentation/testing) and
cover pure logic (hotkey parsing, TOML round-trip) so they run in CI. See
`.github/workflows/ci.yml`.

## Commit messages

Commits must follow [Conventional Commits](https://www.conventionalcommits.org).
The `commit-msg` hook enforces it. Examples:

```
feat(hotkeys): support letter keys
fix: don't crash on empty config
docs(readme): clarify install steps
feat!: drop JSON config       # "!" marks a breaking change
```
