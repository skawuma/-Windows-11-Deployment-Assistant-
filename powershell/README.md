# PowerShell technician assistant

Sprint 2 provides the safe configuration foundation for Version 1. Application
detection, next-action decisions, operational logs, and JSON/text summaries are
deferred to Sprint 3.

## Implemented

- Interactive or parameter-based asset tag and user email input.
- Noninteractive mode that refuses missing required input.
- Versioned JSON configuration and a Draft 2020-12 configuration schema.
- Configurable validation for asset tags and email addresses.
- Eastern time-zone configuration.
- Lid-close action set to do nothing on AC and battery.
- Power-button action set to shut down on AC and battery.
- Sleep-button action set to do nothing on AC and battery.
- Read-before-write behavior and post-change verification.
- `-WhatIf` support for every device-changing operation.
- Safe, noninteractive simulation with injected platform, permission, current
  state, and failure conditions.
- Normalized `Pass`, `Fail`, `Skipped`, and `Error` check results.
- A dependency-free PowerShell test runner.

The assistant does not install applications, call an API, switch networks, collect
credentials or MFA codes, or authorize destructive migration work.

## Layout

```text
powershell/
├── Start-QnityDeploymentAssistant.ps1
├── config/
│   ├── assistant.config.json
│   └── assistant.config.schema.json
├── samples/
├── src/
│   ├── Qnity.DeploymentAssistant.psd1
│   └── Qnity.DeploymentAssistant.psm1
└── tests/
    ├── fixtures/
    └── Invoke-Tests.ps1
```

## Requirements

- Windows 11 for real configuration checks and changes.
- Windows PowerShell 5.1 or PowerShell 7+.
- Administrator permission only when a setting needs to change.
- Organization-approved execution policy and script-signing process before
  production deployment.

PowerShell 7.6.4 simulation tests pass on macOS. Windows PowerShell 5.1 and real
Windows device behavior still require validation on an approved device.

## Run safely

From the `powershell` directory, preview a real Windows device:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'QNY-10427' `
  -UserEmail 'user@example.com' `
  -WhatIf
```

Apply the configured settings from an approved elevated Windows test session:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'QNY-10427' `
  -UserEmail 'user@example.com'
```

Run a non-destructive simulation:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'TEST-1001' `
  -UserEmail 'user@example.com' `
  -SimulationDataPath '.\samples\simulation.device-needs-configuration.json' `
  -NonInteractive
```

See [`samples/README.md`](samples/README.md) for both supplied scenarios.

## Input rules

The asset-tag rule is provisional because the authoritative Qnity format remains
unconfirmed. The checked-in configuration:

- trims and normalizes asset tags to uppercase;
- accepts 3–32 letters, numbers, and internal hyphens;
- requires a letter or number at both ends; and
- rejects spaces and other punctuation.

Email validation accepts one complete address, rejects display-name syntax and
consecutive dots, and enforces standard total/local-part length limits. Neither
input accepts or prompts for a password or MFA code.

Both regular expressions and length limits are read from
[`config/assistant.config.json`](config/assistant.config.json). Configuration is
validated before any system check or change.

## Device settings and idempotence

The desired values are read from configuration. The assistant queries the current
time zone and active power scheme before changing anything:

- an already compliant setting returns `Pass` with `Changed = false`;
- a required change is attempted only with Administrator permission and
  `ShouldProcess` approval;
- a successful change is queried again and returns `Pass` only if verified;
- a verification mismatch returns `Fail`;
- a permission or command problem returns `Error`; and
- a declined or `-WhatIf` change returns `Skipped`.

Partial command failures are not bypassed. Re-running the assistant safely
re-evaluates current state and attempts only values that still differ.

## Configuration approval boundary

The documented settings are implemented as a configurable baseline, but the
checked-in configuration deliberately states
`productionApprovalRequired: true`. Qnity endpoint and change-management owners
must confirm the values before production rollout.

`apiEnabled` and `downloadQueueEnabled` are required to remain `false` in Sprint
2. Enabling either causes configuration validation to fail.

## Exit behavior

- `0`: checks passed or were safely skipped.
- `1`: input, configuration, simulation, or startup validation failed.
- `2`: at least one device-setting check returned `Fail` or `Error`.

The script reports safe messages without stack traces, credentials, tokens, or
raw command output.

## Test

```powershell
.\tests\Invoke-Tests.ps1
```

The tests require no external PowerShell modules and exercise configuration,
inputs, simulation, `-WhatIf`, permissions, normalized errors, idempotence, and
the entry point.
