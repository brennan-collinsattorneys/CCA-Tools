#requires -Version 7.0
<#
.SYNOPSIS
    Creates (or reuses) the standardized Matter Team and its standard channels.

.DESCRIPTION
    Reads templates/teams/matter-team-template.json, applies the matter tokens, creates the Team
    (Microsoft 365 group + connected SharePoint site) and ensures the standardized channel set.
    Idempotent: an existing Team with the same mail nickname is reused and missing channels added.

    Requires an active PnP connection (Connect-LkosTenant) with Team.Create / Group.ReadWrite.All
    / Channel.Create consented.

.PARAMETER MatterDisplayName
    Standardized display name (from New-LkosMatterName).

.PARAMETER MatterId
    Firm matter number.

.PARAMETER ClientName
    Client name (for description).

.PARAMETER MailNickname
    URL/alias-safe nickname (from New-LkosMatterName, e.g. matter-2026-0142).

.PARAMETER TemplatePath
    Path to the Team template JSON.

.OUTPUTS
    [pscustomobject]@{ TeamId; MailNickname; SiteUrl }
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$MatterDisplayName,
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$ClientName,
    [Parameter(Mandatory)] [string]$MailNickname,
    [string]$TemplatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $TemplatePath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $TemplatePath = Join-Path $repoRoot 'templates/teams/matter-team-template.json'
}
if (-not (Test-Path $TemplatePath)) { throw "Team template not found: $TemplatePath" }

$template = Get-Content $TemplatePath -Raw | ConvertFrom-Json
$description = $template.description `
    -replace '\{\{MatterId\}\}', $MatterId `
    -replace '\{\{ClientName\}\}', $ClientName

# --- Idempotency: find existing group by mailNickname ---
$escaped  = $MailNickname.Replace("'", "''")
$existing = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=mailNickname eq '$escaped'" -Method Get
$teamId   = $null

if ($existing.value -and $existing.value.Count -gt 0) {
    $teamId = $existing.value[0].id
    Write-Host "Reusing existing Team/group '$MailNickname' ($teamId)." -ForegroundColor DarkYellow
}
elseif ($PSCmdlet.ShouldProcess($MatterDisplayName, 'Create Matter Team')) {
    $team = New-PnPTeamsTeam -DisplayName $MatterDisplayName -MailNickname $MailNickname `
        -Description $description -Visibility ([string]$template.visibility)
    $teamId = $team.GroupId
    if (-not $teamId) { $teamId = $team.Id }
    Write-Host "Created Team '$MatterDisplayName' ($teamId)." -ForegroundColor Green
}

# --- Ensure standardized channels ---
if ($teamId -and $PSCmdlet.ShouldProcess($MatterDisplayName, 'Ensure standard channels')) {
    $existingChannels = @()
    try { $existingChannels = (Get-PnPTeamsChannel -Team $teamId).DisplayName } catch { $existingChannels = @() }

    foreach ($channel in $template.channels) {
        if ($channel.displayName -eq 'General') { continue }  # created by default
        if ($existingChannels -contains $channel.displayName) { continue }
        try {
            Add-PnPTeamsChannel -Team $teamId -DisplayName $channel.displayName -Description ([string]$channel.description) | Out-Null
            Write-Host "  + channel '$($channel.displayName)'" -ForegroundColor Green
        } catch {
            Write-Warning "  ! channel '$($channel.displayName)' could not be added: $($_.Exception.Message)"
        }
    }
}

# --- Resolve connected SharePoint site URL (provisioning can lag; retry briefly) ---
$siteUrl = $null
for ($i = 0; $i -lt 10 -and -not $siteUrl; $i++) {
    try {
        $grp = Get-PnPMicrosoft365Group -Identity $teamId -IncludeSiteUrl -ErrorAction Stop
        $siteUrl = $grp.SiteUrl
    } catch { }
    if (-not $siteUrl) { Start-Sleep -Seconds 6 }
}
if (-not $siteUrl) { Write-Warning "Team created but connected site URL not yet available; resolve before applying the site template." }

return [pscustomobject]@{
    TeamId       = $teamId
    MailNickname = $MailNickname
    SiteUrl      = $siteUrl
}
