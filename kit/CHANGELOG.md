# Changelog

History of the **Repository Standards Kit**. **Kit version** is defined by dated release sections (`### [X.Y.Z] - YYYY-MM-DD`) under `## repo-kit`. Upstream: https://github.com/shainemeister/repo-kit.

This file is the history of the Repository Standards Kit itself (path: `kit/CHANGELOG.md`).  
**Adopting projects** maintain their own root `CHANGELOG.md` for *project/package* history (behavior, contracts, releases, kit adoption/upgrade notes).  
They record the adopted kit version in the **Kit baseline** table inside `RULES.md` (see [RULES — Kit baseline](./RULES.md#kit-baseline) and [Mandatory project CHANGELOG](./rules/versioning-and-git.md#mandatory-project-changelog)).

Versioned standards also record per-document history in YAML frontmatter and document-history tables. Those document versions are independent of kit and product versions—see [versioning-and-git](./rules/versioning-and-git.md).

**Structure:** `## <Repository Name>` (integrated repository) → `### [X.Y.Z] - YYYY-MM-DD` (version change/update) → `#### Added` / `#### Changed` / … (categories). Categories follow [Keep a Changelog](https://keepachangelog.com/). Dates are ISO 8601. There is no Unreleased section—record each change under the version section that ships it.

**Upgrades:** [UPGRADE.md](./UPGRADE.md).

---

## [Repository Name]

### [X.Y.Z] - YYYY-MM-DD

#### Added

- *(project/package history for this repository — not kit release notes)*

---

## repo-kit

### [2.0.1] - 2026-07-28

#### Changed

- **Adopter packaging doctrine:** new implementations keep **standards under `kit/`** (same model as this repository); **repository-specific** data (product packages, project `CHANGELOG.md`, `PLAN.md`) stays **outside** `kit/`.
- README **Suggested root layout after adopt** corrected (no longer flattens RULES/standards onto product root).
- SETUP copy targets → project `kit/`; permanent hub path → `kit/RULES.md`.
- UPGRADE 1.1.0: migrate 1.x/root-layout standards **into** `kit/`; routine merges target `kit/`.
- Hygiene 1.1.0: unified packaging (replaces “copy onto root” dual layout).
- RULES hub 2.0.1, examples, versioning-and-git: authority map and baseline paths aligned.

#### Notes

- Supersedes 2.0.0 wording that adopters “usually keep RULES at project root after copy.”

### [2.0.0] - 2026-07-28

#### Added

- **`kit/` payload directory** — all standards source under one directory; repository root holds only `README.md`, `LICENSE`, and `.gitignore`.
- **`kit/rules/` domain modules** (7): `hygiene.md`, `authoring-and-style.md`, `architecture.md`, **`contracts.md`**, `security.md`, `versioning-and-git.md`, `verification-and-ops.md`.
- **`kit/UPGRADE.md`** — durable upgrade guide (routine procedure, **1.x → 2.0 migration**, merge options, AI prompts). Not deleted after initiation.
- Dedicated **contract policy** module (`rules/contracts.md`): ownership, same-change-set, cross-reference rules.
- Root README **Mandatory governance** digest and bottom **Source files** inventory.
- SETUP **Existing repository (first adopt)** section for live codebases without a kit baseline.

#### Changed

- **BREAKING:** Public kit paths moved under `kit/` (see migration table below).
- `RULES.md` is a **hub** (authority map, kit baseline, module index); body content lives in `rules/*`.
- MARKDOWN-STANDARD 1.0.1 → **1.1.0**: cross-linking form; kit paths.
- README how-to: three paths (new / existing first adopt / upgrade) pointing at SETUP vs UPGRADE.
- Upgrade procedure deferred from RULES body to **UPGRADE.md**.
- Kit CHANGELOG location: `kit/CHANGELOG.md` (this file).

#### Removed

- Root-level `RULES.md`, `SETUP.md`, `MARKDOWN-STANDARD.md`, `CHANGELOG.md`, `configs/`, `templates/`, `examples/` (moved under `kit/`).

#### Migration (1.x → 2.0)

| Old (1.x) | New (2.0) |
|-----------|-----------|
| `/RULES.md` | `/kit/RULES.md` + `/kit/rules/*` |
| `/SETUP.md` | `/kit/SETUP.md` |
| *(none)* | `/kit/UPGRADE.md` |
| `/MARKDOWN-STANDARD.md` | `/kit/MARKDOWN-STANDARD.md` |
| `/CHANGELOG.md` | `/kit/CHANGELOG.md` |
| `/configs/` | `/kit/configs/` |
| `/templates/` | `/kit/templates/` |
| `/examples/` | `/kit/examples/` |

Adopting projects keep **standards under `kit/`** and **project** `CHANGELOG.md` at repo root (see [2.0.1](#201---2026-07-28)). Upstream **reading** paths for upgrades are under `kit/`. Full procedure: [UPGRADE.md — Migrate from kit 1.x / root layout to 2.x](./UPGRADE.md#migrate-from-kit-1x--root-layout-to-2x).

### [1.2.1] - 2026-07-28

#### Changed

- README quick-path upgrade label renamed to **Upgrade repo-kit** (`####` heading); AI upgrade prompt now references project Kit baseline (Adopted kit version, Kit source) and the canonical kit source.
- Quick-path modes promoted to stable `####` headings (New implementation, Alternative, Upgrade repo-kit) for deep links.
- RULES.md document version 1.4.0 → **1.4.1**: upgrade procedure starts from Kit baseline **Kit source**; deep link to README prompt corrected to `#upgrade-repo-kit`.
- SETUP upgrade pointer includes README **Upgrade repo-kit** alongside RULES.

### [1.2.0] - 2026-07-28

#### Added

- **Language surface inventory** in RULES.md: full catalog aligned with existing style + SAST tables (Python, Python deps, PowerShell, JavaScript/TypeScript/Node, Go, Rust, Shell, Other/mixed, Secrets, Semgrep) with Domain A (security) and Domain B (code validation) columns.
- **Security and code-validation certification** policy in RULES.md: single `certification/` folder, certificate JSON/TXT schema, OverallPass rules, developer-only and non–product-gate constraints (no runnable harness yet).
- **Completion rule** and **Before marking work complete** steps (humans and AI agents): declared style + SAST gates required when inventory lists the surface.
- `templates/TEMPLATE-CERTIFICATION-README.md` operator guide skeleton for adopter `certification/README.md`.
- SETUP, examples (docs-only / Python library / CLI), TEMPLATE-SECURITY, README, and `.gitignore` updates for inventory, required-when-declared SAST, and regenerable cert outputs.

#### Changed

- RULES.md document version 1.3.1 → **1.4.0**: SAST posture from advisory-only to **required when declared**; verification, checklist, maintenance cadence, and anti-patterns updated.

#### Removed

- Root `SECURITY_PLAN.md` — product-oriented concept fully absorbed into RULES (language inventory, SAST required-when-declared, certification schema, completion rule); RULES is the sole authority.

### [1.1.7] - 2026-07-26

#### Changed

- Root README Purpose: fixed typo (“percision” → “precision”) and tightened the sentence while preserving instructional voice.

### [1.1.6] - 2026-07-26

#### Added

- Root README **Upgrading an existing adoption** pointer (with copy-pasteable AI upgrade prompt) and navigation rows in “You want to…”, Use cases, and Where to go next.
- Explicit CHANGELOG discipline sentence in RULES.md upgrade procedure: read only kit CHANGELOG entries since the current Adopted kit version; merge only what you need; never copy the full kit history into the project CHANGELOG.
- Cross-link from RULES upgrade section to the README AI upgrade prompt.

#### Changed

- RULES.md document version 1.3.0 → **1.3.1** (upgrade-path clarity only).

#### Removed

- Completed root `PLAN.md` for the upgrade-instructions / existing-adopters cycle (enhancement fully executed).

### [1.1.5] - 2026-07-26

#### Added

- Security documentation modularity in RULES.md: omit `SECURITY.md` when a package has no execution surface, network access, elevated privilege, or secrets handling.
- Advisory multi-language **Security / SAST gates** in RULES.md, keyed by language/surface (Bandit, pip-audit, PSScriptAnalyzer, npm audit, govulncheck, cargo-audit, ShellCheck, Gitleaks, optional Semgrep)—declare only languages the repo ships.
- Optional verification-table row for language-specific security / SAST commands.
- Brief “delete if not applicable” guidance on key sections of `templates/TEMPLATE-SECURITY.md`.
- SETUP pointers for optional security docs and language-scoped SAST gates.
- Explicit modularity notes in `examples/docs-only.md`, `examples/python-library.md`, and `examples/cli-tool.md`.

#### Changed

- RULES.md document version 1.2.2 → **1.3.0** (security modularity + SAST section; anti-pattern updates).

#### Removed

- Completed root `PLAN.md` for the modular security documentation & multi-language SAST gates cycle (enhancement fully executed).

### [1.1.4] - 2026-07-26

#### Changed

- Root README How-to section: fixed typo, added explicit “no traditional install” sentence, and smoothed agent prompts for cleaner copy-paste use.

### [1.1.3] - 2026-07-26

#### Added

- Root README **Purpose** and **How to use (quick path)** blocks: human consistency + AI-agent context efficiency; recommend a user-supplied project `PLAN.md`; copy-pasteable clone and agent-context prompts.

#### Changed

- Root README Quick start: primary 9-step checklist deferred to [SETUP.md](./SETUP.md); suggested layout notes recommended project `PLAN.md`.
- Root README lead and maintainers section: surface AI-context differentiator.

#### Removed

- Completed root `PLAN.md` for the README purpose / AI-context cycle (enhancement fully executed).

### [1.1.2] - 2026-07-25

#### Added

- Required AI-assisted commit disclosure footers in RULES.md Git rules: `Assisted-by` (AI make/model per commit), `Compliance: RULES.md`, `Instructed-by` (from `git config user.name`).

#### Changed

- RULES.md document version 1.2.1 → 1.2.2; strengthened pre-commit and contributor checklists for AI transparency.

### [1.1.1] - 2026-07-25

#### Changed

- Hierarchical CHANGELOG structure: repository H2 → version H3 → category H4; Unreleased workflow removed.
- Clarified kit vs project history distinction in this file’s header and in root README.
- Strengthened anti-pattern guidance in RULES.md against putting kit release history into a project CHANGELOG.
- Aligned `RULES.md`, `README.md`, `SETUP.md`, and `examples/` with the hierarchical structure (RULES document version **1.2.1**).

### [1.1.0] - 2026-07-25

#### Added

- Ephemeral `SETUP.md` for one-time project initiation (adoption modes, authority-map fill, template pick).
- `examples/` with filled authority-map and verification skeletons (CLI, Python library, docs-only).
- `CHANGELOG.md` for kit-level history (canonical **kit version** authority).
- Non-Python style-gate guidance table in `RULES.md`.
- Stronger commit-message guidance in `RULES.md` (modularity, scopes, body, examples, optional footers).
- Root hygiene rules in `RULES.md`.
- **Mandatory project CHANGELOG** policy in `RULES.md` (Keep a Changelog; required for all adopters, including docs-only).
- **Kit baseline** block in `RULES.md` (adopted kit version, date, source) so upgrades remain trackable after SETUP is removed.
- Kit upgrade procedure pointing at https://github.com/shainemeister/repo-kit.
- SETUP step to record kit baseline and ensure root CHANGELOG before delete.
- Sample kit baseline + required CHANGELOG rows in `examples/`.

#### Changed

- Root `README.md`: initiation checklist moved to `SETUP.md`; landing page kept light.
- `RULES.md` **Versioning and change control**: three surfaces (kit / project-package / document); CHANGELOG required; consistency rules strengthened (document version **1.2.0**).
- Root hygiene: `CHANGELOG.md` required (was recommended); SETUP lifecycle note for kit shippers and adopters.
- `configs/pylintrc`: louder adopter guidance that `py-version` **must** be set (3.13 remains starter default only).
- `.gitignore`: richer starter set (Python caches/build, venvs, coverage, light `node_modules/`) with adopter header comment.
- README maintainers section: kit version = CHANGELOG releases; canonical source URL; SETUP lifecycle.

#### Removed

- Completed prior-cycle `PLAN.md` (improvement plan fully executed).

### [1.0.1] - 2026-07-22

#### Changed

- Initiation-from-interest guidance and platform-aware verify/examples in `RULES.md` and related docs.
- Pylintrc path wording aligned (copy as `.pylintrc` or pass `--rcfile`).

### [1.0.0] - 2026-07-22

#### Added

- Initial portable kit: `MARKDOWN-STANDARD.md`, `RULES.md`, `templates/`, `configs/pylintrc`.
- Root landing README pattern (no frontmatter; use cases first).
- MIT license.
