# Architecture decisions

## D-001 — Preserve the existing workspace and establish monorepo areas

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Keep the user's current workspace path and establish
  `backend/`, `frontend/`, `powershell/`, `docs/`, and `scripts/` inside it.
- **Rationale:** Renaming or nesting the active workspace could break local
  references. The logical project and future repository name remains
  `qnity-deployment-assistant`.
- **Consequence:** The physical checkout directory may differ from the logical
  repository name without changing packages, artifact names, or documentation.

## D-002 — Treat prior implementation claims as requirements, not evidence

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Archive the original Version 1 README and correct active
  documentation to describe absent scripts and behavior as planned.
- **Rationale:** Sprint 1 found only Markdown files. Claiming that scripts,
  tests, API calls, or device behavior exist would be inaccurate.
- **Consequence:** Later sprints must earn implemented status through code and
  tests. The archived source remains available for traceability.

## D-003 — Select a current, Java 21-compatible planning toolchain

- **Date:** 2026-07-26
- **Status:** Accepted for planning; revalidation required at scaffold time
- **Decision:** Plan for Java 21, Spring Boot 4.1.0, Maven 3.9.16, Angular 22,
  TypeScript 6.0.x, Node.js 24.18.0 LTS, and PostgreSQL 18.4.
- **Rationale:** These versions satisfy the project constraints and were current,
  supported combinations in official documentation on the decision date.
- **Consequence:** Sprints 5 and 9 pin exact build/runtime versions. No later
  sprint silently upgrades a scaffolded toolchain.

## D-004 — Use four explicitly separated environments

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Define development, test, pilot, and production as separate
  controlled environments.
- **Rationale:** Simulation, approved-device validation, limited real-world
  rollout, and change-controlled production have different risks and evidence.
- **Consequence:** Success in one environment does not prove another. Production
  integrations remain disabled until tested and approved.

## D-005 — Enforce the three-tier backend dependency direction

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Use `Controller -> Service interface -> Service implementation ->
  Repository`, with DTOs and mappers at the HTTP/persistence boundaries.
- **Rationale:** The required separation keeps HTTP, business, and persistence
  responsibilities testable and prevents controllers from coupling to JPA.
- **Consequence:** Controllers cannot call repositories or return entities.
  Constructor injection and architecture tests are required.

## D-006 — Use versioned JSON Schema 2020-12 contracts

- **Date:** 2026-07-26
- **Status:** Accepted as direction; contracts not frozen
- **Decision:** Use JSON Schema Draft 2020-12, required semantic
  `schemaVersion`, camelCase fields, controlled enum values, UTC timestamps, and
  separate record types for technical and human/enterprise assertions.
- **Rationale:** Durable versioned contracts are necessary for offline
  PowerShell producers, API consumers, immutable history, and safe evolution.
- **Consequence:** Sprint 4 freezes the Version 1 summary; Sprint 6 finalizes
  device-event DTOs. Sprint 1 examples are non-operational.

## D-007 — Keep PostgreSQL behind Spring Boot

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Devices and Angular communicate only with Spring Boot; only the
  backend accesses PostgreSQL.
- **Rationale:** Direct client database access would bypass validation,
  authorization, idempotency, auditing, and workflow-state ownership.
- **Consequence:** No database port, credential, driver, or connection string is
  exposed to PowerShell or frontend code.

## D-008 — Do not invent a GitHub remote or repository

- **Date:** 2026-07-26
- **Status:** Accepted
- **Decision:** Initialize local Git and create the Sprint 1 commit, but do not
  create or infer a remote. Push only after the exact repository URL is supplied,
  verified as owned by `skawuma`, and GitHub authentication succeeds.
- **Rationale:** The workspace had no Git metadata or exact repository URL.
- **Consequence:** Sprint 1 can reach `READY_FOR_REVIEW` locally but cannot be
  `COMPLETE` until the milestone commit is pushed to the verified remote.

## D-009 — Use a provisional configurable asset-tag rule

- **Date:** 2026-07-28
- **Status:** Accepted for development; enterprise confirmation required
- **Decision:** Normalize asset tags to uppercase and, for the Sprint 2
  baseline, accept 3–32 alphanumeric characters with internal hyphens. Keep the
  pattern and length limits in versioned configuration.
- **Rationale:** Sprint 2 needs deterministic input validation, but the
  enterprise asset-tag format remains unresolved.
- **Consequence:** The baseline is suitable for simulation and approved test
  work only. A confirmed enterprise format requires coordinated configuration,
  schema, implementation, test, and documentation updates before production.

## D-010 — Make device configuration observable and repeatable

- **Date:** 2026-07-28
- **Status:** Accepted
- **Decision:** Validate all inputs and configuration first, read each current
  setting before writing, use PowerShell `ShouldProcess`, verify after a real
  write, and normalize every outcome to `Pass`, `Fail`, `Skipped`, or `Error`.
- **Rationale:** A technician must be able to rerun the assistant safely and
  distinguish compliance, permission, platform, and execution outcomes.
- **Consequence:** Compliant settings are not rewritten, `-WhatIf` performs no
  writes, non-Windows systems skip safely, and setting failures do not authorize
  a bypass.

## D-011 — Simulate device state behind the same configuration workflow

- **Date:** 2026-07-28
- **Status:** Accepted
- **Decision:** Use checked-in JSON device-state fixtures for deterministic
  cross-platform tests while preserving the same validation and result-shaping
  path used by a real run.
- **Rationale:** Sprint 2 is being developed on macOS and cannot claim real
  Windows validation. Simulation allows safe coverage without manufacturing
  enterprise integration evidence.
- **Consequence:** Simulation results prove local logic only. Windows PowerShell
  5.1, supported Windows commands, Administrator behavior, signing, and approved
  device settings still require test-environment validation.
