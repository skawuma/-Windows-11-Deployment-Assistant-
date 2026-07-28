Set-StrictMode -Version Latest

$script:AgentVersion = '0.2.0'
$script:SupportedConfigurationSchemaVersion = '1.0.0'
$script:SupportedSimulationSchemaVersion = '1.0.0'
$script:ResultStatuses = @('Pass', 'Fail', 'Skipped', 'Error')

function Test-QnityHasProperty {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $false
    }

    return $null -ne $InputObject.PSObject.Properties[$Name]
}

function Add-QnityUnexpectedPropertyErrors {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string[]]$AllowedProperties,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($null -eq $InputObject) {
        return
    }

    foreach ($property in $InputObject.PSObject.Properties) {
        if ($AllowedProperties -notcontains $property.Name) {
            [void]$Errors.Add("$Path contains unsupported property '$($property.Name)'.")
        }
    }
}

function Test-QnityInteger {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    return ($Value -is [int]) -or ($Value -is [long])
}

function Test-QnityGuidText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return $false
    }

    try {
        [void][guid]::Parse([string]$Value)
        return $true
    }
    catch {
        return $false
    }
}

function Test-QnityRegexText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return $false
    }

    try {
        [void]([regex][string]$Value)
        return $true
    }
    catch {
        return $false
    }
}

