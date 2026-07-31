# Changelog

Project history for **powershell-fancy-menu** (PsMenuKit). Structure follows [Keep a Changelog](https://keepachangelog.com/). Dates are ISO 8601.

Standards kit history lives upstream under [repo-kit](https://github.com/shainemeister/repo-kit); this file is **project** history only. Adopted kit version is recorded in [kit/RULES.md](./kit/RULES.md) (Kit baseline).

---

## powershell-fancy-menu

### [0.1.0] - 2026-07-30

#### Added

- Adopted repo-kit **2.0.1** from https://github.com/shainemeister/repo-kit (standards under `kit/`).
- Project plan (`PLAN.md`) for a pure Windows PowerShell 5.1 modular menu kit.
- **PsMenuKit.Core** — dependency-free menu model, render loop, keyboard navigation, and action dispatch.
- Demo backbone: `demos/Launch.cmd` + `demos/Demo.ps1`.
- Package contracts: README, CLI-GUIDE, SECURITY, METHODOLOGY.
- Parse gate: `tests/Parse-Gate.ps1`.
