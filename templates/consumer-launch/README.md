# Consumer launch template

Minimal **enterprise-standard** host for PsMenuKit.

## Files

| File | Role |
|------|------|
| `Launch.cmd` | Double-click entry (no ExecutionPolicy Bypass) |
| `App.ps1` | Import kit, HandlerMap, menu loop |
| `menus/app.menu.psd1` | Config-driven menu data |

## Prerequisites

- Windows PowerShell 5.1
- This repo layout (template under `templates/consumer-launch`, kit under `packages/PsMenuKit`)
- Host ExecutionPolicy that allows running local scripts (prefer signed / RemoteSigned - IT-owned)

## Run

```cmd
cd templates\consumer-launch
Launch.cmd
```

## Customize

1. Edit `menus/app.menu.psd1` items and `Handler` names.  
2. Map handlers in `App.ps1` `$handlers`.  
3. Keep `Import-PsMenuConfig -AllowedRoot` pointed at your menus folder.  
4. Point `$pkg` at your PsMenuKit install if you relocate files.

## Security

- Config is data only; HandlerMap is trusted host code.  
- See [packages/PsMenuKit/SECURITY.md](../../packages/PsMenuKit/SECURITY.md).  
- Do not use permanent ExecutionPolicy Unrestricted as an install step.
