# Requirements reconciliation

Sprint 1 reviewed all five Markdown files initially present in the workspace plus
the twelve-sprint build prompt. Sprint 2 implemented the first bounded
PowerShell increment and updated this reconciliation without changing later
sprint scope.

## Initial workspace

The workspace contained only:

- `README (1).md`
- `architecture.md`
- `implementation-guide.md`
- `device-to-dashboard-interaction.md`
- `field-workflow-reference.md`

It did not contain Git metadata, a remote, PowerShell source, configuration,
samples, tests, backend or frontend source, a database definition,
`SPRINT-STATUS.md`, `CHANGELOG.md`, or `DECISIONS.md`.

## Contradictions resolved in Sprint 1

### Implemented Version 1 versus documentation-only workspace

The original README and two guides described Version 1 scripts, configuration,
module behavior, samples, and tests as present or operational. Those files did not
exist.

Resolution:

- The original README is preserved at
  [`reference/original-version-1-readme.md`](reference/original-version-1-readme.md)
  with an archival status banner.
- The root README now reports the actual implementation status.
- The implementation and device-interaction guides distinguish the Sprint 2
  implementation from behavior still planned for Sprints 3 and 4.
- No missing implementation was recreated in Sprint 1 because that would cross
  into Sprints 2 and 3.

### Three environments versus four required environments

The original implementation guide named development simulation, approved Windows
test, and pilot. The sprint prompt also requires production to be documented.

Resolution: [`toolchain-and-environments.md`](toolchain-and-environments.md)
defines development, test, pilot, and production while preserving the original
safety distinctions.

### Workspace name versus requested monorepo name

The desired logical repository name is `qnity-deployment-assistant`, while the
user's current directory is `Windows 11 Deployment Assistant`.

Resolution: establish the requested folders inside the existing workspace without
renaming the user's directory. The logical project name remains
`qnity-deployment-assistant`.

## Requirements implemented in Sprint 2

- Versioned local configuration and strict configuration validation.
- Asset-tag and email normalization/validation before device work.
- Time-zone and lid/button settings with platform, permission, idempotence,
  `-WhatIf`, and post-change verification safeguards.
- Deterministic simulation fixtures and a dependency-free PowerShell test
  harness.

These settings remain development/test behavior until endpoint and
change-management owners approve the exact production values.

## Requirements retained without implementation

- Application detection and next-action behavior are planned for Sprint 3.
- The Version 1 JSON contract freezes in Sprint 4.
- Spring Boot and PostgreSQL begin in Sprint 5.
- Device-event ingestion begins in Sprint 6.
- API upload/outbox behavior begins in Sprint 7.
- Angular begins in Sprint 9.
- Download-slot leases begin in Sprint 11.

These documents describe target behavior but do not prove that it exists.

## Unresolved enterprise requirements

1. Confirm that `Replace`, `Rebuild with USB`, and `Windows Reset` are the exact
   migration types.
2. Confirm which backup categories support `Not applicable`.
3. Define which user responses block work and who may approve an exception.
4. Define acceptable evidence for each backup category.
5. Decide when Cloud PC access must be checked relative to destructive work.
6. Define required Cloud PC applications and the remediation path.
7. Clarify “OneDrive configured on Cloud PC to only show Qnity.”
8. Define the two Teams account contexts and supported sign-in policy.
9. Define the Ricoh driver, queue, mapping, and pass evidence.
10. Approve a signature or authenticated acceptance mechanism, retention, and
    correction workflow.
11. Confirm time-zone and power-setting values with endpoint/change-management
    owners.
12. Confirm Company Portal, Windows App, and Microsoft 365 detection identities
    across approved images and account contexts.
13. Define asset-tag, device-ID, serial-number, and site-code formats.
14. Define output storage ACLs, retention, deletion, and operational ownership.
15. Select device and human authentication designs for Version 2.
16. Confirm exact enterprise URLs, tenant registrations, roles, and gateway/TLS
    requirements before any integration is claimed.

## Resolved operational requirements

- The exact GitHub repository was supplied and verified as
  `https://github.com/skawuma/-Windows-11-Deployment-Assistant-.git`; the active
  branch is connected to that remote.

## Safe interpretation rules

Until requirements are approved:

- no unresolved field becomes an automatic workflow rule;
- no `No`, missing, or detected state authorizes destructive work;
- no network, identity, Company Portal, Intune, or Cloud PC behavior is simulated
  as a production integration;
- ambiguous outcomes remain explicit blockers or documentation items; and
- the active sprint remains the only implementation scope.
