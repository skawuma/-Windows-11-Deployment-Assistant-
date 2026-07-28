# Simulation samples

These files exercise Sprint 2 without reading or changing the host operating
system.

- `simulation.device-needs-configuration.json` represents an elevated Windows
  device whose time-zone and power settings need correction.
- `simulation.device-compliant.json` represents an elevated Windows device that
  already matches configuration.

Run the first scenario:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'TEST-1001' `
  -UserEmail 'user@example.com' `
  -SimulationDataPath '.\samples\simulation.device-needs-configuration.json' `
  -NonInteractive
```

Preview it without even mutating the in-memory simulation state:

```powershell
.\Start-QnityDeploymentAssistant.ps1 `
  -AssetTag 'TEST-1001' `
  -UserEmail 'user@example.com' `
  -SimulationDataPath '.\samples\simulation.device-needs-configuration.json' `
  -NonInteractive `
  -WhatIf
```

Simulation files contain synthetic technical state only. They are not evidence
from a real device, user attestations, technician validations, or enterprise
approvals.
