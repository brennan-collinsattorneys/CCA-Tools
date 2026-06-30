#requires -Version 7.0
<#
.SYNOPSIS
    Applies the standardized SharePoint Matter Site configuration to a matter's connected site.

.DESCRIPTION
    Connects to the matter site (app-only) and configures it to the LKOS standard:
      1) Applies matter-content-type.xml (LKOS site columns + "LKOS Matter Document" content type)
         via the PnP provisioning engine (validated, schema-clean).
      2) Builds the rest of the site with PnP cmdlets (more robust than hand-authored site XML):
         - "Matter Documents" library: content type bound + default, versioning, channel folders,
           default column values.
         - "LKOS AI Registration" list (AI-ready marker).
         - Least-privilege permissions: break inheritance and bind the per-matter security groups
           (best-effort; validated/finalized during the US4 pilot).
    All steps are idempotent.

.PARAMETER SiteUrl          The matter's connected SharePoint site URL.
.PARAMETER MatterId         Firm matter number.
.PARAMETER OwnersGroup / MembersGroup / ReadOnlyGroup
    Display names of the per-matter security groups (from New-MatterSecurityGroups).
.PARAMETER RetentionLabel   Purview retention label name (applied by Set-MatterMetadata).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$OwnersGroup,
    [Parameter(Mandatory)] [string]$MembersGroup,
    [Parameter(Mandatory)] [string]$ReadOnlyGroup,
    [string]$RetentionLabel = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$cfg      = Get-Content (Join-Path $repoRoot 'config/lkos-settings.local.json') -Raw | ConvertFrom-Json
$ctPath   = Join-Path $repoRoot 'templates/sharepoint/matter-content-type.xml'
if (-not (Test-Path $ctPath)) { throw "Content type template not found: $ctPath" }

$LibraryTitle = 'Matter Documents'
$AiListTitle  = 'LKOS AI Registration'
$Channels = @('General','Administration','Pleadings','Discovery','Medical Records','Experts',
              'Depositions','Motions','Trial','Settlement','AI Workspace')

function Test-PnPListExists {
    param([string]$Title)
    return [bool](Get-PnPList -Identity $Title -ErrorAction SilentlyContinue)
}

if (-not $PSCmdlet.ShouldProcess($SiteUrl, 'Apply LKOS site configuration')) {
    return [pscustomobject]@{ SiteUrl = $SiteUrl; Applied = $false }
}

Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint

# 1) Site columns + content type (validated provisioning XML).
Write-Host "Applying content type to $SiteUrl ..." -ForegroundColor Cyan
Invoke-PnPSiteTemplate -Path $ctPath

# 2) Matter Documents library.
Write-Host "Configuring '$LibraryTitle' library ..." -ForegroundColor Cyan
if (-not (Test-PnPListExists -Title $LibraryTitle)) {
    New-PnPList -Title $LibraryTitle -Template DocumentLibrary -OnQuickLaunch | Out-Null
}
Set-PnPList -Identity $LibraryTitle -EnableContentTypes $true -EnableVersioning $true -MajorVersions 500 | Out-Null
try { Add-PnPContentTypeToList -List $LibraryTitle -ContentType 'LKOS Matter Document' -DefaultContentType -ErrorAction Stop }
catch { Write-Warning "Could not bind content type: $($_.Exception.Message)" }

# Channel-aligned folders.
foreach ($folder in $Channels) {
    try { Resolve-PnPFolder -SiteRelativePath "$LibraryTitle/$folder" | Out-Null }
    catch { Write-Warning "Folder '$folder' not created: $($_.Exception.Message)" }
}

# Default column values.
try {
    Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterID'     -Value $MatterId
    Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterStatus' -Value 'Open'
    Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSAIIndexState' -Value 'Pending'
} catch { Write-Warning "Could not set default column values: $($_.Exception.Message)" }

# 3) AI Registration list.
Write-Host "Configuring '$AiListTitle' list ..." -ForegroundColor Cyan
if (-not (Test-PnPListExists -Title $AiListTitle)) {
    New-PnPList -Title $AiListTitle -Template GenericList | Out-Null
}
foreach ($siteField in 'LKOSMatterID','LKOSAIIndexState') {
    try { Add-PnPField -List $AiListTitle -Field $siteField -ErrorAction Stop | Out-Null } catch { }
}
try { Add-PnPField -List $AiListTitle -DisplayName 'Source Site URL' -InternalName 'SourceSiteUrl' -Type URL -ErrorAction Stop | Out-Null } catch { }
try { Add-PnPField -List $AiListTitle -DisplayName 'Registered' -InternalName 'RegisteredDateTime' -Type DateTime -ErrorAction Stop | Out-Null } catch { }

# 4) Least-privilege permissions (break inheritance + bind per-matter groups). Best-effort:
#    binding Entra security groups by display name is finalized/validated during the US4 pilot.
Write-Host "Applying least-privilege permissions ..." -ForegroundColor Cyan
try {
    Set-PnPWebPermission -InheritPermissions:$false -ErrorAction SilentlyContinue
    foreach ($pair in @(@{G=$OwnersGroup;R='Full Control'}, @{G=$MembersGroup;R='Edit'}, @{G=$ReadOnlyGroup;R='Read'})) {
        try { Set-PnPWebPermission -Group $pair.G -AddRole $pair.R -ErrorAction Stop }
        catch { Write-Warning "Permission bind for '$($pair.G)' ($($pair.R)) deferred to pilot: $($_.Exception.Message)" }
    }
} catch { Write-Warning "Permission configuration deferred to pilot: $($_.Exception.Message)" }

Write-Host "Site configuration applied to $SiteUrl." -ForegroundColor Green
return [pscustomobject]@{ SiteUrl = $SiteUrl; Applied = $true }
