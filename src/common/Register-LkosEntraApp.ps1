#requires -Version 7.0
<#
.SYNOPSIS
    Registers the LKOS Entra ID app registration and a self-signed certificate for automation.

.DESCRIPTION
    Creates (or reuses) an Entra ID app registration used by LKOS local automation, generates a
    self-signed certificate in Cert:\CurrentUser\My, uploads the public key to the app, and prints
    the Tenant ID, Application (client) ID, and certificate thumbprint to record in
    config/lkos-settings.local.json.

    Admin consent for the required API permissions must be granted separately by a Global /
    Privileged Role Administrator (see docs/auth-setup.md, Step 2).

.PARAMETER ApplicationName
    Display name for the app registration. Default: LKOS-Provisioning.

.PARAMETER TenantDomain
    The tenant primary domain, e.g. contoso.onmicrosoft.com.

.EXAMPLE
    ./src/common/Register-LkosEntraApp.ps1 -TenantDomain "collinsattorneys.onmicrosoft.com"
#>
[CmdletBinding()]
param(
    [string]$ApplicationName = "LKOS-Provisioning",
    [Parameter(Mandatory)] [string]$TenantDomain,
    # Use device-code sign-in (prints a URL + code) instead of launching a browser.
    [switch]$DeviceLogin
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell is not installed. Run: Install-Module PnP.PowerShell -Scope CurrentUser"
}

Write-Host "Registering Entra ID app '$ApplicationName' in tenant '$TenantDomain'..." -ForegroundColor Cyan

# Register-PnPEntraIDApp (PnP.PowerShell 3.x) creates the app, a self-signed cert in
# Cert:\CurrentUser\My, and uploads the public key. Sign-in is interactive (browser by default,
# or device code via -DeviceLogin). Adjust permissions to match config/lkos-settings.json
# (prefer Sites.Selected for least privilege where feasible).
$registerArgs = @{
    ApplicationName               = $ApplicationName
    Tenant                        = $TenantDomain
    Store                         = 'CurrentUser'
    GraphApplicationPermissions   = @(
        'Group.ReadWrite.All',
        'Directory.ReadWrite.All',
        'GroupMember.ReadWrite.All',
        'Team.Create',
        'Channel.Create',
        'TeamSettings.ReadWrite.All',
        'Sites.FullControl.All'
    )
    SharePointApplicationPermissions = @('Sites.FullControl.All')
}
if ($DeviceLogin) { $registerArgs['DeviceLogin'] = $true }

$result = Register-PnPEntraIDApp @registerArgs

Write-Host "`nApp registration complete. Record these in config/lkos-settings.local.json:" -ForegroundColor Green
$result | Format-List

Write-Host "`nNext: a Global/Privileged Role Administrator must grant admin consent (docs/auth-setup.md Step 2)." -ForegroundColor Yellow