function Get-QnityConfigurationErrors {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Configuration
    )

    $errors = New-Object 'System.Collections.Generic.List[string]'

    if ($null -eq $Configuration) {
        [void]$errors.Add('Configuration is empty.')
        return $errors.ToArray()
    }

    Add-QnityUnexpectedPropertyErrors `
        -InputObject $Configuration `
        -AllowedProperties @('schemaVersion', 'configurationVersion', 'input', 'deviceSettings', 'safety') `
        -Path 'configuration' `
        -Errors $errors

    if (-not (Test-QnityHasProperty -InputObject $Configuration -Name 'schemaVersion')) {
        [void]$errors.Add('configuration.schemaVersion is required.')
    }
    elseif ([string]$Configuration.schemaVersion -ne $script:SupportedConfigurationSchemaVersion) {
        [void]$errors.Add(
            "configuration.schemaVersion must be '$script:SupportedConfigurationSchemaVersion'."
        )
    }

    if (-not (Test-QnityHasProperty -InputObject $Configuration -Name 'configurationVersion')) {
        [void]$errors.Add('configuration.configurationVersion is required.')
    }
    elseif ([string]$Configuration.configurationVersion -notmatch '^\d{4}\.\d{2}\.\d{2}$') {
        [void]$errors.Add('configuration.configurationVersion must use yyyy.MM.dd.')
    }

    $inputConfiguration = $null
    if (-not (Test-QnityHasProperty -InputObject $Configuration -Name 'input')) {
        [void]$errors.Add('configuration.input is required.')
    }
    else {
        $inputConfiguration = $Configuration.input
        Add-QnityUnexpectedPropertyErrors `
            -InputObject $inputConfiguration `
            -AllowedProperties @('assetTag', 'userEmail') `
            -Path 'configuration.input' `
            -Errors $errors
    }

    if ($null -ne $inputConfiguration) {
        if (-not (Test-QnityHasProperty -InputObject $inputConfiguration -Name 'assetTag')) {
            [void]$errors.Add('configuration.input.assetTag is required.')
        }
        else {
            $assetTagConfiguration = $inputConfiguration.assetTag
            Add-QnityUnexpectedPropertyErrors `
                -InputObject $assetTagConfiguration `
                -AllowedProperties @('pattern', 'minimumLength', 'maximumLength', 'description') `
                -Path 'configuration.input.assetTag' `
                -Errors $errors

            if (
                -not (Test-QnityHasProperty -InputObject $assetTagConfiguration -Name 'pattern') -or
                -not (Test-QnityRegexText -Value $assetTagConfiguration.pattern)
            ) {
                [void]$errors.Add('configuration.input.assetTag.pattern must be a valid regular expression.')
            }

            foreach ($lengthProperty in @('minimumLength', 'maximumLength')) {
                if (
                    -not (Test-QnityHasProperty -InputObject $assetTagConfiguration -Name $lengthProperty) -or
                    -not (Test-QnityInteger -Value $assetTagConfiguration.$lengthProperty) -or
                    [int]$assetTagConfiguration.$lengthProperty -lt 1
                ) {
                    [void]$errors.Add(
                        "configuration.input.assetTag.$lengthProperty must be a positive integer."
                    )
                }
            }

            if (
                (Test-QnityHasProperty -InputObject $assetTagConfiguration -Name 'minimumLength') -and
                (Test-QnityHasProperty -InputObject $assetTagConfiguration -Name 'maximumLength') -and
                (Test-QnityInteger -Value $assetTagConfiguration.minimumLength) -and
                (Test-QnityInteger -Value $assetTagConfiguration.maximumLength) -and
                [int]$assetTagConfiguration.minimumLength -gt [int]$assetTagConfiguration.maximumLength
            ) {
                [void]$errors.Add(
                    'configuration.input.assetTag.minimumLength cannot exceed maximumLength.'
                )
            }

            if (
                -not (Test-QnityHasProperty -InputObject $assetTagConfiguration -Name 'description') -or
                [string]::IsNullOrWhiteSpace([string]$assetTagConfiguration.description)
            ) {
                [void]$errors.Add('configuration.input.assetTag.description is required.')
            }
        }

        if (-not (Test-QnityHasProperty -InputObject $inputConfiguration -Name 'userEmail')) {
            [void]$errors.Add('configuration.input.userEmail is required.')
        }
        else {
            $emailConfiguration = $inputConfiguration.userEmail
            Add-QnityUnexpectedPropertyErrors `
                -InputObject $emailConfiguration `
                -AllowedProperties @('pattern', 'maximumLength') `
                -Path 'configuration.input.userEmail' `
                -Errors $errors

            if (
                -not (Test-QnityHasProperty -InputObject $emailConfiguration -Name 'pattern') -or
                -not (Test-QnityRegexText -Value $emailConfiguration.pattern)
            ) {
                [void]$errors.Add('configuration.input.userEmail.pattern must be a valid regular expression.')
            }

            if (
                -not (Test-QnityHasProperty -InputObject $emailConfiguration -Name 'maximumLength') -or
                -not (Test-QnityInteger -Value $emailConfiguration.maximumLength) -or
                [int]$emailConfiguration.maximumLength -ne 254
            ) {
                [void]$errors.Add('configuration.input.userEmail.maximumLength must be 254.')
            }
        }
    }

    $deviceSettings = $null
    if (-not (Test-QnityHasProperty -InputObject $Configuration -Name 'deviceSettings')) {
        [void]$errors.Add('configuration.deviceSettings is required.')
    }
    else {
        $deviceSettings = $Configuration.deviceSettings
        Add-QnityUnexpectedPropertyErrors `
            -InputObject $deviceSettings `
            -AllowedProperties @('timeZone', 'power') `
            -Path 'configuration.deviceSettings' `
            -Errors $errors
    }

    if ($null -ne $deviceSettings) {
        if (-not (Test-QnityHasProperty -InputObject $deviceSettings -Name 'timeZone')) {
            [void]$errors.Add('configuration.deviceSettings.timeZone is required.')
        }
        else {
            $timeZoneConfiguration = $deviceSettings.timeZone
            Add-QnityUnexpectedPropertyErrors `
                -InputObject $timeZoneConfiguration `
                -AllowedProperties @('id') `
                -Path 'configuration.deviceSettings.timeZone' `
                -Errors $errors

            if (
                -not (Test-QnityHasProperty -InputObject $timeZoneConfiguration -Name 'id') -or
                [string]$timeZoneConfiguration.id -ne 'Eastern Standard Time'
            ) {
                [void]$errors.Add(
                    "configuration.deviceSettings.timeZone.id must be 'Eastern Standard Time'."
                )
            }
        }

        if (-not (Test-QnityHasProperty -InputObject $deviceSettings -Name 'power')) {
            [void]$errors.Add('configuration.deviceSettings.power is required.')
        }
        else {
            $powerConfiguration = $deviceSettings.power
            Add-QnityUnexpectedPropertyErrors `
                -InputObject $powerConfiguration `
                -AllowedProperties @('scheme', 'subgroupGuid', 'lidClose', 'powerButton', 'sleepButton') `
                -Path 'configuration.deviceSettings.power' `
                -Errors $errors

            if (
                -not (Test-QnityHasProperty -InputObject $powerConfiguration -Name 'scheme') -or
                [string]$powerConfiguration.scheme -ne 'SCHEME_CURRENT'
            ) {
                [void]$errors.Add(
                    "configuration.deviceSettings.power.scheme must be 'SCHEME_CURRENT'."
                )
            }

            if (
                -not (Test-QnityHasProperty -InputObject $powerConfiguration -Name 'subgroupGuid') -or
                -not (Test-QnityGuidText -Value $powerConfiguration.subgroupGuid)
            ) {
                [void]$errors.Add(
                    'configuration.deviceSettings.power.subgroupGuid must be a valid GUID.'
                )
            }

            $expectedPowerValues = @{
                lidClose    = 0
                powerButton = 3
                sleepButton = 0
            }

            foreach ($settingName in @('lidClose', 'powerButton', 'sleepButton')) {
                if (-not (Test-QnityHasProperty -InputObject $powerConfiguration -Name $settingName)) {
                    [void]$errors.Add(
                        "configuration.deviceSettings.power.$settingName is required."
                    )
                    continue
                }

                $setting = $powerConfiguration.$settingName
                Add-QnityUnexpectedPropertyErrors `
                    -InputObject $setting `
                    -AllowedProperties @('settingGuid', 'acValue', 'dcValue') `
                    -Path "configuration.deviceSettings.power.$settingName" `
                    -Errors $errors

                if (
                    -not (Test-QnityHasProperty -InputObject $setting -Name 'settingGuid') -or
                    -not (Test-QnityGuidText -Value $setting.settingGuid)
                ) {
                    [void]$errors.Add(
                        "configuration.deviceSettings.power.$settingName.settingGuid must be a valid GUID."
                    )
                }

                foreach ($powerSource in @('acValue', 'dcValue')) {
                    if (
                        -not (Test-QnityHasProperty -InputObject $setting -Name $powerSource) -or
                        -not (Test-QnityInteger -Value $setting.$powerSource) -or
                        [int]$setting.$powerSource -ne [int]$expectedPowerValues[$settingName]
                    ) {
                        [void]$errors.Add(
                            "configuration.deviceSettings.power.$settingName.$powerSource must be " +
                            "$($expectedPowerValues[$settingName])."
                        )
                    }
                }
            }
        }
    }

    if (-not (Test-QnityHasProperty -InputObject $Configuration -Name 'safety')) {
        [void]$errors.Add('configuration.safety is required.')
    }
    else {
        $safety = $Configuration.safety
        Add-QnityUnexpectedPropertyErrors `
            -InputObject $safety `
            -AllowedProperties @(
                'productionApprovalRequired',
                'deviceChangesRequireAdministrator',
                'apiEnabled',
                'downloadQueueEnabled'
            ) `
            -Path 'configuration.safety' `
            -Errors $errors

        foreach ($requiredTrue in @('productionApprovalRequired', 'deviceChangesRequireAdministrator')) {
            if (
                -not (Test-QnityHasProperty -InputObject $safety -Name $requiredTrue) -or
                $safety.$requiredTrue -isnot [bool] -or
                -not [bool]$safety.$requiredTrue
            ) {
                [void]$errors.Add("configuration.safety.$requiredTrue must be true.")
            }
        }

        foreach ($requiredFalse in @('apiEnabled', 'downloadQueueEnabled')) {
            if (
                -not (Test-QnityHasProperty -InputObject $safety -Name $requiredFalse) -or
                $safety.$requiredFalse -isnot [bool] -or
                [bool]$safety.$requiredFalse
            ) {
                [void]$errors.Add("configuration.safety.$requiredFalse must be false.")
            }
        }
    }

    return $errors.ToArray()
}

