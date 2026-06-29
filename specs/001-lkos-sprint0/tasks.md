---
description: "Task list for LKOS Sprint 0 — Permanent Matter Architecture"
---

# Tasks: LKOS Sprint 0 — Permanent Matter Architecture

**Input**: Design documents from `/specs/001-lkos-sprint0/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md,
data-model.md, contracts/

**Tests**: No automated test suite is requested for this M365 provisioning effort. Validation
is performed via the pilot validation checklist (`docs/validation-checklist.md`) plus the
manual-approval checkpoints, rather than unit/contract tests, so no test tasks are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and
validation of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US9)
- **🔶 MANUAL**: Task requires a human action or approval (credentials, consent, or a gate)
- Include exact file paths in descriptions

## Path Conventions

Microsoft 365 provisioning project (per plan.md): declarative templates in `templates/`,
PowerShell automation in `src/`, Power Automate solution in `src/conversion/powerautomate/`,
configuration in `config/`, inventory in `inventory/`, operator docs in `docs/`.

---

## Phase 1: Setup & Credentials (Shared Infrastructure)

**Purpose**: Repository scaffolding plus the Entra ID app registration and tenant connectivity
that every later phase depends on.

- [ ] T001 Create the repository folder structure per plan.md (`templates/teams/`, `templates/sharepoint/`, `src/provisioning/`, `src/migration/`, `src/conversion/powerautomate/`, `src/repository/`, `src/governance/`, `src/common/`, `config/`, `inventory/`, `docs/`)
- [x] T002 [P] Create `config/lkos-settings.json` (committed placeholders: tenant URLs, scopes, group naming, retention label IDs) and `config/lkos-settings.local.sample.json` (template for the git-ignored local file)
- [x] T003 🔶 MANUAL Register the Microsoft Entra ID app + certificate by running `src/common/Register-LkosEntraApp.ps1` (produces Client ID + certificate thumbprint); record values in `config/lkos-settings.local.json`
- [x] T004 🔶 MANUAL Have a Global/Privileged Role Administrator grant admin consent for the least-privilege Graph/SharePoint/Power Platform permissions on the app registration
- [x] T005 [P] Implement `src/common/Connect-LkosTenant.ps1` supporting both interactive (delegated) and certificate-based app-only connections to Microsoft Graph + PnP PowerShell
- [x] T006 [P] Author `docs/auth-setup.md` documenting the app registration, permissions/consent, certificate handling, and how each tool (PnP, Graph, `pac`) consumes the credential

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting standards (naming, metadata model, approval gate) that every template
and provisioning/conversion path depends on.

**⚠️ CRITICAL**: No matter Team/site can be standardized until these exist.

- [x] T007 [P] Define the canonical naming standard in `config/naming-standard.json` (`Matter Number – Client Last Name – Short Description`)
- [x] T008 [P] Define the canonical metadata model in `config/matter-metadata-model.json` (AI-indexable columns/terms shared by matter sites and the knowledge repository)
- [x] T009 Implement `src/common/Lkos.Naming.ps1` to validate/normalize matter display names against `config/naming-standard.json` (depends on T007)
- [x] T010 [P] Implement `src/common/Request-LkosApproval.ps1`, a reusable manual-approval checkpoint helper that pauses automation until a human approves (used by bulk, conversion, and cutover steps)

**Checkpoint**: Standards, auth, and the approval gate are ready — template and provisioning work can begin.

---

## Phase 3: User Story 1 - Standardized Matter Team & SharePoint Templates (Priority: P1) 🎯 MVP

**Goal**: One standardized Matter Team template and one standardized SharePoint Matter Site
template that all matters reuse.

**Independent Test**: Instantiate one matter from the templates and confirm all standard
channels, libraries, metadata columns, permissions, versioning, and retention are present with
no per-matter customization.

### Implementation for User Story 1

- [x] T011 [P] [US1] Author the Matter Team template in `templates/teams/matter-team-template.json` with standard channels: General, Administration, Pleadings, Discovery, Medical Records, Experts, Depositions, Motions, Trial, Settlement, AI Workspace
- [x] T012 [P] [US1] Author the Matter content type + metadata columns in `templates/sharepoint/matter-content-type.xml` from `config/matter-metadata-model.json`
- [x] T013 [US1] Author the SharePoint Matter Site template in `templates/sharepoint/matter-site-template.xml` (document libraries, metadata columns, versioning, retention settings) referencing the content type from T012
- [x] T014 [US1] Encode permission scheme/least-privilege roles into the site template in `templates/sharepoint/matter-site-template.xml`
- [x] T015 [US1] Add the standardized retention + versioning configuration to `templates/sharepoint/matter-site-template.xml`
- [x] T016 [US1] Document the template instantiation + verification steps for a single matter in `docs/provisioning-runbook.md`

**Checkpoint**: Templates exist and a single matter can be built from them with full standard structure.

---

## Phase 4: User Story 2 - One-Click Matter Provisioning Automation (Priority: P1)

**Goal**: A single automated workflow that creates Team + SharePoint site + Matter ID +
channels + libraries + security groups + metadata + optional Planner/Lists + AI placeholder.

**Independent Test**: Run the provisioning workflow once for a test matter and confirm an
end-to-end, AI-ready matter is created with zero manual assembly.

### Implementation for User Story 2

- [x] T017 [P] [US2] Implement `src/provisioning/New-MatterTeam.ps1` to create a Team from `templates/teams/matter-team-template.json` and ensure all standard channels
- [x] T018 [P] [US2] Implement `src/provisioning/New-MatterSite.ps1` to apply `templates/sharepoint/matter-site-template.xml` (libraries, metadata, versioning, retention) and link it to the Team
- [x] T019 [P] [US2] Implement `src/provisioning/New-MatterSecurityGroups.ps1` to create/assign least-privilege security groups per `config/lkos-settings.json`
- [x] T020 [P] [US2] Implement `src/provisioning/Set-MatterMetadata.ps1` to apply the metadata model and stamp the Matter ID, enforcing the naming standard via `src/common/Lkos.Naming.ps1`
- [x] T021 [P] [US2] Implement `src/provisioning/Register-MatterAIPlaceholder.ps1` to emit the standardized AI registration placeholder (machine-readable marker enabling future OCR/semantic/vector/knowledge-graph indexing with no separate AI upload)
- [x] T022 [US2] Implement the orchestrator `src/provisioning/New-MatterWorkspace.ps1` to run the full single-workflow provisioning per `contracts/provisioning-contract.md` (calls T017–T021; optional Planner/Lists; connects via `Connect-LkosTenant.ps1`), guaranteeing idempotency
- [x] T023 [US2] Add provisioning error handling and idempotent re-run behavior (no duplicate Team/site; partial failures flagged for cleanup) across `src/provisioning/New-MatterWorkspace.ps1`
- [x] T024 [US2] Document the one-click provisioning command and inputs/outputs in `docs/provisioning-runbook.md` (aligned to `contracts/provisioning-contract.md`)

**Checkpoint**: A brand-new matter is fully provisioned and AI-ready from a single command.

---

## Phase 5: User Story 3 - Matter Inventory & Migration List (Priority: P1)

**Goal**: Authoritative master inventory of all matters with required columns and a
Prospective/Open/Closed classification; the single source for bulk provisioning and conversion.

**Independent Test**: Open the inventory and confirm every matter appears once with all
required columns populated and a valid classification; Open matters are clearly separable.

### Implementation for User Story 3

- [ ] T025 [P] [US3] Create the inventory template `inventory/matter-inventory.template.xlsx` with required columns: Matter ID, Matter Name, Client Name, Status (Open/Closed/Intake), Lead Attorney, Assigned Staff, Existing Teams Channel, Existing File Locations, Existing SharePoint Location
- [ ] T026 [US3] 🔶 MANUAL (PM) Populate the master inventory `inventory/matter-inventory.xlsx` for every existing matter (one row per matter, no duplicates)
- [ ] T027 [US3] 🔶 MANUAL (PM) Classify every matter as Prospective / Open / Closed and confirm only Open matters are in scope for Teams provisioning this sprint
- [ ] T028 [P] [US3] Implement `src/migration/Import-MatterInventory.ps1` to read and validate the inventory (required columns present, single valid status per row, no duplicate Matter IDs) and output the validated Open set

**Checkpoint**: A validated, authoritative migration list exists and is machine-readable.

---

## Phase 6: User Story 7 - Freeze New Channel Creation in Legacy Clients Team (Priority: P1)

**Goal**: Immediately stop creating new matter channels in the legacy Clients Team; route new
matters to provisioning.

**Independent Test**: Attempting to create a new matter channel in the Clients Team is
prevented/governed; new matters go through provisioning instead.

### Implementation for User Story 7

- [ ] T029 [US7] Implement `src/governance/Set-ClientsTeamChannelFreeze.ps1` to restrict channel creation in the legacy Clients Team to owners/governed process
- [ ] T030 [P] [US7] Author `docs/legacy-clients-team-policy.md` defining the freeze and the post-sprint intake/referral/administration-only usage, and the route for newly accepted matters into provisioning

**Checkpoint**: No new matter channels can be added to the legacy Clients Team.

---

## Phase 7: User Story 4 - Pilot Migration of Three Representative Matters (Priority: P2)

**Goal**: Provision three pilots (large/medium/small) and validate before scaling.

**Independent Test**: All three pilots pass the full validation checklist (permissions,
documents, search, metadata, Team structure, SharePoint structure).

### Implementation for User Story 4

- [ ] T031 [P] [US4] Author the pilot validation checklist `docs/validation-checklist.md` covering permissions, documents, search, metadata, Team structure, and SharePoint structure
- [ ] T032 [US4] 🔶 MANUAL Select the three representative pilot matters (large/medium/small) from the validated inventory and record them in `docs/validation-checklist.md`
- [ ] T033 [US4] Provision the three pilot matters using `src/provisioning/New-MatterWorkspace.ps1`
- [ ] T034 [US4] 🔶 MANUAL Execute the validation checklist against all three pilots and record pass/fail in `docs/validation-checklist.md`
- [ ] T035 [US4] Remediate any issues by correcting `templates/` and/or `src/provisioning/` and re-validate until all three pilots pass

**Checkpoint**: Provisioning is proven on representative matters; safe to scale.

---

## Phase 8: User Story 9 - Power Automate Channel-to-Workspace Conversion with Manual Gates (Priority: P2)

**Goal**: Convert existing matter channels in the legacy Clients Team into standardized
workspaces (Team + SharePoint site) via a Power Automate flow, pausing at human-approval gates.

**Independent Test**: Run the conversion flow against one existing channel; it produces a
standardized workspace, pauses at the approval checkpoint, and only proceeds to cutover after
explicit human approval.

### Implementation for User Story 9

- [ ] T036 [US9] 🔶 MANUAL Authenticate the Power Platform CLI (`pac auth create`) to the target environment using the Entra ID app/service principal, and add the service principal as an application user with an appropriate Dataverse role
- [ ] T037 [P] [US9] Author the conversion flow design (triggers, connections, batch + approval-gate logic, mapping legacy channel → matter inputs) in `src/conversion/powerautomate/README.md`
- [ ] T038 [US9] Build the Power Automate conversion flow that, per channel, invokes standardized provisioning (`New-MatterWorkspace` equivalent), copies content, and links the workspace — using governed Power Platform connections, exported as a solution under `src/conversion/powerautomate/`
- [ ] T039 [US9] Implement the manual-approval gates in the flow (pause before each conversion batch and before cutover) using `Request-LkosApproval.ps1` semantics / Power Automate approvals
- [ ] T040 [US9] 🔶 MANUAL Pilot-convert one existing channel end-to-end and verify the standardized output, gate behavior, and cutover approval
- [ ] T041 [P] [US9] Author `docs/conversion-runbook.md` documenting how to run conversions, the approval gates, and rollback/link-preservation behavior

**Checkpoint**: Existing channels can be safely, repeatably converted with human oversight.

---

## Phase 9: User Story 5 - Bulk Provisioning of All Open Matters (Priority: P2)

**Goal**: Provision every remaining open matter from the inventory automatically, behind a gate.

**Independent Test**: Every Open matter in the inventory has a dedicated, standardized Team and
SharePoint site; reconciliation shows none missing and no manual creation.

### Implementation for User Story 5

- [ ] T042 [US5] Implement `src/migration/Invoke-BulkProvisioning.ps1` to iterate the validated Open set from `Import-MatterInventory.ps1` and call `New-MatterWorkspace.ps1` for each (idempotent, skips Prospective/Closed)
- [ ] T043 [US5] Insert a manual-approval checkpoint (via `Request-LkosApproval.ps1`) at the start of `src/migration/Invoke-BulkProvisioning.ps1` so bulk runs require explicit human approval
- [ ] T044 [US5] Add a reconciliation report to `src/migration/Invoke-BulkProvisioning.ps1` listing provisioned vs. expected Open matters and flagging gaps
- [ ] T045 [US5] 🔶 MANUAL Approve and run bulk provisioning for all remaining open matters and reconcile against the inventory

**Checkpoint**: Every open matter now has its own Team and SharePoint site.

---

## Phase 10: User Story 6 - Document Migration from Legacy Clients Team (Priority: P2)

**Goal**: Move legacy documents into the new matter sites, keeping links until a human approves
cutover.

**Independent Test**: For a migrated matter, documents reside in the new SharePoint site with
metadata applied, and legacy links still resolve until migration is verified and approved.

### Implementation for User Story 6

- [ ] T046 [US6] Implement `src/migration/Move-LegacyDocuments.ps1` to move documents from each matter's legacy Clients Team location into the new matter site, applying the metadata model
- [ ] T047 [US6] Add link-preservation behavior to `src/migration/Move-LegacyDocuments.ps1` so legacy links remain functional until migration is verified
- [ ] T048 [US6] Add a cutover manual-approval gate (via `Request-LkosApproval.ps1`) to `src/migration/Move-LegacyDocuments.ps1` so legacy links/content are removed only after explicit human verification/approval
- [ ] T049 [US6] 🔶 MANUAL Execute document migration for provisioned open matters, verify in the new sites, and approve cutover

**Checkpoint**: Open-matter documents live in the new architecture.

---

## Phase 11: User Story 8 - Litigation Knowledge Repository for Closed Matters (Priority: P3)

**Goal**: A standalone, read-only, AI-indexable repository for closed matters, ready to receive
historical content (no Team). Closed-matter content migration is OUT OF SCOPE this sprint.

**Independent Test**: The repository exists with libraries, shared metadata model, read-only
permissions for most users, AI-indexing support, and no associated Team.

### Implementation for User Story 8

- [ ] T050 [P] [US8] Author the repository site template `templates/sharepoint/knowledge-repo-site-template.xml` (historical-case-file libraries, shared metadata model, AI-indexing support)
- [ ] T051 [US8] Set read-only-for-most-users permissions in `templates/sharepoint/knowledge-repo-site-template.xml`
- [ ] T052 [US8] Implement `src/repository/New-KnowledgeRepository.ps1` to provision the standalone repository site (no Team) from the template
- [ ] T053 [US8] Provision the repository and confirm it is operational and ready to receive historical matters (no content migration this sprint)

**Checkpoint**: The Litigation Knowledge Repository exists and is ready.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Finalize documentation, governance, and Definition-of-Done verification.

- [ ] T054 [P] Finalize `docs/provisioning-runbook.md` and `docs/conversion-runbook.md` so operators can run one-click provisioning, bulk provisioning, and conversions end-to-end
- [ ] T055 [P] Verify the spec quality checklist `specs/001-lkos-sprint0/checklists/requirements.md` and Definition of Done from spec.md (all Open matters have Teams + sites; provisioning automated; repository exists; legacy freeze active; auth via Entra app; manual gates enforced)
- [ ] T056 Confirm the legacy Clients Team is repurposed to intake/referrals/administration only, per `docs/legacy-clients-team-policy.md`
- [ ] T057 [P] Run `quickstart.md` end-to-end as an acceptance pass for the operator runbook

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup & Credentials (Phase 1)**: No code dependencies — start immediately. T003/T004 are
  manual and gate any tenant-touching task (provisioning, conversion).
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (naming, metadata, gate helper).
- **US1 Templates (Phase 3)**: Depends on Foundational. Blocks US2.
- **US2 Provisioning (Phase 4)**: Depends on US1 + auth (T003–T005). Blocks US4/US5/US9.
- **US3 Inventory (Phase 5)**: Depends only on Setup/Foundational; parallel with US1/US2. Blocks US5/US6/US9.
- **US7 Freeze (Phase 6)**: Depends only on Setup/auth; can be executed early/immediately.
- **US4 Pilot (Phase 7)**: Depends on US2 + US3.
- **US9 Conversion (Phase 8)**: Depends on US2 + US3 (+ Power Platform auth T036).
- **US5 Bulk (Phase 9)**: Depends on US4 (validated pilots) + US3.
- **US6 Doc Migration (Phase 10)**: Depends on US5 (sites exist).
- **US8 Repository (Phase 11)**: Depends on Foundational (metadata model); independent of matter provisioning.
- **Polish (Phase 12)**: Depends on the desired user stories being complete.

### Manual-intervention gates (🔶)

- **T003 / T004**: Entra app registration + admin consent (credentials) — one-time, blocks tenant ops.
- **T026 / T027**: PM populates and classifies the inventory.
- **T032 / T034**: Pilot selection and validation sign-off.
- **T036 / T040**: Power Platform auth and conversion pilot verification.
- **T045**: Approve bulk provisioning before it runs.
- **T049**: Approve legacy cutover before links/content are removed.

### Parallel Opportunities

- Phase 1: T002, T005, T006 in parallel (T003 before T004; both before tenant-touching tasks).
- Phase 2: T007, T008, T010 in parallel (T009 after T007).
- US1: T011 and T012 in parallel; T013 after T012.
- US2: T017–T021 in parallel; T022 after them.
- US3 (T025, T028) and US7 (T029, T030) can proceed in parallel with US1/US2 work.
- US8 (T050) can proceed in parallel once the metadata model (T008) exists.

---

## Parallel Example: User Story 2

```text
# Launch the independent provisioning building blocks together:
Task: "Implement New-MatterTeam.ps1 in src/provisioning/New-MatterTeam.ps1"
Task: "Implement New-MatterSite.ps1 in src/provisioning/New-MatterSite.ps1"
Task: "Implement New-MatterSecurityGroups.ps1 in src/provisioning/New-MatterSecurityGroups.ps1"
Task: "Implement Set-MatterMetadata.ps1 in src/provisioning/Set-MatterMetadata.ps1"
Task: "Implement Register-MatterAIPlaceholder.ps1 in src/provisioning/Register-MatterAIPlaceholder.ps1"
# Then assemble:
Task: "Implement orchestrator New-MatterWorkspace.ps1 in src/provisioning/New-MatterWorkspace.ps1"
```

---

## Implementation Strategy

### MVP First

1. Phase 1: Setup & Credentials (register Entra app, admin consent, connection helper).
2. Phase 2: Foundational (naming + metadata + approval gate) — CRITICAL.
3. Phase 3: US1 templates.
4. Phase 4: US2 one-click provisioning.
5. **STOP and VALIDATE**: Provision one matter end-to-end; confirm AI-ready, standardized.

This MVP (auth + US1 + US2) delivers the core LKOS capability: standardized, automated,
AI-ready matter provisioning.

### Incremental Delivery (mapped to the migration plan)

1. MVP (auth + US1 + US2) → standardized one-click provisioning.
2. US3 inventory + US7 freeze → scope locked, legacy growth stopped.
3. **Phase A** — US4 pilots (large/medium/small) → validate.
4. **Conversion** — US9 Power Automate channel-to-workspace conversion (human-gated).
5. **Phase B** — US5 bulk provisioning of all open matters (approval-gated).
6. **Phase C** — US6 document migration (keep links until verified; cutover gated).
7. **Phase D** — US8 Litigation Knowledge Repository operational and ready.

### Definition of Done (from spec.md)

- All open matters have dedicated Teams (SC-001) and SharePoint sites (SC-002).
- Matter provisioning is automated and AI-ready with no separate AI upload (SC-003, SC-004).
- The Litigation Knowledge Repository exists and is ready (SC-007).
- No new matter channels are created in the legacy Clients Team (SC-006); it is used only for
  intake, referrals, and administration.
- Local automation authenticates via the Entra ID app with no committed secrets (SC-010).
- Every conversion passes its manual-approval checkpoints; no cutover without approval (SC-011).
- All future development targets the LKOS architecture.

---

## Notes

- [P] tasks = different files, no dependencies.
- 🔶 MANUAL tasks require a human (credentials, admin consent, PM data entry, or an approval gate).
- [Story] label maps each task to a spec.md user story for traceability.
- Tasks ordered by priority: P1 stories (US1, US2, US3, US7) precede P2 (US4, US9, US5, US6) and P3 (US8).
- Power Automate is used **only** for channel-to-workspace conversion (US9). Power Automate
  **document workflows**, document generation, knowledge-graph implementation, closed-matter
  content migration, AI indexing of historical files, and ChatGPT/Copilot/Claude/Lexis Protégé
  integrations / advanced AI agents remain OUT OF SCOPE this sprint.
