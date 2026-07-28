# Changelog

All notable project changes are recorded here. Dates use `yyyy-MM-dd`.

## [Unreleased]

### Sprint 2 — 2026-07-28

#### Added

- Versioned PowerShell configuration and strict Draft 2020-12 configuration
  schema for local input, time-zone, power, and safety policy.
- PowerShell module and entry script with asset-tag/email validation,
  read-before-write configuration, post-change verification, idempotence, and
  `-WhatIf` support.
- Deterministic simulation fixtures for compliant, changes-required,
  standard-user, non-Windows, and injected-failure device states.
- Dependency-free PowerShell behavior tests and safe operator samples.

#### Changed

- Advanced the project to Version 1 Sprint 2 local device configuration.
- Documented the provisional asset-tag format and production approval boundary
  for configured device settings.
- Recorded PowerShell 7.6.4 as the local simulation-test runtime.

#### Validation

- PowerShell configuration, input, platform, permission, idempotence, failure,
  entry-point, and no-change behavior are covered by the Sprint 2 harness.
- Real Windows, Windows PowerShell 5.1, code signing, and production setting
  approval remain pending.

#### Security

- Configuration validation finishes before any setting operation.
- API and download-queue capabilities remain disabled.
- Permission failures are reported rather than bypassed, and simulation/WhatIf
  paths do not alter device state.

### Sprint 1 — 2026-07-26

#### Added

- Monorepo foundations for backend, frontend, PowerShell, documentation, and
  repository validation.
- Root project README with truthful current implementation status.
- Sprint tracking, architecture decisions, requirements reconciliation,
  development standards, security/privacy boundaries, toolchain/environment
  baseline, and initial JSON schema direction.
- Safe `.gitignore` coverage for secrets, runtime state, build products, IDE
  files, logs, database data, and temporary artifacts.
- A dependency-free Sprint 1 foundation validation script.

#### Changed

- Reorganized the four active source documents under `docs/`.
- Corrected present-tense claims about missing Version 1 implementation.
- Preserved the original concept README under `docs/reference/` with a clear
  archival status.

#### Validation

- No pre-existing source code or tests were available.
- Sprint 1 structure, local Markdown links, credential patterns, ignored
  artifacts, and staged whitespace were validated successfully.

#### Security

- Added explicit separation of technical evidence, user attestations, technician
  validations, and enterprise approvals/exceptions.
- Added prohibitions on credentials/MFA collection, secret logging, automatic
  destructive authorization, enterprise-control bypass, network switching, and
  direct database exposure.
