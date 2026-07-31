# PsMenuKit - Manual interactive checklist

Run on **Windows PowerShell 5.1** with a real console (conhost or Windows Terminal).

## Demo (enterprise Launch.cmd)

```cmd
demos\Launch.cmd
```

Uses enterprise pattern: `-NoProfile`, **no** `-ExecutionPolicy Bypass`. Host policy must allow local scripts.

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

## MultiSelect demo

```cmd
cd demos
powershell.exe -NoProfile -File Demo.ps1 -MultiSelect
```

| # | Step | Expected |
|---|------|----------|
| 1 | Space on items | `[x]` markers toggle |
| 2 | Enter with markers | Batch actions / MultiSelected reason |
| 3 | Enter with none marked | Activates focused item |

## Automated gates (developer tooling)

From repo root (Bypass allowed for **gates only**, not product install):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

Do not commit `certification/last_certification.*`.
