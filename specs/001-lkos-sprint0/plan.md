# Implementation Plan: LKOS Sprint 0 — Permanent Matter Architecture

**Branch**: `001-lkos-sprint0` | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-lkos-sprint0/spec.md`

## Summary

Stand up the permanent Legal Knowledge Operating System (LKOS) information architecture on
Microsoft 365: a standardized Matter Team template, a standardized SharePoint Matter Site
template (system of record), one-click matter provisioning automation, and a read-only
Litigation Knowledge Repository for closed matters. Use the PM's authoritative matter
inventory to migrate every open matter into its own Team + SharePoint site (pilot first, then
bulk), move legacy documents, and freeze new channel creation in the legacy Clients Team.
Every provisioned matter is AI-ready by construction (OCR/metadata/semantic-indexing-ready,
with an AI registration placeholder) so no separate "AI upload" is ever required.

## Technical Context

**Language/Version**: PowerShell 7+ (provisioning scripts); declarative SharePoint/Teams
template definitions (XML/JSON)

**Primary Dependencies**: Microsoft Graph (Teams, Groups, Sites), PnP PowerShell
(`PnP.PowerShell`) and PnP Provisioning Templates / Site Designs & Site Scripts, Microsoft
Teams team templates, Microsoft 365 Groups, Microsoft Purview retention (labels/policies),
Power Automate + Power Platform CLI (`pac`) for the channel-to-workspace conversion flow

**Authentication**: A dedicated Microsoft Entra ID app registration (service principal). Two
modes: (1) interactive/delegated sign-in for manual and pilot steps; (2) certificate-based
app-only auth for unattended bulk runs. Credentials referenced by scripts are Tenant ID +
Client ID + certificate thumbprint (cert stored in `CurrentUser\My`); no secrets in the repo.
Power Automate flows act through governed Power Platform connections (service account / service
principal), not personal credentials. Admin consent requires Global/Privileged Role Admin.

**Storage**: SharePoint Online document libraries (system of record); Microsoft 365 Group
mailbox/Team for collaboration; a CSV/Excel matter inventory as the migration source list

**Testing**: Manual/scripted validation against the pilot-matter validation checklist
(permissions, documents, search, metadata, Team structure, SharePoint structure); idempotency
checks on provisioning re-runs in a non-production tenant or test site collection

**Target Platform**: Microsoft 365 tenant (SharePoint Online + Microsoft Teams), administered
from Windows PowerShell 7+

**Project Type**: Microsoft 365 information-architecture + provisioning automation (not a
traditional app); deliverables are templates, scripts, configuration, and operational docs

**Performance Goals**: One-click provisioning of a complete matter (Team + site + channels +
libraries + groups + metadata + AI placeholder) in a single workflow; bulk provisioning of all
open matters from the inventory within the 3–5 day sprint window

**Constraints**: 3–5 day target; production tenant changes must be reversible/idempotent;
least-privilege security; closed matters never get a Team; no separate AI-upload step; legacy
Clients Team frozen for new matter channels; migration includes mandatory human-approval gates
(before bulk provisioning, before each conversion batch, before legacy cutover)

**Scale/Scope**: All current open matters at Collins & Collins (tens to low-hundreds expected);
one knowledge repository; one provisioning pipeline

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Compliance in this plan |
|-----------|-------------------------|
| I. SharePoint is the System of Record | Matter Site template owns documents/metadata; Teams links to it; retention/versioning standardized on the site. PASS |
| II. Teams is the Collaboration Workspace | Teams created only for open matters; closed matters get no Team; channels mirror standard structure. PASS |
| III. AI is a core component of every matter | Provisioning emits a standardized AI registration placeholder + AI Workspace channel + AI-indexable metadata; no separate AI-upload. PASS |
| IV. Standardized architecture for every matter | Single Team template + single Site template + single naming standard enforced by provisioning; no bespoke matters. PASS |
| V. Closed matters become institutional knowledge | Read-only Litigation Knowledge Repository created with shared metadata model; closed-matter content migration deferred per spec. PASS |

**Power Automate scope note**: Constitution/spec defer "Power Automate document workflows."
This plan uses Power Automate **only** as the channel-to-workspace conversion mechanism (US9),
which is distinct from document workflows and remains consistent with standardized provisioning
(Principle IV). Document-workflow automation stays out of scope. No constitutional violation.

**Least privilege (auth)**: The Entra ID app uses admin-consented, least-privilege scopes
(prefer `Sites.Selected` over tenant-wide `Sites.FullControl.All` where feasible), reinforcing
the governance posture. PASS.

No violations. Complexity Tracking not required.

## Project Structure

### Documentation (this feature)

```text
specs/001-lkos-sprint0/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (key decisions)
├── data-model.md        # Phase 1 output (entities & metadata model)
├── quickstart.md        # Phase 1 output (operator runbook)
├── contracts/           # Phase 1 output (provisioning input/output contracts)
│   └── provisioning-contract.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
templates/
├── teams/
│   └── matter-team-template.json        # Standard Matter Team (channels) definition
└── sharepoint/
    ├── matter-site-template.xml         # PnP provisioning template (libraries/columns/views)
    ├── matter-content-type.xml          # Matter content type + metadata columns
    └── knowledge-repo-site-template.xml # Litigation Knowledge Repository site definition

