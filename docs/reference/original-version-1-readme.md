> **Archived source document:** This is the original Version 1 concept README found
> during Sprint 1. It is preserved for requirements traceability. Its statements
> about implemented scripts, configuration, samples, and tests do not describe the
> current workspace; see the repository root `README.md` for authoritative status.

# Qnity Windows 11 Deployment Assistant — Version 1

A production-style PowerShell technician assistant for the documented Marlborough post-image workflow. It applies approved local settings, detects the three required applications, identifies the next action, logs the session, and creates machine-readable and human-readable summaries.

This is an operational prototype. Qnity's endpoint, security, and change-management owners must review the configuration and application detection identifiers before production rollout.

## Workflow reference

Version 1 is based on two field-workflow sources:

1. The documented post-image sequence: build the Qnity profile, configure the local device, wait for Company Portal, install Windows App and Microsoft 365, then hand control to the user for DuPont Cloud PC authentication and Cloud PC setup.
2. The Qnity/illuminet migration and user-signoff checklist supplied with this project and transcribed in [`docs/field-workflow-reference.md`](../field-workflow-reference.md).

The field checklist adds important lifecycle information beyond application installation:

- Device identity: user name, original serial number, optional replacement serial number, and migration type.
- Migration types: replacement, rebuild with USB, or Windows Reset.
- Pre-migration user attestation for OneDrive data, Chrome bookmarks, OneNote notebooks, Edge favorites, PST files, and miscellaneous data outside OneDrive.
- Confirmation that Cloud PC was set up and accessed, including a distinct “apps missing” outcome.
- Post-migration technician validation for local and Cloud PC services.
- User signature/date, all technicians who worked on the device, and free-form notes.

The photograph is a field reference, not a machine-readable specification. Ambiguous wording and every security-sensitive step must be confirmed with Qnity before it becomes an automated rule.

## What it does

### Implemented in Version 1

- Prompts for or accepts an asset tag and user email.
- Validates input without collecting a password or MFA code.
- Sets the Windows time zone to `Eastern Standard Time`.
- Applies the documented settings:
  - lid close: do nothing on AC and battery
  - power button: shut down on AC and battery
  - sleep button: do nothing on AC and battery
- Detects Company Portal, Windows App, and Microsoft 365 using configurable Appx and uninstall-registry rules.
- Chooses one next action in workflow priority order.
- Writes a timestamped log, JSON summary, and text summary.
- Includes disabled API and download-queue extension settings for Versions 2 and 3.

### Documented for a later increment

The field checklist identifies these future workflow records and validations:

- Original and replacement serial numbers and the selected migration type.
- User-entered backup attestations and explicit blockers before a destructive migration.
- OneDrive working on the Qnity laptop.
- Outlook configured with the Qnity mailbox.
- Qnity-only OneDrive view/configuration inside Cloud PC, subject to tenant-owner clarification.
- User training for launching Cloud PC, Cloud-PC-only applications, and Company Portal.
- Ricoh driver verification.
- Teams configured for both required account contexts.
- Cloud PC reached successfully or reached with missing applications.
- User signoff, technician names, and notes.

These are requirements for later design, not claims about current Version 1 behavior.

### Safety boundary

The assistant does **not** wipe or reset devices, declare backups complete, capture a handwritten/electronic signature, enter or store Qnity/DuPont credentials, perform MFA, bypass Company Portal or Intune, automatically switch networks, or install/select a printer.

In particular, a “Yes” backup response must remain a user attestation reviewed by an authorized technician. The software must not infer that a device is safe to wipe merely because OneDrive is running.

## Project layout

```text
qnity-deployment-assistant/
├── Start-QnityDeploymentAssistant.ps1  entry point
├── config/
│   └── assistant.config.json           policy, detection, actions, future endpoints
├── src/
│   ├── Qnity.DeploymentAssistant.psd1  module manifest
│   └── Qnity.DeploymentAssistant.psm1  implementation
├── samples/
│   ├── simulation.all-ready.json
│   ├── simulation.portal-pending.json
│   └── sample-summary.txt
├── tests/
│   └── Invoke-Tests.ps1                dependency-free test runner
└── docs/
    ├── architecture.md                 target workflow and Version 2/3 contract
    ├── field-workflow-reference.md     structured transcription of field checklist
    └── implementation-guide.md         step-by-step build and system diagrams
```

## Start here

