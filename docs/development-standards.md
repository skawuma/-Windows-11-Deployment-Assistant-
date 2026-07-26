# Development standards

## Repository and file naming

- Top-level application areas use lowercase names: `backend`, `frontend`,
  `powershell`, `docs`, and `scripts`.
- Documentation filenames use lowercase kebab-case except for conventional
  governance files such as `README.md`, `CHANGELOG.md`, `DECISIONS.md`, and
  `SPRINT-STATUS.md`.
- Branches for the controlled sprint sequence use
  `codex/qnity-incremental-development` unless a verified repository convention
  is later approved.
- Commits use the sprint-specific messages defined in the project roadmap.

## Java and Spring Boot

- Base package: `com.qnity.deploymentassistant`.
- Packages are lowercase and singular as specified:

```text
com.qnity.deploymentassistant
├── controller
├── service
│   └── impl
├── repo
├── dto
│   ├── request
│   └── response
├── entity
├── mapper
├── exception
├── aspect
├── config
├── security
├── validation
└── util
```

- Java types use PascalCase; methods and variables use camelCase; constants and
  enum values use `UPPER_SNAKE_CASE`.
- Use constructor injection. Field injection is prohibited.
- Use UTC for persisted timestamps and ISO 8601 UTC in API contracts.
- Use enums for controlled values.
- JPA entities never cross the controller boundary.
- DTOs define API contracts; mappers convert DTOs and entities.
- Database constraints reinforce application validation.
- Avoid circular dependencies.

Every human-maintained Java source and test file must place this Javadoc
immediately above its primary class, interface, enum, or record:

```java
/**
 * @author samuelkawuma
 * @package com.qnity.deploymentassistant.<actual-subpackage>
 * @project qnity-deployment-assistant
 * @date <actual creation date in yyyy-MM-dd>
 */
```

The actual package and creation date must be correct. Generated sources under
`target/` do not receive this header.

## Backend dependency rules

The required flow is:

```text
Controller -> Service interface -> Service implementation -> Repository
```

- Controllers handle HTTP translation, validation entry, and response status only.
- Controllers never call repositories directly.
- Service interfaces define business operations.
- Service implementations contain transactions and business rules.
- Repositories contain persistence access, not workflow decisions.
- Cross-cutting correlation, logging, exception translation, security, and
  validation belong in their dedicated packages.
- No lower tier depends on a controller or API DTO unless an explicit architecture
  decision approves a narrowly defined exception.
- Architecture tests will enforce these rules in Sprint 10.

## REST, JSON, and database naming

- Resource paths use lowercase plural nouns and kebab-case where needed, for
  example `/api/v1/device-events`.
- JSON properties use camelCase.
- Controlled JSON values use `UPPER_SNAKE_CASE`.
- PostgreSQL tables, columns, constraints, and indexes use lowercase snake_case.
- Primary identifiers use UUIDs unless an approved enterprise identifier requires
  a constrained string.
- Timestamps use names ending in `At`, such as `occurredAt`, and represent UTC.
- API errors use stable machine-readable codes plus safe technician-facing text.

## Angular

- TypeScript strict mode is mandatory.
- TypeScript types and Angular classes use PascalCase.
- Variables and methods use camelCase; filenames and route segments use
  kebab-case.
- Models and API services are typed.
- Components remain presentation-focused.
- Angular communicates only with Spring Boot.
- The backend calculates authoritative workflow state and authorization.
- Accessible semantic HTML and keyboard behavior are required.
- Multi-state requirements are not reduced to Boolean checkboxes.

## PowerShell

- Public functions use approved verb-noun names such as
  `Get-QnityDeviceEvidence`.
- Script parameters and function names use PascalCase; local variables use
  descriptive camelCase.
- Functions return structured objects rather than parsing human-readable output.
- Check results use only `Pass`, `Fail`, `Skipped`, or `Error` for Version 1.
- `SupportsShouldProcess` and `-WhatIf` protect device-changing operations.
- Simulation paths remain separate from Windows adapters.
- Repeated execution must be idempotent.
- Logs never contain credentials or authentication material.

## Testing and documentation

- Implement only tests required for the active sprint plus necessary regression
  tests.
- Name tests after observable behavior.
- Record skipped or unsupported Windows-specific checks explicitly.
- Do not describe planned functionality as implemented.
- Update README, changelog, sprint status, and decisions in the sprint where
  behavior or architecture changes.
