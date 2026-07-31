---
title: PsMenuKit
description: Modular pure-PowerShell 5.1 console menu kit (package overview).
version: "0.5.0"
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

| Piece | Role | Module version |
|-------|------|----------------|
| **Package root** | NestedModules load Core + all features | **0.5.0** |
| **Core** | Model builders + interactive loop + hardening | **0.5.0** |
| **Config** | Load `.psd1` / `.json` menus | **0.5.0** |
| **Nested** | Submenus + breadcrumbs | **0.3.0** |
| **Theme** | Named palettes + banners | **0.2.0** |
| **Status** | Header status line builder | **0.2.0** |
| **Confirm** | Y/N before destructive actions | **0.2.0** |
| **Search** | Type-to-filter | **0.2.0** |
| **MultiSelect** | Space-toggle multi selection | **0.2.0** |

Root landing with copy-paste adoption: [repository README - Add to your repo](../../README.md#add-to-your-repo).

## Contents

1. [Summary](#summary)
2. [Requirements](#requirements)
3. [Install / import](#install--import)
4. [Minimal example](#minimal-example)
5. [Config-driven example](#config-driven-example)
6. [Related docs](#related-docs)

## Requirements

- Windows
- Windows PowerShell **5.1**
- Console host (classic console or Windows Terminal)

## Install / import

No install. **Vendor** this package folder into your app (e.g. `vendor\PsMenuKit` or keep monorepo `packages\PsMenuKit`).

### Full package (all features)

Monorepo:

```powershell
Import-Module .\packages\PsMenuKit\PsMenuKit.psd1 -Force
```

Vendored (path relative to your script; adjust depth as needed):

```powershell
$kit = Join-Path $PSScriptRoot '..\..\vendor\PsMenuKit\PsMenuKit.psd1'
Import-Module $kit -Force
```

### Selective (recommended for small apps)

```powershell
$root = Join-Path $PSScriptRoot '..\..\vendor\PsMenuKit'  # or .\packages\PsMenuKit
Import-Module (Join-Path $root 'src\Core\PsMenuKit.Core.psd1') -Force
Import-Module (Join-Path $root 'src\Modules\Theme\PsMenuKit.Theme.psd1') -Force
# add only the feature modules you need
```

## Minimal example

Code-first menu with scriptblock actions:

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

## Config-driven example

Config is **data only**. Bind handler names in host-trusted code:

```powershell
Import-Module .\packages\PsMenuKit\PsMenuKit.psd1 -Force

$handlers = @{
    Hello = { 'Hello from HandlerMap.' }
    Quit  = { 'quit' }
}

$menus = Join-Path $PSScriptRoot 'menus'
$menu = Import-PsMenuConfig -Path (Join-Path $menus 'app.menu.psd1') `
    -HandlerMap $handlers -AllowedRoot $menus

$result = Show-PsMenu -Menu $menu
```

Enterprise host template: [templates/consumer-launch/](../../templates/consumer-launch/).

## Enterprise / IT

PsMenuKit is designed for **enterprise-compatible** use: current user only, offline kit code, zero runtime Gallery deps, config-as-data (not code). Read **[SECURITY.md](./SECURITY.md)** before production rollout. Prefer `Import-PsMenuConfig -AllowedRoot` and enterprise [demos/Launch.cmd](../../demos/Launch.cmd) (no Bypass) over permanent ExecutionPolicy changes.

## Related docs

| Doc | Purpose |
|-----|---------|
| [Root README - Add to your repo](../../README.md#add-to-your-repo) | Copy-paste vendor + host examples |
| [CLI-GUIDE.md](./CLI-GUIDE.md) | Public function contract, results, exit codes |
| [METHODOLOGY.md](./METHODOLOGY.md) | Composition model and extension rules |
| [SECURITY.md](./SECURITY.md) | Trust boundary, ban list, IT allowances |
| [demos/Launch.cmd](../../demos/Launch.cmd) | Enterprise-standard demo launcher |
| [templates/consumer-launch/](../../templates/consumer-launch/) | Consumer starter |
| [certification/README.md](../../certification/README.md) | Dev quality/security self-attestation |

## Document history

| Version | Notes |
|---------|--------|
| 0.5.0 | Action fail-closed; graph limits; reparse reject; display sanitization; CI; version table sync; vendored import examples |
| 0.4.0 | Enterprise Launch only; cert + consumer template pointers |
| 0.3.0 | Console restore, edges, nest depth, Run-AllGates |
| 0.2.1 | Enterprise security close-out (SECURITY, Config controls) |
| 0.2.0 | All planned feature modules shipped |
| 0.1.0 | Initial Core package overview |
