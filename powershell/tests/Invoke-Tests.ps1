[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:passedTests = 0
$script:failedTests = 0

$powerShellRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$moduleManifest = Join-Path $powerShellRoot 'src/Qnity.DeploymentAssistant.psd1'
$configurationPath = Join-Path $powerShellRoot 'config/assistant.config.json'
$configurationSchemaPath = Join-Path $powerShellRoot 'config/assistant.config.schema.json'
$entryPoint = Join-Path $powerShellRoot 'Start-QnityDeploymentAssistant.ps1'
$fixtureRoot = Join-Path $PSScriptRoot 'fixtures'

function Assert-QnityTrue {
    param(
        [bool]$Condition,
        [string]$Message = 'Expected condition to be true.'
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-QnityFalse {
    param(
        [bool]$Condition,
        [string]$Message = 'Expected condition to be false.'
    )

    if ($Condition) {
        throw $Message
    }
}

function Assert-QnityEqual {
    param(
        [AllowNull()]
        [object]$Expected,

        [AllowNull()]
        [object]$Actual,

        [string]$Message = 'Values were not equal.'
    )

    if ($Expected -ne $Actual) {
        throw "$Message Expected '$Expected'; actual '$Actual'."
    }
}

function Assert-QnityThrows {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [string]$MessagePattern = '*'
    )

    $threw = $false
    try {
        & $Action | Out-Null
    }
    catch {
        $threw = $true
        if ($_.Exception.Message -notlike $MessagePattern) {
            throw (
                "Exception message did not match '$MessagePattern'. " +
                "Actual: '$($_.Exception.Message)'."
            )
        }
    }

    if (-not $threw) {
        throw 'Expected an exception, but no exception was thrown.'
    }
}

function Invoke-QnityTestCase {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Test
    )

    try {
        & $Test
        $script:passedTests += 1
        Write-Host "PASS: $Name"
    }
    catch {
        $script:failedTests += 1
        Write-Host "FAIL: $Name"
        Write-Host "      $($_.Exception.Message)"
    }
}

Import-Module $moduleManifest -Force -ErrorAction Stop
$configuration = Import-QnityConfiguration -Path $configurationPath

Invoke-QnityTestCase 'The checked-in configuration is valid and versioned' {
    Assert-QnityEqual '1.0.0' $configuration.schemaVersion
    Assert-QnityEqual '2026.07.28' $configuration.configurationVersion
    Assert-QnityEqual 'Eastern Standard Time' $configuration.deviceSettings.timeZone.id
    Assert-QnityTrue ([bool]$configuration.safety.productionApprovalRequired
    )
    Assert-QnityFalse ([bool]$configuration.safety.apiEnabled)
    Assert-QnityFalse ([bool]$configuration.safety.downloadQueueEnabled)
}

Invoke-QnityTestCase 'The checked-in JSON Schema is parseable and uses Draft 2020-12' {
    $schema = Get-Content -LiteralPath $configurationSchemaPath -Raw |
        ConvertFrom-Json -ErrorAction Stop
    $schemaUri = $schema.PSObject.Properties['$schema'].Value
    Assert-QnityEqual 'https://json-schema.org/draft/2020-12/schema' $schemaUri
}

Invoke-QnityTestCase 'A missing configuration file stops safely' {
    Assert-QnityThrows `
        -Action {
            Import-QnityConfiguration -Path (
                Join-Path $PSScriptRoot 'fixtures/does-not-exist.json'
            )
        } `
        -MessagePattern 'Configuration file was not found:*'
}

Invoke-QnityTestCase 'An unsupported configuration schema version is rejected' {
    $temporaryPath = [IO.Path]::GetTempFileName()
    try {
        $invalidConfiguration = Get-Content -LiteralPath $configurationPath -Raw |
            ConvertFrom-Json
        $invalidConfiguration.schemaVersion = '99.0.0'
        $invalidConfiguration |
            ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $temporaryPath -Encoding UTF8

        Assert-QnityThrows `
            -Action {
                Import-QnityConfiguration -Path $temporaryPath
            } `
            -MessagePattern '*schemaVersion must be*'
    }
    finally {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}

Invoke-QnityTestCase 'Unsafe API enablement is rejected by configuration validation' {
    $temporaryPath = [IO.Path]::GetTempFileName()
    try {
        $invalidConfiguration = Get-Content -LiteralPath $configurationPath -Raw |
            ConvertFrom-Json
        $invalidConfiguration.safety.apiEnabled = $true
        $invalidConfiguration |
            ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $temporaryPath -Encoding UTF8

        Assert-QnityThrows `
            -Action {
                Import-QnityConfiguration -Path $temporaryPath
            } `
            -MessagePattern '*apiEnabled must be false*'
    }
    finally {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}

Invoke-QnityTestCase 'Documented power values are read from configuration' {
    Assert-QnityEqual 0 ([int]$configuration.deviceSettings.power.lidClose.acValue)
    Assert-QnityEqual 0 ([int]$configuration.deviceSettings.power.lidClose.dcValue)
    Assert-QnityEqual 3 ([int]$configuration.deviceSettings.power.powerButton.acValue)
    Assert-QnityEqual 3 ([int]$configuration.deviceSettings.power.powerButton.dcValue)
    Assert-QnityEqual 0 ([int]$configuration.deviceSettings.power.sleepButton.acValue)
    Assert-QnityEqual 0 ([int]$configuration.deviceSettings.power.sleepButton.dcValue)
}

Invoke-QnityTestCase 'Valid asset tags are accepted by the provisional configurable rule' {
    foreach ($assetTag in @('QNY-10427', 'abc-123', 'A12', 'ASSET1234567890')) {
        Assert-QnityTrue (
            Test-QnityAssetTag -AssetTag $assetTag -Configuration $configuration
        ) "Expected asset tag '$assetTag' to be accepted."
    }
}

Invoke-QnityTestCase 'Invalid asset tags are rejected' {
    foreach ($assetTag in @('', 'AB', '-QNY123', 'QNY123-', 'QNY_123', 'QNY 123')) {
        Assert-QnityFalse (
            Test-QnityAssetTag -AssetTag $assetTag -Configuration $configuration
        ) "Expected asset tag '$assetTag' to be rejected."
    }
}

Invoke-QnityTestCase 'Valid user email addresses are accepted' {
    foreach ($email in @('user@example.com', 'first.last+pilot@sub.example.org')) {
        Assert-QnityTrue (
            Test-QnityUserEmail -UserEmail $email -Configuration $configuration
        ) "Expected email '$email' to be accepted."
    }
}

Invoke-QnityTestCase 'Invalid user email addresses are rejected' {
    foreach ($email in @('', 'user', 'user@', '@example.com', 'a..b@example.com', 'Name <user@example.com>')) {
        Assert-QnityFalse (
            Test-QnityUserEmail -UserEmail $email -Configuration $configuration
        ) "Expected email '$email' to be rejected."
    }
}

Invoke-QnityTestCase 'Invalid input stops before any settings are evaluated' {
    Assert-QnityThrows `
        -Action {
            Invoke-QnityDeploymentAssistant `
                -AssetTag 'bad tag' `
                -UserEmail 'user@example.com' `
                -ConfigurationPath $configurationPath `
                -SimulationDataPath (
                    Join-Path $fixtureRoot 'simulation.changes-required.json'
                ) `
                -NonInteractive
        } `
        -MessagePattern 'Asset tag is invalid.*'
}

Invoke-QnityTestCase 'Noninteractive simulation applies and verifies every documented setting' {
    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'qny-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.changes-required.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'QNY-10427' $run.AssetTag
    Assert-QnityTrue ([bool]$run.Simulation)
    Assert-QnityTrue ([bool]$run.NonInteractive)
    Assert-QnityEqual 'Pass' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results).Count
    Assert-QnityEqual 0 @($run.Results | Where-Object { $_.Status -ne 'Pass' }).Count
    Assert-QnityEqual 4 @($run.Results | Where-Object { $_.Changed }).Count
}

Invoke-QnityTestCase 'An already compliant simulation is idempotent' {
    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.compliant.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'Pass' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results).Count
    Assert-QnityEqual 0 @($run.Results | Where-Object { $_.Changed }).Count
    Assert-QnityEqual 4 @(
        $run.Results |
            Where-Object { $_.Evidence.ReasonCode -eq 'ALREADY_COMPLIANT' }
    ).Count
}

Invoke-QnityTestCase 'WhatIf skips every required change and leaves simulation data untouched' {
    $simulationPath = Join-Path $fixtureRoot 'simulation.changes-required.json'
    $beforeHash = (Get-FileHash -LiteralPath $simulationPath -Algorithm SHA256).Hash

    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath $simulationPath `
        -NonInteractive `
        -WhatIf

    $afterHash = (Get-FileHash -LiteralPath $simulationPath -Algorithm SHA256).Hash
    Assert-QnityEqual 'Skipped' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results | Where-Object { $_.Status -eq 'Skipped' }).Count
    Assert-QnityEqual 0 @($run.Results | Where-Object { $_.Changed }).Count
    Assert-QnityEqual $beforeHash $afterHash
}

Invoke-QnityTestCase 'Standard-user permission failures are explicit and do not apply changes' {
    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.standard-user.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'Error' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results | Where-Object { $_.Status -eq 'Error' }).Count
    Assert-QnityEqual 4 @(
        $run.Results |
            Where-Object { $_.Evidence.ReasonCode -eq 'ADMINISTRATOR_REQUIRED' }
    ).Count
    Assert-QnityEqual 0 @($run.Results | Where-Object { $_.Changed }).Count
}

Invoke-QnityTestCase 'A non-Windows target skips all Windows settings safely' {
    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.non-windows.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'Skipped' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results | Where-Object { $_.Status -eq 'Skipped' }).Count
    Assert-QnityEqual 4 @(
        $run.Results |
            Where-Object { $_.Evidence.ReasonCode -eq 'UNSUPPORTED_PLATFORM' }
    ).Count
}

Invoke-QnityTestCase 'Simulated command failures become normalized errors without bypassing them' {
    $run = Invoke-QnityDeploymentAssistant `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.failures.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'Error' $run.OverallStatus
    Assert-QnityEqual 2 @($run.Results | Where-Object { $_.Status -eq 'Error' }).Count
    Assert-QnityEqual 2 @($run.Results | Where-Object { $_.Status -eq 'Pass' }).Count
    Assert-QnityEqual 0 @(
        $run.Results |
            Where-Object { $_.Status -eq 'Error' -and $_.Changed }
    ).Count
}

Invoke-QnityTestCase 'Every emitted check uses a normalized result status' {
    $allowedStatuses = @('Pass', 'Fail', 'Skipped', 'Error')
    foreach ($fixtureName in @(
        'simulation.changes-required.json',
        'simulation.compliant.json',
        'simulation.standard-user.json',
        'simulation.non-windows.json',
        'simulation.failures.json'
    )) {
        $run = Invoke-QnityDeploymentAssistant `
            -AssetTag 'QNY-10427' `
            -UserEmail 'user@example.com' `
            -ConfigurationPath $configurationPath `
            -SimulationDataPath (Join-Path $fixtureRoot $fixtureName) `
            -NonInteractive

        foreach ($result in $run.Results) {
            Assert-QnityTrue ($allowedStatuses -contains $result.Status) (
                "Unexpected result status '$($result.Status)'."
            )
        }
    }
}

Invoke-QnityTestCase 'The entry point runs noninteractively with simulation data' {
    $run = & $entryPoint `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.compliant.json'
        ) `
        -NonInteractive

    Assert-QnityEqual 'QnityDeviceConfiguration' $run.RunType
    Assert-QnityEqual 'Pass' $run.OverallStatus
}

Invoke-QnityTestCase 'The entry point propagates WhatIf without applying simulated changes' {
    $run = & $entryPoint `
        -AssetTag 'QNY-10427' `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.changes-required.json'
        ) `
        -NonInteractive `
        -WhatIf

    Assert-QnityEqual 'Skipped' $run.OverallStatus
    Assert-QnityEqual 4 @($run.Results | Where-Object { $_.Status -eq 'Skipped' }).Count
    Assert-QnityEqual 0 @($run.Results | Where-Object { $_.Changed }).Count
}

Invoke-QnityTestCase 'The entry point refuses missing input in noninteractive mode' {
    $hostExecutable = (Get-Process -Id $PID).Path
    $output = & $hostExecutable `
        -NoLogo `
        -NoProfile `
        -File $entryPoint `
        -UserEmail 'user@example.com' `
        -ConfigurationPath $configurationPath `
        -SimulationDataPath (
            Join-Path $fixtureRoot 'simulation.compliant.json'
        ) `
        -NonInteractive 2>&1
    $exitCode = $LASTEXITCODE

    Assert-QnityEqual 1 $exitCode
    Assert-QnityTrue (($output | Out-String) -match 'AssetTag is required')
}

Write-Host ''
Write-Host "PowerShell tests passed: $script:passedTests"
Write-Host "PowerShell tests failed: $script:failedTests"

if ($script:failedTests -gt 0) {
    exit 1
}
