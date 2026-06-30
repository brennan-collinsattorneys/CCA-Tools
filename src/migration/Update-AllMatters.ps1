#requires -Version 7.0
<#
.SYNOPSIS
    Re-applies the current LKOS template to existing matters (additive, in-place reconcile).

.DESCRIPTION
    Pushes additive template changes firm-wide: for each existing matter it ensures the standard
    Team channels and re-applies the standard SharePoint site configuration (content type,
    document library, channel folders, AI registration list, metadata defaults, and least-privilege
    permissions). It only ADDS what is missing — it never renames or deletes existing channels,
    columns, libraries, or content. Idempotent and safe to re-run.

    Matters to update are discovered from Microsoft 365 groups whose mail nickname matches the LKOS
    matter alias prefix (default 'matter-'), or you can pass an explicit -MatterAlias list. A manual
    approval gate runs first because this touches every matter.

    NOTE: This is the in-place "update existing matters to current template" capability. It does
    NOT migrate/restructure existing documents and cannot apply rename/removal changes (those
    require deliberate one-off migrations). Connect is handled internally (app-only).

.PARAMETER MatterAlias
    Optional explicit list of matter aliases (mail nicknames, e.g. 'matter-2026-0142'). When
    omitted, all matters with the alias prefix are discovered and updated.

.PARAMETER IncludeTestMatters
    Include matters whose alias contains 'test' (excluded by default).

.PARAMETER AutoApprove
    Skip the interactive approval gate (for scheduled/non-interactive runs).

.EXAMPLE
    ./src/migration/Update-AllMatters.ps1            # reconcile every matter (with approval)
.EXAMPLE
    ./src/migration/Update-AllMatters.ps1 -MatterAlias 'matter-2026-0142' -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$MatterAlias,
    [switch]$IncludeTestMatters,
    [switch]$AutoApprove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here     = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $here)
$common   = Join-Path $repoRoot 'src/common'
$prov     = Join-Path $repoRoot 'src/provisioning'

$local = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json
$base  = Get-Content (Join-Path $repoRoot 'config/lkos-settings.json')       -Raw | ConvertFrom-Json

$groupPattern = $base.groups.namingPattern
$defaultOwner = if ($local.PSObject.Properties.Name -contains 'defaultTeamOwnerUpn') { [string]$local.defaultTeamOwnerUpn } else { '' }
$aliasPrefix  = 'matter-'   # from config/naming-standard.json derived.siteAliasPattern

function Get-GroupIdByDisplayName {
    param([string]$DisplayName)
    $esc  = $DisplayName.Replace("'", "''")
    $resp = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=displayName eq '$esc'&`$select=id" -Method Get
    if ($resp -and $resp.PSObject.Properties.Name -contains 'value' -and @($resp.value).Count -gt 0) { return $resp.value[0].id }
    return $null
}

function Get-MatterIdFromSite {
    param([string]$SiteUrl)
    try {
        Connect-PnPOnline -Url $SiteUrl -ClientId $local.clientId -Tenant $local.tenantId -Thumbprint $local.certificateThumbprint
        $item = Get-PnPListItem -List 'LKOS AI Registration' -PageSize 1 -ErrorAction Stop | Select-Object -First 1
        if ($item) { return [string]$item.FieldValues['LKOSMatterID'] }
    } catch { }
    return $null
}

# --- Connect ---
& (Join-Path $common 'Connect-LkosTenant.ps1') -Mode AppOnly | Out-Null

# --- Discover matters ---
Write-Host "Discovering provisioned matters..." -ForegroundColor Cyan
$matters = @()
$resp = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=startswith(mailNickname,'$aliasPrefix')&`$select=id,displayName,mailNickname" -Method Get
foreach ($g in @($resp.value)) {
    if ($MatterAlias -and ($g.mailNickname -notin $MatterAlias)) { continue }
    if (-not $IncludeTestMatters -and $g.mailNickname -like '*test*') { continue }
    $matters += $g
}
Write-Host "Found $($matters.Count) matter(s) to reconcile." -ForegroundColor Cyan
if ($matters.Count -eq 0) { return }

# --- Manual approval gate (touches every matter) ---
$approved = & (Join-Path $common 'Request-LkosApproval.ps1') `
    -Title 'Update All Matters to Current Template' `
    -Message 'Re-apply the current LKOS template (additive) to the matters listed above.' `
    -ItemCount $matters.Count -AutoApprove:$AutoApprove
if (-not $approved) { Write-Host 'Update cancelled at approval gate.' -ForegroundColor Yellow; return }

# --- Reconcile each matter ---
$results = [System.Collections.Generic.List[object]]::new()
foreach ($g in $matters) {
    Write-Host "`n=== Reconciling $($g.displayName) ===" -ForegroundColor Cyan
    $status = 'OK'
    try {
        $grp     = Get-PnPMicrosoft365Group -Identity $g.id -IncludeSiteUrl -ErrorAction Stop
        $siteUrl = $grp.SiteUrl
        if (-not $siteUrl) { throw "connected site URL not available" }

        $matterId = Get-MatterIdFromSite -SiteUrl $siteUrl
        if (-not $matterId) { $matterId = ($g.mailNickname -replace "^$aliasPrefix", '') }

        if ($PSCmdlet.ShouldProcess($g.displayName, 'Ensure standard channels')) {
            & (Join-Path $prov 'New-MatterTeam.ps1') -MatterDisplayName $g.displayName -MatterId $matterId `
                -ClientName $g.displayName -MailNickname $g.mailNickname -Owners @($defaultOwner) | Out-Null
        }

        # Resolve the per-matter security groups for the permission re-bind.
        $ownersId   = Get-GroupIdByDisplayName -DisplayName ($groupPattern -replace '\{MatterID\}', $matterId -replace '\{Role\}', 'Owners')
        $membersId  = Get-GroupIdByDisplayName -DisplayName ($groupPattern -replace '\{MatterID\}', $matterId -replace '\{Role\}', 'Members')
        $readOnlyId = Get-GroupIdByDisplayName -DisplayName ($groupPattern -replace '\{MatterID\}', $matterId -replace '\{Role\}', 'ReadOnly')

        if ($ownersId -and $membersId -and $readOnlyId) {
            if ($PSCmdlet.ShouldProcess($siteUrl, 'Re-apply site template')) {
                & (Join-Path $prov 'New-MatterSite.ps1') -SiteUrl $siteUrl -MatterId $matterId `
                    -OwnersGroupId $ownersId -MembersGroupId $membersId -ReadOnlyGroupId $readOnlyId | Out-Null
            }
        } else {
            $status = 'PARTIAL: security groups not found; site reconcile skipped'
            Write-Warning $status
        }
    } catch {
        $status = "FAILED: $($_.Exception.Message)"
        Write-Warning $status
    }
    $results.Add([pscustomobject]@{ Matter = $g.displayName; Status = $status })
}

Write-Host "`n==== Update summary ====" -ForegroundColor Green
$results | Format-Table -AutoSize | Out-String | Write-Host
return $results
