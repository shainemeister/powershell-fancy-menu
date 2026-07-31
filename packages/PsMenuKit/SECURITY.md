---
title: PsMenuKit Security
description: Trust boundary, unacceptable patterns, IT allowances, and validation for the pure-PowerShell menu kit.
version: "0.5.0"
status: current
audience:
  - security
  - developers
  - it
doc_type: security
related:
  - ./README.md
  - ./CLI-GUIDE.md
  - ./METHODOLOGY.md
  - ../../kit/rules/security.md
  - ../../demos/Launch.cmd
  - ../../certification/README.md
  - ../../tests/MANUAL.md
  - ../../tests/Run-AllGates.ps1
last_updated: "2026-07-30"
---

# PsMenuKit - Security & Execution Notes

Enterprise-oriented trust boundary for **PsMenuKit**: a modular, dependency-free interactive console menu framework for **Windows PowerShell 5.1**.

**Package version:** 0.5.0  
**Package folder:** `packages/PsMenuKit/`  
**Runtime:** Windows PowerShell 5.1 (`powershell.exe`) - zero product runtime dependencies

**Related docs:** [README.md](./README.md) / [CLI-GUIDE.md](./CLI-GUIDE.md) / [METHODOLOGY.md](./METHODOLOGY.md) / [kit/rules/security.md](../../kit/rules/security.md)

---

## Summary

PsMenuKit runs **locally under the current user**, with **no network access** from kit modules, **no elevation**, and **no secrets handling**. Menu data files are **structure only**; executable behavior comes only from **host-supplied** scriptblocks (`HandlerMap` / `Action`). The default demo launcher (`demos/Launch.cmd`) uses the **enterprise** pattern (no Bypass, no permanent policy change).

Aligned with repo-kit security baseline: privilege, network, secrets, dependencies, and host-policy rules in [kit/rules/security.md](../../kit/rules/security.md).

---

## Contents

