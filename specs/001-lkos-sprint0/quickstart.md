# Quickstart / Operator Runbook: LKOS Sprint 0

> High-level operational flow. Detailed steps live in `docs/provisioning-runbook.md`.

## Prerequisites

- PowerShell 7+ with `PnP.PowerShell` and Microsoft Graph access.
- Admin rights on the Microsoft 365 tenant (Teams, SharePoint, Groups, Purview retention).
- `config/lkos-settings.json` populated (tenant URL, group naming, retention label IDs).

## 1. One-click provision a single matter

```powershell
./src/provisioning/New-MatterWorkspace.ps1 `
  -MatterID "2026-0142" `
  -ClientLastName "Nguyen" `
  -ShortDescription "MVA Personal Injury" `
  -LeadAttorney "jdoe@collins.law"
```

Produces a Team (all standard channels), a linked SharePoint site (libraries, metadata,
versioning, retention), security groups, naming-standard display names, and an AI registration
placeholder — in one run.

## 2. Validate (pilot checklist)

Run through `docs/validation-checklist.md`: permissions, documents, search, metadata, Team
structure, SharePoint structure. All must pass before bulk provisioning.

## 3. Bulk provision all open matters

```powershell
./src/migration/Invoke-BulkProvisioning.ps1 -InventoryPath ./inventory/matter-inventory.xlsx
```

Reads validated Open rows only; skips Prospective/Closed; idempotent re-runs are safe.

## 4. Migrate legacy documents

```powershell
./src/migration/Move-LegacyDocuments.ps1 -InventoryPath ./inventory/matter-inventory.xlsx
```

Moves docs from the Clients Team into each matter's new site; keeps links until verified.

## 5. Freeze legacy Clients Team

```powershell
./src/governance/Set-ClientsTeamChannelFreeze.ps1
```

## 6. Stand up the Litigation Knowledge Repository

```powershell
./src/repository/New-KnowledgeRepository.ps1
```

Creates a standalone, read-only, AI-indexable site (no Team), ready to receive historical
matters. Closed-matter content migration is out of scope this sprint.
