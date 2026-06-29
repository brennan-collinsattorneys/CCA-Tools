#requires -Version 7.0
<#
.SYNOPSIS
    Connects to Microsoft Graph and SharePoint (PnP) using the LKOS Entra ID app registration.

.DESCRIPTION
    Reads credentials from config/lkos-settings.local.json and establishes connections in one of
    two modes:
      - Interactive : delegated sign-in (used for manual checkpoints and pilot runs)
      - AppOnly     : certificate-based app-only auth (used for unattended bulk runs)

    No secrets are stored in this repo; the certificate lives in Cert:\CurrentUser\My and is
    referenced by thumbprint.

.PARAMETER Mode
    Interactive (default) or AppOnly.

.PARAMETER SiteUrl
    Optional SharePoint site URL to connect to. Defaults to the tenant root from settings.

.EXAMPLE
    ./src/common/Connect-LkosTenant.ps1 -Mode Interactive
.EXAMPLE
    ./src/common/Connect-LkosTenant.ps1 -Mode AppOnly -SiteUrl "https://contoso.sharepoint.com/sites/Matter-2026-0142"
#>
[CmdletBinding()]
param(
    [ValidateSet('Interactive', 'AppOnly')]
    [string]$Mode = 'Interactive',
    [string]$SiteUrl
)

$ErrorActionPreference = 'Stop'

$repoRoot     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$localPath    = Join-Path $repoRoot 'config/lkos-settings.local.json'
$samplePath   = Join-Path $repoRoot 'config/lkos-settings.local.sample.json'

if (-not (Test-Path $localPath)) {
    throw "Missing config/lkos-settings.local.json. Copy '$samplePath' to '$localPath' and fill in real values (see docs/auth-setup.md)."
}

$cfg = Get-Content $localPath -Raw | ConvertFrom-Json

foreach ($required in 'tenantId', 'clientId') {
    if ([string]::IsNullOrWhiteSpace($cfg.$required)) {
        throw "config/lkos-settings.local.json is missing required value: $required"
    }
}

if (-not $SiteUrl) { $SiteUrl = $cfg.sharePointRootUrl }

Write-Host "Connecting to LKOS tenant ($Mode mode)..." -ForegroundColor Cyan

switch ($Mode) {
    'Interactive' {
        Connect-MgGraph -ClientId $cfg.clientId -TenantId $cfg.tenantId -NoWelcome
        Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $cfg.clientId
    }
    'AppOnly' {
        if ([string]::IsNullOrWhiteSpace($cfg.certificateThumbprint)) {
            throw "AppOnly mode requires 'certificateThumbprint' in config/lkos-settings.local.json."
        }
        Connect-MgGraph -ClientId $cfg.clientId -TenantId $cfg.tenantId -CertificateThumbprint $cfg.certificateThumbprint -NoWelcome
        Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint
    }
}

Write-Host "Connected to Graph and SharePoint ($SiteUrl)." -ForegroundColor Green