function Import-QnityConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        throw "Configuration file was not found: '$Path'."
    }

    try {
        $rawConfiguration = Get-Content -LiteralPath $resolvedPath -Raw -ErrorAction Stop
    }
    catch {
        throw "Configuration file could not be read: '$resolvedPath'."
    }

    if ([string]::IsNullOrWhiteSpace($rawConfiguration)) {
        throw "Configuration file is empty: '$resolvedPath'."
    }

    try {
        $configuration = $rawConfiguration | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Configuration file is not valid JSON: '$resolvedPath'."
    }

    $validationErrors = @(Get-QnityConfigurationErrors -Configuration $configuration)
    if ($validationErrors.Count -gt 0) {
        throw "Configuration validation failed: $($validationErrors -join ' ')"
    }

    return $configuration
}

function Test-QnityAssetTag {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$AssetTag,

        [Parameter(Mandatory)]
        [object]$Configuration
    )

    if ([string]::IsNullOrWhiteSpace($AssetTag)) {
        return $false
    }

    $candidate = $AssetTag.Trim().ToUpperInvariant()
    $rules = $Configuration.input.assetTag

    if (
        $candidate.Length -lt [int]$rules.minimumLength -or
        $candidate.Length -gt [int]$rules.maximumLength
    ) {
        return $false
    }

    return $candidate -match [string]$rules.pattern
}

