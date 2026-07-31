# PsMenuKit.Confirm

Y/N confirmation prompts. Core calls `Read-PsMenuConfirm` when an item has `ConfirmMessage`.

```powershell
New-PsMenuItem -Label 'Delete' -ConfirmMessage 'Are you sure?' -Action { ... }
```
