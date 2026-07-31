---
title: Repository Maintenance Rules
description: Maintenance policy hub - authority map, kit baseline, and index to domain rule modules.
version: "2.0.1"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - ../README.md
  - UPGRADE.md
  - MARKDOWN-STANDARD.md
  - CHANGELOG.md
  - rules/hygiene.md
  - rules/authoring-and-style.md
  - rules/architecture.md
  - rules/contracts.md
  - rules/security.md
  - rules/versioning-and-git.md
  - rules/verification-and-ops.md
  - configs/pylintrc
last_updated: "2026-07-28"
---

# Repository Maintenance Rules

Fundamental rules for maintaining a professional, auditable repository. This file is the **hub**: authority map, kit baseline, and Must / Must not. Domain detail lives in [rules/](./rules/). In adopting product repos this hub lives at **`kit/RULES.md`**.

**Document version:** 2.0.1  

**Related:** [README.md](../README.md) / [UPGRADE.md](./UPGRADE.md) / [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) / [CHANGELOG.md](../CHANGELOG.md) / [rules/](./rules/)

---

## Summary

**RULES.md** is the maintenance policy hub. Detailed contracts live in package guides and in domain modules under [rules/](./rules/). When contracts change, update the **canonical** file in the same change set - see [rules/contracts.md](./rules/contracts.md).

Copy this hub (and the `rules/` modules you need) into the project's **`kit/`** directory and **fill the authority map and verification table** with real paths and commands. Product code stays **outside** `kit/` ([hygiene](./rules/hygiene.md)). On initiation, derive paths from **project interest** (see [SETUP.md](./SETUP.md)). Keep authoring shape in [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md). Filled map examples: [examples/](./examples/).

