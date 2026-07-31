# PsMenuKit.MultiSelect

Space toggles `[x]` markers when `New-PsMenu -MultiSelect $true` (uses `Set-PsMenuItemSelection -Toggle`). Enter runs all selected actions (or focused item if none marked).

```powershell
$menu = New-PsMenu -Title 'Pick' -MultiSelect $true -Items @(...)
```