function Test-QnityUserEmail {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$UserEmail,

        [Parameter(Mandatory)]
        [object]$Configuration
    )

    if ([string]::IsNullOrWhiteSpace($UserEmail)) {
        return $false
    }

    $candidate = $UserEmail.Trim()
    $rules = $Configuration.input.userEmail

    if (
        $candidate.Length -gt [int]$rules.maximumLength -or
        $candidate -notmatch [string]$rules.pattern -or
        $candidate.Contains('..')
    ) {
        return $false
    }

    $atIndex = $candidate.LastIndexOf('@')
    if ($atIndex -le 0 -or $atIndex -ge ($candidate.Length - 1)) {
        return $false
    }

    $localPart = $candidate.Substring(0, $atIndex)
    $domainPart = $candidate.Substring($atIndex + 1)
    if (
        $localPart.Length -gt 64 -or
        $localPart.StartsWith('.') -or
        $localPart.EndsWith('.') -or
        $domainPart.StartsWith('.') -or
        $domainPart.EndsWith('.')
    ) {
        return $false
    }

    try {
        $parsedAddress = New-Object System.Net.Mail.MailAddress -ArgumentList $candidate
        return $parsedAddress.Address -eq $candidate
    }
    catch {
        return $false
    }
}

function Resolve-QnityAssetTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AssetTag,

        [Parameter(Mandatory)]
        [object]$Configuration
    )

    if (-not (Test-QnityAssetTag -AssetTag $AssetTag -Configuration $Configuration)) {
        throw (
            'Asset tag is invalid. Use 3-32 letters, numbers, or internal hyphens; ' +
            'the value must begin and end with a letter or number.'
        )
    }

    return $AssetTag.Trim().ToUpperInvariant()
}

function Resolve-QnityUserEmail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserEmail,

        [Parameter(Mandatory)]
        [object]$Configuration
    )

    if (-not (Test-QnityUserEmail -UserEmail $UserEmail -Configuration $Configuration)) {
        throw 'User email is invalid. Enter one complete email address without display-name text.'
    }

    return $UserEmail.Trim()
}

function Import-QnitySimulationData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $rawSimulation = Get-Content -LiteralPath $resolvedPath -Raw -ErrorAction Stop
        $simulation = $rawSimulation | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Simulation data could not be loaded as JSON: '$Path'."
    }

    $errors = New-Object 'System.Collections.Generic.List[string]'

    if (
        -not (Test-QnityHasProperty -InputObject $simulation -Name 'schemaVersion') -or
        [string]$simulation.schemaVersion -ne $script:SupportedSimulationSchemaVersion
    ) {
        [void]$errors.Add(
            "simulation.schemaVersion must be '$script:SupportedSimulationSchemaVersion'."
        )
    }

    if (-not (Test-QnityHasProperty -InputObject $simulation -Name 'platform')) {
        [void]$errors.Add('simulation.platform is required.')
    }
    else {
        foreach ($platformProperty in @('isWindows', 'isAdministrator')) {
            if (
                -not (Test-QnityHasProperty -InputObject $simulation.platform -Name $platformProperty) -or
                $simulation.platform.$platformProperty -isnot [bool]
            ) {
                [void]$errors.Add("simulation.platform.$platformProperty must be Boolean.")
            }
        }
    }

    if (-not (Test-QnityHasProperty -InputObject $simulation -Name 'settings')) {
        [void]$errors.Add('simulation.settings is required.')
    }
    else {
        if (
            -not (Test-QnityHasProperty -InputObject $simulation.settings -Name 'timeZoneId') -or
            [string]::IsNullOrWhiteSpace([string]$simulation.settings.timeZoneId)
        ) {
            [void]$errors.Add('simulation.settings.timeZoneId is required.')
        }

        if (-not (Test-QnityHasProperty -InputObject $simulation.settings -Name 'power')) {
            [void]$errors.Add('simulation.settings.power is required.')
        }
        else {
            foreach ($settingName in @('lidClose', 'powerButton', 'sleepButton')) {
                if (-not (Test-QnityHasProperty -InputObject $simulation.settings.power -Name $settingName)) {
                    [void]$errors.Add("simulation.settings.power.$settingName is required.")
                    continue
                }

                $setting = $simulation.settings.power.$settingName
                foreach ($powerSource in @('acValue', 'dcValue')) {
                    if (
                        -not (Test-QnityHasProperty -InputObject $setting -Name $powerSource) -or
                        -not (Test-QnityInteger -Value $setting.$powerSource)
                    ) {
                        [void]$errors.Add(
                            "simulation.settings.power.$settingName.$powerSource must be an integer."
                        )
                    }
                }
            }
        }
    }

    if (
        (Test-QnityHasProperty -InputObject $simulation -Name 'failures') -and
        $null -ne $simulation.failures
    ) {
        foreach ($failure in @($simulation.failures)) {
            if ([string]::IsNullOrWhiteSpace([string]$failure)) {
                [void]$errors.Add('simulation.failures entries must be non-empty strings.')
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Simulation validation failed: $($errors.ToArray() -join ' ')"
    }

    return $simulation
}

function Test-QnitySimulationFailure {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$SimulationData,

        [Parameter(Mandatory)]
        [string]$FailureCode
    )

    if (
        $null -eq $SimulationData -or
        -not (Test-QnityHasProperty -InputObject $SimulationData -Name 'failures') -or
        $null -eq $SimulationData.failures
    ) {
        return $false
    }

    return @($SimulationData.failures) -contains $FailureCode
}

