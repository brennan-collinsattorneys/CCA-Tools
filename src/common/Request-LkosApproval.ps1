#requires -Version 7.0
<#
.SYNOPSIS
    Manual-approval checkpoint gate for LKOS automation.

.DESCRIPTION
    Pauses an automation run until a human explicitly approves continuing. Used at the required
    manual-intervention gates: before bulk provisioning, before each conversion batch, and before
    legacy cutover (per spec FR-021).

    Returns $true when approved, $false when declined. Throws on decline only if -ThrowOnDecline
    is set. Every decision is appended to an approval log for an auditable trail.

.PARAMETER Title
    Short name of the gate, e.g. "Bulk Provisioning" or "Legacy Cutover".

.PARAMETER Message
    Description of what will happen if approved.

.PARAMETER ItemCount
    Optional count of items affected (e.g. number of matters), surfaced in the prompt and log.

.PARAMETER AutoApprove
    Non-interactive approval for tested/scripted runs (e.g. CI). Recorded as an auto-approval.

.PARAMETER ThrowOnDecline
    Throw a terminating error if the operator declines (use to hard-stop a pipeline).

.PARAMETER LogPath
    Approval log file. Defaults to <repoRoot>/logs/approvals.log.

.EXAMPLE
    if (-not (./src/common/Request-LkosApproval.ps1 -Title "Bulk Provisioning" -Message "Provision 42 open matters" -ItemCount 42)) { return }
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Title,
    [Parameter(Mandatory)] [string]$Message,
    [int]$ItemCount = -1,
    [switch]$AutoApprove,
    [switch]$ThrowOnDecline,
    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $LogPath) {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $logDir   = Join-Path $repoRoot 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $LogPath  = Join-Path $logDir 'approvals.log'
}

function Write-ApprovalLog {
    param([string]$Decision, [string]$By)
    $line = '{0} | {1} | decision={2} | by={3} | items={4} | {5}' -f `
        (Get-Date -Format o), $Title, $Decision, $By, $ItemCount, $Message
    Add-Content -Path $LogPath -Value $line
}

$banner = @"

================ LKOS MANUAL APPROVAL GATE ================
 Gate    : $Title
 Action  : $Message
$(if ($ItemCount -ge 0) { " Items   : $ItemCount`n" })==========================================================
"@
Write-Host $banner -ForegroundColor Yellow

if ($AutoApprove) {
    Write-Host "AUTO-APPROVED (non-interactive)." -ForegroundColor DarkYellow
    Write-ApprovalLog -Decision 'APPROVED' -By 'auto'
    return $true
}

$response = Read-Host "Type 'APPROVE' to continue, anything else to cancel"
$approved = ($response.Trim().ToUpperInvariant() -eq 'APPROVE')
$who = try { [System.Security.Principal.WindowsIdentity]::GetCurrent().Name } catch { $env:USERNAME }

if ($approved) {
    Write-Host "Approved by $who. Continuing." -ForegroundColor Green
    Write-ApprovalLog -Decision 'APPROVED' -By $who
    return $true
}

Write-Host "Declined. Halting at this gate." -ForegroundColor Red
Write-ApprovalLog -Decision 'DECLINED' -By $who
if ($ThrowOnDecline) { throw "LKOS approval gate '$Title' was declined by $who." }
return $false
