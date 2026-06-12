<h1 align="center">AeroHUD</h1>

<h4 align="center">Native macOS SwiftUI grid overview for <a href="https://github.com/nikitabobko/AeroSpace/">AeroSpace</a>.</h4>

<p align="center"><img src="./screenshot.png" height="600" /></p>


### About

A little utility designed for my own esoteric workflow, where I have nine desktops in 3x3 grid.

This app helps me recall which window was where, and quickly switch desktops.

Also supports dragging and dropping windows between workspaces.

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
