#requires -Version 7.0
<#
.SYNOPSIS
    Generates the LKOS matter inventory Excel template (inventory/matter-inventory.template.xlsx).

.DESCRIPTION
    Produces a formatted .xlsx with the standard inventory columns, a sample row, a frozen/bold
    header, and a Status data-validation dropdown (Prospective / Open / Closed / Intake).
    Requires the ImportExcel module (Install-Module ImportExcel -Scope CurrentUser).

    Regenerate the template by running this script; the PM then copies it to
    inventory/matter-inventory.xlsx and fills it in (that populated file is git-ignored).

.PARAMETER OutputPath
    Output xlsx path. Defaults to inventory/matter-inventory.template.xlsx.
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable ImportExcel)) {
    throw "ImportExcel is required. Run: Install-Module ImportExcel -Scope CurrentUser"
}
Import-Module ImportExcel

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $OutputPath) { $OutputPath = Join-Path $repoRoot 'inventory/matter-inventory.template.xlsx' }
if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

# One sample row to show the expected shape (delete before real use).
$sample = [ordered]@{
    'Matter ID'                    = '2026-0142'
    'Matter Name'                  = 'Nguyen v. Acme Trucking'
    'Client Name'                  = 'Tran Nguyen'
    'Client Last Name'             = 'Nguyen'
    'Short Description'            = 'MVA Personal Injury'
    'Status'                       = 'Open'
    'Lead Attorney'                = 'brennan@collinsattorneys.com'
    'Assigned Staff'               = 'jhen@collinsattorneys.com; kelly@collinsattorneys.com'
    'Existing Teams Channel'       = 'Clients > Nguyen MVA'
    'Existing File Locations'      = '\\fileserver\Matters\Nguyen'
    'Existing SharePoint Location' = ''
}

$pkg = [pscustomobject]$sample | Export-Excel -Path $OutputPath -WorksheetName 'Matters' `
    -TableName 'MatterInventory' -FreezeTopRow -BoldTopRow -AutoSize -PassThru

# Status dropdown (column F) for a generous row range.
$ws = $pkg.Workbook.Worksheets['Matters']
$dv = $ws.DataValidations.AddListValidation('F2:F1000')
foreach ($s in 'Prospective','Open','Closed','Intake') { [void]$dv.Formula.Values.Add($s) }
$dv.ShowErrorMessage = $true
$dv.ErrorTitle = 'Invalid Status'
$dv.Error = 'Status must be Prospective, Open, Closed, or Intake.'

Close-ExcelPackage $pkg
Write-Host "Inventory template written to $OutputPath" -ForegroundColor Green
