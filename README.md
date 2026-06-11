# AeroHUD

Native macOS SwiftUI grid overview for [AeroSpace](https://github.com/nikitabobko/AeroSpace/).

![Screenshot](./screenshot.png)

This was designed for my own estoeric workflow, where I have nine desktops in 3x3 grid like this:
```
1 2 3
q w e
a s d
```

This app helps me recall which window was where, and quickly switch desktops.

If you have a similar-ish workflow, just edit the arrays in `./Sources/main.swift` to your liking and rebuild. It's a very simple app.

### Installation

```bash
git clone https://github.com/nikhilmwarrier/aerohud.git
cd aerohud
just build # or open justfile and run the commands from there
just copy
```

### Configuration

Add this directive to `~/.aerospace.toml`:

```toml
[mode.main.binding]
alt-space = 'exec-and-forget ~/.local/bin/aerohud'

```

### Automation

* `just run` - Runs local debug instance.
* `just build` - Wipes build cache and compiles optimized release binary.
* `just copy` - Deploys release binary into `~/.local/bin/`.
