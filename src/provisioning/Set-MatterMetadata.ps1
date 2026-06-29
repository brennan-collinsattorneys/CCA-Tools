#requires -Version 7.0
<#
.SYNOPSIS
    Stamps matter identity/metadata onto the matter site and applies the retention label.

.DESCRIPTION
    Sets LKOS site property-bag values, stamps the Matter ID / Client / Matter Name as library
    field defaults, and applies the Purview retention label to the document library. Idempotent.
    Assumes the matter site template has already been applied (New-MatterSite).

.PARAMETER SiteUrl
    The matter site URL.

.PARAMETER MatterId / ClientName / MatterName
    Identity values stamped as defaults / property bag.

.PARAMETER RetentionLabel
    Purview retention label name to apply to the "Matter Documents" library (best-effort).

.PARAMETER LibraryTitle
    Document library title. Default "Matter Documents".
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$ClientName,
    [string]$MatterName = '',
    [string]$RetentionLabel = '',
    [string]$LibraryTitle = 'Matter Documents'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cfg      = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json

if ($PSCmdlet.ShouldProcess($SiteUrl, 'Stamp matter metadata')) {
    Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint

    # Site property bag (queryable identity markers).
    Set-PnPPropertyBagValue -Key 'LKOS_MatterID'    -Value $MatterId   -ErrorAction SilentlyContinue
    Set-PnPPropertyBagValue -Key 'LKOS_ClientName'  -Value $ClientName -ErrorAction SilentlyContinue
    if ($MatterName) { Set-PnPPropertyBagValue -Key 'LKOS_MatterName' -Value $MatterName -ErrorAction SilentlyContinue }

    # Ensure library column defaults reflect this matter.
    try {
        Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterID'   -Value $MatterId
        Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSClientName' -Value $ClientName
        Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterStatus' -Value 'Open'
    } catch {
        Write-Warning "Could not set default column values: $($_.Exception.Message)"
    }

    # Apply Purview retention label to the library (best-effort; tenant must define the label).
    if ($RetentionLabel) {
        try {
            Set-PnPLabel -List $LibraryTitle -Label $RetentionLabel -SyncToItems $true
            Write-Host "Applied retention label '$RetentionLabel' to '$LibraryTitle'." -ForegroundColor Green
        } catch {
            Write-Warning "Retention label '$RetentionLabel' not applied (define it in Purview): $($_.Exception.Message)"
        }
    }

    Write-Host "Metadata stamped on $SiteUrl." -ForegroundColor Green
}

return [pscustomobject]@{ SiteUrl = $SiteUrl; MatterId = $MatterId }
