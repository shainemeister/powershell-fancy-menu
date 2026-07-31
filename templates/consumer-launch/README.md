# Consumer launch template

Minimal **enterprise-standard** host for PsMenuKit. Copy this folder into your app, vendor the kit, map handlers, edit the menu file.

## Files

| File | Role |
|------|------|
| `Launch.cmd` | Double-click entry (no ExecutionPolicy Bypass) |
| `App.ps1` | Resolve kit, HandlerMap, menu loop |
| `menus/app.menu.psd1` | Config-driven menu data |

## Prerequisites

- Windows PowerShell 5.1
- Host ExecutionPolicy that allows running local scripts (prefer signed / RemoteSigned - IT-owned)
- PsMenuKit available via one of the paths below

## Kit path resolution (`App.ps1`)

`App.ps1` looks for `PsMenuKit.psd1` in this order:

1. **`$env:PSMENUKIT_HOME`** - folder containing the manifest, or a full path to the `.psd1`
2. **`.\vendor\PsMenuKit\PsMenuKit.psd1`** - next to `App.ps1`
3. **`..\vendor\PsMenuKit\PsMenuKit.psd1`** - sibling of the app folder (e.g. `YourApp\MyMenu` + `YourApp\vendor`)
4. **`..\..\vendor\PsMenuKit\PsMenuKit.psd1`** - two levels up (e.g. `YourApp\tools\MyMenu` + `YourApp\vendor`)
5. **`..\..\packages\PsMenuKit\PsMenuKit.psd1`** - this monorepo (`templates/consumer-launch`)

## Run (this monorepo)

```cmd
cd templates\consumer-launch
Launch.cmd
```

## Copy into another repo

### 1. Vendor the kit

```cmd
xcopy /E /I /Y packages\PsMenuKit YourApp\vendor\PsMenuKit
```

### 2. Copy this template

```cmd
xcopy /E /I /Y templates\consumer-launch YourApp\tools\MyMenu
```

Layout:

```text
YourApp/
  vendor/PsMenuKit/
    PsMenuKit.psd1
    src/...
  tools/MyMenu/
    Launch.cmd
    App.ps1
    menus/app.menu.psd1
```

With that layout, resolution hits step 4 (`..\..\vendor\PsMenuKit`). Alternatively place `vendor\` next to `App.ps1` (step 2), put the host one level under the repo root (step 3), or set:

```cmd
set PSMENUKIT_HOME=C:\path\to\PsMenuKit
```

### 3. Run

```cmd
cd YourApp\tools\MyMenu
Launch.cmd
```

## Customize

1. Edit `menus/app.menu.psd1` items and `Handler` names.
2. Map handlers in `App.ps1` `$handlers` (scriptblocks only).
3. Keep `Import-PsMenuConfig -AllowedRoot` pointed at your menus folder.
4. Prefer enterprise `Launch.cmd` (no Bypass). Do not set permanent ExecutionPolicy Unrestricted as an install step.

## Security

- Config is data only; HandlerMap is trusted host code.
- Always pass `Import-PsMenuConfig -AllowedRoot` (template does this).
- **`PSMENUKIT_HOME` is a trust boundary:** it can redirect `Import-Module` to any path. Prefer vendored `vendor\PsMenuKit` under an approved directory; only set the env var to IT-approved locations. Prefer Authenticode-signed modules where policy requires it.
- See [packages/PsMenuKit/SECURITY.md](../../packages/PsMenuKit/SECURITY.md).
- Root adoption (AI prompts + examples): [README - How to use](../../README.md#how-to-use-quick-path) · [Add to your repo](../../README.md#add-to-your-repo).
