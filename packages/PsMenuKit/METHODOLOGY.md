---
title: PsMenuKit Methodology
description: Composition model, extension rules, and pure-PS 5.1 design constraints.
version: "0.1.0"
status: current
audience:
  - developers
  - architects
doc_type: methodology
related:
  - ./README.md
  - ./CLI-GUIDE.md
  - ./SECURITY.md
  - ../../PLAN.md
last_updated: "2026-07-30"
---

# PsMenuKit Methodology

How the modular menu kit is composed and extended without runtime dependencies.

## Summary

Consumers **import Core**, optionally import feature modules, build a **menu model**, then call `Show-PsMenu`. Feature modules extend behavior through optional item/menu properties and optional commands that Core detects at runtime (`Get-Command`). Core never hard-requires feature modules.

## Contents

1. [Summary](#summary)
2. [Layers](#layers)
3. [Composition rules](#composition-rules)
4. [Extension style](#extension-style)
5. [PS 5.1 constraints](#ps-51-constraints)
6. [Planned feature modules](#planned-feature-modules)
7. [Document history](#document-history)

## Layers

```text
Launch.cmd → powershell.exe → consumer script
                                 ├─ Import Core (+ features)
                                 ├─ Build menu model
                                 └─ Show-PsMenu loop
```

| Layer | Responsibility |
|-------|----------------|
| `.cmd` | CWD, UTF-8 code page, title, invoke `powershell.exe` |
| Consumer script | Composition, actions, process exit codes |
| Core | Model, render, keys, dispatch |
| Feature modules | Theme, Nested, Search, MultiSelect, Confirm, Status, Config |

## Composition rules

1. **Core is always required** for interactive menus.
2. **Feature modules are optional** — import only what the app needs.
3. **No circular imports** — feature modules may call Core public functions only.
4. **Capability detection** — Core uses `Get-Command` for hooks such as `Read-PsMenuConfirm` and `Show-PsMenuNested`.
5. **Unknown properties are ignored** by Core (forward-compatible models).
6. **Join at the workflow layer** — compose modules in the consumer script, not by merging engines into one monolithic file.

## Extension style

| Mechanism | Example |
|-----------|---------|
| Optional item properties | `Children`, `ConfirmMessage` |
| Optional commands | `Read-PsMenuConfirm`, `Get-PsMenuTheme` |
| Theme hashtables | ConsoleColor palettes |
| Config → model | Future Config module loads `.psd1` into `New-PsMenu` graphs |

## PS 5.1 constraints

- No PS7-only syntax (`??`, `?:`, `&&`, `||` language operators, `$PSStyle`).
- Colors via `Write-Host` / `ConsoleColor`.
- Input via `[Console]::ReadKey($true)` with RawUI fallback.
- Manifests declare `PowerShellVersion = '5.1'`.

## Planned feature modules

| Module | Adds |
|--------|------|
| Theme | Named palettes, banners, box styles |
| Nested | Submenus, breadcrumb, Esc = back |
| Search | Incremental filter |
| MultiSelect | Space toggle, batch activate |
| Confirm | Y/N before destructive actions |
| Status | Dynamic header/footer |
| Config | Load menus from `.psd1` / JSON |

## Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial composition methodology |
