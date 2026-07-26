# Deployment Assistant architecture

> **Implementation status:** This is the target architecture. At Sprint 1 the
> repository contains governance and architecture documentation only; no
> PowerShell agent, Spring Boot service, Angular application, PostgreSQL schema,
> API integration, or download-slot service is implemented.

Version 1 deliberately keeps the device workflow local while defining stable seams for later increments. The target architecture now also reflects the supplied Qnity/illuminet migration, user-signoff, and technician checklist transcribed in [`field-workflow-reference.md`](field-workflow-reference.md).

```text
User attestation                 Technician actions
       |                                |
       +---------------+----------------+
                       v
             Migration workflow record
                       |
       +---------------+----------------+
       |                                |
       v                                v
PowerShell device assistant      Manual validation/training
       |
       +-- configuration policy (JSON)
       +-- Windows configuration adapter
       +-- application detection adapter
       +-- next-action rules
       +-- structured summary (JSON)
       +-- technician summary (text)
       +-- append-only session log
                       |
                       v
              Future Spring Boot API
                       |
          +------------+-------------+
          |                          |
          v                          v
 Angular operations dashboard   Download-slot coordinator
```

## Workflow model

The field checklist shows that a deployment is not only an application-installation job. It is a migration record that crosses five controlled gates:

```text
INTAKE
  |
  v
BACKUP_ATTESTATION
  |
  +-- unresolved applicable item --> BLOCKED_BEFORE_MIGRATION
  |
  v
MIGRATION_AUTHORIZED
  |
  v
LOCAL_DEVICE_READINESS
  |
  v
CLOUD_PC_READINESS
  |
  +-- required apps missing --> EXCEPTION_REQUIRES_REMEDIATION
  |
  v
USER_ACCEPTANCE
  |
  v
COMPLETE
```

Every gate must also support `WAITING_FOR_USER`, `WAITING_FOR_NETWORK`, `FAILED`, and `ESCALATED`. State changes should be timestamped events rather than destructive updates so the eventual API preserves an audit trail.

## Automation responsibility

| Requirement | Planned handling | Authority |
|---|---|---|
| Name and serial numbers | Technician entry plus device-query comparison | Technician |
| Migration type | Controlled selection: replacement, USB rebuild, or Windows Reset | Technician/lead |
| Backup items | Individual user attestations with `Yes`, `No`, or `Not applicable` where permitted | User |
| Safe-to-migrate decision | Policy gate using attestations and technician approval | Authorized technician |
| Time zone and power settings | Automated and verified | Version 1 assistant |
| Company Portal, Windows App, Microsoft 365 | Automated detection; enterprise-approved install guidance | Version 1 assistant |
| OneDrive, Outlook, Cloud PC apps, Ricoh, Teams | Detection where reliable, otherwise technician validation | Later increment |
| Qnity/DuPont credentials and MFA | Never captured or automated | User |
| User training items | Technician attestation | Technician |
| User acceptance/signature | Approved signoff mechanism; not inferred from technical checks | User |

The system may help verify local evidence, but it must never manufacture user attestation, technician approval, or acceptance.

## Stable contracts

- `schemaVersion` protects configuration and summary consumers from silent breaking changes.
- `session.id` is the future API idempotency/correlation key.
- `migration.id` should become the durable business identifier; one migration can reference an original and a replacement device.
- `device.assetTag` remains a device identifier, subject to server-side validation.
- `results[]` provides normalized `Pass`, `Fail`, `Skipped`, and `Error` records.
- `nextAction.code` is machine-readable; `description` is technician-facing.
- `extensions.api` and `extensions.downloadQueue` reserve status in the Version 1 payload without making network calls.

## Planned domain records

Version 2 should introduce these records without forcing them into the Version 1 application-check result:

- `Migration`: ID, user, site, migration type, lifecycle state, created/completed timestamps.
- `DeviceAssignment`: original serial number, optional replacement serial number, asset tags, and comparison status.
- `BackupAttestation`: one record per backup category, response, applicability, user-confirmed timestamp, and unresolved reason.
- `ReadinessCheck`: local or Cloud PC scope, check code, status, evidence, technician, and timestamp.
- `UserInstruction`: Cloud PC launch, Cloud-PC-only services, and Company Portal guidance acknowledgments.
- `UserAcceptance`: Cloud PC outcome, signature/approved equivalent, and date.
- `TechnicianAssignment`: every technician who worked on the migration.
- `MigrationNote`: timestamped notes and exceptions; append-only after completion.

Recommended response states are `NOT_CHECKED`, `PASS`, `FAIL`, `NOT_APPLICABLE`, `BLOCKED`, and `EXCEPTION`. A Boolean checkbox cannot accurately represent the paper form's multi-option responses.

## Identity and device contexts

The workflow operates across separate contexts and must label evidence accordingly:

- **Qnity physical laptop:** Qnity profile, Company Portal, Windows App, Microsoft 365, OneDrive, Outlook/Qnity mailbox.
- **DuPont Cloud PC:** user-controlled DuPont authentication and MFA, Cloud PC application availability, Company Portal, OneDrive behavior, Ricoh driver/printer, and Teams account contexts.

Detection from the physical laptop must not be reported as evidence that the equivalent Cloud PC check passed. Cloud PC checks should use an approved agent, management API, or explicit technician/user attestation—not remote credential capture.

## Version 2 connection point

Add a transport function such as `Send-QnityDeploymentSummary`. It should:

1. Read API settings from configuration.
2. Obtain a machine or technician token using the enterprise-approved identity flow.
3. POST the JSON summary with `session.id` as an idempotency key.
4. Retry transient failures with bounded exponential backoff.
5. Never log tokens, passwords, MFA codes, or sensitive response bodies.
6. Retain the local summary until the API acknowledges it.

The Spring Boot API should own workflow-state validation. For example, it must reject `MIGRATION_AUTHORIZED` while an applicable backup attestation is `No`, missing, or unresolved. The Angular dashboard should present separate queues for pre-migration blockers, local readiness, user authentication, Cloud PC exceptions, network/download waits, and final signoff.

## Version 3 queue connection point

Before an approved large installation, add `Request-QnityDownloadSlot` and `Release-QnityDownloadSlot`. A lease should contain:

- lease ID
- device/session ID
- package ID
- expiration time
- renewal interval

The server, not the technician script, must enforce concurrency. Leases must expire automatically so an interrupted device cannot hold a slot indefinitely.

Queue policy should distinguish packages by scope and importance. Windows App should normally take priority because it unlocks Cloud PC access; large Microsoft 365 downloads should use a separate, lower-concurrency pool. Network switching remains an approved technician procedure rather than an automatic queue action.

## Audit and privacy

The future service will hold personal and operational records: user identity, device serial numbers, backup attestations, signoff, technician identities, and notes. It therefore needs:

- enterprise SSO and role-based access
- encryption in transit and at rest
- field-level validation and minimal free text
- append-only lifecycle events
- correction history for attestations and signoff
- approved retention and deletion rules
- export controls for support/audit use
- redaction rules that prohibit passwords, MFA codes, recovery keys, tokens, and unnecessary personal data

## Enterprise boundaries

The assistant reports and guides; it does not bypass Intune, Company Portal, application entitlements, network policy, or administrative controls. User credentials, DuPont/Qnity passwords, MFA, Cloud PC authentication, and final user acceptance remain outside the automated boundary.

Backup and wipe authorization require special separation: software may display missing attestations and block progression, but only the user and authorized technician can provide the required confirmation. No future “backup verifier” should independently declare a device safe to replace, rebuild, reset, or wipe.
