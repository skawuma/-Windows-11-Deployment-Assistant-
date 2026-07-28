# Security and privacy boundaries

These boundaries apply to every version and sprint.

## Prohibited behavior

The system must never collect or store passwords.

It must also never:

- collect MFA codes;
- collect or log authentication tokens, authorization headers, client secrets,
  signing material, recovery keys, or signature images without explicit approved
  design;
- bypass Intune, Company Portal, Windows App, Microsoft 365 entitlements, Cloud
  PC controls, enterprise identity, network policy, or change management;
- automatically authorize a device wipe, reset, rebuild, or replacement;
- treat Technical evidence as User attestations;
- treat Technical evidence as Technician validations;
- manufacture Enterprise approvals or exceptions;
- infer user acceptance from application detection;
- switch networks automatically;
- expose PostgreSQL directly to devices or Angular;
- store secrets in source control; or
- claim an enterprise integration works before it has been tested.

## Separated evidence and authority

| Concept | Example | Permitted source | Must not imply |
|---|---|---|---|
| Technical evidence | Windows App package detected | PowerShell agent | App works for the user; user accepted it |
| User attestations | User says Chrome bookmarks were backed up | User through an approved workflow | Independent technical verification; wipe approval |
| Technician validations | Technician confirms user training occurred | Authenticated technician | Enterprise exception approval |
| Enterprise approvals | Authorized lead approves a documented exception | Approved policy and role | A reusable rule for unrelated migrations |

Every stored record and event must identify its source category, actor or agent
identity as appropriate, and timestamp. Corrections must preserve audit history.

## Data minimization

Collect only fields needed for the active, approved workflow. Potential personal
or operational data includes email addresses, asset tags, computer names, serial
numbers, site codes, technician identities, notes, attestations, and acceptance
records.

Before these fields enter production, Qnity must approve:

- purpose and lawful/organizational basis;
- access roles;
- retention and deletion periods;
- encryption and backup handling;
- support and audit export rules;
- correction procedures; and
- free-text redaction and review rules.

Avoid raw command output and unnecessary free text. Never put personal data into
correlation IDs, event IDs, filenames, metrics labels, or log templates when a
non-identifying identifier is sufficient.

## Secrets and authentication

- No shared API key or client secret may be embedded in PowerShell or Angular.
- Device authentication and human-user authentication remain separate.
- Future device identity should use a unique enterprise-issued certificate or
  another enterprise-approved device-bound flow.
- Future Angular authentication should use approved Entra ID/OAuth/OIDC settings;
  development authentication must be clearly non-production.
- Secrets enter processes through approved runtime mechanisms and are never
  committed.
- Logs include correlation IDs but exclude request/response bodies and
  authentication material by default.

## Device-changing operations

- Sprint 2 implements only configured time-zone and lid/button settings; its
  exact values still require enterprise approval before production use.
- Settings come from strict versioned configuration.
- Input and configuration validation must finish before any change.
- `-WhatIf` must cause no change.
- Permission failures are reported, not bypassed.
- Operations must be idempotent.
- Simulation changes in-memory fixture state only.
- The assistant guides technicians to approved install mechanisms; it does not
  sideload software or bypass enterprise deployment controls.

Imaging, wipe, reset, rebuild, and replacement actions remain outside automatic
authorization. Applicable user attestations and authorized technician/enterprise
approval must remain explicit, separate gates.

## Service boundaries

- Devices send structured events to Spring Boot over authenticated HTTPS.
- Angular calls only Spring Boot over authenticated HTTPS.
- Spring Boot is the only application tier that accesses PostgreSQL.
- Immutable event history remains separate from rebuildable current projections.
- The backend enforces validation, workflow transitions, idempotency,
  authorization, and download-slot capacity.
- Local operation continues safely when a future API is unavailable.

## Incident-safe logging

Logs may include:

- UTC timestamp;
- correlation ID;
- safe class/function and operation names;
- normalized result code;
- duration; and
- non-sensitive identifiers only where operationally required and approved.

Logs must not include full request or response serialization, passwords, MFA
codes, tokens, authorization headers, signatures, secrets, recovery keys, or SQL
errors. Unexpected failures return a safe error contract and preserve detailed
diagnostics only in access-controlled server logging.
