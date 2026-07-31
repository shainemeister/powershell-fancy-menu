---
title: PsMenuKit CLI / Module Contract
description: Public surface, parameters, result objects, and host exit-code guidance.
version: "0.1.0"
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

| Function | Purpose |
|----------|---------|
| `New-PsMenuItem` | Build one menu item |
| `New-PsMenu` | Build a menu model |
| `Show-PsMenu` | Run interactive loop; return `PsMenuKit.MenuResult` |

Runtime: **Windows PowerShell 5.1**. Zero product dependencies.

## Contents

1. [Summary](#summary)
2. [New-PsMenuItem](#new-psmenuitem)
3. [New-PsMenu](#new-psmenu)
4. [Show-PsMenu](#show-psmenu)
5. [Result objects](#result-objects)
6. [Keyboard map (Core)](#keyboard-map-core)
7. [Host exit codes (guidance)](#host-exit-codes-guidance)
8. [Launcher demo](#launcher-demo)
9. [Document history](#document-history)

## New-PsMenuItem

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Label` | Yes | string | Display text |
| `Id` | No | string | Auto GUID fragment if omitted |
| `Action` | No | scriptblock | Invoked on activate |
| `Enabled` | No | bool | Default `$true` |
| `Hotkey` | No | string(1) | Case-insensitive single char |
| `Meta` | No | hashtable | Consumer metadata |
| `Children` | No | object[] | Reserved for Nested module |
| `ConfirmMessage` | No | string | Reserved for Confirm module |

## New-PsMenu

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Title` | Yes | string | Window title + header |
| `Items` | Yes | object[] | Menu items |
| `Subtitle` | No | string | Secondary header line |
| `Theme` | No | object | Hashtable overlay or name (Theme module) |

## Show-PsMenu

| Parameter | Required | Type | Notes |
|-----------|----------|------|-------|
| `Menu` | Yes | pscustomobject | From `New-PsMenu` |
| `Theme` | No | object | Overrides menu theme |
| `StatusLine` | No | string | Optional status under title |
| `ClearOnExit` | No | bool | Default `$true` |

Returns a **MenuResult** (see below). Does not call `exit`; host scripts decide process exit codes.

## Result objects

### MenuResult (`PSTypeName = PsMenuKit.MenuResult`)

| Property | Type | Meaning |
|----------|------|---------|
| `Cancelled` | bool | User quit / empty menu / no selection |
| `ItemId` | string | Selected item id (null if cancelled) |
| `Label` | string | Selected label |
| `ActionResult` | object | See ActionResult |
| `Reason` | string | `Selected`, `UserQuit`, `EmptyMenu`, … |

### ActionResult (`PSTypeName = PsMenuKit.ActionResult`)

| Property | Type | Meaning |
|----------|------|---------|
| `ItemId` | string | Item id |
| `Label` | string | Item label |
| `Success` | bool | Action completed without throw |
| `Error` | object | Error record if failed |
| `Output` | object | Pipeline output from Action |

## Keyboard map (Core)

| Input | Behavior |
|-------|----------|
| Up / Down | Move selection (skips disabled) |
| Enter | Activate selected item |
| Esc or `Q` | Cancel / quit loop |
| `1`–`9` | Jump selection to index |
| Hotkey char | Select and activate matching item |

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
| 0.1.0 | Initial Core contract |
