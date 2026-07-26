# Changelog

All notable project changes are recorded here. Dates use `yyyy-MM-dd`.

## [Unreleased]

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
