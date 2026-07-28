# Toolchain and environments

This document records the Sprint 1 planning baseline. Versions were selected on
2026-07-26 from official project support and compatibility documentation. They
are not implementation claims: the backend and frontend have not been scaffolded.

## Selected versions

| Component | Selected version | Rationale and source |
|---|---|---|
| Java | 21 LTS | Required by the project. OpenJDK identifies JDK 21 as an LTS release from most vendors: <https://openjdk.org/projects/jdk/21/>. The production JDK distribution and support vendor remain an enterprise decision. |
| Spring Boot | 4.1.0 | Current stable line on 2026-07-26. Its system requirements support Java 17 through 26 and Maven 3.6.3+: <https://docs.spring.io/spring-boot/system-requirements.html>. |
| Maven | 3.9.16 | Current recommended production release; Maven 4 remains preview: <https://maven.apache.org/download.cgi>. |
| Angular and Angular CLI | 22.0.x | Angular 22 is the active major release. Core and CLI majors must match. Pin the current 22.x patch in `package-lock.json` when Sprint 9 scaffolds: <https://angular.dev/reference/releases>. |
| TypeScript | 6.0.x | Angular 22 requires TypeScript `>=6.0.0 <6.1.0`: <https://angular.dev/reference/versions>. |
| Node.js | 24.18.0 LTS | Production applications should use an LTS line. Node 24 is LTS and is compatible with Angular 22's `^24.15.0` range: <https://nodejs.org/en/about/previous-releases>. |
| npm | Version bundled with Node.js 24.18.0 | Avoid a separately floating global npm requirement. The lockfile created in Sprint 9 will be authoritative. |
| PostgreSQL | 18.4 | Current supported major and current minor on 2026-07-26. PostgreSQL recommends the current minor for a selected major: <https://www.postgresql.org/support/versioning/>. |
| PowerShell | Windows PowerShell 5.1 compatibility; PowerShell 7 supported where tested | Version 1 must run on managed Windows 11 devices. Sprint 2 must test the exact editions available in the approved Qnity environment. |

## Pinning and upgrade policy

- Sprint 5 must pin Spring Boot and Maven wrapper versions in the backend build.
- Sprint 5 must pin the PostgreSQL container image to an approved immutable
  version or digest; it must not use `latest`.
- Sprint 9 must pin Angular, Angular CLI, TypeScript, Node, and resolved npm
  dependencies through checked-in version and lock files.
- Patch updates are deliberate changes with tests and changelog entries.
- Major or minor upgrades require an architecture decision when they affect
  contracts, runtime support, or deployment.
- A later sprint must not silently upgrade a toolchain chosen by an earlier
  sprint.
- Compatibility and security support must be rechecked at Sprint 5 and Sprint 9,
  because these components are time-sensitive.

## Development-machine inventory

The development host reported:

| Tool | Installed version and observation date | Sprint baseline satisfied? |
|---|---|---|
| PowerShell | 7.6.4, installed 2026-07-28 | Yes for cross-platform Sprint 2 simulation; Windows PowerShell 5.1 remains untested |
| Java | OpenJDK 23.0.2 | No; Java 21 must be selected for backend work |
| Maven | 3.9.9 | No; wrapper will pin 3.9.16 in Sprint 5 |
| Node.js | 22.15.0 | No; below Angular 22's supported Node 22 minimum |
| npm | 10.9.2 | Not evaluated independently |
| PostgreSQL client | 14.19 | No; local client is older than selected server |
| Docker | 28.1.1 | Available; no Sprint 1 container is defined |
| GitHub CLI | 2.53.0 | Installed and authenticated for the verified `skawuma` remote |

Remaining mismatches must be resolved or isolated through project
wrappers/containers before their respective implementation sprints.

## Controlled environments

### Development

- Runs on developer workstations.
- Uses noninteractive simulations by default.
- Performs no Windows device changes unless deliberately executed on an approved
  test device.
- Uses local, non-production configuration and synthetic identifiers.
- Stores no enterprise credentials or production personal data.

### Test

- Runs automated PowerShell, backend, frontend, repository, and integration tests.
- Uses approved Windows 11 test devices for platform-specific behavior.
- Uses test identities, representative hardware, and non-production PostgreSQL.
- Uses Testcontainers when Docker is available, with a documented fallback when
  it is not.
- Records unsupported platform-specific tests explicitly.

### Pilot

- Uses a small, approved migration wave under technician supervision.
- Uses signed packages, controlled assignments, approved authentication, and
  restricted operational storage.
- Compares detection and workflow results to authoritative enterprise evidence.
- Has a defined stop, escalation, and rollback procedure before enrollment.

### Production

- Requires change-management, security, privacy, endpoint, and operational
  approval.
- Uses signed PowerShell artifacts distributed by an approved mechanism such as
  Intune.
- Uses production enterprise identity, TLS, authorization, monitoring, backup,
  retention, incident response, and rollback controls.
- Does not reuse development secrets or seed data.
- Enables only integrations proven in test and pilot.

## Configuration separation

Sprint 2 adds a versioned PowerShell configuration under `powershell/config/`.
It contains no secrets, keeps future API and queue extensions disabled, and
requires production approval for the documented device-setting baseline.

Future implementation must:

- read secrets from approved runtime secret stores or environment injection;
- commit only safe examples such as `.env.example`;
- keep local, test, pilot, and production values separate;
- default optional API and queue integration to disabled until their sprints; and
- fail safely when required configuration is absent or malformed.
