#requires -Version 7.0
<#
.SYNOPSIS
    Reads and validates the PM matter inventory and returns the validated set (Open by default).

.DESCRIPTION
    The matter inventory is the authoritative source for migration and bulk provisioning. This
    importer reads a .csv (native) or .xlsx (requires ImportExcel), validates it, and returns
    normalized matter objects. By default it returns only Open matters (the Sprint 0 scope).

    Validation:
      - Required columns present.
      - Each row has a valid Status (Prospective | Open | Closed). "Intake" is normalized to
        Prospective.
      - Matter ID is non-empty and unique (duplicates reported).
    On any validation error the function throws (so downstream bulk provisioning will not run on
    bad data) unless -ReportOnly is specified.

    Each returned object is enriched with ClientLastName and ShortDescription (explicit columns if
    present, otherwise derived) so it can feed New-MatterWorkspace directly.

.PARAMETER InventoryPath
    Path to the inventory file (.csv or .xlsx). Defaults to inventory/matter-inventory.xlsx, then
    inventory/matter-inventory.csv.

.PARAMETER Status
    Status filter for the returned set. Default 'Open'.

.PARAMETER All
    Return all matters (ignore the Status filter).

.PARAMETER ReportOnly
    Print the validation summary and return nothing; do not throw on validation errors.

.OUTPUTS
    Normalized matter objects: MatterId, MatterName, ClientName, ClientLastName, ShortDescription,
    Status, LeadAttorney, AssignedStaff, ExistingTeamsChannel, ExistingFileLocations,
    ExistingSharePointLocation.
#>
[CmdletBinding()]
param(
    [string]$InventoryPath,
    [ValidateSet('Prospective','Open','Closed')]
    [string]$Status = 'Open',
    [switch]$All,
    [switch]$ReportOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if (-not $InventoryPath) {
    foreach ($candidate in 'inventory/matter-inventory.xlsx','inventory/matter-inventory.csv') {
        $p = Join-Path $repoRoot $candidate
        if (Test-Path $p) { $InventoryPath = $p; break }
    }
}
if (-not $InventoryPath -or -not (Test-Path $InventoryPath)) {
    throw "Inventory file not found. Provide -InventoryPath, or create inventory/matter-inventory.xlsx (copy the template)."
}

# --- Load rows ---
$ext = [System.IO.Path]::GetExtension($InventoryPath).ToLowerInvariant()
switch ($ext) {
    '.csv'  { $rows = @(Import-Csv -Path $InventoryPath) }
    '.xlsx' {
        if (-not (Get-Module -ListAvailable ImportExcel)) {
            throw "Reading .xlsx requires ImportExcel (Install-Module ImportExcel -Scope CurrentUser), or export the inventory to .csv."
        }
        Import-Module ImportExcel
        $rows = @(Import-Excel -Path $InventoryPath -WorksheetName 'Matters')
    }
    default { throw "Unsupported inventory format '$ext'. Use .csv or .xlsx." }
}

$requiredColumns = @('Matter ID','Matter Name','Client Name','Status','Lead Attorney',
                     'Assigned Staff','Existing Teams Channel','Existing File Locations',
                     'Existing SharePoint Location')

$errors = [System.Collections.Generic.List[string]]::new()

# --- Column presence ---
if ($rows.Count -eq 0) { $errors.Add('Inventory is empty.') }
else {
    $present = $rows[0].PSObject.Properties.Name
    foreach ($col in $requiredColumns) {
        if ($present -notcontains $col) { $errors.Add("Missing required column: '$col'.") }
    }
}

function Get-Prop { param($Row, [string]$Name) if ($Row.PSObject.Properties.Name -contains $Name) { return [string]$Row.$Name } return '' }

# --- Row validation + normalization ---
$normalized = [System.Collections.Generic.List[object]]::new()
$seen = @{}
$rowNum = 1
foreach ($row in $rows) {
    $rowNum++
    $id = (Get-Prop $row 'Matter ID').Trim()
    if (-not $id) { $errors.Add("Row ${rowNum}: Matter ID is empty."); continue }
    if ($seen.ContainsKey($id)) { $errors.Add("Row ${rowNum}: duplicate Matter ID '$id'.") } else { $seen[$id] = $true }

    $rawStatus = (Get-Prop $row 'Status').Trim()
    $statusNorm = switch -Regex ($rawStatus) {
        '^(?i)intake$'      { 'Prospective' }
        '^(?i)prospective$' { 'Prospective' }
        '^(?i)open$'        { 'Open' }
        '^(?i)closed$'      { 'Closed' }
        default             { $null }
    }
    if (-not $statusNorm) { $errors.Add("Row $rowNum ('$id'): invalid Status '$rawStatus'."); continue }

    $clientName = (Get-Prop $row 'Client Name').Trim()
    $lastName   = (Get-Prop $row 'Client Last Name').Trim()
    if (-not $lastName -and $clientName) { $lastName = ($clientName -split '\s+')[-1] }
    $shortDesc  = (Get-Prop $row 'Short Description').Trim()
    if (-not $shortDesc) { $shortDesc = (Get-Prop $row 'Matter Name').Trim() }

    $normalized.Add([pscustomobject]@{
        MatterId                   = $id
        MatterName                 = (Get-Prop $row 'Matter Name').Trim()
        ClientName                 = $clientName
        ClientLastName             = $lastName
        ShortDescription           = $shortDesc
        Status                     = $statusNorm
        LeadAttorney               = (Get-Prop $row 'Lead Attorney').Trim()
        AssignedStaff              = (Get-Prop $row 'Assigned Staff').Trim()
        ExistingTeamsChannel       = (Get-Prop $row 'Existing Teams Channel').Trim()
        ExistingFileLocations      = (Get-Prop $row 'Existing File Locations').Trim()
        ExistingSharePointLocation = (Get-Prop $row 'Existing SharePoint Location').Trim()
    })
}

# --- Summary ---
$byStatus = $normalized | Group-Object Status | ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }
Write-Host "Inventory: $InventoryPath" -ForegroundColor Cyan
Write-Host ("Rows: {0} | {1}" -f $normalized.Count, ($byStatus -join ', ')) -ForegroundColor Cyan
if ($errors.Count -gt 0) {
    Write-Host "Validation errors ($($errors.Count)):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
} else {
    Write-Host "Validation: PASS" -ForegroundColor Green
}

if ($ReportOnly) { return }
if ($errors.Count -gt 0) { throw "Inventory validation failed with $($errors.Count) error(s). Fix the inventory before provisioning." }

if ($All) { return $normalized }
return @($normalized | Where-Object { $_.Status -eq $Status })
