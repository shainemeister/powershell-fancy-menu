# Changelog

Project history for **powershell-fancy-menu** (PsMenuKit). Structure follows [Keep a Changelog](https://keepachangelog.com/). Dates are ISO 8601.

Standards kit history lives upstream under [repo-kit](https://github.com/shainemeister/repo-kit); this file is **project** history only. Adopted kit version is recorded in [kit/RULES.md](./kit/RULES.md) (Kit baseline).

---

## powershell-fancy-menu

### [0.2.0] - 2026-07-30

#### Added

- Feature modules (composable, zero deps):
  - **Theme** — Default/Dark/Light/HighContrast palettes, banners, `Register-PsMenuTheme`
  - **Status** — `New-PsMenuStatusLine` (user/time/last-result)
  - **Confirm** — `Read-PsMenuConfirm` for item `ConfirmMessage`
  - **Nested** — `Show-PsMenuNested` for item `Children` + breadcrumb titles
  - **Search** — `Filter-PsMenuItems`; Core type-to-filter when module loaded
  - **MultiSelect** — Space toggle; `New-PsMenu -MultiSelect`; batch activate
  - **Config** — `Import-PsMenuConfig` for `.psd1` / `.json` + HandlerMap
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
- **PsMenuKit.Core** — dependency-free menu model, render loop, keyboard navigation, and action dispatch.
- Demo backbone: `demos/Launch.cmd` + `demos/Demo.ps1`.
- Package contracts: README, CLI-GUIDE, SECURITY, METHODOLOGY.
- Parse gate: `tests/Parse-Gate.ps1`.
