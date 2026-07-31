# PsMenuKit.Status

Header status line builder.

## Exports

| Function | Purpose |
|----------|---------|
| `New-PsMenuStatusLine` | Compose user/time/custom/last-result segments |

```powershell
$status = New-PsMenuStatusLine -IncludeUser -IncludeTime -LastResult $last
Show-PsMenu -Menu $menu -StatusLine $status
```
