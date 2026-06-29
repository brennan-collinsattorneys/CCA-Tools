#requires -Version 7.0
<#
.SYNOPSIS
    Applies the standardized SharePoint Matter Site configuration to a matter's connected site.

.DESCRIPTION
    Connects to the matter site (app-only) and applies, in order:
      1) matter-content-type.xml  (LKOS site columns + content type)
      2) matter-site-template.xml (library, folders, AI list, permissions, versioning, retention)
    Invoke-PnPSiteTemplate is idempotent and safe to re-run.

    Connection values are read from config/lkos-settings.local.json so this script can target the
    specific site (a different URL than the tenant root).

.PARAMETER SiteUrl
    The matter's connected SharePoint site URL.

.PARAMETER MatterId
    Firm matter number (template parameter).

.PARAMETER OwnersGroup / MembersGroup / ReadOnlyGroup
    Display names of the per-matter security groups (from New-MatterSecurityGroups).

.PARAMETER RetentionLabel
    Purview retention label name to record on the library.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$OwnersGroup,
    [Parameter(Mandatory)] [string]$MembersGroup,
    [Parameter(Mandatory)] [string]$ReadOnlyGroup,
    [string]$RetentionLabel = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cfg        = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json
$ctPath     = Join-Path $repoRoot 'templates/sharepoint/matter-content-type.xml'
$sitePath   = Join-Path $repoRoot 'templates/sharepoint/matter-site-template.xml'

foreach ($p in $ctPath, $sitePath) { if (-not (Test-Path $p)) { throw "Template not found: $p" } }

if ($PSCmdlet.ShouldProcess($SiteUrl, 'Apply LKOS site templates')) {
    # Connect to the specific matter site (app-only certificate).
    Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint

    Write-Host "Applying content type to $SiteUrl ..." -ForegroundColor Cyan
    Invoke-PnPSiteTemplate -Path $ctPath

    Write-Host "Applying matter site template to $SiteUrl ..." -ForegroundColor Cyan
    Invoke-PnPSiteTemplate -Path $sitePath -Parameters @{
        MatterId       = $MatterId
        OwnersGroup    = $OwnersGroup
        MembersGroup   = $MembersGroup
        ReadOnlyGroup  = $ReadOnlyGroup
        RetentionLabel = $RetentionLabel
    }

    Write-Host "Site template applied." -ForegroundColor Green
}

return [pscustomobject]@{ SiteUrl = $SiteUrl; Applied = $true }
