# Contributing

Thanks for your interest in Leap! It's a small, focused macOS app — contributions
that keep it that way are very welcome.

## Setup

```sh
mise run setup    # installs SwiftFormat, SwiftLint, git-cliff + the git hooks
```

Requires macOS 14+ and Xcode (Swift 6 toolchain).

## Tasks

| Task                | What it does                            |
|---------------------|-----------------------------------------|
| `mise run build`    | Debug build.                            |
| `mise run run`      | Build + run in the terminal (see logs). |
| `mise run test`     | Run the test suite.                     |
| `mise run check`    | Format-check + strict lint.             |
| `mise run bundle`   | Build `dist/Leap.app`.                  |
| `mise run open`     | Bundle + launch the app.                |

`mise run run` runs the bare binary (handy for logs); launch-at-login and
persisted permissions need the bundled app (`mise run open`).

## Workflow

1. Branch off `main`.
2. Make your change. Keep the layering intact — put OS-specific code in
   `Platform/`, keep `Core/` free of AppKit/Carbon. See [ARCHITECTURE.md](ARCHITECTURE.md).
3. Before pushing, make sure this passes:
   ```sh
   mise run check    # format-check + strict lint
   swift test
   ```
4. Open a PR. CI runs the same checks on macOS.

## Commit messages

Commits **must** follow [Conventional Commits](https://www.conventionalcommits.org)
— a `commit-msg` hook enforces it:

```
feat(hotkeys): support letter keys
fix: don't open a second terminal window on cold launch
docs: clarify uninstall steps
```

`feat:` → minor, `fix:` → patch, `!` (e.g. `feat!:`) → breaking/major.

## Style

- Match the surrounding code; SwiftFormat + SwiftLint are the source of truth.
- Prefer small types and clear names over comments; only comment the non-obvious.
- Add tests for pure logic (parsing, validation) — see `Tests/LeapTests`.