If you are learning or handing the project to another Codex agent, begin with [`docs/implementation-guide.md`](../implementation-guide.md). It explains the problem, project phases, role boundaries, architecture, use cases, workflow states, and acceptance criteria before describing individual files.

## Requirements

- Windows 11
- Windows PowerShell 5.1 or PowerShell 7+
- An elevated PowerShell session to change time-zone and power settings
- An execution policy and script-signing process approved by the organization

Application detection can be tested in simulation mode on any system with PowerShell. Production configuration changes only run on Windows and require Administrator rights.

## Run it

From an elevated PowerShell window:

```powershell
Set-Location C:\ApprovedTools\qnity-deployment-assistant
.\Start-QnityDeploymentAssistant.ps1
```

For a known device:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'QNY-10427' `
  -UserEmail 'user@example.com'
```

For automated validation without changing device configuration:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'TEST-1001' `
  -UserEmail 'user@example.com' `
  -SimulationDataPath '.\samples\simulation.all-ready.json' `
  -SkipConfiguration `
  -NonInteractive
```

Preview the configuration work without applying it:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'QNY-10427' `
  -UserEmail 'user@example.com' `
  -WhatIf
```

## Workflow and next-action order

### Current Version 1 sequence

The assistant currently evaluates blockers in this order:

1. Correct failed time-zone or power configuration.
2. Wait for Company Portal provisioning.
3. Request Windows App through Company Portal.
4. Request Microsoft 365 through Company Portal.
5. Hand control to the user for DuPont sign-in, MFA, and Cloud PC launch.

Company Portal not being immediately visible is treated as a provisioning wait—not permission to bypass enterprise deployment controls. Re-run the assistant after the approved wait interval.

### Target end-to-end sequence

The checklist refines the future workflow into five gates:

1. **Intake:** identify the user and record original/replacement hardware plus migration type.
2. **Pre-migration signoff:** record each data-backup response; block replacement, USB rebuild, or reset when an applicable item is unresolved.
3. **Local-device readiness:** complete the current Version 1 configuration and application checks, then validate OneDrive and the Qnity mailbox.
4. **Cloud PC readiness:** the user signs in and completes MFA; the technician validates Cloud PC access, required applications, Qnity OneDrive behavior, Ricoh driver, Teams account contexts, and user instruction.
5. **Handoff:** record exceptions, responsible technicians, user acceptance, and completion date.

The eventual dashboard should distinguish `Not checked`, `Yes/complete`, `No/blocked`, `Not applicable`, and `Exception` instead of reducing every checklist response to a checkbox.

## Output

By default, files are written to `output/`:

- `<asset>-<timestamp>.log`
- `<asset>-<timestamp>-summary.json`
- `<asset>-<timestamp>-summary.txt`

The JSON includes a schema version, correlation ID, application evidence, normalized result statuses, a machine-readable next-action code, and placeholders for future API/queue state. The referenced `samples/sample-summary.txt` was not present in the Sprint 1 workspace.

The summaries contain the user's email and device identity. Store the output only in an approved location, apply the organization's retention policy, and restrict access appropriately.

## Validate the project

The test runner uses no external modules:

```powershell
.\tests\Invoke-Tests.ps1
```

Before enterprise use, also validate on approved test devices representing every supported model and both a newly provisioned and established user profile.

## Production rollout checklist

1. Confirm the power-setting values with Qnity endpoint engineering.
2. Confirm the actual Windows App package identity in the Qnity tenant.
3. Confirm Microsoft 365 detection across Click-to-Run versions used onsite.
4. Code-sign the entry script and module using the approved certificate.
5. Select an approved output path and retention/access policy.
6. Test standard-user detection and elevated configuration behavior.
7. Pilot with a small deployment wave and compare results to Company Portal/Intune.
8. Establish the escalation threshold for delayed Company Portal provisioning.
9. Confirm the authoritative migration-type names and whether Windows Reset and USB rebuild require different controls.
10. Confirm how user backup attestation and signatures may be stored, retained, and audited.
11. Clarify “OneDrive on Cloud PC to only show Qnity” and the required Teams dual-account configuration.
12. Define pass/fail evidence for OneDrive, Outlook, Cloud PC applications, Ricoh drivers, and user training.

## Extension points

[`docs/architecture.md`](../architecture.md) describes how the JSON contract can feed a Spring Boot API and Angular dashboard, and how a future server-owned lease system can coordinate large downloads. Both integrations are disabled in Version 1 and perform no network calls.
