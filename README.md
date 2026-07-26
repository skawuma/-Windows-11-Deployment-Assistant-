# Qnity Windows 11 Deployment Assistant

The Qnity Windows 11 Deployment Assistant is a planned production-style
full-stack system for technicians performing controlled Windows 11 migrations.
It will combine a local PowerShell technician assistant, a Spring Boot API backed
by PostgreSQL, and an Angular operations dashboard. A later server-owned lease
service will coordinate large Windows App and Microsoft 365 downloads.

## Current status

- **Version:** 1 — Local PowerShell Technician Assistant
- **Sprint:** 1 — Discovery, governance, and project foundation
- **Implementation:** documentation and repository foundation only
- **Runtime behavior:** none
- **Next sprint:** Sprint 2, only after the user explicitly says
  `Proceed with Sprint 2`

No PowerShell assistant, backend, frontend, database schema, API integration, or
download-slot coordinator exists yet. Earlier source documents that described
Version 1 as already implemented have been corrected or archived; see
[requirements reconciliation](docs/requirements-reconciliation.md).

## Purpose and boundaries

The system is intended to make migration checks consistent, preserve trustworthy
operational evidence, show the next action and its owner, and eventually provide
team-level progress and blocker visibility.

It supplements approved enterprise processes. It does not replace or bypass
Intune, Company Portal, Windows App, Microsoft 365, Cloud PC, identity controls,
change management, or technician judgment.

Four kinds of truth remain separate throughout the design:

1. Technical evidence produced by the PowerShell agent.
2. User attestations.
3. Technician validations.
4. Enterprise approvals or exceptions.

Technical evidence must never be treated as backup attestation, user acceptance,
or authorization to wipe, reset, rebuild, or replace a device.

## Target architecture

```text
Windows 11 deployment PC
  └─ signed PowerShell assistant
       ├─ protected local logs and summaries
       └─ future protected outbox
              │ authenticated HTTPS
              ▼
Spring Boot API ── PostgreSQL
       │
       ├─ Angular dashboard
       └─ future download-slot lease service
```

Devices and Angular will communicate only with Spring Boot. PostgreSQL will never
be exposed directly to devices or browsers. The backend will own authoritative
workflow state and download concurrency.

See [architecture](docs/architecture.md) and
[device-to-dashboard interaction](docs/device-to-dashboard-interaction.md).

## Repository layout

```text
qnity-deployment-assistant/
├── backend/                  Spring Boot work beginning in Sprint 5
├── frontend/                 Angular work beginning in Sprint 9
├── powershell/               local assistant work beginning in Sprint 2
├── docs/                     architecture, governance, and requirements
├── scripts/                  repository-level validation utilities
├── README.md
├── CHANGELOG.md
├── DECISIONS.md
├── SPRINT-STATUS.md
└── .gitignore
```

The repository directory is currently named
`Windows 11 Deployment Assistant` on the development machine. Renaming it is not
required for Sprint 1 and was avoided to prevent breaking the user's workspace.

## Selected toolchain baseline

These are planning pins selected on 2026-07-26. Each implementation sprint must
revalidate compatibility and must not silently upgrade a scaffolded toolchain.

| Component | Selected baseline |
|---|---|
| Java | 21 LTS |
| Spring Boot | 4.1.0 |
| Maven | 3.9.16 |
| Angular / Angular CLI | 22.x, exact patch pinned when Sprint 9 scaffolds |
| Node.js | 24 LTS, exact patch pinned when Sprint 9 scaffolds |
| TypeScript | 6.0.x compatible with Angular 22 |
| PostgreSQL | 18, current minor maintained in deployment configuration |
| PowerShell | Windows PowerShell 5.1 compatibility; PowerShell 7 support where tested |

The rationale, support links, installed development-machine versions, and upgrade
policy are in [toolchain and environments](docs/toolchain-and-environments.md).

## Environments

Four controlled environments are defined:

1. **Development:** non-destructive simulation by default.
2. **Test:** automated tests plus approved Windows 11 devices and test identities.
3. **Pilot:** a supervised, limited deployment wave.
4. **Production:** signed, change-controlled packages and approved enterprise
   identity, retention, monitoring, and rollback procedures.

Production behavior must never be inferred from simulation results. Details are
in [toolchain and environments](docs/toolchain-and-environments.md).

## Local development in Sprint 1

There are no application dependencies to install and no services to start yet.
Run the foundation validation from a POSIX shell:

```bash
./scripts/validate-foundation.sh
```

Current validation checks repository structure, required governance documents,
documented security boundaries, and placeholder scope.

The following operational instructions are intentionally deferred:

- PowerShell execution: Sprint 2
- PostgreSQL and Docker Compose startup: Sprint 5
- Backend startup and API environment variables: Sprint 5
- Sample device event: Sprint 6
- Frontend startup and API URL configuration: Sprint 9
- Dashboard URL: Sprint 9

No `.env` file or application secret is required or committed in Sprint 1.

## Security and privacy

The system must never:

- collect or store passwords or MFA codes;
- log authentication tokens, authorization headers, signatures, recovery keys,
  or other authentication material;
- bypass enterprise management, entitlement, network, or identity controls;
- authorize a device wipe, reset, rebuild, or replacement automatically;
- treat application detection as user acceptance;
- treat technical evidence as user backup attestation;
- switch networks automatically;
- expose PostgreSQL directly to devices or Angular;
- store secrets in source control; or
- claim an enterprise integration works before it has been tested.

See [security and privacy](docs/security-and-privacy.md).

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation guide](docs/implementation-guide.md)
- [Device-to-dashboard interaction](docs/device-to-dashboard-interaction.md)
- [Field workflow reference](docs/field-workflow-reference.md)
- [Requirements reconciliation](docs/requirements-reconciliation.md)
- [Development standards](docs/development-standards.md)
- [JSON schema direction](docs/contracts/json-schema-direction.md)
- [Toolchain and environments](docs/toolchain-and-environments.md)
- [Security and privacy](docs/security-and-privacy.md)
- [Sprint status](SPRINT-STATUS.md)
- [Architecture decisions](DECISIONS.md)
- [Changelog](CHANGELOG.md)

## Known limitations and unresolved requirements

- No application behavior or application tests exist yet.
- Windows-specific validation cannot run because no Sprint 2 code exists and the
  current development host does not have PowerShell installed.
- Package identities, approved power-setting values, site codes, evidence rules,
  authentication details, retention, signatures, exception authorities, and
  multiple checklist meanings still require enterprise confirmation.
- No GitHub repository remote is configured. The exact repository URL under the
  `skawuma` account must be supplied and verified before any push.

Do not begin Sprint 2 until it is explicitly authorized.
