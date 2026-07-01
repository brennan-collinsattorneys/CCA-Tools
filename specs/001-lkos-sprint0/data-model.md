# Phase 1 Data Model: LKOS Sprint 0

## Entities

### Matter

The central record representing a legal case/engagement.

| Attribute | Type | Notes |
|-----------|------|-------|
| MatterID | string | Unique; also used in naming standard |
| MatterName | string | |
| ClientName | string | |
| Status | enum | Eval \| Pre-Litigation \| Litigation \| Closed (lifecycle state; Intake/Prospective map to Eval) |
| LeadAttorney | string | |
| AssignedStaff | string[] | |
| ExistingTeamsChannel | string | legacy Clients Team channel reference |
| ExistingFileLocations | string[] | |
| ExistingSharePointLocation | string | optional |
| NamingLabel | string | `Matter Number – Client Last Name – Short Description` |

**Rules**: Every matter has exactly one Status and ONE persistent Team + site. Active matters
(`Eval`/`Pre-Litigation`/`Litigation`) have a Team + site; status changes as the matter progresses
(see `Set-MatterStatus.ps1`). `Closed` matters archive to the Litigation Knowledge Repository.

### MatterTeam

Microsoft Team instantiated from the standard template for an Open matter.

- Standard channels: General, Administration, Pleadings, Discovery, Medical Records, Experts,
  Depositions, Motions, Trial, Settlement, AI Workspace.
- Linked 1:1 to a MatterSharePointSite.

### MatterSharePointSite (System of Record)

- Standard document libraries (aligned to channels/practice areas).
- Standard metadata columns (see MetadataModel).
- Permissions via SecurityGroups; versioning enabled; retention configured.

### MatterInventory

Authoritative spreadsheet of all matters and classifications; the source for bulk provisioning
and migration reconciliation. One row per matter; no duplicates.

### ProvisioningWorkflow

The single automated process producing a fully configured matter. Inputs/outputs defined in
`contracts/provisioning-contract.md`.

### SecurityGroup

Least-privilege access group governing a matter's content. Created/assigned during
provisioning.

### MetadataModel

Canonical set of columns/terms applied to all matter sites and the knowledge repository
(`config/matter-metadata-model.json`). AI-indexable.

### AIRegistrationPlaceholder

Machine-readable marker/configuration emitted per matter so future AI services can index/
retrieve without a separate upload step.

### LitigationKnowledgeRepository

Standalone, read-only SharePoint site for closed matters; AI-indexable; uses MetadataModel
where practical; no associated Team.

### LegacyClientsTeam

Existing single Team. After freeze: used only for intake, referrals, administration. No new
matter channels.

## Relationships

- Matter (Open) 1—1 MatterTeam 1—1 MatterSharePointSite.
- Matter * —1 MatterInventory (each matter listed once).
- MatterSharePointSite * —1 MetadataModel; LitigationKnowledgeRepository *—1 MetadataModel.
- MatterSharePointSite 1—* SecurityGroup.
- Matter (Open) 1—1 AIRegistrationPlaceholder.

## State Transitions (Matter.Status)

One persistent Team + site per matter; status is metadata updated by `Set-MatterStatus.ps1`.

- (New matter) → Eval: provisioning creates the Team + site (default status Eval).
- Eval → Pre-Litigation → Litigation: status updated in place as the matter progresses; same
  workspace throughout.
- Litigation/any → Closed: matter flagged for archival to the LitigationKnowledgeRepository
  (closed-matter content migration deferred beyond Sprint 0).
