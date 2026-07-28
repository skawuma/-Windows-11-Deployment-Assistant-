# Sprint status

Current version: Version 1 — Local PowerShell Technician Assistant

Current sprint: Sprint 2 — PowerShell inputs and device configuration

Sprint status: COMPLETE

Start date: 2026-07-28

Completion date: 2026-07-28

Implemented:

- Added the Version 1 PowerShell module manifest, module, and entry script.
- Added strict Draft 2020-12 validation for the versioned local configuration.
- Added asset-tag normalization and validation using a provisional configurable
  format, plus email normalization and validation.
- Added read-before-write, post-change verification, idempotence, and
  `ShouldProcess`/`-WhatIf` handling for the approved time-zone and lid, power
  button, and sleep button settings.
- Added safe platform and Administrator checks that report normalized
  `Pass`, `Fail`, `Skipped`, or `Error` outcomes without bypassing controls.
- Added deterministic device-state simulation, including compliant,
  changes-required, standard-user, non-Windows, and injected-failure fixtures.
- Added a dependency-free PowerShell test harness and safe usage samples.
- Kept API and download-queue integrations explicitly disabled.
- Deferred application detection, decision rules, persistent logs, and durable
  summary artifacts to their authorized later sprints.
- Published milestone commit `c549240` to
  `origin/codex/qnity-incremental-development`.

Tests executed:

- `pwsh -NoProfile -File ./powershell/tests/Invoke-Tests.ps1` — 21 tests passed,
  0 failed.
- `Test-ModuleManifest` — passed for module version `0.2.0` with declared
  PowerShell 5.1 compatibility.
- All nine checked-in PowerShell JSON configuration, schema, fixture, and sample
  files parsed successfully.
- The Draft 2020-12 configuration schema and checked-in configuration instance
  passed independent `jsonschema` 4.23.0 validation.
- All four PowerShell source, module, manifest, and test files parsed without
  syntax errors.
- A real host-guard run on macOS returned four safe `Skipped` results and
  attempted no Windows commands.
- `./scripts/validate-foundation.sh` — passed.
- Local links across 19 Markdown files — passed.
- Sensitive credential and private-key pattern scan — passed with no matches.
- `git diff --check` — passed.

Known limitations:

- Simulation tests run on PowerShell 7.6.4 on macOS; Windows PowerShell 5.1 and
  an approved Windows test device have not yet been validated.
- The real `powercfg.exe` query parser depends on English output labels.
- The asset-tag rule is provisional pending the enterprise format decision.
- The configured power values require endpoint/change-management approval before
  production use.
- Application detection, local logs/summaries, signing, packaging, and
  production rollout are not part of Sprint 2.

Unresolved decisions:

- Enterprise approvals listed in `docs/requirements-reconciliation.md`,
  including asset-tag format, device settings, application identities,
  authentication, retention, signatures, and exception policy.

Next authorized sprint: None. Wait for the explicit instruction
`Proceed with Sprint 3`.
