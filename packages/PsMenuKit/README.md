---
title: PsMenuKit
description: Modular pure-PowerShell 5.1 console menu kit (package overview).
version: "0.1.0"
status: current
audience:
  - developers
doc_type: readme
related:
  - ./CLI-GUIDE.md
  - ./METHODOLOGY.md
  - ./SECURITY.md
  - ../../README.md
  - ../../PLAN.md
last_updated: "2026-07-30"
---

# PsMenuKit

Modular, **dependency-free** interactive console menus for **Windows PowerShell 5.1**.

## Summary

PsMenuKit is a framework: compose **Core** (always) with optional feature modules as they ship. No Gallery modules, no NuGet packages, no external binaries at runtime.

| Piece | Role | Status |
|-------|------|--------|
| **Core** | Model builders + interactive loop | **0.1.0** |
| Theme / Nested / Search / MultiSelect / Confirm / Status / Config | Opt-in capabilities | Planned |

## Contents

1. [Summary](#summary)
2. [Requirements](#requirements)
3. [Install / import](#install--import)
4. [Minimal example](#minimal-example)
5. [Related docs](#related-docs)

## Requirements

- Windows
- Windows PowerShell **5.1**
- Console host (classic console or Windows Terminal)

## Install / import

No install. From a consumer script:

```powershell
$core = Join-Path $PSScriptRoot '..\packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1'
Import-Module $core -Force
```

Or import the package root (nested Core):

```powershell
Import-Module (Join-Path $PSScriptRoot '..\packages\PsMenuKit\PsMenuKit.psd1') -Force
```

## Minimal example

```powershell
Import-Module .\packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1 -Force

$menu = New-PsMenu -Title 'Demo' -Subtitle 'Arrow keys + Enter' -Items @(
    New-PsMenuItem -Id 'hello' -Label 'Say hello' -Hotkey 'h' -Action {
        Write-Host 'Hello from PsMenuKit.'
    }
    New-PsMenuItem -Id 'disabled' -Label 'Not available' -Enabled $false
)

$result = Show-PsMenu -Menu $menu
if ($result.Cancelled) {
    Write-Host 'Cancelled.'
}
else {
    Write-Host ("Selected: {0}" -f $result.Label)
}
```

## Related docs

| Doc | Purpose |
|-----|---------|
| [CLI-GUIDE.md](./CLI-GUIDE.md) | Public function contract, results, exit codes |
| [METHODOLOGY.md](./METHODOLOGY.md) | Composition model and extension rules |
| [SECURITY.md](./SECURITY.md) | Trust boundary and launcher policy |
| [demos/Launch.cmd](../../demos/Launch.cmd) | Windows `.cmd` backbone demo |

## Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial Core package overview |
