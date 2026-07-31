---
title: powershell-fancy-menu - Security and code-validation certification
description: Operator guide for regenerable self-attestation certificates (security static analysis and code validation).
version: "0.4.0"
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

**Document version:** 0.4.0  
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
| **Harness** | `New-Certification.ps1` |

This is **not** a third-party audit, SOC 2, or ISO seal.

---

## Contents

1. [Summary](#summary)
2. [When to regenerate](#when-to-regenerate)
3. [Declared surfaces](#declared-surfaces)
4. [How to run](#how-to-run)
5. [Outputs](#outputs)
6. [Disclaimer](#disclaimer)
7. [Document history](#document-history)

---

## When to regenerate

After any change set that touches product code or declared gates:

1. Run `New-Certification.ps1` (or ensure gates match).  
2. Confirm `OverallPass` is true when shipping.  
3. Leave regenerable outputs **untracked** (gitignored).

Do not mark the task complete if a **declared** critical gate was skipped or failed.

---

## Declared surfaces

| Surface | Domain B command | Domain A command | Pass criteria |
|---------|------------------|------------------|---------------|
| PowerShell | `tests\Parse-Gate.ps1`, `Encoding.Ascii`, `Core.Model`, `Core.Edge`, `Feature.Modules` | `Security.BanList`, `Security.Config`, `Run-ScriptAnalyzer.ps1` | Exit 0 (Analyzer exit 2 = skip unless `-RequireAnalyzer`) |
| Shell (.cmd) | Documented launcher checklist in package SECURITY / MANUAL | Manual review | Enterprise Launch.cmd pattern |

---

## How to run

From repo root (developer machine):

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

Require PSScriptAnalyzer:

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1 -RequireAnalyzer
```

`-ExecutionPolicy Bypass` here is for **developer tooling only**, not product install. Product demo uses enterprise `demos\Launch.cmd` without Bypass.

---

## Outputs

| File | Role |
|------|------|
| `last_certification.json` | Machine-readable certificate (gitignored) |
| `last_certification.txt` | Human-readable certificate (gitignored) |

Fields include: `CertificateType`, `OverallPass`, `GitCommit`, `GitDirty`, `LanguageSurfaces`, `Domains.Security`, `Domains.CodeValidation`, `Checks[]`, `Disclaimer`.

---

## Disclaimer

Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No claim rows, passwords, or secret values in outputs (report counts / rule ids on failure).

**Suggested IT one-liner:**

> Automated security static analysis and code validation for declared PowerShell surfaces produced a pass certificate for commit \<sha\> at \<timestamp\>. Self-attestation only; not a third-party audit.

---

## Document history

| Version | Notes |
|---------|--------|
| 0.4.0 | Initial certification operator guide + harness |
