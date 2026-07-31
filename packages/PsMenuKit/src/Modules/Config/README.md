# PsMenuKit.Config

Load menus from `.psd1` or `.json`. Handlers map names to scriptblocks (no arbitrary code from disk).

```powershell
$menu = Import-PsMenuConfig -Path .\menu.psd1 -HandlerMap @{
    Deploy = { .\Deploy.ps1 }
}
```
