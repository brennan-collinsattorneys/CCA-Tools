#requires -Version 7.0
<#
.SYNOPSIS
    LKOS matter naming-standard helper. Builds, validates, and normalizes matter display names
    and derives URL/alias-safe identifiers, per config/naming-standard.json.

.DESCRIPTION
    Dot-source this file to use its functions:
        . ./src/common/Lkos.Naming.ps1

    Functions:
      - Get-LkosNamingStandard   : loads and caches the naming standard config
      - ConvertTo-LkosSlug       : produces a lowercase URL/alias-safe slug
      - Test-LkosMatterName      : validates raw matter name components
      - New-LkosMatterName       : returns a normalized display name + derived alias/nickname

.NOTES
    Implements the LKOS naming standard: "Matter Number - Client Last Name - Short Description".
#>

Set-StrictMode -Version Latest

function Get-LkosNamingStandard {
    [CmdletBinding()]
    param(
        [string]$ConfigPath
    )
    if (-not $ConfigPath) {
        $repoRoot   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $ConfigPath = Join-Path $repoRoot 'config/naming-standard.json'
    }
    if (-not (Test-Path $ConfigPath)) {
        throw "Naming standard config not found at '$ConfigPath'."
    }
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

function ConvertTo-LkosSlug {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$Value)
    $slug = $Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    return $slug.Trim('-')
}

function ConvertTo-LkosTitleCase {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Value }
    return (Get-Culture).TextInfo.ToTitleCase($Value.ToLowerInvariant())
}

function Format-LkosComponent {
    param([string]$Value, [string]$NormalizeRules)
    $result = $Value
    foreach ($rule in ($NormalizeRules -split ',')) {
        switch ($rule.Trim()) {
            'trim'                { $result = $result.Trim() }
            'collapse-whitespace' { $result = [regex]::Replace($result, '\s+', ' ').Trim() }
            'titlecase'           { $result = ConvertTo-LkosTitleCase $result }
        }
    }
    return $result
}

function Test-LkosMatterName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$MatterNumber,
        [Parameter(Mandatory)] [string]$ClientLastName,
        [Parameter(Mandatory)] [string]$ShortDescription,
        [object]$Standard
    )
    if (-not $Standard) { $Standard = Get-LkosNamingStandard }
    $errors = [System.Collections.Generic.List[string]]::new()

    $map = @{
        MatterNumber     = $MatterNumber
        ClientLastName   = $ClientLastName
        ShortDescription = $ShortDescription
    }
    foreach ($name in $map.Keys) {
        $spec  = $Standard.components.$name
        $value = Format-LkosComponent -Value $map[$name] -NormalizeRules ($spec.normalize ?? '')
        if ($spec.required -and [string]::IsNullOrWhiteSpace($value)) {
            $errors.Add("$name is required.")
            continue
        }
        if ($spec.PSObject.Properties.Name -contains 'validationRegex' -and $value -notmatch $spec.validationRegex) {
            $errors.Add("$name '$value' does not match the required pattern.")
        }
        if ($spec.PSObject.Properties.Name -contains 'maxLength' -and $value.Length -gt $spec.maxLength) {
            $errors.Add("$name exceeds max length of $($spec.maxLength).")
        }
    }
    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors  = $errors
    }
}

function New-LkosMatterName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$MatterNumber,
        [Parameter(Mandatory)] [string]$ClientLastName,
        [Parameter(Mandatory)] [string]$ShortDescription
    )
    $standard = Get-LkosNamingStandard

    $validation = Test-LkosMatterName -MatterNumber $MatterNumber -ClientLastName $ClientLastName `
        -ShortDescription $ShortDescription -Standard $standard
    if (-not $validation.IsValid) {
        throw "Invalid matter name components:`n - $($validation.Errors -join "`n - ")"
    }

    $num   = Format-LkosComponent -Value $MatterNumber     -NormalizeRules $standard.components.MatterNumber.normalize
    $last  = Format-LkosComponent -Value $ClientLastName   -NormalizeRules $standard.components.ClientLastName.normalize
    $desc  = Format-LkosComponent -Value $ShortDescription -NormalizeRules $standard.components.ShortDescription.normalize

    $displayName = $standard.displayNamePattern `
        -replace '\{MatterNumber\}', $num `
        -replace '\{ClientLastName\}', $last `
        -replace '\{ShortDescription\}', $desc

    foreach ($ch in $standard.constraints.forbiddenCharacters) {
        $displayName = $displayName.Replace($ch, '')
    }
    if ($standard.constraints.collapseWhitespace) {
        $displayName = [regex]::Replace($displayName, '\s+', ' ').Trim()
    }
    if ($displayName.Length -gt $standard.constraints.maxDisplayNameLength) {
        $displayName = $displayName.Substring(0, $standard.constraints.maxDisplayNameLength).Trim()
    }

    $slug = ConvertTo-LkosSlug $num
    return [pscustomobject]@{
        DisplayName   = $displayName
        MatterNumber  = $num
        ClientLastName = $last
        ShortDescription = $desc
        SiteAlias     = $standard.derived.siteAliasPattern    -replace '\{MatterNumberSlug\}', $slug
        MailNickname  = $standard.derived.mailNicknamePattern -replace '\{MatterNumberSlug\}', $slug
    }
}
