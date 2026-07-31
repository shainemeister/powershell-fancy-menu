# PsMenuKit.Config

Load menus from local `.psd1` or `.json`. Handlers map names to scriptblocks (no arbitrary code from disk).

```powershell
$menu = Import-PsMenuConfig -Path .\menus\app.menu.psd1 -AllowedRoot .\menus -HandlerMap @{
    Deploy = { .\Deploy.ps1 }
}
```

Security: URI/remote paths rejected; UNC default-deny; optional `-AllowedRoot` (reparse/junction reject); HandlerMap values must be scriptblocks; graph limits (MaxItems/MaxDepth/MaxLabelLength); banned keys like `ActionScript` fail closed. See package [SECURITY.md](../../../SECURITY.md).
