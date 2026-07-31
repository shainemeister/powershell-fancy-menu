# PsMenuKit.Theme

Named ConsoleColor palettes and banner helper.

## Exports

| Function | Purpose |
|----------|---------|
| `Get-PsMenuTheme` | Get theme by name (or current) |
| `Set-PsMenuTheme` | Set current theme name |
| `Get-PsMenuThemeName` | List names / `-Current` |
| `Write-PsMenuBanner` | ASCII banner |
| `Register-PsMenuTheme` | Add custom palette |

Built-in: `Default`, `Dark`, `Light`, `HighContrast`.

```powershell
Import-Module .\PsMenuKit.Theme.psd1
Set-PsMenuTheme -Name Dark
Show-PsMenu -Menu $menu -Theme Dark
```
