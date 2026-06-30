#requires -Version 7.0
<#
.SYNOPSIS
    Creates (or reuses) the standardized Matter Team and its standard channels.

.DESCRIPTION
    Reads templates/teams/matter-team-template.json and creates the matter Team using the robust
    app-only pattern: create the Microsoft 365 group WITH an owner bound at creation, enable the
    Team on the group, then ensure the standardized channel set. This avoids the TeamMember API
    (which needs TeamMember.ReadWrite.All); it only requires Group.ReadWrite.All / Channel.Create.

    Idempotent: an existing group with the same mail nickname is reused and missing channels added.
    Requires an active PnP connection (Connect-LkosTenant).

.PARAMETER MatterDisplayName
    Standardized display name (from New-LkosMatterName).
.PARAMETER MatterId
    Firm matter number.
.PARAMETER ClientName
    Client name (for description).
.PARAMETER MailNickname
    URL/alias-safe nickname (from New-LkosMatterName, e.g. matter-2026-0142).
.PARAMETER Owners
    One or more owner UPNs (required for app-only Team creation).
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
    [Parameter(Mandatory)] [string[]]$Owners,
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

function Get-GroupIdByNickname {
    param([string]$Nickname)
    $esc = $Nickname.Replace("'", "''")
    $resp = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=mailNickname eq '$esc'&`$select=id" -Method Get
    if ($resp -and $resp.PSObject.Properties.Name -contains 'value' -and @($resp.value).Count -gt 0) {
        return $resp.value[0].id
    }
    return $null
}

# --- Idempotency: reuse an existing group by mailNickname ---
$teamId = Get-GroupIdByNickname -Nickname $MailNickname

if ($teamId) {
    Write-Host "Reusing existing Team/group '$MailNickname' ($teamId)." -ForegroundColor DarkYellow
}
elseif ($PSCmdlet.ShouldProcess($MatterDisplayName, 'Create Matter Team')) {

    # Resolve owner object id (owners must be bound at group creation for app-only).
    $ownerUpn = $Owners[0]
    $ownerObj = Invoke-PnPGraphMethod -Url "v1.0/users/$ownerUpn`?`$select=id" -Method Get
    $ownerId  = $ownerObj.id
    if (-not $ownerId) { throw "Could not resolve owner '$ownerUpn' to a user object id." }

    # 1) Create the M365 group with the owner bound.
    $groupBody = @{
        displayName         = $MatterDisplayName
        mailNickname        = $MailNickname
        description         = $description
        groupTypes          = @('Unified')
        mailEnabled         = $true
        securityEnabled     = $false
        visibility          = 'Private'
        'owners@odata.bind' = @("https://graph.microsoft.com/v1.0/users/$ownerId")
    }
    $created = Invoke-PnPGraphMethod -Url 'v1.0/groups' -Method Post -Content $groupBody
    $teamId  = $created.id
    Write-Host "Created group '$MatterDisplayName' ($teamId). Enabling Team..." -ForegroundColor Green

    # 2) Enable the Team on the group (retry while the group replicates).
    $teamBody = @{
        memberSettings    = $template.memberSettings
        guestSettings     = $template.guestSettings
        messagingSettings = $template.messagingSettings
        funSettings       = $template.funSettings
    }
    $enabled = $false
    for ($i = 0; $i -lt 15 -and -not $enabled; $i++) {
        try {
            Invoke-PnPGraphMethod -Url "v1.0/groups/$teamId/team" -Method Put -Content $teamBody | Out-Null
            $enabled = $true
        } catch {
            Start-Sleep -Seconds 10
        }
    }
    if (-not $enabled) { throw "Group created but Team enablement did not succeed in time; re-run to reconcile." }
    Write-Host "Team enabled for '$MatterDisplayName'." -ForegroundColor Green
}

# --- Ensure standardized channels (Graph) ---
if ($teamId -and $PSCmdlet.ShouldProcess($MatterDisplayName, 'Ensure standard channels')) {
    $existingChannels = @()
    try {
        $ch = Invoke-PnPGraphMethod -Url "v1.0/teams/$teamId/channels?`$select=displayName" -Method Get
        if ($ch -and $ch.PSObject.Properties.Name -contains 'value') { $existingChannels = @($ch.value.displayName) }
    } catch { $existingChannels = @() }

    foreach ($channel in $template.channels) {
        if ($channel.displayName -eq 'General') { continue }
        if ($existingChannels -contains $channel.displayName) { continue }
        try {
            $body = @{ displayName = $channel.displayName; description = [string]$channel.description }
            Invoke-PnPGraphMethod -Url "v1.0/teams/$teamId/channels" -Method Post -Content $body | Out-Null
            Write-Host "  + channel '$($channel.displayName)'" -ForegroundColor Green
            Start-Sleep -Milliseconds 800
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
