---
title: Verification and Operations
description: Verification before ship, completion rule, maintenance cadence, anti-patterns, and contributor checklist.
version: "1.0.0"
status: current
audience:
  - developers
  - security
doc_type: other
related:
  - ../RULES.md
  - ./security.md
  - ./authoring-and-style.md
  - ./contracts.md
  - ./versioning-and-git.md
  - ../MARKDOWN-STANDARD.md
  - ../UPGRADE.md
last_updated: "2026-07-28"
---

# Verification and Operations

Ship gates, completion rules, cadence, anti-patterns, and the contributor checklist.

**Document version:** 1.0.0  

**Related:** [RULES.md](../RULES.md) · [security.md](./security.md) · [authoring-and-style.md](./authoring-and-style.md) · [contracts.md](./contracts.md) · [versioning-and-git.md](./versioning-and-git.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [UPGRADE.md](../UPGRADE.md)

---

## Summary

Do **not** mark work complete if any **declared** Domain B (style) or Domain A (SAST) gate for a surface in the inventory was skipped or failed. Docs-only inventories declare no language gates.

---

## Contents

1. [Summary](#summary)
2. [Verification before ship](#verification-before-ship)
3. [Completion rule](#completion-rule)
4. [Before marking work complete](#before-marking-work-complete)
5. [Maintenance cadence](#maintenance-cadence)
6. [Anti-patterns](#anti-patterns)
7. [Contributor checklist](#contributor-checklist)
8. [Document history](#document-history)

---

## Verification before ship

Fill concrete commands for your project from the [language surface inventory](./security.md#language-surface-inventory). Rows that do not apply may be removed.

| Change type | Minimum verification |
|-------------|----------------------|
| Public behavior, scores, exports | Project tests / golden fixtures (define command for each primary platform) |
| Python product code style | `python -m pylint <package_or_paths>` (must pass; see [Python style gate](./authoring-and-style.md#python-style-gate-pylint)) |
| Other language product style | Project-declared gate per inventory (see [Non-Python style gates](./authoring-and-style.md#non-python-style-gates)) |
| Security / SAST (language-specific) | Only the commands for **surfaces in the inventory** (see [Security / SAST gates](./security.md#security--sast-gates-required-when-declared)); omit entire row if inventory is empty |
| Formal certification | If `certification/` is maintained: regenerate `last_certification.json` / `.txt` after critical gates; confirm OverallPass; do not stage outputs |
| Environment / packaging | Project probe or smoke script (define command; list Windows and Unix forms if both are supported) |
| Schema or sample data | Headers/fields match schema; consumers still load samples |
| Docs only | [Author checklist](../MARKDOWN-STANDARD.md#author-checklist); relative links resolve; platform examples consistent |
| New/removed source files | Inventory/catalog updated (if maintained); language surface inventory if languages added/removed |

---

## Completion rule

Do **not** mark a change complete, and do **not** claim ship readiness, if any **declared** Domain B (code validation / style) or Domain A (security / SAST) gate for a **surface present in the inventory** was skipped or failed. Docs-only inventories declare no language gates. Missing required developer tools is a **failed** gate, not a skip.

Fill commands for the host OS(es) the team develops on. When multi-platform, either one portable command or one row/note per OS.

---

## Before marking work complete

Ordered steps for humans and AI agents:

1. Read **language surface inventory** ([security.md](./security.md#language-surface-inventory); pick only declared rows from the full kit catalog).  
2. Run **Domain B** gates for every surface touched by the change.  
3. Run **Domain A** gates for every surface touched (plus Secrets / Semgrep if those rows exist).  
4. Update canonical docs / `CHANGELOG.md` per the [authority map](../RULES.md#authority-map) and [contracts.md](./contracts.md).  
5. If `certification/` is maintained: regenerate the certificate pair; confirm OverallPass; leave outputs unstaged.  
6. Only then state the task is complete.

---

## Maintenance cadence

| Trigger | Action |
|---------|--------|
| Every source path add/remove/rename | Update inventory/catalog if maintained |
| Language surface added or removed | Update [language surface inventory](./security.md#language-surface-inventory) + verification rows (+ certification checks if maintained) |
| Every release-worthy package behavior change | Bump code version; refresh CLI/API guide and status blocks; update `CHANGELOG.md` |
| Every product Python edit | Run pylint gate; keep exit 0 / 10.00 score; run Bandit if Python is in inventory |
| Every product edit in another declared language | Run that surface’s Domain B + Domain A gates |
| Security-relevant change | Update matching security doc; re-run declared SAST; CHANGELOG entry |
| Formal certification maintained | Regenerate `last_certification.*` after critical gates; do not commit outputs |
| Fixture failure after intentional math/logic change | Refresh expected outputs only with methodology note |
| Stale `last_updated` on heavily edited docs | Set ISO date when merging |
| Kit upgrade available upstream | Follow [UPGRADE.md](../UPGRADE.md); update baseline + project CHANGELOG |

---

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| Shipping pylint as a product runtime dependency | Keep pylint developer-only |
| Skipping pylint after Python product edits | Run `python -m pylint <package_or_paths>` |
| Committing regenerable outputs “for convenience” | Document regenerate commands in README / catalog |
| Silent public field or API rename | Coordinated contract bump + fixtures + docs ([contracts.md](./contracts.md)) |
| Long docs without Summary | MARKDOWN-STANDARD order |
| Duplicating security matrices into README | Link to security doc |
| Merging unrelated runtimes into one process without design | Keep boundaries ([architecture.md](./architecture.md)) |
| Absolute machine-only paths as the only example | Placeholder + one repo-relative example |
| Orphan files missing from the inventory | Update catalog in the same change |
| Vague commits (`update stuff`, `wip`) | Conventional `type(scope):` subject ([versioning-and-git.md](./versioning-and-git.md)) |
| Code without CLI/methodology/security docs when those contracts apply | Same change set as the canonical doc; omit security when [modularity](./security.md#security-documentation-modularity) allows |
| Empty `SECURITY.md` for docs-only or pure libraries with no side effects | Omit the file and the authority-map row |
| Pasting the full multi-language SAST table into every project | Declare only tools for languages the repo ships |
| Claiming complete while skipping a **declared** style or SAST gate | Run inventory gates; see [Completion rule](#completion-rule) |
| Shipping Bandit / npm audit / Gitleaks / etc. as product runtime deps | Keep security / SAST tools developer-only |
| Committing `certification/last_certification.*` | Gitignore regenerable cert outputs; regenerate locally |
| Treating certification as a product launcher / diagnostics gate | Certification attests **source tree** policy only |
| Empty language inventory while shipping product code | Fill inventory when product languages exist |
| `feat` commit that only edits markdown | Use `docs` / `docs(scope)` |
| Leaving SETUP.md forever after adoption | Delete or archive after initiation; keep [Kit baseline](../RULES.md#kit-baseline); use [UPGRADE.md](../UPGRADE.md) |
| Language style “somehow” without a named gate | Declare tool + pass criteria in verification table |
| No project `CHANGELOG.md` | Maintain root CHANGELOG (repository H2 → version H3 → category H4) |
| Package version bump without CHANGELOG section | Add matching `### [X.Y.Z]` in the same change set |
| Shipping release-worthy behavior without CHANGELOG | Same change set: behavior + canonical docs + version + CHANGELOG |
| Kit upgrade with no baseline or CHANGELOG note | Update Adopted kit version/date and project CHANGELOG via [UPGRADE.md](../UPGRADE.md) |
| Inventing an alternate kit source URL | Use https://github.com/shainemeister/repo-kit (unless a deliberate fork) |
| Putting kit release history into a project `CHANGELOG.md` | Keep kit version only in the Kit baseline table |

---

## Contributor checklist

Before you commit or share a change:

- [ ] Behavior matches the **canonical** doc for that surface (CLI / API / methodology / security / README)  
- [ ] Inventory/catalog updated if paths changed (when maintained)  
- [ ] [Language surface inventory](./security.md#language-surface-inventory) still matches languages the repo ships  
- [ ] Versions and `last_updated` bumped where contracts changed  
- [ ] **CHANGELOG.md** updated when required (release-worthy behavior, version bump, security, kit adopt/upgrade)  
- [ ] Required **verification** from the table above has been run ([Completion rule](#completion-rule))  
- [ ] If product Python changed: **pylint** passed; **Bandit** passed when Python is in inventory  
- [ ] Other declared language surfaces: Domain B + Domain A gates passed for surfaces touched  
- [ ] If `certification/` is maintained: certificate regenerated; OverallPass true; outputs not staged  
- [ ] No secrets, sensitive production data, regenerable outputs, or caches staged  
- [ ] Markdown follows [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) when docs were edited  
- [ ] Commit message uses `type(scope):` format and matches the staged files  
- [ ] Subject would still make sense years later; one logical surface preferred  
- [ ] Canonical docs for any behavior change are in the same change set ([contracts.md](./contracts.md))  
- [ ] If kit pieces changed: [Kit baseline](../RULES.md#kit-baseline) version/date updated and CHANGELOG notes the upgrade ([UPGRADE.md](../UPGRADE.md))  
- [ ] If AI assisted: commit includes `Assisted-by` / `Compliance` / `Instructed-by`  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
