# powershell-fancy-menu (PsMenuKit)

Interactive **console menus** for **Windows PowerShell 5.1** — modular, dependency-free, and easy to vendor into an existing app. Double-click demos with a `.cmd` backbone; compose **Core** plus optional feature modules for your own tools.

## Summary

PsMenuKit is a pure-PowerShell menu framework you **copy into your tree** (offline). There is no Gallery install and no runtime packages beyond Windows PowerShell itself.

- **Runtime:** Windows + Windows PowerShell **5.1** (`powershell.exe`)
- **Install:** vendor `packages/PsMenuKit` (manifest + `src/`) into e.g. `vendor/PsMenuKit`
- **Host styles:** code-first scriptblocks, or config-as-data (`.psd1` / `.json`) with a trusted HandlerMap
- **Enterprise-minded:** offline kit, config is data only, enterprise `Launch.cmd` (no permanent ExecutionPolicy changes)

Canonical source: [https://github.com/shainemeister/powershell-fancy-menu](https://github.com/shainemeister/powershell-fancy-menu)

## How to use (quick path)

There is **no traditional install step**. Prefer a local clone or sparse copy of **`packages/PsMenuKit`** as the product surface. Do **not** vendor `kit/`, `tests/`, or `certification/` into application trees.

Paste one of the blocks below into an AI chat (or follow the steps yourself). Each block is self-contained.

### Try the demo (explore)

```text
Explore PsMenuKit at https://github.com/shainemeister/powershell-fancy-menu

1. Clone or open the repository.
2. On Windows, run demos/Launch.cmd (double-click or from a cmd prompt).
3. Summarize the product from README.md and packages/PsMenuKit/README.md: Core vs feature modules, zero Gallery deps, Windows PowerShell 5.1 only.
4. Note contracts: packages/PsMenuKit/CLI-GUIDE.md (public commands), packages/PsMenuKit/SECURITY.md (trust boundary).
Do not install from the PowerShell Gallery. Do not target PowerShell 7 as first-class.
```

### Add menus to an existing repo (code-first)

```text
Add PsMenuKit console menus to this existing repository (code-first host).

Source of truth: https://github.com/shainemeister/powershell-fancy-menu
Read: README.md (Add to your repo), packages/PsMenuKit/README.md, packages/PsMenuKit/CLI-GUIDE.md

Requirements:
- Windows PowerShell 5.1 only (powershell.exe). Zero runtime Gallery or NuGet dependencies.
- Vendor only packages/PsMenuKit (PsMenuKit.psd1 + entire src/) into vendor/PsMenuKit (or equivalent). Do not copy kit/, tests/, certification/, or demos/ into the app product tree.
- Create a small host script (e.g. tools/MyMenu/App.ps1) that Import-Modules the vendored PsMenuKit.psd1, builds a menu with New-PsMenu / New-PsMenuItem, and runs Show-PsMenu.
- Prefer a double-click Launch.cmd that uses: powershell.exe -NoProfile -File ... (no -ExecutionPolicy Bypass; do not permanently set ExecutionPolicy Unrestricted).
- Must not: Gallery Install-Module, PS 7-only APIs, executing menu config as code, inventing unexported cmdlets.

Deliver: vendor tree, host script, run instructions from the app root.
```

### Add menus (enterprise / config-driven)

```text
Add PsMenuKit to this existing repository using the enterprise config-driven host pattern.

Source of truth: https://github.com/shainemeister/powershell-fancy-menu
Read: README.md (Add to your repo), templates/consumer-launch/, packages/PsMenuKit/SECURITY.md, packages/PsMenuKit/CLI-GUIDE.md

Requirements:
- Vendor only packages/PsMenuKit into vendor/PsMenuKit (manifest + src/).
- Prefer copying templates/consumer-launch into e.g. tools/MyMenu (Launch.cmd, App.ps1, menus/*.menu.psd1).
- Menu files are data only (.psd1 or .json). Map Handler names to scriptblocks in the host (HandlerMap). Always call Import-PsMenuConfig with -AllowedRoot pointed at the menus folder.
- Enterprise Launch.cmd: -NoProfile -File; no Bypass; no permanent Unrestricted policy.
- Must not: treat config as executable code, omit AllowedRoot for production hosts, Gallery install, or vendor kit/tests/certification.

Deliver: vendor tree, host + menus, short run and customize notes.
```

### Local clone / offline reference

```text
git clone https://github.com/shainemeister/powershell-fancy-menu.git
```

```text
Use the local clone of powershell-fancy-menu as the offline reference for PsMenuKit.
Vendor packages/PsMenuKit into the target app (e.g. vendor/PsMenuKit). Follow README.md Add to your repo for code-first or templates/consumer-launch for config-driven. Runtime is Windows PowerShell 5.1 only; no Gallery install.
```

### Upgrade a vendored copy

```text
Upgrade the vendored PsMenuKit in this repository.

1. Read the current vendor ModuleVersion from vendor/PsMenuKit/PsMenuKit.psd1 (or your vendor path).
2. Open https://github.com/shainemeister/powershell-fancy-menu and check root CHANGELOG.md plus packages/PsMenuKit versions.
3. Replace the vendored package tree (PsMenuKit.psd1 + src/) with the newer packages/PsMenuKit. Preserve your host scripts, HandlerMap, and menus.
4. Smoke-test the host (Launch.cmd or App.ps1). Re-check Import-PsMenuConfig -AllowedRoot and SECURITY.md if you use config-driven menus.
5. Note the upgrade briefly in this project's CHANGELOG.md. Do not copy this monorepo's kit/ or tests/ into the app.
```

Detail steps live under [Add to your repo](#add-to-your-repo).

## Use cases

| You want to... | Start here |
|----------------|------------|
| Try the interactive demo | [Quick start](#quick-start-try-the-demo) / [`demos/Launch.cmd`](./demos/Launch.cmd) |
| Add a small menu in code | [Code-first](#2a-code-first-minimal) |
| Config-driven menus (enterprise) | [Config-driven host](#2b-config-driven-host) / [`templates/consumer-launch/`](./templates/consumer-launch/) |
| Public command contract | [`packages/PsMenuKit/CLI-GUIDE.md`](./packages/PsMenuKit/CLI-GUIDE.md) |
| Trust boundary / IT notes | [`packages/PsMenuKit/SECURITY.md`](./packages/PsMenuKit/SECURITY.md) |
| Composition model | [`packages/PsMenuKit/METHODOLOGY.md`](./packages/PsMenuKit/METHODOLOGY.md) |

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **Windows** | Primary platform; `.cmd` launchers |
| **Windows PowerShell 5.1** | `powershell.exe` — not PowerShell 7 as first-class |
| **No Gallery modules** | Product is offline / vendored |
| **Console host** | Classic console or Windows Terminal |

## Quick start (try the demo)

```cmd
cd demos
Launch.cmd
```

Or from the repo root:

```cmd
demos\Launch.cmd
```

Double-click `demos\Launch.cmd` works the same way. The launcher sets UTF-8, working directory, and runs `powershell.exe -NoProfile -File` (no ExecutionPolicy Bypass).

## Add to your repo

Offline vendor only — no Gallery install. Copy the kit into your tree, then either build menus in code or load menu data from `.psd1` / `.json`.

### Choose a path

| Path | When | Outcome |
|------|------|---------|
| **Code-first** | Few items; logic stays in the host script | Smallest host; actions as scriptblocks |
| **Config-driven** | Menus edited as data; handlers in trusted host code | `.psd1` / `.json` + HandlerMap + `-AllowedRoot` |
| **Consumer template** | Want Launch.cmd, path resolution, and a menu loop | Copy [`templates/consumer-launch/`](./templates/consumer-launch/) |

Suggested layout:

```text
YourApp/
  vendor/PsMenuKit/     # copy of packages/PsMenuKit
  tools/MyMenu/         # your host (or scripts/, app/, etc.)
    Launch.cmd          # optional enterprise entry
    App.ps1
    menus/              # config-driven only
      app.menu.psd1
```

### 1. Vendor the kit

You need **`PsMenuKit.psd1` + the entire `src\` tree**. Package docs are optional for runtime.

**From a local clone of this repo:**

```cmd
xcopy /E /I /Y packages\PsMenuKit YourApp\vendor\PsMenuKit
```

**From scratch (clone then copy):**

```cmd
git clone --depth 1 https://github.com/shainemeister/powershell-fancy-menu.git psmenukit-src
xcopy /E /I /Y psmenukit-src\packages\PsMenuKit YourApp\vendor\PsMenuKit
```

**Optional — sparse checkout of the package only:**

```cmd
git clone --filter=blob:none --sparse https://github.com/shainemeister/powershell-fancy-menu.git psmenukit-src
cd psmenukit-src
git sparse-checkout set packages/PsMenuKit
xcopy /E /I /Y packages\PsMenuKit ..\YourApp\vendor\PsMenuKit
```

GitHub **Download ZIP** also works: extract, then copy `packages\PsMenuKit` into `YourApp\vendor\PsMenuKit`.

### 2a. Code-first (minimal)

Save as `YourApp\tools\MyMenu\App.ps1` (layout above: host two levels under `YourApp`, kit at `vendor\PsMenuKit`). Adjust the relative path if your host lives elsewhere.

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

**Same folder as `vendor\`** (e.g. `YourApp\App.ps1` next to `YourApp\vendor\`):

```powershell
$kit = Join-Path $PSScriptRoot 'vendor\PsMenuKit\PsMenuKit.psd1'
Import-Module $kit -Force
```

Run from `YourApp`:

```cmd
powershell.exe -NoProfile -File tools\MyMenu\App.ps1
```

### 2b. Config-driven host

Menu files are **data only**. Map handler names to scriptblocks in your host. Prefer **`-AllowedRoot`** so config cannot escape your menus folder.

**`menus\app.menu.psd1`**

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

**`App.ps1`** (import + HandlerMap + loop)

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

**`Launch.cmd`** (double-click; no ExecutionPolicy Bypass)

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

Trust boundary, ban list, and IT notes: [SECURITY.md](./packages/PsMenuKit/SECURITY.md). Public command contract: [CLI-GUIDE.md](./packages/PsMenuKit/CLI-GUIDE.md).

### 2c. Full starter template

Copy the ready host (path resolution, HandlerMap loop, menus folder, enterprise launcher):

```cmd
xcopy /E /I /Y packages\PsMenuKit YourApp\vendor\PsMenuKit
xcopy /E /I /Y templates\consumer-launch YourApp\tools\MyMenu
cd /d YourApp\tools\MyMenu
Launch.cmd
```

Details and path candidates (`PSMENUKIT_HOME`, multi-level `vendor\`): [templates/consumer-launch/README.md](./templates/consumer-launch/README.md).

### Advanced: selective module import

Import only what you need instead of the full package:

```powershell
$root = Join-Path $PSScriptRoot '..\..\vendor\PsMenuKit'
Import-Module (Join-Path $root 'src\Core\PsMenuKit.Core.psd1') -Force
Import-Module (Join-Path $root 'src\Modules\Theme\PsMenuKit.Theme.psd1') -Force
# add Nested, Search, Confirm, Config, MultiSelect, Status only when required
```

Feature roles: [packages/PsMenuKit/README.md](./packages/PsMenuKit/README.md).

## Design highlights

- **Zero runtime dependencies** — pure PowerShell + console APIs.
- **Modular** — import Core only, or add Theme, Nested, Search, MultiSelect, Confirm, Status, Config.
- **`.cmd` backbone** — double-click friendly: UTF-8, working directory, `powershell.exe -NoProfile -File`.
- **Enterprise-minded** — offline kit, config as data, enterprise Launch.cmd; see [SECURITY.md](./packages/PsMenuKit/SECURITY.md).

## What's included

```text
packages/PsMenuKit/   # menu kit product — vendor this folder
demos/                # Launch.cmd + Demo.ps1
templates/            # consumer-launch starter host
kit/                  # repo-kit standards (not product code)
tests/                # gates and fixtures (developers)
certification/        # quality + security self-attestation (dev)
CHANGELOG.md          # project history
```

## Where to go next

| Need | Doc |
|------|-----|
| Package overview + module table | [packages/PsMenuKit/README.md](./packages/PsMenuKit/README.md) |
| Public functions, results, keys | [CLI-GUIDE.md](./packages/PsMenuKit/CLI-GUIDE.md) |
| Security / IT checklist | [SECURITY.md](./packages/PsMenuKit/SECURITY.md) |
| Composition rules | [METHODOLOGY.md](./packages/PsMenuKit/METHODOLOGY.md) |
| Copy-ready host | [templates/consumer-launch/](./templates/consumer-launch/) |
| Project history | [CHANGELOG.md](./CHANGELOG.md) |

## For maintainers

Standards live under [`kit/`](./kit/) ([RULES.md](./kit/RULES.md)). Product plan: [PLAN.md](./PLAN.md). Certification: [certification/README.md](./certification/README.md).

### Verify

Developer tooling only (Bypass for gates/CI — not product install):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

### Status

**0.5.1** — Defense-in-depth (Confirm/title sanitization, MaxFileBytes, schema allowlist, AllowedRoot warn), launcher policy gate, certification schema 1.1. See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT — see [LICENSE](./LICENSE).
