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
.PARAMETER OwnersGroupId / MembersGroupId / ReadOnlyGroupId
    Entra ID object ids of the per-matter security groups (from New-MatterSecurityGroups).
    Bound to the site as Full Control / Edit / Read respectively.
.PARAMETER RetentionLabel   Purview retention label name (applied by Set-MatterMetadata).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SiteUrl,
    [Parameter(Mandatory)] [string]$MatterId,
    [Parameter(Mandatory)] [string]$OwnersGroupId,
    [Parameter(Mandatory)] [string]$MembersGroupId,
    [Parameter(Mandatory)] [string]$ReadOnlyGroupId,
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

# 1) Site columns + content type (validated provisioning XML). Retry: a freshly created site can
#    briefly return transient errors (e.g. "Error while copying content to a stream").
Write-Host "Applying content type to $SiteUrl ..." -ForegroundColor Cyan
$ctApplied = $false
for ($attempt = 1; $attempt -le 5 -and -not $ctApplied; $attempt++) {
    try {
        Invoke-PnPSiteTemplate -Path $ctPath -ErrorAction Stop
        $ctApplied = $true
    } catch {
        if ($attempt -eq 5) { throw }
        Write-Warning "Content type apply attempt $attempt failed ($($_.Exception.Message)); retrying in 15s..."
        Start-Sleep -Seconds 15
        Connect-PnPOnline -Url $SiteUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint
    }
}

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
    # Note: LKOSMatterStatus is NOT set as a library default here — matter status is tracked on the
    # AI registration record and changed via Set-MatterStatus.ps1 (re-runs must not reset it).
    Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSMatterID'     -Value $MatterId
    Set-PnPDefaultColumnValues -List $LibraryTitle -Field 'LKOSAIIndexState' -Value 'Pending'
} catch { Write-Warning "Could not set default column values: $($_.Exception.Message)" }

# 3) AI Registration list.
Write-Host "Configuring '$AiListTitle' list ..." -ForegroundColor Cyan
if (-not (Test-PnPListExists -Title $AiListTitle)) {
    New-PnPList -Title $AiListTitle -Template GenericList | Out-Null
}
foreach ($siteField in 'LKOSMatterID','LKOSAIIndexState','LKOSMatterStatus') {
    try { Add-PnPField -List $AiListTitle -Field $siteField -ErrorAction Stop | Out-Null } catch { }
}
try { Add-PnPField -List $AiListTitle -DisplayName 'Source Site URL' -InternalName 'SourceSiteUrl' -Type URL -ErrorAction Stop | Out-Null } catch { }
try { Add-PnPField -List $AiListTitle -DisplayName 'Registered' -InternalName 'RegisteredDateTime' -Type DateTime -ErrorAction Stop | Out-Null } catch { }

# 4) Least-privilege permissions: bind each per-matter Entra security group directly to a role
#    on the site's root web. Entra groups are referenced via the SharePoint claims login format
#    'c:0t.c|tenant|<groupObjectId>'; New-PnPUser ensures the principal before the role assignment.
Write-Host "Applying least-privilege permissions ..." -ForegroundColor Cyan
$bindings = @(
    [pscustomobject]@{ Label = 'Owners';   Id = $OwnersGroupId;   Role = 'Full Control' },
    [pscustomobject]@{ Label = 'Members';  Id = $MembersGroupId;  Role = 'Edit' },
    [pscustomobject]@{ Label = 'ReadOnly'; Id = $ReadOnlyGroupId; Role = 'Read' }
)
foreach ($b in $bindings) {
    $login = "c:0t.c|tenant|$($b.Id)"
    try {
        New-PnPUser -LoginName $login -ErrorAction Stop | Out-Null
        Set-PnPWebPermission -User $login -AddRole $b.Role -ErrorAction Stop
        Write-Host "  $($b.Label) group -> $($b.Role)" -ForegroundColor Green
    } catch {
        Write-Warning "  Permission bind for $($b.Label) ($($b.Role)) failed: $($_.Exception.Message)"
    }
}

# 5) Confidentiality: restrict external sharing to guests only (no anonymous "anyone" links).
#    External collaborators (co-counsel) are still supported via explicit guest invitations
#    (see Grant-MatterExternalAccess.ps1). Requires SharePoint admin rights; best-effort.
Write-Host "Hardening site sharing (guests only, no anonymous links) ..." -ForegroundColor Cyan
try {
    Connect-PnPOnline -Url $cfg.sharePointAdminUrl -ClientId $cfg.clientId -Tenant $cfg.tenantId -Thumbprint $cfg.certificateThumbprint
    Set-PnPTenantSite -Identity $SiteUrl -SharingCapability ExternalUserSharingOnly -ErrorAction Stop
    try {
        Set-PnPTenantSite -Identity $SiteUrl -DefaultSharingLinkType Direct -DefaultLinkPermission View -ErrorAction Stop
    } catch { Write-Warning "  default link type not tightened: $($_.Exception.Message)" }
    Write-Host "  sharing = ExternalUserSharingOnly (guests allowed, no anonymous)" -ForegroundColor Green
} catch {
    Write-Warning "  Could not set site sharing (needs SharePoint admin rights): $($_.Exception.Message)"
}

Write-Host "Site configuration applied to $SiteUrl." -ForegroundColor Green
return [pscustomobject]@{ SiteUrl = $SiteUrl; Applied = $true }