| Must | Must not |
|------|----------|
| Update canonical docs with behavior changes ([contracts](./rules/contracts.md)) | Commit secrets, regenerable outputs, or real sensitive data |
| Maintain **project root** `CHANGELOG.md` (Keep a Changelog) | Ship version bumps or release-worthy changes without CHANGELOG |
| Keep standards under **`kit/`**; product outside | Flatten RULES/standards onto product root as default |
| Keep [Kit baseline](#kit-baseline) current after adopt/upgrade | Lose track of kit version after deleting SETUP |
| Use conventional commit messages that match staged files ([versioning-and-git](./rules/versioning-and-git.md)) | Mix unrelated packages or leave CLI/API/security docs stale |
| Keep packages composable at the workflow layer ([architecture](./rules/architecture.md)) | Silently rename public APIs, CLI fields, or schema columns |
| Run **pylint** on Python product code after those edits ([authoring-and-style](./rules/authoring-and-style.md)) | Treat pylint as a product runtime install for end users |
| Fill [language surface inventory](./rules/security.md#language-surface-inventory); run declared style + SAST before complete | Paste the full multi-language SAST table without inventory evidence |
| Verify before sharing contract or behavior changes ([verification-and-ops](./rules/verification-and-ops.md)) | Claim complete when a **declared** style or SAST gate was skipped or failed |
| Regenerate `certification/` outputs when that folder is maintained | Commit `last_certification.*` or treat certification as a product launcher gate |
| Fill authority map + verification from project interest at start | Leave contracts empty until "docs later" after behavior ships |

**Kit initiation completed** for this repository (SETUP removed). **Later kit upgrades:** [UPGRADE.md](./UPGRADE.md) (durable).

---

## Contents

1. [Summary](#summary)
2. [Authority map](#authority-map)
3. [Domain modules](#domain-modules)
4. [Kit baseline](#kit-baseline)
5. [Upgrading the kit](#upgrading-the-kit)
6. [Document history](#document-history)

---

## Authority map

Update the **owner** document for a change. Cross-link; do not duplicate full contracts ([contracts.md](./rules/contracts.md)).

Replace paths below with your project's real files. Rows that do not apply may be removed; add rows for domain-specific contracts. For filled skeletons by interest, see [examples/](./examples/).

| Concern | Canonical source |
|---------|------------------|
| Repo purpose and quick start | Project root [README.md](../README.md) |
| Project plan | Root [PLAN.md](../PLAN.md) |
| Kit upgrade / migration (durable) / [UPGRADE.md](./UPGRADE.md) - under `kit/` |
| Markdown structure, frontmatter, author checklist | [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) / [templates/](./templates/) |
| Maintenance policy hub (this file) | **`kit/RULES.md`** ([RULES.md](./RULES.md)) |
| Contract policy (breaking changes, co-updates, cross-links) / [rules/contracts.md](./rules/contracts.md) |
| Root hygiene / packaging (`kit/` vs product) / [rules/hygiene.md](./rules/hygiene.md) |
| Authoring + style gates | [rules/authoring-and-style.md](./rules/authoring-and-style.md) |
| Architecture boundaries | [rules/architecture.md](./rules/architecture.md) |
| Security, inventory, SAST, certification | [rules/security.md](./rules/security.md) |
| Versioning, CHANGELOG rules, git | [rules/versioning-and-git.md](./rules/versioning-and-git.md) |
| Verification, completion, checklist | [rules/verification-and-ops.md](./rules/verification-and-ops.md) / [Verification before ship](#verification-before-ship) |
| Project history (**required**) | Root [CHANGELOG.md](../CHANGELOG.md) |
| Kit version history (upstream) | Kit source `kit/CHANGELOG.md` under `## repo-kit` |
| Standards kit baseline | [Kit baseline](#kit-baseline) in this file (version + source) |
| Package overview | [packages/PsMenuKit/README.md](../packages/PsMenuKit/README.md) |
| Module / automation contract | [packages/PsMenuKit/CLI-GUIDE.md](../packages/PsMenuKit/CLI-GUIDE.md) |
| Composition / how it works | [packages/PsMenuKit/METHODOLOGY.md](../packages/PsMenuKit/METHODOLOGY.md) |
| Security / trust boundary | [packages/PsMenuKit/SECURITY.md](../packages/PsMenuKit/SECURITY.md) |
| Language surface inventory | [Language surface inventory](#language-surface-inventory) (this file) |
| Default sample menu config | [demos/menus/sample.menu.psd1](../demos/menus/sample.menu.psd1) |
| Golden tests / fixtures | [tests/](../tests/) / [tests/fixtures/](../tests/fixtures/) |
| Windows launcher demo | [demos/Launch.cmd](../demos/Launch.cmd) / [demos/Demo.ps1](../demos/Demo.ps1) |
| Security and code-validation certification | [certification/README.md](../certification/README.md) |
| Consumer launch template | [templates/consumer-launch/](../templates/consumer-launch/) |

**Rule:** Adding, removing, or renaming intentional source files should update the inventory (catalog or equivalent) in the same change set when the project maintains one.

### Language surface inventory

| Surface | Domain B (validation) | Domain A (security) | Notes |
|---------|----------------------|---------------------|--------|
| **PowerShell** product code | `tests/Parse-Gate.ps1` exit 0; `tests/Core.Model.Tests.ps1`; `tests/Feature.Modules.Tests.ps1`; PS 5.1 only | **PSScriptAnalyzer** `-Severity Error` (required in CI via `-RequireAnalyzer`); kit ban-list `tests/Security.BanList.Tests.ps1` (packages + templates); Config path tests `tests/Security.Config.Tests.ps1`; Action/limits/display `tests/Security.Action.Tests.ps1` | Runtime: Windows PowerShell 5.1; **zero** product deps; no network/elevation in kit |
| **Shell** product (`.cmd` launchers) | Documented launcher checklist in [SECURITY.md](../packages/PsMenuKit/SECURITY.md) | Manual review; no download-and-run; enterprise `Launch.cmd` (no Bypass) | Windows primary |
| **Secrets** (optional enterprise) | - | **Gitleaks** `gitleaks detect` when team enables secrets scanning | Prefer enable for enterprise releases |

### Verification before ship

| Change type | Minimum verification |
|-------------|----------------------|
| Core / module behavior | `demos\Launch.cmd` + [tests/MANUAL.md](../tests/MANUAL.md) critical path |
| Public API | Contract in CLI-GUIDE matches exports; smoke import in demo |
| Domain B + kit security (primary) | `powershell.exe -NoProfile -File tests\Run-AllGates.ps1` exit 0 |
| Domain A (PSScriptAnalyzer) | Included in Run-AllGates; CI uses `-RequireAnalyzer`. Local skip (exit 2) only when module missing outside CI. |
| CI | `.github/workflows/ci.yml` Windows job: install analyzer, `Run-AllGates -RequireAnalyzer`, certification artifact |
| Formal certification | `certification\New-Certification.ps1`; OverallPass true; do not stage `last_certification.*` |
| Domain A (Secrets, if inventory enabled) | `gitleaks detect --source .` clean |
| Docs / contracts | Authority map paths resolve; SECURITY.md matches behavior; no leftover `{{PLACEHOLDERS}}` |
| Launcher | Double-click `demos\Launch.cmd` (enterprise-standard; no Bypass) |
| Security / trust | [packages/PsMenuKit/SECURITY.md](../packages/PsMenuKit/SECURITY.md) co-updated with execution/launcher/config changes |

---

## Domain modules

| Module | Topic |
|--------|--------|
| [rules/hygiene.md](./rules/hygiene.md) | Packaging: standards under `kit/`; product outside; SETUP/UPGRADE lifecycle |
| [rules/authoring-and-style.md](./rules/authoring-and-style.md) | Docs rules; formatting; pylint; non-Python style |
| [rules/architecture.md](./rules/architecture.md) | Entry points, composition, runtime separation, dependencies |
| [rules/contracts.md](./rules/contracts.md) | What is a contract; co-updates; cross-reference policy |
| [rules/security.md](./rules/security.md) | Trust baseline; inventory; SAST; certification |
| [rules/versioning-and-git.md](./rules/versioning-and-git.md) | Version surfaces; CHANGELOG; commits; AI disclosure |
| [rules/verification-and-ops.md](./rules/verification-and-ops.md) | Verify table; completion; cadence; anti-patterns; checklist |

Adopters keep domain modules under **`kit/rules/`**, or fold selected modules into a single `kit/RULES.md` - document the choice in the authority map. See [UPGRADE.md](./UPGRADE.md) merge options.

---

## Kit baseline

After initiation, `SETUP.md` is gone. Projects still need a durable record of **which kit version** they adopted and **where upgrades come from**.

Fill and keep this table in every adopting project's **`kit/RULES.md`**. Update it on every kit upgrade.

| Field | Value |
|-------|--------|
| Adopted kit version | `2.0.1` |
| Adopted on | `2026-07-30` |
| Kit source | https://github.com/shainemeister/repo-kit |

**Kit source** is always **https://github.com/shainemeister/repo-kit** for this standards kit (not a free-form alternate). Forks that deliberately diverge document their own source.

**Project-specific architecture overlay**

| Rule | Detail |
|------|--------|
| Runtime | Windows PowerShell **5.1** (`powershell.exe`) only as first-class |
| Dependencies | **Zero** runtime dependencies (no Gallery modules, no NuGet) |
| Composition | Core engine + optional feature modules joined at the consumer script layer |
| Entry points | Enterprise `demos/Launch.cmd` for demo; public module functions for consumers; certification is developer-only |

At adopt time: read the kit's [CHANGELOG.md](./CHANGELOG.md) (latest released `### [X.Y.Z]` under `## repo-kit`), set **Adopted kit version** and **Adopted on**, keep **Kit source** as above, then delete or archive `SETUP.md`. Prefer keeping or re-fetching [UPGRADE.md](./UPGRADE.md) for later bumps.

---

## Upgrading the kit

**Do not use SETUP after initiation.** Follow the durable guide:

-> **[UPGRADE.md](./UPGRADE.md)** - routine upgrade procedure, **1.x / root-layout -> 2.x** migration (standards into `kit/`), merge options, and copy-paste AI prompts.

Short reminder: read Kit baseline in `kit/RULES.md` -> open Kit source `kit/CHANGELOG.md` under `## repo-kit` -> merge deltas into project `kit/` -> preserve product paths and verification -> update baseline + project root CHANGELOG note.

Copy-paste prompt also on root [README - Upgrade repo-kit](../README.md#upgrade-repo-kit).

---

## Document history

| Version | Notes |
|---------|--------|
| 2.0.1 | Adopter packaging: standards under `kit/`; project CHANGELOG and product paths outside; hygiene-aligned authority map |
| 2.0.0 | Kit 2.0 hub: authority map + kit baseline + domain module index; body content moved to `rules/*`; upgrade deferred to UPGRADE.md |
| 1.4.1 | (pre-split) Upgrade procedure from Kit baseline; README AI prompt deep link |
| 1.4.0 | Language inventory; SAST required when declared; certification schema; completion rule |
| 1.3.1-1.0.0 | See kit CHANGELOG history under `## repo-kit` for full lineage before modular split |
