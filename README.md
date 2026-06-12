<h1 align="center">AeroHUD</h1>

<h4 align="center">Native macOS SwiftUI grid overview for <a href="https://github.com/nikitabobko/AeroSpace/">AeroSpace</a>.</h4>

<p align="center"><img src="./screenshot.png" height="600" /></p>


### About

Grid overview for the [Aerospace tiling WM](https://github.com/nikitabobko/AeroSpace) on macOS.

The ultimate coping mechanism for anyone who misses true 2-d desktop grids from more [civilised](https://youtu.be/_w_ksgcNnYc) <a href="https://github.com/user-attachments/assets/21f966ef-139c-445f-9645-9eea47eea4a4">environments</a>.

- Simple macOS binary called directly from AeroSpace (no `.app` wrapper or permission wrangling).

- Fully configurable grid, configured via command-line args.

- Supports dragging and dropping windows between different workspaces directly from the HUD.

Inspired by [GridLion](https://blog.hopefullyuseful.com/blog/macos-needs-its-grid-back/).

### Preview



https://github.com/user-attachments/assets/10762393-a880-4095-aa49-6aa04d55162d



### Install

Supports macOS 13+.   

Download the binary from [Releases](https://github.com/nikhilmwarrier/aerohud/releases) to `~/.local/bin/`.  

Otherwise see [build instructions ](#build) below.

### Configuration

Add this directive to `~/.aerospace.toml`:
```toml
[mode.main.binding]
# Modify according to your layout
alt-space = 'exec-and-forget ~/.local/bin/aerohud 3 1 2 3 q w e a s d'
```

### Usage

```bash
aerohud <COLS> <workspaces...>
```

### Examples

```
┌────┬────┬────┐
│  1 │  2 │  3 │
├────┼────┼────┤
│  q │  w │  e │
├────┼────┼────┤
│  a │  s │  d │
└────┴────┴────┘
```
```bash
# Three cols, workspaces 1 2 3, q w e, a s d
aerohud 3 1 2 3 q w e a s d
```

Similarly,
```
┌────┬────┬────┬────┐
│  1 │  2 │  3 │  4 │
├────┼────┼────┼────┤
│  q │  w │  e │  r │
└────┴────┴────┴────┘
```
```bash
# Four cols, workspaces 1 2 3 4, q w e r
aerohud 4 1 2 3 4 q w e r
```


## Build

```bash
git clone https://github.com/nikhilmwarrier/aerohud.git
cd aerohud
just build # or open justfile and run the commands from there
just copy
```
