#requires -Version 7.0
<#
.SYNOPSIS
    Emits the standardized AI registration placeholder for a matter (AI-ready by default).

.DESCRIPTION
    Adds (or updates) a record in the "LKOS AI Registration" list on the matter site so future AI
    services (OCR, metadata extraction, semantic indexing, vector indexing, knowledge graph) can
    discover and index the matter with NO separate "AI upload" process. Idempotent: one record per
    Matter ID.

.PARAMETER SiteUrl
    The matter site URL.

.PARAMETER MatterId
    Firm matter number.

.PARAMETER ListTitle
    AI registration list title. Default "LKOS AI Registration".
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$MatterId,
    [string]$ListTitle = 'LKOS AI Registration'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cfg      = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json

if ($PSCmdlet.ShouldProcess($SiteUrl, "Register AI placeholder for $MatterId")) {
    Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint

    $values = @{
        Title              = $MatterId
        LKOSMatterID       = $MatterId
        LKOSAIIndexState   = 'Pending'
        LKOSMatterStatus   = 'Eval'
        SourceSiteUrl      = $SiteUrl
        RegisteredDateTime = (Get-Date).ToString('o')
    }

    # Idempotency: find an existing record for this Matter ID.
    $existing = $null
    try {
        $camlQuery = "<View><Query><Where><Eq><FieldRef Name='LKOSMatterID'/><Value Type='Text'>$MatterId</Value></Eq></Where></Query></View>"
        $existing  = Get-PnPListItem -List $ListTitle -Query $camlQuery -PageSize 1
    } catch {
        Write-Warning "Could not query '$ListTitle' (will attempt to add): $($_.Exception.Message)"
    }

    if ($existing) {
        # Preserve lifecycle status and index state on re-runs (do NOT reset to Eval/Pending).
        $updateValues = @{ LKOSMatterID = $MatterId; SourceSiteUrl = $SiteUrl }
        Set-PnPListItem -List $ListTitle -Identity $existing.Id -Values $updateValues | Out-Null
        Write-Host "AI registration already present for $MatterId (status preserved)." -ForegroundColor DarkYellow
    } else {
        Add-PnPListItem -List $ListTitle -Values $values | Out-Null
        Write-Host "Registered AI placeholder for $MatterId (AI-ready, status=Eval)." -ForegroundColor Green
    }
}

return [pscustomobject]@{ SiteUrl = $SiteUrl; MatterId = $MatterId; AIIndexState = 'Pending' }
