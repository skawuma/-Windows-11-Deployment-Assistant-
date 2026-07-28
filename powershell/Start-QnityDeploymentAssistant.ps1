[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$AssetTag,

    [string]$UserEmail,

    [string]$ConfigurationPath = (
        Join-Path $PSScriptRoot 'config/assistant.config.json'
    ),

    [string]$SimulationDataPath,

    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleManifest = Join-Path $PSScriptRoot 'src/Qnity.DeploymentAssistant.psd1'

try {
    Import-Module $moduleManifest -Force -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($AssetTag)) {
        if ($NonInteractive) {
            throw 'AssetTag is required in noninteractive mode.'
        }

        $AssetTag = Read-Host 'Asset tag'
    }

    if ([string]::IsNullOrWhiteSpace($UserEmail)) {
        if ($NonInteractive) {
            throw 'UserEmail is required in noninteractive mode.'
        }

        $UserEmail = Read-Host 'User email'
    }

    $invokeParameters = @{
        AssetTag         = $AssetTag
        UserEmail        = $UserEmail
        ConfigurationPath = $ConfigurationPath
        NonInteractive   = $NonInteractive
        WhatIf           = [bool]$WhatIfPreference
    }

    if (-not [string]::IsNullOrWhiteSpace($SimulationDataPath)) {
        $invokeParameters.SimulationDataPath = $SimulationDataPath
    }

    $run = Invoke-QnityDeploymentAssistant @invokeParameters

    Write-Host "Qnity configuration run for asset '$($run.AssetTag)': $($run.OverallStatus)"
    foreach ($result in $run.Results) {
        Write-Host "[$($result.Status)] $($result.CheckCode): $($result.Message)"
    }

    Write-Output $run

    if ($run.OverallStatus -in @('Fail', 'Error')) {
        exit 2
    }
}
catch {
    [Console]::Error.WriteLine(
        "Qnity Deployment Assistant stopped safely: $($_.Exception.Message)"
    )
    exit 1
}
