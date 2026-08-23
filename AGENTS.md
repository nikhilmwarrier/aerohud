# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

AeroHUD is a native macOS SwiftUI grid overview for the [AeroSpace tiling window manager](https://github.com/nikitabobko/AeroSpace). It is a single SwiftPM **executable target** (`aerohud`) — a plain binary invoked directly from AeroSpace bindings, with no `.app` wrapper. Users pass the grid layout as CLI args, e.g. `aerohud 3 1 2 3 q w e a s d` (3 columns, then workspace keys row by row).

## Commands

```bash
just run    # swift run (dev)
just build  # swift package clean && swift build -c release
just copy   # copy release binary to ~/.local/bin/
```

- Toolchain: Swift 5.9+, Swift Package Manager, no external dependencies.
- Minimum deployment target: **macOS 13**. Do not use APIs newer than this.
- There is no test target or lint config. Verify changes with `swift build` and manual testing via `swift run`.

## Architecture

All source lives in `Sources/`:

- `main.swift` — CLI arg parsing (`parseCommandLineArgs`), `HUDWindow` (borderless `NSPanel`, key handling), `AppDelegate`, singleton lock-file logic. Also holds the user-facing version string.
- `Views.swift` — SwiftUI views (`GridHUDView`, grid cells, hover/drag-and-drop behavior).
- `AeroSpaceService.swift` — shells out to the `aerospace` CLI (`list-windows`, `list-workspaces --focused`, `workspace`, `focus`, `move-node-to-workspace`) to fetch windows/workspaces and perform actions.
- `AeroSpaceWindow.swift` — window model.

## Conventions & Gotchas

- The `aerospace` binary path is hardcoded to `/opt/homebrew/bin/aerospace`.
- Window listing output is parsed with the `###` field delimiter — do not change it without updating both sides of the format string.
- App icons are resolved from running apps, falling back to `/Applications/`, `/System/Applications/`, and `~/Applications/`.
- The app is expected to terminate itself after most actions (e.g. `switchToWorkspace`, `focusWindow` call `NSApp.terminate`).
- Update the version string in `parseCommandLineArgs()` in `Sources/main.swift` when releasing.

## Releases

Releases are automated by `.github/workflows/release.yml`: pushing a tag matching `v*` builds a universal (arm64 + x86_64) release binary and attaches it to a GitHub Release.

## Commit Style

Short conventional-ish prefixes, no scopes: `feat:`, `fix:`, `doc:`, `ci:` (e.g. `fix: Calibre windows now show up properly`).
