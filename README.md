# powershell-fancy-menu (PsMenuKit)

Dependency-free **Windows PowerShell 5.1** modular console menu kit. Launch demos with a `.cmd` backbone; compose a small **Core** engine with optional feature modules for your own tools.

## Use cases

| You want to... | Start here |
|--------------|------------|
| Try the interactive demo | Double-click [`demos/Launch.cmd`](./demos/Launch.cmd) (enterprise-standard) |
| **Add menus to an existing repo** | [Add to your repo](#add-to-your-repo) |
| Consumer template (full host) | [templates/consumer-launch/](./templates/consumer-launch/) |
| Build a custom menu (API) | [packages/PsMenuKit/README.md](./packages/PsMenuKit/README.md) / [CLI-GUIDE.md](./packages/PsMenuKit/CLI-GUIDE.md) |
| Security / IT notes | [packages/PsMenuKit/SECURITY.md](./packages/PsMenuKit/SECURITY.md) |
| Understand composition | [METHODOLOGY.md](./packages/PsMenuKit/METHODOLOGY.md) |
| Certification (dev self-attestation) | [certification/README.md](./certification/README.md) |
| Project plan and roadmap | [PLAN.md](./PLAN.md) |
| Maintenance / kit standards | [kit/RULES.md](./kit/RULES.md) |

## Quick start (Windows)

```cmd
cd demos
Launch.cmd
```

Or from the repo root:

```cmd
demos\Launch.cmd
```

Requirements:

- Windows
- Windows PowerShell **5.1** (`powershell.exe`)
- **No** PowerShell Gallery modules

## Add to your repo

Offline vendor only - no Gallery install. Copy the kit into your tree, then either build menus in code or load menu data from `.psd1` / `.json`.

Suggested layout:

```text
YourApp/
  vendor/PsMenuKit/     # copy of packages/PsMenuKit
  tools/MyMenu/         # your host (or scripts/, app/, etc.)
    Launch.cmd
    App.ps1
    menus/app.menu.psd1
```

### 1. Vendor the kit

From a clone of this repo (or any folder that contains `packages\PsMenuKit`):

```cmd
xcopy /E /I /Y packages\PsMenuKit YourApp\vendor\PsMenuKit
```

You only need the `PsMenuKit` package tree (`PsMenuKit.psd1` + `src\`). Docs under the package are optional for runtime.

### 2a. Code-first menu (minimal)

Save as e.g. `YourApp\tools\MyMenu\App.ps1` next to `vendor\` (adjust the relative path if your layout differs):

```powershell
#requires -Version 5.1
$ErrorActionPreference = 'Stop'

# Layout: YourApp\tools\MyMenu\App.ps1  ->  YourApp\vendor\PsMenuKit\
$kit = Join-Path $PSScriptRoot '..\..\vendor\PsMenuKit\PsMenuKit.psd1'
Import-Module $kit -Force

$menu = New-PsMenu -Title 'My Tool' -Items @(
    New-PsMenuItem -Id 'hello' -Label 'Say hello' -Hotkey 'h' -Action {
        'Hello from PsMenuKit.'
    }
    New-PsMenuItem -Id 'quit' -Label 'Quit' -Hotkey 'q' -Action { 'quit' }
)

$result = Show-PsMenu -Menu $menu
if ($result.Cancelled) {
    Write-Host 'Cancelled.'
}
else {
    Write-Host ("Selected: {0}" -f $result.Label)
}
```

Run:

```cmd
powershell.exe -NoProfile -File tools\MyMenu\App.ps1
```

Import only what you need (smaller host) instead of the full package:

```powershell
$root = Join-Path $PSScriptRoot '..\..\vendor\PsMenuKit'
Import-Module (Join-Path $root 'src\Core\PsMenuKit.Core.psd1') -Force
Import-Module (Join-Path $root 'src\Modules\Theme\PsMenuKit.Theme.psd1') -Force
# add Nested, Search, Confirm, Config, etc. only when required
```

### 2b. Config-driven host (enterprise pattern)

Menu files are **data only**. Map handler names to scriptblocks in your host. Prefer `-AllowedRoot` so config cannot escape your menus folder.

**menus\app.menu.psd1**

```powershell
@{
    Title    = 'My Tool'
    Subtitle = 'Edit items; map Handler names in App.ps1'
    Theme    = 'Dark'
    Items    = @(
        @{
            Id      = 'hello'
            Label   = 'Say hello'
            Hotkey  = 'h'
            Handler = 'Hello'
        }
        @{
            Id      = 'quit'
            Label   = 'Quit'
            Hotkey  = 'q'
            Handler = 'Quit'
        }
    )
}
```

**App.ps1** (import + HandlerMap + loop)

```powershell
#requires -Version 5.1
$ErrorActionPreference = 'Stop'

$appRoot = $PSScriptRoot
$kit = Join-Path $appRoot '..\..\vendor\PsMenuKit\PsMenuKit.psd1'
Import-Module $kit -Force

$handlers = @{
    Hello = { 'Hello from HandlerMap.' }
    Quit  = { 'quit' }
}

$menus = Join-Path $appRoot 'menus'
$menu = Import-PsMenuConfig -Path (Join-Path $menus 'app.menu.psd1') `
    -HandlerMap $handlers -AllowedRoot $menus

while ($true) {
    $result = Show-PsMenu -Menu $menu
    if ($result.Cancelled) { break }
    if ($result.ItemId -eq 'quit') { break }
    Write-Host ("Selected: {0}" -f $result.Label)
}
```

**Launch.cmd** (double-click; no ExecutionPolicy Bypass)

```cmd
@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
powershell.exe -NoProfile -File "%~dp0App.ps1" %*
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo App exited with code %ERR%.
  echo If scripts are blocked, use signed scripts or an IT-approved process.
  pause
)
endlocal & exit /b %ERR%
```

Full starter (same pattern, monorepo-ready): [templates/consumer-launch/](./templates/consumer-launch/). Trust boundary, ban list, and IT notes: [SECURITY.md](./packages/PsMenuKit/SECURITY.md). Public command contract: [CLI-GUIDE.md](./packages/PsMenuKit/CLI-GUIDE.md).

## Design highlights

- **Zero runtime dependencies** - pure PowerShell + console APIs.
- **Modular** - import Core only, or add Theme, Nested, Search, MultiSelect, Confirm, Status, Config.
- **`.cmd` backbone** - double-click friendly: sets UTF-8, working directory, and invokes `powershell.exe`.
- **Enterprise-minded** - offline kit, Config as data, enterprise `Launch.cmd`; see [SECURITY.md](./packages/PsMenuKit/SECURITY.md).
- **repo-kit governed** - standards under `kit/`; product under `packages/`.

## Verify

Developer tooling only (Bypass for gates/CI - not product install):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

## Repository layout

```text
kit/                  # repo-kit standards (not product code)
packages/PsMenuKit/   # menu kit product + contracts (vendor this folder)
demos/                # Launch.cmd + Demo.ps1
templates/            # consumer-launch starter
certification/        # quality + security self-attestation (dev)
tests/                # gates and fixtures
PLAN.md               # project plan
CHANGELOG.md          # project history
```

## Status

**0.5.0** - Security hardening (action type fail-closed, HandlerMap validation, AllowedRoot reparse reject, config limits, display sanitization), expanded gates, Windows CI. See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT - see [LICENSE](./LICENSE).