1. [Summary](#summary)
2. [Purpose of this document](#1-purpose-of-this-document)
3. [Trust boundary](#2-trust-boundary)
4. [Unacceptable patterns](#3-unacceptable-patterns)
5. [Required allowances](#4-required-allowances)
6. [Runtime restrictions](#5-runtime-restrictions)
7. [Supported environments](#6-supported-environments)
8. [Config and HandlerMap trust](#7-config-and-handlermap-trust)
9. [Launcher policy](#8-launcher-policy)
10. [Recommended validation](#9-recommended-validation)
11. [IT hardening checklist](#10-it-hardening-checklist)
12. [Audit snapshot](#11-audit-snapshot)
13. [Statement for reviewers](#12-statement-for-reviewers)
14. [Related files](#13-related-files)
15. [Document history](#14-document-history)

---

## 1. Purpose of this document

1. Describe what PsMenuKit **does** from a security perspective.  
2. List patterns treated as **unacceptable** in kit product code.  
3. State what **enterprise / IT** must allow (and what they need not allow).  
4. Provide **validation** commands for a controlled machine (repo-kit Domain A/B).

---

## 2. Trust boundary

| Area | Behavior |
|------|----------|
| **Privilege** | Current user only. Kit modules do not elevate (no UAC / `RunAs`). |
| **Network** | **None.** Kit does not download modules, menus, telemetry, or package indexes. |
| **Identity** | Runs as the interactive (or scheduled) user identity of the host process. |
| **Scope of files** | Local filesystem for config (`.psd1` / `.json`). Optional `-AllowedRoot` restricts config paths; reparse points (junctions/symlinks) under the root are rejected. UNC rejected by default. |
| **Dependencies** | **Zero** product runtime dependencies. SAST tools (PSScriptAnalyzer, optional Gitleaks) are **developer tooling only**. |
| **Actions** | Host-defined **scriptblocks** only. Non-scriptblock Actions (e.g. mutated string command names) are rejected at invoke time. Kit does not invent remote or file-embedded code execution. |

```text
Untrusted (remote URLs, foreign shares, unreviewed HandlerMap)
        x
Current user session -> host script (trusted HandlerMap)
                    -> PsMenuKit (local UI + local config data)
```

---

## 3. Unacceptable patterns

| Pattern | Why sensitive | Status in kit product code (`packages/`) |
|---------|---------------|------------------------------------------|
| `Invoke-Expression` / `IEX` on file or user input | Arbitrary code execution | **Banned** (enforced by `tests/Security.BanList.Tests.ps1`) |
| `Invoke-WebRequest` / `WebClient` / `DownloadString` in kit modules | Remote load | **Banned** |
| Kit-initiated elevation (`RunAs`, permanent admin) | Privilege escalation | **Banned** |
| Base64 / encoded payload -> execute | Obfuscated malware pattern | **Banned** |
| Config fields executed as code (`ActionScript`, `Command`, `ScriptBlock` strings from file) | Config-as-RCE | **Banned** (schema reject) |
| Permanent `Set-ExecutionPolicy Unrestricted` (or similar) in product | Weakens host | **Banned** |
| Hard-coded credentials / tokens | Secret exposure | **Banned** |
| Telemetry / phone-home | Network + privacy | **Banned** |
| Silent `Install-Module` from product path | Supply chain | **Banned** |

**Allowed (controlled):**

| Pattern | Condition |
|---------|-----------|
| `Import-PowerShellDataFile` | Local `.psd1` menu **data** only |
| `ConvertFrom-Json` | Local `.json` menu **data** only |
| Host `scriptblock` Actions / HandlerMap | Trusted, reviewed host application code |
| Demo launcher Bypass | **Not used** - enterprise `Launch.cmd` only; Bypass may appear in **developer test runners** only |

---

## 4. Required allowances

| Capability | Used for | Typical gate |
|------------|----------|--------------|
| Run PowerShell scripts from an approved folder | Menu host + kit modules | AppLocker / WDAC path allowlist (customer-owned) |
| Interactive console (conhost or Windows Terminal) | UI | Standard user desktop |
| Optional: script signing (AllSigned / RemoteSigned) | Enterprise launcher without Bypass | Authenticode process (customer-owned) |
| Developer-only: PSScriptAnalyzer | Pre-ship SAST (Domain A) | Dev workstation / CI - **not** end-user install |

**Not required / not requested by this product:**

- Disabling antivirus, AMSI, or Constrained Language Mode  
- Permanent ExecutionPolicy weakening on the machine  
- Network egress for the kit itself  
- Elevation for Core or feature modules  

---

## 5. Runtime restrictions

### 5.1 Supported runtime

| Item | Expectation |
|------|-------------|
| **Version / host** | Windows PowerShell **5.1** (`powershell.exe`) |
| **Libraries** | Built-in only; no Gallery modules at runtime |
| **Profile** | Prefer `-NoProfile` for production launchers |

### 5.2 Controls

| Control | Detail |
|---------|--------|
| Config extensions | `.psd1`, `.json` only |
| Config location | Local path; URI schemes rejected; UNC default-deny |
| Config allowlist | `-AllowedRoot` recommended for enterprise hosts; junctions/symlinks under root rejected |
| Config graph limits | Default **MaxItems=500**, **MaxDepth=16**, **MaxLabelLength=500** (fail closed; overridable) |
| Handler binding | Name -> host HandlerMap only; map values must be scriptblocks; missing handler => no action unless host sets DefaultAction |
| Action invoke | Fail-closed: only `[scriptblock]` is invoked (blocks string/command-name abuse) |
| Display integrity | Control characters and ANSI/OSC sequences stripped before console write (best effort) |
| Secrets | Do not place secrets in menu labels, config, Meta, or status lines |
| Nested UI depth | Default max **8** (fail soft / stay on parent) |
| Console restore | Title + cursor restored on normal exit (best effort on Ctrl+C) |
| Status line | Optional user/host/time slots may appear on shared screens - avoid sensitive free-text |

---

## 6. Supported environments

| Environment | Interactive menus | Config load | Notes |
|-------------|-------------------|-------------|-------|
| Windows PowerShell **5.1**, Full Language Mode, console host | **Supported** | **Supported** | Primary target |
| Windows Terminal hosting 5.1 | **Supported** | **Supported** | Preferred UX |
| Constrained Language Mode | **Unsupported** for full Action dispatch | **Partial** (data parse may work) | Scriptblock Actions / host maps typically cannot run under CLM. **Do not** disable CLM as an install step. |
| Non-interactive / no RawUI console | **Unsupported** | Config-only hosts OK | `Show-PsMenu` needs keyboard input |
| PowerShell 7+ | Best effort | Best effort | Not first-class in 0.5.0 |
| Remote PSSession without interactive console | **Unsupported** | N/A | |

**Honesty rules:** never document permanent ExecutionPolicy Unrestricted, CLM disable, or AV/AMSI disable as product requirements.

---

## 7. Config and HandlerMap trust

| Concept | Trust level | Notes |
|---------|-------------|-------|
| Menu `.psd1` / `.json` | **Data** | Structure and labels; not executable policy |
| `Handler` string in config | **Name only** | Looked up in HandlerMap |
| `HandlerMap` scriptblocks | **Code (host)** | Same trust as any internal automation script; non-scriptblock values rejected |
| `DefaultAction` | **Code (host)** | Binds to every item without a matching Handler - use only as intentional catch-all |
| `New-PsMenuItem -Action { }` in host scripts | **Code (host)** | Reviewed with the application |

**IT takeaway:** Approving a menu config file is **not** the same as approving code. Approving the **host application** (HandlerMap / action scripts) is the code trust decision.

---

## 8. Launcher policy

### Demo (enterprise-standard default)

[`demos/Launch.cmd`](../../demos/Launch.cmd):

```text
powershell.exe -NoProfile -File ...\Demo.ps1
```

| Rule | Detail |
|------|--------|
| Profile | `-NoProfile` avoids user-profile injection |
| ExecutionPolicy flag | **Not** passed (no Bypass on demo path) |
| Permanent policy | Never changed by this launcher |
| Host policy | Relies on existing RemoteSigned / AllSigned / IT process |
| On failure | Hints to signed scripts / approved process; no Unrestricted advice |

Production hosts should:

1. Place kit + host scripts under an approved path.  
2. Prefer signed scripts where policy requires it.  
3. Pass `-AllowedRoot` when calling `Import-PsMenuConfig`.  

### Developer gates (not product install)

`tests\Run-AllGates.ps1` and `certification\New-Certification.ps1` may use `-ExecutionPolicy Bypass` so CI/dev machines can run gates without changing machine policy. That is **developer tooling only**.

---

## 9. Recommended validation

Developer tooling only - not product runtime dependencies. Declared Domain B/A gates live in [kit/RULES.md](../../kit/RULES.md).

**Primary (all required smokes)**

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
```

**CI (require analyzer):** GitHub Actions workflow `.github/workflows/ci.yml` runs `Run-AllGates.ps1 -RequireAnalyzer` and certification on Windows.

**Formal certification pair** (gitignored outputs):

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

**Interactive checklist:** [tests/MANUAL.md](../../tests/MANUAL.md)

**Domain A analyzer wrapper**

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-ScriptAnalyzer.ps1
```

- Exit **0** = zero Error findings  
- Exit **2** = module not installed (skip)  
- Exit **1** = findings or require-module failure  

Install (developer only): `Install-Module PSScriptAnalyzer -Scope CurrentUser`

**Optional secrets scan (when Gitleaks is adopted)**

```text
gitleaks detect --source .
```

---

## 10. IT hardening checklist

| Step | Guidance |
|------|----------|
| 1. Approved path | Place kit + host scripts under AppLocker / WDAC allowlisted directories |
| 2. NoProfile launch | Use `powershell.exe -NoProfile -File host.ps1` (see demos/templates) |
| 3. AllowedRoot | Always pass `Import-PsMenuConfig -AllowedRoot <approved\menus>` |
| 4. HandlerMap change control | Treat host scriptblocks as application code (review / PR) |
| 5. Prefer explicit handlers | Avoid broad `DefaultAction` unless catch-all is intentional |
| 6. Signing (if policy requires) | Authenticode-sign host + modules; do not set Unrestricted |
| 7. Release integrity | Prefer release checksums or signed packages; treat dropped files under `src/` as supply-chain risk |
| 8. No secrets in menus | Labels, Meta, ConfirmMessage, and status free-text are display surfaces |
| 9. Screen share | Status lines may show username/host/last labels - disable sensitive slots when recording |
| 10. Run gates | `tests\Run-AllGates.ps1` (CI with `-RequireAnalyzer` on merge) |

---

## 11. Audit snapshot

| Decision | Rationale |
|----------|-----------|
| Zero runtime deps | Shrink supply chain; offline enterprise use |
| Config = data only | Prevent config-as-RCE |
| HandlerMap = host trust | Explicit code ownership for IT review |
| Action type fail-closed | Block mutated string command invocation |
| AllowedRoot + reparse reject | Prefix check alone is insufficient against junctions |
| Graph limits | Reduce config-driven DoS / hang risk |
| Display sanitization | Best-effort terminal control-sequence integrity |
| No network in kit | Clear offline boundary |
| Single enterprise Launch.cmd | No Bypass on product demo path |
| Ban-list + CI | Regression guard; analyzer required in CI |
| Certification folder | Self-attestation for IT packets; not a product gate |

---

## 12. Statement for reviewers

> PsMenuKit is a **local, current-user, offline** PowerShell console menu framework with **no product runtime dependencies**. It does not elevate privileges, phone home, or execute menu configuration files as code. Executable behavior is limited to **host-supplied scriptblocks** (non-scriptblock Actions rejected). The default demo launcher uses an **enterprise** pattern (no ExecutionPolicy Bypass). Developer gate runners and CI may use Bypass for automation only. Prefer approved paths, signing where required, and `Import-PsMenuConfig -AllowedRoot`. This document is a **self-attested trust description**, not a third-party certification.

---

## 13. Related files

| Path | Role |
|------|------|
| `packages/PsMenuKit/src/**` | Product modules (ban-list scoped) |
| `templates/**` | Consumer patterns (ban-list + analyzer scoped) |
| `demos/Launch.cmd` | Enterprise-standard demo launcher |
| `demos/menus/sample.menu.psd1` | Sample config (no secrets) |
| `certification/` | Quality + security self-attestation (dev only) |
| `tests/Run-AllGates.ps1` | Single Domain B + kit security gate entrypoint |
| `tests/Run-ScriptAnalyzer.ps1` | Domain A wrapper |
| `tests/MANUAL.md` | Interactive checklist |
| `tests/Security.BanList.Tests.ps1` | Banned API scan |
| `tests/Security.Config.Tests.ps1` | Config path / schema negatives |
| `tests/Security.Action.Tests.ps1` | Action type, display sanitization, limits, reparse |
| `.github/workflows/ci.yml` | Windows CI with required analyzer |
| `kit/RULES.md` | Inventory + verification table |
| `kit/rules/security.md` | repo-kit security policy |

---

## 14. Document history

| Version | Notes |
|---------|--------|
| 0.5.0 | Action type fail-closed; HandlerMap validation; reparse reject; graph limits; display sanitization; CI; IT checklist; honest CLM |
| 0.4.0 | Single enterprise Launch.cmd; certification pointer; Bypass only for dev gates |
| 0.3.0 | Supported environments matrix; Run-AllGates validation; console restore notes |
| 0.2.1 | Full TEMPLATE-SECURITY shape; Config controls; validation gates |
| 0.1.0 | Initial trust boundary for Core + demo launcher |