function Get-QnityPowerFailurePrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('lidClose', 'powerButton', 'sleepButton')]
        [string]$SettingName
    )

    switch ($SettingName) {
        'lidClose' {
            return 'POWER_LID_CLOSE'
        }
        'powerButton' {
            return 'POWER_BUTTON'
        }
        'sleepButton' {
            return 'POWER_SLEEP_BUTTON'
        }
    }
}

function New-QnityResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CheckCode,

        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Fail', 'Skipped', 'Error')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [bool]$Changed,

        [Parameter(Mandatory)]
        [object]$Evidence
    )

    return [pscustomobject][ordered]@{
        CheckCode = $CheckCode
        Status    = $Status
        Message   = $Message
        Changed   = $Changed
        Evidence  = $Evidence
    }
}

function Test-QnityIsWindows {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$SimulationData
    )

    if ($null -ne $SimulationData) {
        return [bool]$SimulationData.platform.isWindows
    }

    return $env:OS -eq 'Windows_NT'
}

function Test-QnityIsAdministrator {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$SimulationData
    )

    if ($null -ne $SimulationData) {
        return [bool]$SimulationData.platform.isAdministrator
    }

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Get-QnityTimeZoneId {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$SimulationData
    )

    if ($null -ne $SimulationData) {
        if (Test-QnitySimulationFailure -SimulationData $SimulationData -FailureCode 'TIME_ZONE_GET') {
            throw 'Simulated time-zone query failure.'
        }

        return [string]$SimulationData.settings.timeZoneId
    }

    $timeZone = Get-TimeZone -ErrorAction Stop
    return [string]$timeZone.Id
}

function Set-QnityTimeZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [AllowNull()]
        [object]$SimulationData
    )

    if ($null -ne $SimulationData) {
        if (Test-QnitySimulationFailure -SimulationData $SimulationData -FailureCode 'TIME_ZONE_SET') {
            throw 'Simulated time-zone update failure.'
        }

        $SimulationData.settings.timeZoneId = $Id
        return
    }

    Set-TimeZone -Id $Id -ErrorAction Stop
}

function Get-QnityPowerCfgPath {
    [CmdletBinding()]
    param()

    $command = Get-Command 'powercfg.exe' -CommandType Application -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace([string]$command.Source)) {
        return [string]$command.Source
    }

    return [string]$command.Definition
}

function Invoke-QnityPowerCfg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $powerCfgPath = Get-QnityPowerCfgPath
    $output = & $powerCfgPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "powercfg.exe failed with exit code $exitCode."
    }

    return ($output | Out-String)
}

function Get-QnityPowerSettingState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SettingName,

        [Parameter(Mandatory)]
        [object]$PowerConfiguration,

        [AllowNull()]
        [object]$SimulationData
    )

    if ($null -ne $SimulationData) {
        $failurePrefix = Get-QnityPowerFailurePrefix -SettingName $SettingName
        if (
            Test-QnitySimulationFailure `
                -SimulationData $SimulationData `
                -FailureCode "${failurePrefix}_GET"
        ) {
            throw "Simulated $SettingName power-setting query failure."
        }

        $state = $SimulationData.settings.power.PSObject.Properties[$SettingName].Value
        return [pscustomobject]@{
            AcValue = [int]$state.acValue
            DcValue = [int]$state.dcValue
        }
    }

    $setting = $PowerConfiguration.PSObject.Properties[$SettingName].Value
    $queryText = Invoke-QnityPowerCfg -Arguments @(
        '/QUERY',
        [string]$PowerConfiguration.scheme,
        [string]$PowerConfiguration.subgroupGuid,
        [string]$setting.settingGuid
    )

    $acMatch = [regex]::Match(
        $queryText,
        'Current AC Power Setting Index:\s+0x([0-9a-fA-F]+)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $dcMatch = [regex]::Match(
        $queryText,
        'Current DC Power Setting Index:\s+0x([0-9a-fA-F]+)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if (-not $acMatch.Success -or -not $dcMatch.Success) {
        throw (
            'powercfg.exe output could not be interpreted. ' +
            'The current Windows display language may not be supported.'
        )
    }

    return [pscustomobject]@{
        AcValue = [Convert]::ToInt32($acMatch.Groups[1].Value, 16)
        DcValue = [Convert]::ToInt32($dcMatch.Groups[1].Value, 16)
    }
}

