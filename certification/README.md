---
title: powershell-fancy-menu - Security and code-validation certification
description: Operator guide for regenerable self-attestation certificates (security static analysis and code validation).
version: "0.5.1"
status: current
audience:
  - developers
  - security
  - it
doc_type: other
related:
  - ../kit/RULES.md
  - ../kit/rules/security.md
  - ../packages/PsMenuKit/SECURITY.md
  - ../tests/Run-AllGates.ps1
last_updated: "2026-07-30"
---

# powershell-fancy-menu - Certification

Operator guide for the **formal, regenerable** security and code-validation certificate for this repository.

**Document version:** 0.5.1  
**Certificate schema:** **1.1**  
**Status:** current  

**Related:** [kit/rules/security.md](../kit/rules/security.md) / [packages/PsMenuKit/SECURITY.md](../packages/PsMenuKit/SECURITY.md) / [tests/Run-AllGates.ps1](../tests/Run-AllGates.ps1)

---

## Summary

| Item | Decision |
|------|----------|
| **What** | Developer **self-attestation** certificate (JSON + TXT) for Domain A (security) and Domain B (code validation) |
| **Where** | This folder only: `certification/` |
| **Who runs it** | Developers / release reviewers - **not** end-user product launchers |
| **Product impact** | Must **not** gate `demos/Launch.cmd` or product install |
| **Harness** | `New-Certification.ps1` (schema **1.1**) |
| **Outputs** | Gitignored `last_certification.json` + `last_certification.txt` |

This is **not** a third-party audit, SOC 2, or ISO seal.

---

## Contents

