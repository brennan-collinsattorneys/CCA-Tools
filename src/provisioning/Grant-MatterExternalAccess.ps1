#requires -Version 7.0
<#
.SYNOPSIS
    Grants an external collaborator (co-counsel) access to a single matter — both the SharePoint
    site and the Team — via a guest (Azure AD B2B) invitation.

.DESCRIPTION
    Because each matter is its own Microsoft 365 group (Team + connected SharePoint site), adding a
    guest to that group grants the external person BOTH Teams collaboration and SharePoint document
    access, scoped to that matter only.

    Steps:
      1. Invite the external email as a guest (Graph /invitations) if not already present.
      2. Add the guest to the matter's group as a Member (Team + site) or Owner.
    Idempotent: existing guests are reused; existing membership is left as-is. Requires an active
    PnP connection (Connect-LkosTenant) with Group.ReadWrite.All / User.Invite.All consented.

    NOTE: Matter sites are provisioned as guests-allowed / no-anonymous. Guest invitations require
    tenant guest access to be enabled (it is: ExternalUserAndGuestSharing).

.PARAMETER MatterAlias
    The matter's group mail nickname (e.g. 'matter-2026-0142'). Provide this or -TeamId.

.PARAMETER TeamId
    The matter's group/team object id (alternative to -MatterAlias).

.PARAMETER ExternalEmail
    The external collaborator's email address.

.PARAMETER DisplayName
    Optional display name for the invited guest.

.PARAMETER AsOwner
    Add the guest as a group Owner instead of Member.

.EXAMPLE
    ./src/provisioning/Grant-MatterExternalAccess.ps1 -MatterAlias 'matter-2026-0142' -ExternalEmail 'cocounsel@otherfirm.com'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$MatterAlias,
    [string]$TeamId,
    [Parameter(Mandatory)] [string]$ExternalEmail,
    [string]$DisplayName,
    [switch]$AsOwner
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $MatterAlias -and -not $TeamId) { throw "Provide -MatterAlias or -TeamId." }
if (-not $DisplayName) { $DisplayName = $ExternalEmail }

# --- Resolve the matter group ---
if (-not $TeamId) {
    $esc = $MatterAlias.Replace("'", "''")
    $resp = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=mailNickname eq '$esc'&`$select=id,displayName" -Method Get
    if (-not ($resp -and @($resp.value).Count -gt 0)) { throw "Matter group '$MatterAlias' not found." }
    $TeamId = $resp.value[0].id
    Write-Host "Matter group: $($resp.value[0].displayName) ($TeamId)" -ForegroundColor Cyan
}

if (-not $PSCmdlet.ShouldProcess($ExternalEmail, "Grant matter access ($TeamId)")) { return }

# --- 1) Ensure the guest exists (invite if needed) ---
$escMail = $ExternalEmail.Replace("'", "''")
$existing = Invoke-PnPGraphMethod -Url "v1.0/users?`$filter=mail eq '$escMail' or userPrincipalName eq '$escMail'&`$select=id,mail" -Method Get
$guestId = $null
if ($existing -and @($existing.value).Count -gt 0) {
    $guestId = $existing.value[0].id
    Write-Host "Guest already present ($guestId)." -ForegroundColor DarkYellow
} else {
    $invite = @{
        invitedUserEmailAddress = $ExternalEmail
        invitedUserDisplayName  = $DisplayName
        inviteRedirectUrl       = 'https://myapps.microsoft.com'
        sendInvitationMessage   = $true
    }
    $result = Invoke-PnPGraphMethod -Url 'v1.0/invitations' -Method Post -Content $invite
    $guestId = $result.invitedUser.id
    Write-Host "Invited guest $ExternalEmail ($guestId)." -ForegroundColor Green
}

# --- 2) Add the guest to the matter group (Team + site access) ---
$rel = if ($AsOwner) { 'owners' } else { 'members' }
$body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$guestId" }
try {
    Invoke-PnPGraphMethod -Url "v1.0/groups/$TeamId/$rel/`$ref" -Method Post -Content $body | Out-Null
    Write-Host "Added guest to matter as $rel (Team + SharePoint access granted)." -ForegroundColor Green
} catch {
    if ($_.Exception.Message -match 'added object references already exist|One or more added object references') {
        Write-Host "Guest is already a $rel of this matter." -ForegroundColor DarkYellow
    } else { throw }
}

return [pscustomobject]@{ TeamId = $TeamId; GuestId = $guestId; Email = $ExternalEmail; Role = $rel }
