---
title: PsMenuKit
description: Modular pure-PowerShell 5.1 console menu kit (package overview).
version: "0.2.0"
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

PsMenuKit is a framework: compose **Core** (always) with optional feature modules. No Gallery modules, no NuGet packages, no external binaries at runtime.

| Piece | Role | Status |
|-------|------|--------|
| **Core** | Model builders + interactive loop | **0.2.0** |
| **Theme** | Named palettes + banners | **0.2.0** |
| **Status** | Header status line builder | **0.2.0** |
| **Confirm** | Y/N before destructive actions | **0.2.0** |
| **Nested** | Submenus + breadcrumbs | **0.2.0** |
| **Search** | Type-to-filter | **0.2.0** |
| **MultiSelect** | Space-toggle multi selection | **0.2.0** |
| **Config** | Load `.psd1` / `.json` menus | **0.2.0** |

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

No install. Selective (recommended for small apps):

```powershell
Import-Module .\packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1 -Force
Import-Module .\packages\PsMenuKit\src\Modules\Theme\PsMenuKit.Theme.psd1 -Force
# add only the feature modules you need
```

Or import everything via package root:

```powershell
Import-Module .\packages\PsMenuKit\PsMenuKit.psd1 -Force
```

## Minimal example

```powershell
Import-Module .\packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1 -Force
Import-Module .\packages\PsMenuKit\src\Modules\Theme\PsMenuKit.Theme.psd1 -Force
Import-Module .\packages\PsMenuKit\src\Modules\Search\PsMenuKit.Search.psd1 -Force

Set-PsMenuTheme -Name Dark | Out-Null

$menu = New-PsMenu -Title 'Demo' -Subtitle 'type to filter' -Theme Dark -Items @(
    New-PsMenuItem -Id 'hello' -Label 'Say hello' -Hotkey 'h' -Action {
        'Hello from PsMenuKit.'
    }
    New-PsMenuItem -Id 'disabled' -Label 'Not available' -Enabled $false
)

$result = Show-PsMenu -Menu $menu -Theme Dark
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
| 0.2.0 | All planned feature modules shipped |
| 0.1.0 | Initial Core package overview |
