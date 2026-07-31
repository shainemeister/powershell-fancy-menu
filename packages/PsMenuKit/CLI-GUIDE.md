---
title: PsMenuKit CLI / Module Contract
description: Public surface, parameters, result objects, and host exit-code guidance.
version: "0.2.0"
status: current
audience:
  - developers
doc_type: cli
related:
  - ./README.md
  - ./METHODOLOGY.md
  - ./SECURITY.md
last_updated: "2026-07-30"
---

# PsMenuKit CLI / Module Contract

Canonical contract for exported PowerShell commands. Co-update this file when public behavior changes.

## Summary

| Function | Module | Purpose |
|----------|--------|---------|
| `New-PsMenuItem` | Core | Build one menu item |
| `New-PsMenu` | Core | Build a menu model |
| `Show-PsMenu` | Core | Run interactive loop; return `PsMenuKit.MenuResult` |
| `Get-PsMenuTheme` / `Set-PsMenuTheme` / `Get-PsMenuThemeName` / `Write-PsMenuBanner` / `Register-PsMenuTheme` | Theme | Palettes and banners |
| `New-PsMenuStatusLine` | Status | Header status line |
| `Read-PsMenuConfirm` | Confirm | Y/N prompt (auto-hooked by Core) |
| `Show-PsMenuNested` | Nested | Submenu runner (auto-hooked by Core) |
| `Select-PsMenuItem` / `Test-PsMenuSearchAvailable` | Search | Label filter (auto when imported) |
| `Set-PsMenuItemSelection` / `Get-PsMenuSelectedItems` / `Clear-PsMenuItemSelections` | MultiSelect | Selection markers |
| `Import-PsMenuConfig` | Config | Load `.psd1` / `.json` menus |

Runtime: **Windows PowerShell 5.1**. Zero product dependencies.

## Contents

1. [Summary](#summary)
2. [New-PsMenuItem](#new-psmenuitem)
3. [New-PsMenu](#new-psmenu)
4. [Show-PsMenu](#show-psmenu)
5. [Feature module surfaces](#feature-module-surfaces)
6. [Result objects](#result-objects)
7. [Keyboard map (Core + features)](#keyboard-map-core--features)
8. [Host exit codes (guidance)](#host-exit-codes-guidance)
9. [Launcher demo](#launcher-demo)
10. [Document history](#document-history)

## New-PsMenuItem

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Label` | Yes | string | Display text |
| `Id` | No | string | Auto GUID fragment if omitted |
| `Action` | No | scriptblock | Invoked on activate |
| `Enabled` | No | bool | Default `$true` |
| `Hotkey` | No | string(1) | Case-insensitive single char |
| `Meta` | No | hashtable | Consumer metadata |
| `Children` | No | object[] | Nested module submenus |
| `ConfirmMessage` | No | string | Confirm module prompt |
| `Selected` | No | bool | MultiSelect marker state |

## New-PsMenu

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Title` | Yes | string | Window title + header |
| `Items` | Yes | object[] | Menu items |
| `Subtitle` | No | string | Secondary header line |
| `Theme` | No | object | Hashtable overlay or name (Theme module) |
| `MultiSelect` | No | bool | Enable Space-toggle mode when MultiSelect module loaded |

## Show-PsMenu

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Menu` | Yes | pscustomobject | From `New-PsMenu` |
| `Theme` | No | object | Overrides menu theme |
| `StatusLine` | No | string | Optional status under title |
| `ClearOnExit` | No | bool | Default `$true` |

Returns a **MenuResult** (see below). Does not call `exit`; host scripts decide process exit codes.

## Feature module surfaces

### Import-PsMenuConfig (Config)

| Parameter | Required | Notes |
|-----------|----------|-------|
| `Path` | Yes | `.psd1` or `.json` |
| `HandlerMap` | No | `hashtable` of handler name → scriptblock |
| `DefaultAction` | No | Fallback scriptblock |

Config never executes arbitrary code from the file. Only `Handler` names bound via `HandlerMap` become actions.

### New-PsMenuStatusLine (Status)

Switches: `-IncludeUser`, `-IncludeComputer`, `-IncludeTime`, `-IncludeDate`; plus `-Text`, `-LastResult`.

## Result objects

### MenuResult (`PSTypeName = PsMenuKit.MenuResult`)

| Property | Type | Meaning |
|----------|------|---------|
| `Cancelled` | bool | User quit / empty menu / no selection |
| `ItemId` | string | Selected item id (null if cancelled; comma-joined for multi) |
| `Label` | string | Selected label(s) |
| `ActionResult` | object | ActionResult or ActionResult[] for multi |
| `Reason` | string | `Selected`, `MultiSelected`, `UserQuit`, `EmptyMenu`, … |
| `Selections` | object[] | Selected item object(s) |

### ActionResult (`PSTypeName = PsMenuKit.ActionResult`)

| Property | Type | Meaning |
|----------|------|---------|
| `ItemId` | string | Item id |
| `Label` | string | Item label |
| `Success` | bool | Action completed without throw |
| `Error` | object | Error record if failed |
| `Output` | object | Pipeline output from Action |

## Keyboard map (Core + features)

| Input | Behavior |
|-------|----------|
| Up / Down | Move selection (skips disabled) |
| Enter | Activate selected item; multi = batch selected or focused |
| Esc | Clear filter if non-empty (Search); else quit / nested back |
| `Q` | Quit when filter empty (hotkey `q` wins if present) |
| `1`–`9` | Jump selection to index (when filter empty) |
| Hotkey char | Select and activate (filter empty; single-select) |
| Type chars | Append filter query (Search module loaded) |
| Backspace | Delete last filter character (Search) |
| Space | Toggle multi-select marker (MultiSelect mode) |

## Host exit codes (guidance)

Suggested mapping for launcher scripts (not enforced by Core):

| Code | Meaning |
|------|---------|
| `0` | Success or clean cancel after use |
| `1` | Unhandled error |
| `2` | Cancelled without selection (optional) |

## Launcher demo

```cmd
demos\Launch.cmd
```

Invokes `powershell.exe -NoProfile -ExecutionPolicy Bypass -File demos\Demo.ps1`.

## Document history

| Version | Notes |
|---------|--------|
| 0.2.0 | Feature modules + Search/MultiSelect keyboard contract |
| 0.1.0 | Initial Core contract |
