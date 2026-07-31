# powershell-fancy-menu (PsMenuKit)

Dependency-free **Windows PowerShell 5.1** modular console menu kit. Launch demos with a `.cmd` backbone; compose a small **Core** engine with optional feature modules for your own tools.

## Use cases

| You want to... | Start here |
|--------------|------------|
| Try the interactive demo | Double-click [`demos/Launch.cmd`](./demos/Launch.cmd) (enterprise-standard) |
| Security / IT notes | [packages/PsMenuKit/SECURITY.md](./packages/PsMenuKit/SECURITY.md) |
| Certification (dev self-attestation) | [certification/README.md](./certification/README.md) |
| Consumer template | [templates/consumer-launch/](./templates/consumer-launch/) |
| Build a custom menu | [packages/PsMenuKit/README.md](./packages/PsMenuKit/README.md) / [CLI-GUIDE.md](./packages/PsMenuKit/CLI-GUIDE.md) |
| Understand composition | [METHODOLOGY.md](./packages/PsMenuKit/METHODOLOGY.md) |
| See trust / execution rules | [SECURITY.md](./packages/PsMenuKit/SECURITY.md) |
| Project plan and roadmap | [PLAN.md](./PLAN.md) |
| Maintenance / kit standards | [kit/RULES.md](./kit/RULES.md) |

## Quick start (Windows)

```cmd
cd demos
Launch.cmd
```

Or from the repo root:

```cmd
demos\Launch.cmd
```

Requirements:

- Windows
- Windows PowerShell **5.1** (`powershell.exe`)
- **No** PowerShell Gallery modules

## Design highlights

- **Zero runtime dependencies** - pure PowerShell + console APIs.
- **Modular** - import Core only, or add Theme, Nested, Search, MultiSelect, Confirm, Status, Config.
- **`.cmd` backbone** - double-click friendly: sets UTF-8, working directory, and invokes `powershell.exe`.
- **Enterprise-minded** - offline kit, Config as data, enterprise `Launch.cmd`; see [SECURITY.md](./packages/PsMenuKit/SECURITY.md).
- **repo-kit governed** - standards under `kit/`; product under `packages/`.

## Verify

Developer tooling only (Bypass for gates/CI - not product install):

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\Run-AllGates.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File certification\New-Certification.ps1
```

## Repository layout

```text
kit/                  # repo-kit standards (not product code)
packages/PsMenuKit/   # menu kit product + contracts
demos/                # Launch.cmd + Demo.ps1
templates/            # consumer-launch starter
certification/        # quality + security self-attestation (dev)
tests/                # gates and fixtures
PLAN.md               # project plan
CHANGELOG.md          # project history
```

## Status

**0.4.0** - Enterprise-only `Launch.cmd`, certification harness, consumer template, MultiSelect demo, Core hot-path polish. See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT - see [LICENSE](./LICENSE).
