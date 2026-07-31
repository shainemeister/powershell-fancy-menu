---
title: PsMenuKit Security
description: Trust boundary, execution model, and launcher policy for the menu kit.
version: "0.1.0"
status: current
audience:
  - developers
  - security
doc_type: security
related:
  - ./README.md
  - ./CLI-GUIDE.md
  - ../../kit/rules/security.md
last_updated: "2026-07-30"
---

# PsMenuKit Security

Trust boundary for the interactive menu framework and demo launcher.

## Summary

| Topic | Policy |
|-------|--------|
| Privilege | Current user only; Core does not elevate |
| Network | Core does not download modules, menus, or telemetry |
| Dependencies | Zero runtime dependencies |
| Secrets | Do not store secrets in menu config or labels |
| Actions | Consumer-defined; treated as trusted local code |

## Contents

1. [Summary](#summary)
2. [Execution surface](#execution-surface)
3. [Launcher policy](#launcher-policy)
4. [Threat notes](#threat-notes)
5. [Document history](#document-history)

## Execution surface

| Component | Behavior |
|-----------|----------|
| Core render/input | Local console only |
| `Action` scriptblocks | Run in the caller session when an item is activated |
| Config (planned) | Load **local** `.psd1` / JSON paths only — no remote URLs |

Any network, privilege, or secret handling is the **consumer action’s** responsibility and must be documented by that application.

## Launcher policy

`demos/Launch.cmd` uses:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...
```

| Aspect | Guidance |
|--------|----------|
| `Bypass` | Applies to **local demo/scripts** for double-click convenience |
| Scope | Do not use Bypass to run untrusted remote scripts |
| Profile | `-NoProfile` avoids loading user profile side effects |

## Threat notes

| Risk | Mitigation |
|------|------------|
| Malicious menu action | Only load menus/scripts from trusted paths |
| Path injection via config | Future Config module should resolve paths under a known root |
| Host policy weakening | Do not permanently change machine ExecutionPolicy in product install steps |

## Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial trust boundary for Core + demo launcher |