1. [Summary](#summary)
2. [When to regenerate](#when-to-regenerate)
3. [Declared surfaces](#declared-surfaces)
4. [How to run](#how-to-run)
5. [Parameters](#parameters)
6. [Certificate schema 1.1](#certificate-schema-11)
7. [Checks](#checks)
8. [Outputs](#outputs)
9. [Interpreting results (IT)](#interpreting-results-it)
10. [Disclaimer](#disclaimer)
11. [Document history](#document-history)

---

## When to regenerate

After any change set that touches product code or declared gates:

1. Run `New-Certification.ps1` (or ensure gates match).  
2. Confirm `OverallPass` is true when shipping.  
3. Leave regenerable outputs **untracked** (gitignored).  
4. Prefer a clean git tree for release packets (`GitDirty: false`).

Do not mark the task complete if a **declared critical** gate was skipped or failed.

---

## Declared surfaces

| Surface | Domain B | Domain A | Pass criteria |
|---------|----------|----------|---------------|
| **PowerShell** | Parse-Gate, Encoding.Ascii, Core.Model, Core.Edge, Feature.Modules, Manifest.VersionConsistency | Security.BanList, Security.Config, Security.Action, ScriptAnalyzer | Exit 0 / pass; analyzer required by default |
| **Shell** (`.cmd`) | - | Security.Launcher (enterprise policy on `demos/` + `templates/`) | No Bypass / Set-ExecutionPolicy; `-NoProfile` when invoking powershell |
| **Secrets** (optional) | - | Secrets.Gitleaks when available | Clean detect; required only with `-RequireSecretsScan` |

---

## How to run

From repo root (developer machine):

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

Explicit analyzer require (same as default):

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1 -RequireAnalyzer
```

Enterprise secrets scan (requires `gitleaks` on PATH):

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1 -RequireAnalyzer -RequireSecretsScan
```

`-ExecutionPolicy Bypass` here is for **developer tooling only**, not product install. Product demo uses enterprise `demos\Launch.cmd` without Bypass.

CI runs this harness after `Run-AllGates.ps1 -RequireAnalyzer` and uploads the JSON/TXT as artifacts.

---

## Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `-RequireAnalyzer` | **true** (unless `-SkipAnalyzer`) | Fail if PSScriptAnalyzer missing or reports Error findings |
| `-SkipAnalyzer` | false | Do not run ScriptAnalyzer |
| `-RequireSecretsScan` | false | Fail if gitleaks missing or finds leaks |
| `-SkipSecretsScan` | false | Do not run gitleaks at all |
| `-Quiet` | false | Less console output |

**Exit codes**

| Code | Meaning |
|------|---------|
| 0 | `OverallPass` true |
| 1 | One or more critical checks failed |
| 2 | Required tool missing (e.g. analyzer / gitleaks when required) |

---

## Certificate schema 1.1

Machine-readable fields in `last_certification.json`:

| Field | Purpose |
|-------|---------|
| `CertificateType` | `SecurityAndCodeValidationCertification` |
| `SchemaVersion` | `1.1` |
| `OverallPass` / `Success` | AND of domains for critical checks |
| `TimestampUtc` | Generation time (ISO 8601 UTC) |
| `RepoRoot` | Absolute path on the runner |
| `GitCommit` / `GitCommitShort` / `GitBranch` / `GitDirty` | Source binding |
| `LanguageSurfaces` | Inventory (PowerShell, Shell, Secrets when scanned) |
| `PackageVersions.PsMenuKit` | Read from module manifest (not hard-coded) |
| `ToolVersions` | PowerShell, OS, PSScriptAnalyzer, Gitleaks when present |
| `PassCriteria` | Human summary of pass rules |
| `Policy` | Flags used for this run |
| `Integrity.ManifestSha256` | SHA-256 of `packages/PsMenuKit/PsMenuKit.psd1` |
| `Integrity.PackagesSrcSha256` | Deterministic tree hash of `packages/PsMenuKit/src` |
| `Domains.Security` / `Domains.CodeValidation` | Per-domain pass + critical fail counts |
| `Checks[]` | Name, Domain, Language, Passed, Severity, Detail, DurationMs |
| `Disclaimer` / `Message` / `SuggestedItOneLiner` | Reviewer text |

**Privacy:** paths, versions, rule ids, counts only - never secrets, passwords, PHI, or production claim rows.

---

## Checks

### Domain B - Code validation (critical unless noted)

| Name | What it proves |
|------|----------------|
| Parse-Gate | Product scripts parse under PS 5.1 |
| Encoding.Ascii | ASCII-safe encoding policy |
| Core.Model / Core.Edge | Core model and edge behavior |
| Feature.Modules | Feature modules compose |
| Manifest.VersionConsistency | Root / Core / Config module versions match |
| Docs.SecurityAuthority | **Advisory** - SECURITY.md + this README present, no template placeholders |

### Domain A - Security (critical unless noted)

| Name | What it proves |
|------|----------------|
| Security.BanList | Banned APIs absent from packages + templates |
| Security.Config | Path allowlist, schema, MaxFileBytes, UNC/URI deny |
| Security.Action | Action type fail-closed, display sanitization, limits |
| Security.Launcher | Product `.cmd` enterprise policy |
| ScriptAnalyzer | Zero Error findings (required by default) |
| Secrets.Gitleaks | **Advisory** unless `-RequireSecretsScan` |

---

## Outputs

| File | Role |
|------|------|
| `last_certification.json` | Machine-readable certificate (gitignored) |
| `last_certification.txt` | Human-readable certificate (gitignored) |

Never commit regenerable outputs.

---

## Interpreting results (IT)

| Signal | Interpretation |
|--------|----------------|
| `OverallPass: true` | All **critical** declared gates passed on this tree at this commit |
| `GitDirty: true` | Working tree had uncommitted changes; regenerate after clean commit for release packets |
| `Integrity.*Sha256` | Fingerprint of package manifest + src tree for supply-chain comparison |
| `ToolVersions` | What analyzer/OS ran - pin analyzer in CI for reproducibility |
| `Secrets` surface | Only meaningful if gitleaks ran; optional for day-to-day, preferred for enterprise releases |
| Failures | Inspect `Checks[]` Detail; fix product code; re-run harness |

**Suggested IT one-liner** (also embedded in the certificate):

> Automated security static analysis and code validation for declared surfaces produced a self-attestation certificate for commit \<sha\> at \<timestamp\>. Self-attestation only; not a third-party audit.

---

## Disclaimer

Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No claim rows, passwords, or secret values in outputs (report counts / rule ids on failure).

---

## Document history

| Version | Notes |
|---------|--------|
| 0.5.1 | Schema 1.1: integrity, tool versions, launcher + secrets surfaces, expanded checks |
| 0.4.0 | Initial certification operator guide + harness |