src/
├── provisioning/
│   ├── New-MatterWorkspace.ps1          # One-click provisioning (Team+Site+groups+metadata+AI)
│   ├── New-MatterTeam.ps1               # Apply Teams template + channels
│   ├── New-MatterSite.ps1               # Apply SharePoint site template + libraries/metadata
│   ├── New-MatterSecurityGroups.ps1     # Least-privilege M365/security groups
│   ├── Set-MatterMetadata.ps1           # Apply metadata model + naming standard
│   └── Register-MatterAIPlaceholder.ps1 # Emit standardized AI registration placeholder
├── migration/
│   ├── Import-MatterInventory.ps1       # Read/validate the PM inventory spreadsheet
│   ├── Invoke-BulkProvisioning.ps1      # Provision all open matters (human-gated)
│   └── Move-LegacyDocuments.ps1         # Move docs from Clients Team, keep links until verified
├── conversion/
│   └── powerautomate/                   # Channel-to-workspace conversion flow (exported solution)
│       └── README.md                    # Flow design, triggers, connections, approval gates
├── repository/
│   └── New-KnowledgeRepository.ps1      # Provision read-only closed-matter repository
├── governance/
│   └── Set-ClientsTeamChannelFreeze.ps1 # Freeze new matter channels in legacy Clients Team
└── common/
    ├── Connect-LkosTenant.ps1           # Auth/connection helpers (Graph + PnP, both modes)
    ├── Register-LkosEntraApp.ps1        # Create Entra ID app + certificate for automation
    ├── Request-LkosApproval.ps1         # Manual-approval checkpoint gate helper
    └── Lkos.Naming.ps1                  # Naming-standard enforcement helper

config/
├── lkos-settings.json                   # Committed: tenant placeholders, scopes, structure
├── lkos-settings.local.sample.json      # Template for the git-ignored local settings file
├── matter-metadata-model.json           # Canonical metadata columns/terms
└── naming-standard.json                 # Matter Number – Client Last Name – Short Description

inventory/
└── matter-inventory.template.xlsx       # PM master inventory template (authoritative source)

docs/
├── auth-setup.md                        # Entra ID app registration + credentials setup guide
├── validation-checklist.md              # Pilot validation: permissions/docs/search/metadata/structure
├── provisioning-runbook.md              # Operator one-click + bulk runbook
├── conversion-runbook.md                # Power Automate channel-to-workspace conversion + gates
└── legacy-clients-team-policy.md        # Post-sprint intake/referral/admin-only usage
```

**Structure Decision**: Microsoft 365 provisioning project. `templates/` holds declarative
Team and SharePoint site definitions; `src/` holds idempotent PowerShell that applies them via
Microsoft Graph + PnP PowerShell; `config/` centralizes the metadata model, naming standard,
and tenant settings; `inventory/` holds the PM's authoritative migration source; `docs/` holds
operator runbooks and the pilot validation checklist.

## Complexity Tracking

No constitutional violations. No additional complexity to justify.
