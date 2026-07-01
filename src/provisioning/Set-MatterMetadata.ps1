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

    # Ensure library column defaults reflect this matter (idempotent; primary identity stamping).
    try {
        # Status is managed on the AI registration record (Set-MatterStatus.ps1), not reset here.
        Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterID'   -Value $MatterId
        Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSClientName' -Value $ClientName
    } catch {
        Write-Warning "Could not set default column values: $($_.Exception.Message)"
    }

    # Apply Purview retention label to the library (best-effort; tenant must define the label).
    # Skip unconfigured/placeholder values to avoid stalling on a non-existent label.
    if ($RetentionLabel -and $RetentionLabel -notlike '<*>') {
        try {
            Set-PnPLabel -List $LibraryTitle -Label $RetentionLabel -SyncToItems $false
            Write-Host "Applied retention label '$RetentionLabel' to '$LibraryTitle'." -ForegroundColor Green
        } catch {
            Write-Warning "Retention label '$RetentionLabel' not applied (define it in Purview): $($_.Exception.Message)"
        }
    } else {
        Write-Host "No retention label configured (set config retention.matterRetentionLabelId); skipping." -ForegroundColor DarkYellow
    }

    Write-Host "Metadata stamped on $SiteUrl." -ForegroundColor Green
}

return [pscustomobject]@{ SiteUrl = $SiteUrl; MatterId = $MatterId }