function Set-QnityPowerSettingState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SettingName,

        [Parameter(Mandatory)]
        [object]$PowerConfiguration,

        [Parameter(Mandatory)]
        [int]$CurrentAcValue,

        [Parameter(Mandatory)]
        [int]$CurrentDcValue,

        [AllowNull()]
        [object]$SimulationData
    )

    $setting = $PowerConfiguration.PSObject.Properties[$SettingName].Value
    $failurePrefix = Get-QnityPowerFailurePrefix -SettingName $SettingName
    $failureCode = "${failurePrefix}_SET"

    if ($null -ne $SimulationData) {
        if (Test-QnitySimulationFailure -SimulationData $SimulationData -FailureCode $failureCode) {
            throw "Simulated $SettingName power-setting update failure."
        }

        $state = $SimulationData.settings.power.PSObject.Properties[$SettingName].Value
        $state.acValue = [int]$setting.acValue
        $state.dcValue = [int]$setting.dcValue
        return
    }

    if ($CurrentAcValue -ne [int]$setting.acValue) {
        [void](Invoke-QnityPowerCfg -Arguments @(
            '/SETACVALUEINDEX',
            [string]$PowerConfiguration.scheme,
            [string]$PowerConfiguration.subgroupGuid,
            [string]$setting.settingGuid,
            [string]$setting.acValue
        ))
    }

    if ($CurrentDcValue -ne [int]$setting.dcValue) {
        [void](Invoke-QnityPowerCfg -Arguments @(
            '/SETDCVALUEINDEX',
            [string]$PowerConfiguration.scheme,
            [string]$PowerConfiguration.subgroupGuid,
            [string]$setting.settingGuid,
            [string]$setting.dcValue
        ))
    }

    [void](Invoke-QnityPowerCfg -Arguments @(
        '/SETACTIVE',
        [string]$PowerConfiguration.scheme
    ))
}

