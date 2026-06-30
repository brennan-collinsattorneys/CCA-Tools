#requires -Version 7.0
<#
.SYNOPSIS
    One-click LKOS matter provisioning: Team + SharePoint site + security groups + metadata +
    AI registration placeholder, in a single workflow.

.DESCRIPTION
    Orchestrates the standardized provisioning per contracts/provisioning-contract.md:
      1. Resolve the standardized name (Lkos.Naming).
      2. Connect to the tenant (app-only certificate).
      3. Create least-privilege security groups (New-MatterSecurityGroups).
      4. Create the Team + standard channels (New-MatterTeam) and resolve the connected site.
      5. Apply the SharePoint site template (New-MatterSite): library, folders, permissions,
         versioning, retention.
      6. Stamp metadata + retention label (Set-MatterMetadata).
      7. Register the AI placeholder (Register-MatterAIPlaceholder) — matter is AI-ready.

    Idempotent: re-running for an existing Matter ID reuses the Team/groups/site and reconciles
    to the standard configuration rather than creating duplicates. Each step is wrapped so a
    failure reports which stage failed without leaving silent partial state.

.PARAMETER MatterId
    Firm matter number (e.g. "2026-0142").

.PARAMETER ClientLastName
    Client last name (for the naming standard).

.PARAMETER ShortDescription
    Brief matter descriptor (for the naming standard).

.PARAMETER ClientName
    Full client name for metadata/description. Defaults to ClientLastName.

.PARAMETER LeadAttorney
    Optional lead attorney UPN (recorded; group membership handled separately).

.EXAMPLE
    ./src/provisioning/New-MatterWorkspace.ps1 -MatterId "2026-0142" -ClientLastName "Nguyen" -ShortDescription "MVA Personal Injury"

.EXAMPLE
    ./src/provisioning/New-MatterWorkspace.ps1 -MatterId "TEST-0001" -ClientLastName "Test" -ShortDescription "Pipeline Validation" -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$ClientLastName,
    [Parameter(Mandatory)] [string]$ShortDescription,
    [string]$ClientName,
    [string]$LeadAttorney
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ClientName) { $ClientName = $ClientLastName }

$here     = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $here)
$common   = Join-Path $repoRoot 'src/common'

# --- Load config ---
$localCfgPath = Join-Path $repoRoot 'config/lkos-settings.local.json'
$baseCfgPath  = Join-Path $repoRoot 'config/lkos-settings.json'
if (-not (Test-Path $localCfgPath)) { throw "Missing config/lkos-settings.local.json (see docs/auth-setup.md)." }
$local = Get-Content $localCfgPath -Raw | ConvertFrom-Json
$base  = Get-Content $baseCfgPath  -Raw | ConvertFrom-Json

$groupPattern   = $base.groups.namingPattern
$retentionLabel = ''
if ($base.retention.PSObject.Properties.Name -contains 'matterRetentionLabelId') {
    $retentionLabel = [string]$base.retention.matterRetentionLabelId
}
# Treat unfilled placeholders (e.g. "<retention-label-id>") as not configured.
if ($retentionLabel -like '<*>') { $retentionLabel = '' }

# App-only Team creation requires an owner. Use the LeadAttorney if supplied, otherwise the
# tenant's default provisioning owner from config/lkos-settings.local.json.
$defaultOwner = $null
if ($local.PSObject.Properties.Name -contains 'defaultTeamOwnerUpn') { $defaultOwner = [string]$local.defaultTeamOwnerUpn }
$teamOwner = if ($LeadAttorney) { $LeadAttorney } else { $defaultOwner }
if ([string]::IsNullOrWhiteSpace($teamOwner) -or $teamOwner -like '<*>') {
    throw "No Team owner available. Provide -LeadAttorney <upn> or set 'defaultTeamOwnerUpn' in config/lkos-settings.local.json (app-only Team creation requires an owner)."
}

# --- Resolve standardized naming ---
. (Join-Path $common 'Lkos.Naming.ps1')
$name = New-LkosMatterName -MatterNumber $MatterId -ClientLastName $ClientLastName -ShortDescription $ShortDescription

Write-Host "==== Provisioning matter: $($name.DisplayName) ====" -ForegroundColor Cyan

$summary = [ordered]@{
    MatterId     = $MatterId
    DisplayName  = $name.DisplayName
    MailNickname = $name.MailNickname
    Steps        = [ordered]@{}
}

function Invoke-Stage {
    param([string]$StageName, [scriptblock]$Action)
    Write-Host "-- $StageName --" -ForegroundColor Cyan
    try {
        $out = & $Action
        $summary.Steps[$StageName] = 'OK'
        return $out
    } catch {
        $summary.Steps[$StageName] = "FAILED: $($_.Exception.Message)"
        Write-Host "Stage '$StageName' failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "--- stack ---" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        throw
    }
}

if (-not $PSCmdlet.ShouldProcess($name.DisplayName, 'Provision full matter workspace')) {
    Write-Host "[WhatIf] Would provision groups, Team, site, metadata, and AI placeholder for $($name.DisplayName)." -ForegroundColor Yellow
    return [pscustomobject]$summary
}

# --- Connect (app-only) ---
Invoke-Stage 'Connect' {
    & (Join-Path $common 'Connect-LkosTenant.ps1') -Mode AppOnly
}

# --- Security groups ---
$groups = Invoke-Stage 'SecurityGroups' {
    & (Join-Path $here 'New-MatterSecurityGroups.ps1') -MatterId $MatterId -NamingPattern $groupPattern
}

# --- Team + channels ---
$team = Invoke-Stage 'Team' {
    & (Join-Path $here 'New-MatterTeam.ps1') -MatterDisplayName $name.DisplayName -MatterId $MatterId `
        -ClientName $ClientName -MailNickname $name.MailNickname -Owners @($teamOwner)
}
if (-not $team.SiteUrl) { throw "Connected site URL not resolved; cannot apply site template yet. Re-run to reconcile." }
$summary.SiteUrl = $team.SiteUrl
$summary.TeamId  = $team.TeamId

# --- Site template ---
Invoke-Stage 'Site' {
    & (Join-Path $here 'New-MatterSite.ps1') -SiteUrl $team.SiteUrl -MatterId $MatterId `
        -OwnersGroupId $groups['Owners'].Id -MembersGroupId $groups['Members'].Id `
        -ReadOnlyGroupId $groups['ReadOnly'].Id -RetentionLabel $retentionLabel
}

# --- Metadata + retention ---
Invoke-Stage 'Metadata' {
    & (Join-Path $here 'Set-MatterMetadata.ps1') -SiteUrl $team.SiteUrl -MatterId $MatterId `
        -ClientName $ClientName -MatterName $name.DisplayName -RetentionLabel $retentionLabel
}

# --- AI registration placeholder ---
Invoke-Stage 'AIRegistration' {
    & (Join-Path $here 'Register-MatterAIPlaceholder.ps1') -SiteUrl $team.SiteUrl -MatterId $MatterId
}

Write-Host "==== Provisioning complete: $($name.DisplayName) ====" -ForegroundColor Green
Write-Host "   Site: $($team.SiteUrl)" -ForegroundColor Green
return [pscustomobject]$summary
