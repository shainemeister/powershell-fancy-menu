# PLAN-FIX: Encoding.Ascii CI Failure

## Summary

The GitHub Actions job **Security and validation gates** (workflow `CI`, `.github/workflows/ci.yml`) failed on the latest `master` push. All gates passed except **Encoding.Ascii**, which reported 3 non-ASCII characters across two README files introduced by the docs rewrite commit.

| Item | Value |
|------|--------|
| Failed run | https://github.com/shainemeister/powershell-fancy-menu/actions/runs/30607059945 |
| Job | Security and validation gates |
| Failed step | Run all gates (require analyzer) |
| Failing gate | Encoding.Ascii (`tests/Encoding.Ascii.Tests.ps1`) |
| Trigger commit | `de72b58` - docs: end-user README with AI adoption quick-path |
| Prior run | `ce50db2` (0.5.1 security) - success |

**Goal of this plan:** restore a green Encoding.Ascii gate (and thus a green CI job) with minimal, surgical ASCII-safe edits. No product code, security, or API changes are required.

## Root cause

The Encoding.Ascii gate rejects any character outside the set:

- tab (0x09)
- LF (0x0A)
- CR (0x0D)
- printable ASCII 0x20-0x7E

It scans (among others) everything under `packages/` and `templates/`, including `*.md`.

The docs commit introduced the Unicode **middle dot** `U+00B7` (character: middle-dot) as a separator in cross-link lines.

Exact hits from the CI log:

```text
NON-ASCII: packages\PsMenuKit\README.md (2 char(s))
NON-ASCII: templates\consumer-launch\README.md (1 char(s))
Encoding.Ascii FAILED (3 non-ASCII char(s)).
```

No other files or gates failed. ScriptAnalyzer, security ban-list, config, action, launcher, parse, and core/feature tests all passed.

## Exact locations to change

### 1. `packages/PsMenuKit/README.md` (2 hits)

Find the cross-link sentence near the top of the body (after the module version table):

```text
Root landing with AI paste prompts and copy-paste adoption: [repository README](../../README.md) <MIDDLE-DOT> [How to use (quick path)](../../README.md#how-to-use-quick-path) <MIDDLE-DOT> [Add to your repo](../../README.md#add-to-your-repo).
```

Replace each middle-dot with an ASCII-safe separator. Preferred mapping (matches `tools/Normalize-AsciiText.ps1`):

```text
Root landing with AI paste prompts and copy-paste adoption: [repository README](../../README.md) / [How to use (quick path)](../../README.md#how-to-use-quick-path) / [Add to your repo](../../README.md#add-to-your-repo).
```

Acceptable alternatives: ` | ` or ` - ` (keep spacing readable).

### 2. `templates/consumer-launch/README.md` (1 hit)

Find the Security / Root adoption line near the bottom:

```text
- Root adoption (AI prompts + examples): [README - How to use](../../README.md#how-to-use-quick-path) <MIDDLE-DOT> [Add to your repo](../../README.md#add-to-your-repo).
```

Replace the middle-dot the same way:

```text
- Root adoption (AI prompts + examples): [README - How to use](../../README.md#how-to-use-quick-path) / [Add to your repo](../../README.md#add-to-your-repo).
```

## Recommended fix paths (pick one)

### Path A - Surgical hand-edit (preferred for this 3-char case)

1. Edit the two files above only.
2. Replace the three middle-dot characters with ` / ` (or another pure-ASCII separator).
3. Do not change other wording, links, or structure.
4. Ensure the files remain UTF-8 without BOM (project convention).

### Path B - Run the existing normalizer

From the repository root on Windows PowerShell 5.1:

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\Normalize-AsciiText.ps1
```

This tool already maps U+00B7 middle-dot to ` / ` and handles other common fancy punctuation. Review the diff afterward; it may touch additional files if any other non-ASCII slipped in. Prefer Path A if you want the smallest possible change set.

### Path C - What-if first, then apply

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\Normalize-AsciiText.ps1 -WhatIf
```

Inspect WOULD UPDATE lines, then re-run without `-WhatIf`.

## Out of scope (do not change for this fix)

- Product modules under `packages/PsMenuKit/src/`
- Gate scripts under `tests/` (policy is correct; content violated it)
- CI workflow (`.github/workflows/ci.yml`)
- Certification schema or `New-Certification.ps1`
- Root `README.md` (already ASCII-clean per the failing run)
- Version bumps, CHANGELOG Unreleased notes beyond a one-line mention of the encoding fix (optional)

## Verification (must pass before claiming done)

Run from repository root:

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1 -RequireAnalyzer
```

Expected:

- Encoding.Ascii prints `Encoding.Ascii OK (... file(s)).`
- Overall `Run-AllGates` exits 0
- No new NON-ASCII lines for the two READMEs

Optional local certification (developer-only; do not commit `last_certification.*`):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

After push, confirm the CI job **Security and validation gates** is green on the new commit.

## Suggested commit message

```text
fix(docs): remove non-ASCII middle-dots for Encoding.Ascii gate

Replace U+00B7 separators in packages/PsMenuKit/README.md and
templates/consumer-launch/README.md so the Encoding.Ascii gate and
CI Security and validation gates job pass again.

Assisted-by: <tool if any>
Compliance: RULES.md
Instructed-by: Shaine Meister
```

Follow conventional commits and `kit/rules/versioning-and-git.md`. This is a docs-only fix; no version bump required unless you also touch product behavior.

## Acceptance criteria

1. Zero NON-ASCII reports from `tests/Encoding.Ascii.Tests.ps1`.
2. `tests\Run-AllGates.ps1 -RequireAnalyzer` exits 0 locally.
3. GitHub Actions CI job **Security and validation gates** succeeds on the fix commit.
4. Diff is limited to the two README files (or normalizer-driven equivalent) with only separator character changes.
5. No secrets, regenerable certification outputs, or unrelated refactors staged.

## Context for the assisting AI

- Runtime and gates target **Windows PowerShell 5.1** only.
- Project policy (Windows console safety) intentionally forbids non-ASCII in scanned source/docs trees; see `tests/Encoding.Ascii.Tests.ps1` and `tools/Normalize-AsciiText.ps1`.
- Authority and verification rules live under `kit/RULES.md` and `kit/rules/`.
- Product plan (not this fix plan): root `PLAN.md`.
- Do not weaken the Encoding.Ascii gate to "allow" the middle-dot; fix the content.

## Status

| Field | Value |
|-------|--------|
| Status | Open - ready to execute |
| Created | 2026-07-31 |
| Blocking | CI on `master` (run 30607059945) |
| Owner | Maintainer / assisting AI |
