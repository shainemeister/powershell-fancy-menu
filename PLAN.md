# Plan: Modular Pure-PowerShell Menu Kit (repo-kit)

## Summary

Build **PsMenuKit** - a **dependency-free**, **Windows PowerShell 5.1** modular console menu framework launched via `.cmd`, governed by [repo-kit](https://github.com/shainemeister/repo-kit) **2.0.1** standards. Product code lives **outside** `kit/`; standards live **under** `kit/`. Consumers compose a core engine with optional feature modules.

| Decision | Choice |
|----------|--------|
| Dependencies | **None** at runtime |
| Runtime | **Windows PowerShell 5.1 only** (`powershell.exe`) |
| Platform | **Windows primary** (`.cmd` backbone) |
| Modularity | **Composable feature modules** (core + opt-in) |
| Standards | **repo-kit 2.0.1** under `kit/` |

## Goals

1. Reusable public API for menus, navigation, and action dispatch.
2. Modular by need - small core; import only required feature modules.
3. Pure PS 5.1 syntax and APIs.
4. Double-clickable `Launch.cmd` entry.
5. repo-kit hygiene: authority map, CHANGELOG, inventory, declared gates.

## Non-goals (v1)

- PowerShell 7+ as first-class target.
- Spectre.Console, Terminal.Gui, or any Gallery dependency.
- Full multi-pane TUI / mouse forms.
- Auto plugin-folder discovery.

## Layout

See repository tree: `kit/` (standards), `packages/PsMenuKit/` (product), `demos/` (launcher), `tests/` (gates).

## Architecture

- **Core** - model, render, keys, loop, dispatch.
- **Feature modules** (planned / phased) - Theme, Nested, Search, MultiSelect, Confirm, Status, Config.
- **Composition** - consumer imports Core + optional modules; capability detection for optional item properties.
- **Config** - prefer `.psd1` menu data; optional JSON via built-in `ConvertFrom-Json`.

## Phases

| Phase | Scope | Status |
|-------|--------|--------|
| 0 | Kit adopt + root docs | **Done** (0.1.0) |
| 1 | Core engine + Launch.cmd demo | **Done** (0.1.0) |
| 2 | Feature modules + enterprise security | **Done** (0.2.0 / 0.2.1) |
| 3 | Hardening + verification | **Done** (0.3.0) |
| 4 | Adoption + cert + enterprise Launch + quality | **Done** (0.4.0) |

## Success criteria

1. Double-click `demos/Launch.cmd` works on PS 5.1 with no Gallery modules.
2. Consumers compose Core alone or Core + feature modules.
3. repo-kit layout and filled authority map.
4. CLI-GUIDE / METHODOLOGY / SECURITY present.
5. Parse gate passes.

## References

- https://github.com/shainemeister/repo-kit
- [kit/RULES.md](./kit/RULES.md)
