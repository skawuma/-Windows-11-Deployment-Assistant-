@{
    RootModule        = 'Qnity.DeploymentAssistant.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'd115cb8b-0aec-4c2d-a611-67445d3b0bc4'
    Author            = 'samuelkawuma'
    CompanyName       = 'Qnity'
    Copyright         = '(c) 2026 samuelkawuma. All rights reserved.'
    Description       = 'Safe local configuration foundation for the Qnity Windows 11 Deployment Assistant.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @(
        'Desktop'
        'Core'
    )
    FunctionsToExport = @(
        'Import-QnityConfiguration'
        'Test-QnityAssetTag'
        'Test-QnityUserEmail'
        'Invoke-QnityDeploymentAssistant'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('Windows11', 'Deployment', 'Qnity')
            ProjectUri = 'https://github.com/skawuma/-Windows-11-Deployment-Assistant-'
        }
    }
}
