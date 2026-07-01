#requires -Version 7.0
<#
.SYNOPSIS
    Changes a matter's lifecycle status (Eval / Pre-Litigation / Litigation / Closed).

.DESCRIPTION
    A matter has ONE persistent Team + site; its status is metadata that changes as the matter
    moves through the legal process. This updates the LKOSMatterStatus default on the matter's
    document library and the matter's AI registration record. It does NOT create or delete the
    Team.

    When set to 'Closed', the matter is flagged for archival to the Litigation Knowledge Repository
    (the actual archive/move is handled by the repository/closed-matter migration workflow, not
    here). Requires an active PnP connection (Connect-LkosTenant) or a site connection.

.PARAMETER SiteUrl
    The matter site URL. Provide this or -MatterAlias.

.PARAMETER MatterAlias
    The matter's group mail nickname (e.g. 'matter-2026-0142') to resolve the site URL.

.PARAMETER Status
    New status: Eval | Pre-Litigation | Litigation | Closed.

.PARAMETER LibraryTitle
    Document library title (default 'Matter Documents').

.EXAMPLE
    ./src/provisioning/Set-MatterStatus.ps1 -MatterAlias 'matter-2026-0142' -Status 'Litigation'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SiteUrl,
    [string]$MatterAlias,
    [Parameter(Mandatory)] [ValidateSet('Eval','Pre-Litigation','Litigation','Closed')] [string]$Status,
    [string]$LibraryTitle = 'Matter Documents',
    [string]$AiListTitle  = 'LKOS AI Registration'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cfg      = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json

if (-not $SiteUrl -and -not $MatterAlias) { throw "Provide -SiteUrl or -MatterAlias." }

if (-not $SiteUrl) {
    $esc  = $MatterAlias.Replace("'", "''")
    $resp = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=mailNickname eq '$esc'&`$select=id" -Method Get
    if (-not ($resp -and @($resp.value).Count -gt 0)) { throw "Matter group '$MatterAlias' not found." }
    $grp = Get-PnPMicrosoft365Group -Identity $resp.value[0].id -IncludeSiteUrl
    $SiteUrl = $grp.SiteUrl
}

if (-not $PSCmdlet.ShouldProcess($SiteUrl, "Set matter status to $Status")) { return }

Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint

# Update the library default so new documents inherit the current status.
try { Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterStatus' -Value $Status }
catch { Write-Warning "Could not update library default status: $($_.Exception.Message)" }

# Stamp status on the AI registration record for this matter.
try {
    $item = Get-PnPListItem -List $AiListTitle -PageSize 1 | Select-Object -First 1
    if ($item) { Set-PnPListItem -List $AiListTitle -Identity $item.Id -Values @{ LKOSMatterStatus = $Status } | Out-Null }
} catch { Write-Warning "Could not stamp status on AI registration: $($_.Exception.Message)" }

Write-Host "Matter status set to '$Status' for $SiteUrl." -ForegroundColor Green
if ($Status -eq 'Closed') {
    Write-Host "NOTE: 'Closed' matters are archived to the Litigation Knowledge Repository by the closed-matter workflow (not this script)." -ForegroundColor DarkYellow
}

return [pscustomobject]@{ SiteUrl = $SiteUrl; Status = $Status }
