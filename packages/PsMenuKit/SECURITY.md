---
title: PsMenuKit Security
description: Trust boundary, unacceptable patterns, IT allowances, and validation for the pure-PowerShell menu kit.
version: "0.2.1"
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
  - ../../demos/Launch.Enterprise.cmd
last_updated: "2026-07-30"
---

# PsMenuKit — Security & Execution Notes

Enterprise-oriented trust boundary for **PsMenuKit**: a modular, dependency-free interactive console menu framework for **Windows PowerShell 5.1**.

**Package version:** 0.2.1  
**Package folder:** `packages/PsMenuKit/`  
**Runtime:** Windows PowerShell 5.1 (`powershell.exe`) — zero product runtime dependencies

**Related docs:** [README.md](./README.md) · [CLI-GUIDE.md](./CLI-GUIDE.md) · [METHODOLOGY.md](./METHODOLOGY.md) · [kit/rules/security.md](../../kit/rules/security.md)

---

## Summary

PsMenuKit runs **locally under the current user**, with **no network access** from kit modules, **no elevation**, and **no secrets handling**. Menu data files are **structure only**; executable behavior comes only from **host-supplied** scriptblocks (`HandlerMap` / `Action`). The demo launcher may use `-ExecutionPolicy Bypass` for local convenience; **enterprise** launches must not permanently weaken host policy.

Aligned with repo-kit security baseline: privilege, network, secrets, dependencies, and host-policy rules in [kit/rules/security.md](../../kit/rules/security.md).

---

## Contents

