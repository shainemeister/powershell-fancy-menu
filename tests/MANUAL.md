# PsMenuKit - Manual interactive checklist

Run on **Windows PowerShell 5.1** with a real console (conhost or Windows Terminal).

## Lab demo

```cmd
demos\Launch.cmd
```

| # | Step | Expected |
|---|------|----------|
| 1 | Double-click / run Launch.cmd | Menu appears with title **PsMenuKit Demo** |
| 2 | Up / Down arrows | Highlight moves; disabled item not activatable |
| 3 | Enter on **Say hello** | Result shown; key returns to menu |
| 4 | Open **Tools submenu** | Title shows parent > Tools; Esc returns to parent |
| 5 | Nested action A or B | Result; return to menu |
| 6 | **Simulate wipe** -> **N** | No wipe output; still in menu |
| 7 | **Simulate wipe** -> **Y** | Simulated wipe success |
| 8 | Type filter characters | List shrinks; Filter line updates |
| 9 | Backspace | Filter shortens |
| 10 | Esc with non-empty filter | Filter clears (menu stays) |
| 11 | Esc or Q with empty filter | Exit code 0; **cursor visible**; title restored |
| 12 | Optional: Ctrl+C mid-menu | Note host behavior; restore is best-effort (see SECURITY) |

## Enterprise launcher

```cmd
demos\Launch.Enterprise.cmd
```

| # | Step | Expected |
|---|------|----------|
| 1 | Run under normal policy | Starts if scripts allowed; else clear policy error (no permanent Unrestricted advice) |
| 2 | Same critical path as lab | Behavior matches demo script |

## Automated gates (non-interactive)

From repo root:

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
```

Optional analyzer (when installed):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-ScriptAnalyzer.ps1
```
