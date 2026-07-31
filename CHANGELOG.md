# Changelog

Project history for **powershell-fancy-menu** (PsMenuKit). Structure follows [Keep a Changelog](https://keepachangelog.com/). Dates are ISO 8601.

Standards kit history lives upstream under [repo-kit](https://github.com/shainemeister/repo-kit); this file is **project** history only. Adopted kit version is recorded in [kit/RULES.md](./kit/RULES.md) (Kit baseline).

---

## powershell-fancy-menu

### [0.5.0] - 2026-07-30

#### Security

- **Action invoke fail-closed:** only `[scriptblock]` Actions run; mutated string/command Actions rejected (`Invoke-PsMenuItemAction`)
- **HandlerMap validation:** non-scriptblock map values throw clear errors at config bind time
- **AllowedRoot reparse reject:** junctions/symlinks under the allowlisted root are rejected (prefix-escape mitigation)
- **Config graph limits:** `MaxItems` (500), `MaxDepth` (16), `MaxLabelLength` (500) with fail-closed defaults
- **Display sanitization:** ANSI/OSC and C0 control characters stripped in `Get-PsMenuDisplayText`
- **Expanded ban-list:** additional abuse patterns; scans `packages/` and `templates/`; comment-stripped matching
- **CI:** `.github/workflows/ci.yml` runs `Run-AllGates.ps1 -RequireAnalyzer` and certification on Windows
- **SECURITY.md:** IT hardening checklist; honest CLM unsupported for Action dispatch; controls documented

#### Added

- `tests/Security.Action.Tests.ps1` (action type, display, limits, junction when available)
- Wired into `Run-AllGates.ps1` and certification Domain A checks
- Root README **Add to your repo**: vendor copy, code-first menu, config + HandlerMap + `Launch.cmd` examples
- Package README vendored import paths and config-driven example; module version table aligned to **0.5.0**

#### Changed

- Package / Core / Config module versions **0.5.0**
- CLI-GUIDE Import-PsMenuConfig parameters for limits and security behavior
- `templates/consumer-launch/App.ps1` kit path resolution: `PSMENUKIT_HOME`, `vendor\`, monorepo `packages\` fallbacks
- `templates/consumer-launch/README.md` copy-into-another-repo steps

### [0.4.0] - 2026-07-30

#### Added

- `certification/` repo-kit self-attestation: `README.md` + `New-Certification.ps1` (Domain A/B gates -> gitignored JSON/TXT)
- `templates/consumer-launch/` enterprise starter (Launch.cmd, App.ps1, sample menu)
- MultiSelect demo: `demos/menus/sample-multi.menu.psd1` and `Demo.ps1 -MultiSelect`
- JSON config fixture + automated load test
- Core caches Confirm/Nested (and related) command lookups once per menu session

#### Changed

- **Single enterprise demo launcher:** `demos/Launch.cmd` (no `-ExecutionPolicy Bypass`)
- Demo imports root `PsMenuKit.psd1` once; removed 1s startup delay
- SECURITY / CLI-GUIDE / MANUAL / kit RULES: enterprise Launch only; Bypass reserved for developer gates
- Package version **0.4.0**

#### Removed

- `demos/Launch.Enterprise.cmd` (merged into `Launch.cmd`)

### [0.3.1] - 2026-07-30

#### Fixed

- Normalized docs and source text to ASCII-safe punctuation so Windows consoles do not show mojibake such as `A`/garbled dashes when files are viewed under legacy code pages.
- Em dashes, en dashes, middle dots, curly quotes, arrows, and similar characters replaced with plain ASCII equivalents across product, demos, tests, tools, and local `kit/` copy.

#### Added

- `tools/Normalize-AsciiText.ps1` one-shot normalizer
- `tests/Encoding.Ascii.Tests.ps1` gate (wired into `Run-AllGates.ps1`)

### [0.3.0] - 2026-07-30

#### Added

- Phase 3 hardening and verification:
  - Console state save/restore helpers (`Save`/`Restore-PsMenuConsoleState`)
  - `Get-PsMenuDisplayText` truncation for long labels/titles
  - Nested max depth (default 8) via `NestDepth` / `MaxNestDepth`
  - `tests/Run-AllGates.ps1` single gate entrypoint
  - `tests/Run-ScriptAnalyzer.ps1` Domain A wrapper
  - `tests/Core.Edge.Tests.ps1` and `tests/MANUAL.md`
- Supported environments matrix in SECURITY.md

#### Changed

- `New-PsMenu` allows empty `Items` collections
- `Show-PsMenu` restores title/cursor; localizes `$ErrorActionPreference`
- MenuResult always includes `Selections`
- kit/RULES verification points at Run-AllGates
- Package/module versions **0.3.0**

#### Fixed

- Edge paths for empty menus and depth limits without interactive crashes

### [0.2.1] - 2026-07-30

#### Added

- Enterprise security close-out aligned with repo-kit security baseline:
  - Full [packages/PsMenuKit/SECURITY.md](./packages/PsMenuKit/SECURITY.md) (trust boundary, ban list, IT allowances, validation, reviewer statement)
  - `Import-PsMenuConfig -AllowedRoot` and default UNC deny; URI/remote path rejection; banned config keys (e.g. `ActionScript`)
  - `demos/Launch.Enterprise.cmd` (no permanent policy change; no Bypass)
  - `tests/Security.BanList.Tests.ps1` and `tests/Security.Config.Tests.ps1`
- Optional Secrets inventory guidance (Gitleaks) in kit verification table

#### Changed

- Demo uses `-AllowedRoot` for sample menu loads
- CLI-GUIDE / package README document dual launchers and Config security parameters
- kit/RULES.md Domain A/B verification rows tightened for PowerShell SAST and security tests
- CHANGELOG Search naming corrected to `Select-PsMenuItem` (was Filter-PsMenuItems in 0.2.0 notes)

#### Security

- Kit product tree scanned for banned patterns (IEX, web download, RunAs, Set-ExecutionPolicy, Install-Module, etc.)
- Config fail-closed outside allowlisted roots and for code-from-file keys

### [0.2.0] - 2026-07-30

#### Added

- Feature modules (composable, zero deps):
  - **Theme** - Default/Dark/Light/HighContrast palettes, banners, `Register-PsMenuTheme`
  - **Status** - `New-PsMenuStatusLine` (user/time/last-result)
  - **Confirm** - `Read-PsMenuConfirm` for item `ConfirmMessage`
  - **Nested** - `Show-PsMenuNested` for item `Children` + breadcrumb titles
  - **Search** - `Select-PsMenuItem`; Core type-to-filter when module loaded
  - **MultiSelect** - Space toggle; `New-PsMenu -MultiSelect`; batch activate
  - **Config** - `Import-PsMenuConfig` for `.psd1` / `.json` + HandlerMap
- Demo loads `demos/menus/sample.menu.psd1` with nested tools and confirm item.
- `tests/Feature.Modules.Tests.ps1` non-interactive smoke coverage.

#### Changed

- Core loop: search filter, multi-select, refined hotkey/Q/Esc behavior.
- Root `PsMenuKit.psd1` nests all feature modules (optional selective import still supported).
- Package contracts and module README stubs updated for 0.2.0.

### [0.1.0] - 2026-07-30

#### Added

- Adopted repo-kit **2.0.1** from https://github.com/shainemeister/repo-kit (standards under `kit/`).
- Project plan (`PLAN.md`) for a pure Windows PowerShell 5.1 modular menu kit.
- **PsMenuKit.Core** - dependency-free menu model, render loop, keyboard navigation, and action dispatch.
- Demo backbone: `demos/Launch.cmd` + `demos/Demo.ps1`.
- Package contracts: README, CLI-GUIDE, SECURITY, METHODOLOGY.
- Parse gate: `tests/Parse-Gate.ps1`.
