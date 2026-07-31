# PsMenuKit.Nested

Submenus via item `Children`. Core calls `Show-PsMenuNested` on activate. Esc returns to parent.

```powershell
New-PsMenuItem -Label 'Tools' -Children @(
    New-PsMenuItem -Label 'A' -Action { 'a' }
)
```