1. [Summary](#summary)
2. [Purpose of this document](#1-purpose-of-this-document)
3. [Trust boundary](#2-trust-boundary)
4. [Unacceptable patterns](#3-unacceptable-patterns)
5. [Required allowances](#4-required-allowances)
6. [Runtime restrictions](#5-runtime-restrictions)
7. [Config and HandlerMap trust](#6-config-and-handlermap-trust)
8. [Launcher policy](#7-launcher-policy)
9. [Recommended validation](#8-recommended-validation)
10. [Audit snapshot](#9-audit-snapshot)
11. [Statement for reviewers](#10-statement-for-reviewers)
12. [Related files](#11-related-files)
13. [Document history](#12-document-history)

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
| **Scope of files** | Local filesystem for config (`.psd1` / `.json`). Optional `-AllowedRoot` restricts config paths. UNC rejected by default. |
| **Dependencies** | **Zero** product runtime dependencies. SAST tools (PSScriptAnalyzer, optional Gitleaks) are **developer tooling only**. |
| **Actions** | Host-defined scriptblocks only. Kit does not invent remote or file-embedded code execution. |

```text
Untrusted (remote URLs, foreign shares, unreviewed HandlerMap)
        ✕
Current user session → host script (trusted HandlerMap)
                    → PsMenuKit (local UI + local config data)
```

---

## 3. Unacceptable patterns

| Pattern | Why sensitive | Status in kit product code (`packages/`) |
|---------|---------------|------------------------------------------|
| `Invoke-Expression` / `IEX` on file or user input | Arbitrary code execution | **Banned** (enforced by `tests/Security.BanList.Tests.ps1`) |
| `Invoke-WebRequest` / `WebClient` / `DownloadString` in kit modules | Remote load | **Banned** |
| Kit-initiated elevation (`RunAs`, permanent admin) | Privilege escalation | **Banned** |
| Base64 / encoded payload → execute | Obfuscated malware pattern | **Banned** |
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
| Demo `-ExecutionPolicy Bypass` | **Local demo only** — see [Launcher policy](#7-launcher-policy) |

---

## 4. Required allowances

| Capability | Used for | Typical gate |
|------------|----------|--------------|
| Run PowerShell scripts from an approved folder | Menu host + kit modules | AppLocker / WDAC path allowlist (customer-owned) |
| Interactive console (conhost or Windows Terminal) | UI | Standard user desktop |
| Optional: script signing (AllSigned / RemoteSigned) | Enterprise launcher without Bypass | Authenticode process (customer-owned) |
| Developer-only: PSScriptAnalyzer | Pre-ship SAST (Domain A) | Dev workstation / CI — **not** end-user install |

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
| Config allowlist | `-AllowedRoot` recommended for enterprise hosts |
| Handler binding | Name → host HandlerMap only; missing handler ⇒ no action unless host sets DefaultAction |
| Secrets | Do not place secrets in menu labels, config, Meta, or status lines |

---

## 6. Config and HandlerMap trust

| Concept | Trust level | Notes |
|---------|-------------|-------|
| Menu `.psd1` / `.json` | **Data** | Structure and labels; not executable policy |
| `Handler` string in config | **Name only** | Looked up in HandlerMap |
| `HandlerMap` scriptblocks | **Code (host)** | Same trust as any internal automation script |
| `New-PsMenuItem -Action { }` in host scripts | **Code (host)** | Reviewed with the application |

**IT takeaway:** Approving a menu config file is **not** the same as approving code. Approving the **host application** (HandlerMap / action scripts) is the code trust decision.

---

## 7. Launcher policy

### Demo (lab / developer)

[`demos/Launch.cmd`](../../demos/Launch.cmd):

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...\Demo.ps1
```

| Rule | Detail |
|------|--------|
| Scope | Local repository demo only |
| Must not | Be copied as the default production install without IT review |
| Profile | `-NoProfile` avoids user-profile injection |

### Enterprise (preferred pattern)

[`demos/Launch.Enterprise.cmd`](../../demos/Launch.Enterprise.cmd):

- Uses `-NoProfile`  
- Does **not** set permanent ExecutionPolicy  
- Relies on existing policy (e.g. RemoteSigned / AllSigned) or IT-approved process  
- Documents that unsigned Bypass is a **lab** option only  

Production hosts should:

1. Place kit + host scripts under an approved path.  
2. Prefer signed scripts where policy requires it.  
3. Pass `-AllowedRoot` when calling `Import-PsMenuConfig`.  

---

## 8. Recommended validation

Developer tooling only — not product runtime dependencies. Declared Domain B/A gates live in [kit/RULES.md](../../kit/RULES.md).

**Windows (PowerShell 5.1)**

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Parse-Gate.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Core.Model.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Feature.Modules.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Security.BanList.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Security.Config.Tests.ps1
```

**Domain A (when PSScriptAnalyzer is installed)**

```powershell
Import-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path packages,demos,tests -Recurse -Severity Error
# Pass = zero Error findings (exit code 0 from wrapper / no Error results)
```

**Optional secrets scan (when Gitleaks is adopted)**

```text
gitleaks detect --source .
```

---

## 9. Audit snapshot

| Decision | Rationale |
|----------|-----------|
| Zero runtime deps | Shrink supply chain; offline enterprise use |
| Config = data only | Prevent config-as-RCE |
| HandlerMap = host trust | Explicit code ownership for IT review |
| No network in kit | Clear offline boundary |
| Dual launchers | Demo convenience without forcing production Bypass |
| Ban-list tests | Regression guard against exploitive APIs |

---

## 10. Statement for reviewers

> PsMenuKit is a **local, current-user, offline** PowerShell console menu framework with **no product runtime dependencies**. It does not elevate privileges, phone home, or execute menu configuration files as code. Executable behavior is limited to **host-supplied scriptblocks**. Demo `-ExecutionPolicy Bypass` is for local lab use; enterprise deployments should use approved paths, preferred signing policy, and `Import-PsMenuConfig -AllowedRoot`. This document is a **self-attested trust description**, not a third-party certification.

---

## 11. Related files

| Path | Role |
|------|------|
| `packages/PsMenuKit/src/**` | Product modules (ban-list scoped) |
| `demos/Launch.cmd` | Demo launcher (Bypass, local) |
| `demos/Launch.Enterprise.cmd` | Enterprise-oriented launcher pattern |
| `demos/menus/sample.menu.psd1` | Sample config (no secrets) |
| `tests/Security.BanList.Tests.ps1` | Banned API scan |
| `tests/Security.Config.Tests.ps1` | Config path / schema negatives |
| `kit/RULES.md` | Inventory + verification table |
| `kit/rules/security.md` | repo-kit security policy |

---

## 12. Document history

| Version | Notes |
|---------|--------|
| 0.2.1 | Full TEMPLATE-SECURITY shape; enterprise launcher; Config controls; validation gates |
| 0.1.0 | Initial trust boundary for Core + demo launcher |
