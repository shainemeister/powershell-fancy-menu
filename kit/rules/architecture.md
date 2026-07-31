---
title: Architecture and Boundaries
description: Package composition, entry points, runtime separation, and dependency policy.
version: "1.0.0"
status: current
audience:
  - developers
  - architects
doc_type: other
related:
  - ../RULES.md
  - ./contracts.md
  - ./security.md
last_updated: "2026-07-28"
---

# Architecture and Boundaries

Structural rules for how packages and runtimes relate. Public surfaces those packages expose are **contracts**—see [contracts.md](./contracts.md).

**Document version:** 1.0.0  

**Related:** [RULES.md](../RULES.md) · [contracts.md](./contracts.md) · [security.md](./security.md)

---

## Summary

Keep packages composable at the workflow layer. Document intentional cross-stack boundaries. Prefer schema- and config-driven behavior over buried hard-coding.

---

## Contents

1. [Summary](#summary)
2. [Architecture rules](#architecture-rules)
3. [Document history](#document-history)

---

## Architecture rules

| Rule | Detail |
|------|--------|
| **Clear entry points** | Prefer documented CLI launchers, `__main__` modules, or public package APIs over ad-hoc scripts as the primary surface |
| **Composition** | Join packages at the **workflow** layer (files, CLI, messages), not by merging unrelated engines into one process unless that is an explicit design |
| **Runtime separation** | Do not call one stack from another in product code without an intentional, documented boundary |
| **Dependencies** | Declare the dependency policy in README and security docs (e.g. stdlib-only, locked set, or full package index). No hidden downloads or telemetry in product paths unless documented |
| **Domain hard-coding** | Prefer schema-, config-, or interface-driven behavior over hard-coded business field lists buried in engines |

Fill project-specific rows (runtimes, “never do X”) in a thin overlay or by expanding this table for the repo.

Public automation surfaces (CLI, API, schema fields) must follow [contracts.md](./contracts.md) for co-updates and versioning.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0; data/contract rules moved to contracts.md |
