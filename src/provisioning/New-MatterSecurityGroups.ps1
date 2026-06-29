#requires -Version 7.0
<#
.SYNOPSIS
    Creates (or reuses) the least-privilege Entra ID security groups for a matter.

.DESCRIPTION
    For each role (Owners, Members, ReadOnly) creates an Entra ID security group named per the
    pattern in config/lkos-settings.json (default: LKOS-Matter-{MatterID}-{Role}). Idempotent:
    an existing group with the same display name is reused, not duplicated.

    Requires an active PnP connection (Connect-LkosTenant) with Group.ReadWrite.All consented.
    Uses Invoke-PnPGraphMethod so no separate Microsoft.Graph module is required.

.PARAMETER MatterId
    Firm matter number.

.PARAMETER NamingPattern
    Group naming pattern with {MatterID} and {Role} tokens.

.PARAMETER Roles
    Role names to create. Default: Owners, Members, ReadOnly.

.OUTPUTS
    Hashtable: Role -> [pscustomobject]@{ Id; DisplayName }
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$MatterId,
    [string]$NamingPattern = 'LKOS-Matter-{MatterID}-{Role}',
    [string[]]$Roles = @('Owners', 'Members', 'ReadOnly')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-GroupName {
    param([string]$Role)
    return ($NamingPattern -replace '\{MatterID\}', $MatterId -replace '\{Role\}', $Role)
}

$result = @{}

foreach ($role in $Roles) {
    $displayName = Resolve-GroupName -Role $role
    $mailNickname = ($displayName.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')

    # Idempotency: look for an existing security group by display name.
    $escaped  = $displayName.Replace("'", "''")
    $existing = Invoke-PnPGraphMethod -Url "v1.0/groups?`$filter=displayName eq '$escaped'" -Method Get

    if ($existing.value -and $existing.value.Count -gt 0) {
        $grp = $existing.value[0]
        Write-Host "Reusing security group '$displayName' ($($grp.id))." -ForegroundColor DarkYellow
        $result[$role] = [pscustomobject]@{ Id = $grp.id; DisplayName = $displayName }
        continue
    }

    if ($PSCmdlet.ShouldProcess($displayName, 'Create Entra ID security group')) {
        $body = @{
            displayName     = $displayName
            mailEnabled     = $false
            mailNickname    = $mailNickname
            securityEnabled = $true
            description     = "LKOS $role access for matter $MatterId."
        }
        $created = Invoke-PnPGraphMethod -Url 'v1.0/groups' -Method Post -Content $body
        Write-Host "Created security group '$displayName' ($($created.id))." -ForegroundColor Green
        $result[$role] = [pscustomobject]@{ Id = $created.id; DisplayName = $displayName }
    }
}

return $result