function Invoke-QnityTimeZoneSetting {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [object]$TimeZoneConfiguration,

        [Parameter(Mandatory)]
        [bool]$IsAdministrator,

        [AllowNull()]
        [object]$SimulationData
    )

    $desiredId = [string]$TimeZoneConfiguration.id
    $mode = if ($null -ne $SimulationData) { 'Simulation' } else { 'System' }

    try {
        $currentId = Get-QnityTimeZoneId -SimulationData $SimulationData
    }
    catch {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Error' `
            -Message 'The current time zone could not be read.' `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'TIME_ZONE_QUERY_FAILED'
                CurrentValue = $null
                DesiredValue = $desiredId
            })
    }

    if ($currentId -eq $desiredId) {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Pass' `
            -Message "Time zone is already '$desiredId'." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'ALREADY_COMPLIANT'
                CurrentValue = $currentId
                DesiredValue = $desiredId
            })
    }

    if (-not $IsAdministrator) {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Error' `
            -Message 'Administrator permission is required to change the time zone.' `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'ADMINISTRATOR_REQUIRED'
                CurrentValue = $currentId
                DesiredValue = $desiredId
            })
    }

    if (-not $PSCmdlet.ShouldProcess('Windows time zone', "Set to '$desiredId'")) {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Skipped' `
            -Message "Time-zone change to '$desiredId' was not applied." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'SHOULD_PROCESS_DECLINED'
                CurrentValue = $currentId
                DesiredValue = $desiredId
            })
    }

    try {
        Set-QnityTimeZoneId -Id $desiredId -SimulationData $SimulationData
        $verifiedId = Get-QnityTimeZoneId -SimulationData $SimulationData
    }
    catch {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Error' `
            -Message 'The time-zone change failed and was not bypassed.' `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'TIME_ZONE_UPDATE_FAILED'
                CurrentValue = $currentId
                DesiredValue = $desiredId
            })
    }

    if ($verifiedId -ne $desiredId) {
        return New-QnityResult `
            -CheckCode 'TIME_ZONE_EASTERN' `
            -Status 'Fail' `
            -Message 'The time-zone command completed, but verification did not match the desired value.' `
            -Changed $true `
            -Evidence ([pscustomobject]@{
                Mode         = $mode
                ReasonCode   = 'VERIFICATION_MISMATCH'
                CurrentValue = $verifiedId
                DesiredValue = $desiredId
            })
    }

    return New-QnityResult `
        -CheckCode 'TIME_ZONE_EASTERN' `
        -Status 'Pass' `
        -Message "Time zone was set to '$desiredId' and verified." `
        -Changed $true `
        -Evidence ([pscustomobject]@{
            Mode         = $mode
            ReasonCode   = 'APPLIED_AND_VERIFIED'
            CurrentValue = $verifiedId
            DesiredValue = $desiredId
        })
}

function Invoke-QnityPowerSetting {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [string]$SettingName,

        [Parameter(Mandatory)]
        [string]$CheckCode,

        [Parameter(Mandatory)]
        [string]$DisplayName,

        [Parameter(Mandatory)]
        [object]$PowerConfiguration,

        [Parameter(Mandatory)]
        [bool]$IsAdministrator,

        [AllowNull()]
        [object]$SimulationData
    )

    $mode = if ($null -ne $SimulationData) { 'Simulation' } else { 'System' }
    $setting = $PowerConfiguration.PSObject.Properties[$SettingName].Value
    $desiredAcValue = [int]$setting.acValue
    $desiredDcValue = [int]$setting.dcValue

    try {
        $current = Get-QnityPowerSettingState `
            -SettingName $SettingName `
            -PowerConfiguration $PowerConfiguration `
            -SimulationData $SimulationData
    }
    catch {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Error' `
            -Message "$DisplayName values could not be read." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'POWER_SETTING_QUERY_FAILED'
                CurrentAcValue = $null
                CurrentDcValue = $null
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    if (
        [int]$current.AcValue -eq $desiredAcValue -and
        [int]$current.DcValue -eq $desiredDcValue
    ) {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Pass' `
            -Message "$DisplayName is already configured for AC and battery power." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'ALREADY_COMPLIANT'
                CurrentAcValue = [int]$current.AcValue
                CurrentDcValue = [int]$current.DcValue
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    if (-not $IsAdministrator) {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Error' `
            -Message "Administrator permission is required to change $DisplayName." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'ADMINISTRATOR_REQUIRED'
                CurrentAcValue = [int]$current.AcValue
                CurrentDcValue = [int]$current.DcValue
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    if (-not $PSCmdlet.ShouldProcess('Active Windows power scheme', "Configure $DisplayName")) {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Skipped' `
            -Message "$DisplayName changes were not applied." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'SHOULD_PROCESS_DECLINED'
                CurrentAcValue = [int]$current.AcValue
                CurrentDcValue = [int]$current.DcValue
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    try {
        Set-QnityPowerSettingState `
            -SettingName $SettingName `
            -PowerConfiguration $PowerConfiguration `
            -CurrentAcValue ([int]$current.AcValue) `
            -CurrentDcValue ([int]$current.DcValue) `
            -SimulationData $SimulationData

        $verified = Get-QnityPowerSettingState `
            -SettingName $SettingName `
            -PowerConfiguration $PowerConfiguration `
            -SimulationData $SimulationData
    }
    catch {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Error' `
            -Message "$DisplayName could not be changed and the failure was not bypassed." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'POWER_SETTING_UPDATE_FAILED'
                CurrentAcValue = [int]$current.AcValue
                CurrentDcValue = [int]$current.DcValue
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    if (
        [int]$verified.AcValue -ne $desiredAcValue -or
        [int]$verified.DcValue -ne $desiredDcValue
    ) {
        return New-QnityResult `
            -CheckCode $CheckCode `
            -Status 'Fail' `
            -Message "$DisplayName was changed, but verification did not match the desired values." `
            -Changed $true `
            -Evidence ([pscustomobject]@{
                Mode           = $mode
                ReasonCode     = 'VERIFICATION_MISMATCH'
                CurrentAcValue = [int]$verified.AcValue
                CurrentDcValue = [int]$verified.DcValue
                DesiredAcValue = $desiredAcValue
                DesiredDcValue = $desiredDcValue
            })
    }

    return New-QnityResult `
        -CheckCode $CheckCode `
        -Status 'Pass' `
        -Message "$DisplayName was configured and verified for AC and battery power." `
        -Changed $true `
        -Evidence ([pscustomobject]@{
            Mode           = $mode
            ReasonCode     = 'APPLIED_AND_VERIFIED'
            CurrentAcValue = [int]$verified.AcValue
            CurrentDcValue = [int]$verified.DcValue
            DesiredAcValue = $desiredAcValue
            DesiredDcValue = $desiredDcValue
        })
}

function New-QnityUnsupportedPlatformResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool]$IsSimulation
    )

    $mode = if ($IsSimulation) { 'Simulation' } else { 'System' }
    $definitions = @(
        @{ CheckCode = 'TIME_ZONE_EASTERN'; DisplayName = 'Eastern time zone' },
        @{ CheckCode = 'POWER_LID_CLOSE'; DisplayName = 'Lid-close action' },
        @{ CheckCode = 'POWER_BUTTON'; DisplayName = 'Power-button action' },
        @{ CheckCode = 'POWER_SLEEP_BUTTON'; DisplayName = 'Sleep-button action' }
    )

    $results = @()
    foreach ($definition in $definitions) {
        $results += New-QnityResult `
            -CheckCode $definition.CheckCode `
            -Status 'Skipped' `
            -Message "$($definition.DisplayName) was skipped because the target is not Windows." `
            -Changed $false `
            -Evidence ([pscustomobject]@{
                Mode       = $mode
                ReasonCode = 'UNSUPPORTED_PLATFORM'
            })
    }

    return $results
}

function Get-QnityOverallStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Results
    )

    $statuses = @($Results | ForEach-Object { $_.Status })
    foreach ($candidate in @('Error', 'Fail', 'Skipped', 'Pass')) {
        if ($statuses -contains $candidate) {
            return $candidate
        }
    }

    return 'Error'
}

function Invoke-QnityDeploymentAssistant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AssetTag,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserEmail,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ConfigurationPath,

        [string]$SimulationDataPath,

        [switch]$NonInteractive
    )

    $startedAt = [DateTimeOffset]::UtcNow
    $configuration = Import-QnityConfiguration -Path $ConfigurationPath
    $normalizedAssetTag = Resolve-QnityAssetTag `
        -AssetTag $AssetTag `
        -Configuration $configuration
    $normalizedEmail = Resolve-QnityUserEmail `
        -UserEmail $UserEmail `
        -Configuration $configuration

    $simulationData = $null
    if (-not [string]::IsNullOrWhiteSpace($SimulationDataPath)) {
        $simulationData = Import-QnitySimulationData -Path $SimulationDataPath
    }

    $isSimulation = $null -ne $simulationData
    $isWindows = Test-QnityIsWindows -SimulationData $simulationData
    $results = @()

    if (-not $isWindows) {
        $results = @(New-QnityUnsupportedPlatformResults -IsSimulation $isSimulation)
    }
    else {
        $isAdministrator = Test-QnityIsAdministrator -SimulationData $simulationData
        $results += Invoke-QnityTimeZoneSetting `
            -TimeZoneConfiguration $configuration.deviceSettings.timeZone `
            -IsAdministrator $isAdministrator `
            -SimulationData $simulationData `
            -WhatIf:$WhatIfPreference

        $powerChecks = @(
            @{
                SettingName = 'lidClose'
                CheckCode   = 'POWER_LID_CLOSE'
                DisplayName = 'Lid-close action'
            },
            @{
                SettingName = 'powerButton'
                CheckCode   = 'POWER_BUTTON'
                DisplayName = 'Power-button action'
            },
            @{
                SettingName = 'sleepButton'
                CheckCode   = 'POWER_SLEEP_BUTTON'
                DisplayName = 'Sleep-button action'
            }
        )

        foreach ($powerCheck in $powerChecks) {
            $results += Invoke-QnityPowerSetting `
                -SettingName $powerCheck.SettingName `
                -CheckCode $powerCheck.CheckCode `
                -DisplayName $powerCheck.DisplayName `
                -PowerConfiguration $configuration.deviceSettings.power `
                -IsAdministrator $isAdministrator `
                -SimulationData $simulationData `
                -WhatIf:$WhatIfPreference
        }
    }

    $completedAt = [DateTimeOffset]::UtcNow
    return [pscustomobject][ordered]@{
        RunType                   = 'QnityDeviceConfiguration'
        AgentVersion              = $script:AgentVersion
        ConfigurationVersion      = [string]$configuration.configurationVersion
        AssetTag                  = $normalizedAssetTag
        UserEmail                 = $normalizedEmail
        Simulation                = $isSimulation
        NonInteractive            = [bool]$NonInteractive
        ProductionApprovalRequired = [bool]$configuration.safety.productionApprovalRequired
        StartedAt                 = $startedAt.ToString('o')
        CompletedAt               = $completedAt.ToString('o')
        OverallStatus             = Get-QnityOverallStatus -Results @($results)
        Results                   = @($results)
    }
}

Export-ModuleMember -Function @(
    'Import-QnityConfiguration',
    'Test-QnityAssetTag',
    'Test-QnityUserEmail',
    'Invoke-QnityDeploymentAssistant'
)
