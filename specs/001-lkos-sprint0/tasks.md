---
description: "Task list for LKOS Sprint 0 — Permanent Matter Architecture"
---

# Tasks: LKOS Sprint 0 — Permanent Matter Architecture

**Input**: Design documents from `/specs/001-lkos-sprint0/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md,
data-model.md, contracts/

**Tests**: No automated test suite is requested for this M365 provisioning effort. Validation
is performed via the pilot validation checklist (`docs/validation-checklist.md`) rather than
unit/contract tests, so no test tasks are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and
validation of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US8)
- Include exact file paths in descriptions

## Path Conventions

Microsoft 365 provisioning project (per plan.md): declarative templates in `templates/`,
PowerShell automation in `src/`, configuration in `config/`, inventory in `inventory/`,
operator docs in `docs/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository scaffolding and tenant connectivity needed by every later phase.

- [ ] T001 Create the repository folder structure per plan.md (`templates/teams/`, `templates/sharepoint/`, `src/provisioning/`, `src/migration/`, `src/repository/`, `src/governance/`, `src/common/`, `config/`, `inventory/`, `docs/`)
- [ ] T002 [P] Create `config/lkos-settings.json` with tenant URLs, group-naming pattern, and retention label ID placeholders
- [ ] T003 [P] Create `src/common/Connect-LkosTenant.ps1` providing Microsoft Graph + PnP PowerShell connection/auth helpers
- [ ] T004 [P] Document required PowerShell modules and admin permissions in `docs/provisioning-runbook.md` (PnP.PowerShell, Microsoft Graph scopes)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting standards (naming, metadata model) that every template and
provisioning path depends on.

**⚠️ CRITICAL**: No matter Team/site can be standardized until these exist.

- [ ] T005 [P] Define the canonical naming standard in `config/naming-standard.json` (`Matter Number – Client Last Name – Short Description`)
- [ ] T006 [P] Define the canonical metadata model in `config/matter-metadata-model.json` (AI-indexable columns/terms shared by matter sites and the knowledge repository)
- [ ] T007 Implement `src/common/Lkos.Naming.ps1` to validate/normalize matter display names against `config/naming-standard.json` (depends on T005)

**Checkpoint**: Naming + metadata standards ready — template and provisioning work can begin.

---

## Phase 3: User Story 1 - Standardized Matter Team & SharePoint Templates (Priority: P1) 🎯 MVP

**Goal**: One standardized Matter Team template and one standardized SharePoint Matter Site
template that all matters reuse.

**Independent Test**: Instantiate one matter from the templates and confirm all standard
channels, libraries, metadata columns, permissions, versioning, and retention are present with
no per-matter customization.

### Implementation for User Story 1

- [ ] T008 [P] [US1] Author the Matter Team template in `templates/teams/matter-team-template.json` with standard channels: General, Administration, Pleadings, Discovery, Medical Records, Experts, Depositions, Motions, Trial, Settlement, AI Workspace
- [ ] T009 [P] [US1] Author the Matter content type + metadata columns in `templates/sharepoint/matter-content-type.xml` from `config/matter-metadata-model.json`
- [ ] T010 [US1] Author the SharePoint Matter Site template in `templates/sharepoint/matter-site-template.xml` (document libraries, metadata columns, versioning, retention settings) referencing the content type from T009
- [ ] T011 [US1] Encode permission scheme/least-privilege roles into the site template in `templates/sharepoint/matter-site-template.xml`
- [ ] T012 [US1] Add the standardized retention + versioning configuration to `templates/sharepoint/matter-site-template.xml`
- [ ] T013 [US1] Document the template instantiation + verification steps for a single matter in `docs/provisioning-runbook.md`

**Checkpoint**: Templates exist and a single matter can be built from them with full standard structure.

---

## Phase 4: User Story 2 - One-Click Matter Provisioning Automation (Priority: P1)

**Goal**: A single automated workflow that creates Team + SharePoint site + Matter ID +
channels + libraries + security groups + metadata + optional Planner/Lists + AI placeholder.

**Independent Test**: Run the provisioning workflow once for a test matter and confirm an
end-to-end, AI-ready matter is created with zero manual assembly.

### Implementation for User Story 2

- [ ] T014 [P] [US2] Implement `src/provisioning/New-MatterTeam.ps1` to create a Team from `templates/teams/matter-team-template.json` and ensure all standard channels
- [ ] T015 [P] [US2] Implement `src/provisioning/New-MatterSite.ps1` to apply `templates/sharepoint/matter-site-template.xml` (libraries, metadata, versioning, retention) and link it to the Team
- [ ] T016 [P] [US2] Implement `src/provisioning/New-MatterSecurityGroups.ps1` to create/assign least-privilege security groups per `config/lkos-settings.json`
- [ ] T017 [P] [US2] Implement `src/provisioning/Set-MatterMetadata.ps1` to apply the metadata model and stamp the Matter ID, enforcing the naming standard via `src/common/Lkos.Naming.ps1`
- [ ] T018 [P] [US2] Implement `src/provisioning/Register-MatterAIPlaceholder.ps1` to emit the standardized AI registration placeholder (machine-readable marker enabling future OCR/semantic/vector/knowledge-graph indexing with no separate AI upload)
- [ ] T019 [US2] Implement the orchestrator `src/provisioning/New-MatterWorkspace.ps1` to run the full single-workflow provisioning per `contracts/provisioning-contract.md` (calls T014–T018; optional Planner/Lists), guaranteeing idempotency
- [ ] T020 [US2] Add provisioning error handling and idempotent re-run behavior (no duplicate Team/site; partial failures flagged for cleanup) across `src/provisioning/New-MatterWorkspace.ps1`
- [ ] T021 [US2] Document the one-click provisioning command and inputs/outputs in `docs/provisioning-runbook.md` (aligned to `contracts/provisioning-contract.md`)

**Checkpoint**: A brand-new matter is fully provisioned and AI-ready from a single command.

---

## Phase 5: User Story 3 - Matter Inventory & Migration List (Priority: P1)

**Goal**: Authoritative master inventory of all matters with required columns and a
Prospective/Open/Closed classification; the single source for bulk provisioning.

**Independent Test**: Open the inventory and confirm every matter appears once with all
required columns populated and a valid classification; Open matters are clearly separable.

### Implementation for User Story 3

- [ ] T022 [P] [US3] Create the inventory template `inventory/matter-inventory.template.xlsx` with required columns: Matter ID, Matter Name, Client Name, Status (Open/Closed/Intake), Lead Attorney, Assigned Staff, Existing Teams Channel, Existing File Locations, Existing SharePoint Location
- [ ] T023 [US3] (PM) Populate the master inventory `inventory/matter-inventory.xlsx` for every existing matter (one row per matter, no duplicates)
- [ ] T024 [US3] (PM) Classify every matter as Prospective / Open / Closed and confirm only Open matters are in scope for Teams provisioning this sprint
- [ ] T025 [P] [US3] Implement `src/migration/Import-MatterInventory.ps1` to read and validate the inventory (required columns present, single valid status per row, no duplicate Matter IDs) and output the validated Open set

**Checkpoint**: A validated, authoritative migration list exists and is machine-readable.

---

## Phase 6: User Story 7 - Freeze New Channel Creation in Legacy Clients Team (Priority: P1)

**Goal**: Immediately stop creating new matter channels in the legacy Clients Team; route new
matters to provisioning.

**Independent Test**: Attempting to create a new matter channel in the Clients Team is
prevented/governed; new matters go through provisioning instead.

### Implementation for User Story 7

- [ ] T026 [US7] Implement `src/governance/Set-ClientsTeamChannelFreeze.ps1` to restrict channel creation in the legacy Clients Team to owners/governed process
- [ ] T027 [P] [US7] Author `docs/legacy-clients-team-policy.md` defining the freeze and the post-sprint intake/referral/administration-only usage, and the route for newly accepted matters into provisioning

**Checkpoint**: No new matter channels can be added to the legacy Clients Team.

---

## Phase 7: User Story 4 - Pilot Migration of Three Representative Matters (Priority: P2)

**Goal**: Provision three pilots (large/medium/small) and validate before scaling.

**Independent Test**: All three pilots pass the full validation checklist (permissions,
documents, search, metadata, Team structure, SharePoint structure).

### Implementation for User Story 4

- [ ] T028 [P] [US4] Author the pilot validation checklist `docs/validation-checklist.md` covering permissions, documents, search, metadata, Team structure, and SharePoint structure
- [ ] T029 [US4] Select the three representative pilot matters (large/medium/small) from the validated inventory and record them in `docs/validation-checklist.md`
- [ ] T030 [US4] Provision the three pilot matters using `src/provisioning/New-MatterWorkspace.ps1`
- [ ] T031 [US4] Execute the validation checklist against all three pilots and record pass/fail in `docs/validation-checklist.md`
- [ ] T032 [US4] Remediate any issues by correcting `templates/` and/or `src/provisioning/` and re-validate until all three pilots pass

**Checkpoint**: Provisioning is proven on representative matters; safe to scale.

---

## Phase 8: User Story 5 - Bulk Provisioning of All Open Matters (Priority: P2)

**Goal**: Provision every remaining open matter from the inventory automatically.

**Independent Test**: Every Open matter in the inventory has a dedicated, standardized Team and
SharePoint site; reconciliation shows none missing and no manual creation.

### Implementation for User Story 5

- [ ] T033 [US5] Implement `src/migration/Invoke-BulkProvisioning.ps1` to iterate the validated Open set from `Import-MatterInventory.ps1` and call `New-MatterWorkspace.ps1` for each (idempotent, skips Prospective/Closed)
- [ ] T034 [US5] Add a reconciliation report to `src/migration/Invoke-BulkProvisioning.ps1` listing provisioned vs. expected Open matters and flagging gaps
- [ ] T035 [US5] Run bulk provisioning for all remaining open matters and reconcile against the inventory

**Checkpoint**: Every open matter now has its own Team and SharePoint site.

---

## Phase 9: User Story 6 - Document Migration from Legacy Clients Team (Priority: P2)

**Goal**: Move legacy documents into the new matter sites, keeping links until verified.

**Independent Test**: For a migrated matter, documents reside in the new SharePoint site with
metadata applied, and legacy links still resolve until migration is verified.

### Implementation for User Story 6

- [ ] T036 [US6] Implement `src/migration/Move-LegacyDocuments.ps1` to move documents from each matter's legacy Clients Team location into the new matter site, applying the metadata model
- [ ] T037 [US6] Add link-preservation behavior to `src/migration/Move-LegacyDocuments.ps1` so legacy links remain functional until migration is verified
- [ ] T038 [US6] Add per-matter verification + cutover tracking to `src/migration/Move-LegacyDocuments.ps1` (mark migration verified before removing legacy links)
- [ ] T039 [US6] Execute document migration for provisioned open matters and verify in the new sites

**Checkpoint**: Open-matter documents live in the new architecture.

---

## Phase 10: User Story 8 - Litigation Knowledge Repository for Closed Matters (Priority: P3)

**Goal**: A standalone, read-only, AI-indexable repository for closed matters, ready to receive
historical content (no Team). Closed-matter content migration is OUT OF SCOPE this sprint.

**Independent Test**: The repository exists with libraries, shared metadata model, read-only
permissions for most users, AI-indexing support, and no associated Team.

### Implementation for User Story 8

- [ ] T040 [P] [US8] Author the repository site template `templates/sharepoint/knowledge-repo-site-template.xml` (historical-case-file libraries, shared metadata model, AI-indexing support)
- [ ] T041 [US8] Set read-only-for-most-users permissions in `templates/sharepoint/knowledge-repo-site-template.xml`
- [ ] T042 [US8] Implement `src/repository/New-KnowledgeRepository.ps1` to provision the standalone repository site (no Team) from the template
- [ ] T043 [US8] Provision the repository and confirm it is operational and ready to receive historical matters (no content migration this sprint)

**Checkpoint**: The Litigation Knowledge Repository exists and is ready.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Finalize documentation, governance, and Definition-of-Done verification.

- [ ] T044 [P] Finalize `docs/provisioning-runbook.md` so operators can run one-click and bulk provisioning end-to-end
- [ ] T045 [P] Verify the spec quality checklist `specs/001-lkos-sprint0/checklists/requirements.md` and Definition of Done from spec.md (all Open matters have Teams + sites; provisioning automated; repository exists; legacy freeze active)
- [ ] T046 Confirm the legacy Clients Team is repurposed to intake/referrals/administration only, per `docs/legacy-clients-team-policy.md`
- [ ] T047 [P] Run `quickstart.md` end-to-end as an acceptance pass for the operator runbook

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (naming + metadata).
- **US1 Templates (Phase 3)**: Depends on Foundational. Blocks US2.
- **US2 Provisioning (Phase 4)**: Depends on US1 templates. Blocks US4/US5.
- **US3 Inventory (Phase 5)**: Depends only on Setup/Foundational; can run in parallel with US1/US2. Blocks US5/US6.
- **US7 Freeze (Phase 6)**: Depends only on Setup; can be executed early/immediately.
- **US4 Pilot (Phase 7)**: Depends on US2 (provisioning) and US3 (inventory).
- **US5 Bulk (Phase 8)**: Depends on US4 (validated pilots) and US3 (inventory).
- **US6 Doc Migration (Phase 9)**: Depends on US5 (sites exist).
- **US8 Repository (Phase 10)**: Depends on Foundational (metadata model); independent of matter provisioning.
- **Polish (Phase 11)**: Depends on the desired user stories being complete.

### User Story Dependencies

- US1 (P1): after Foundational — foundation for everything.
- US2 (P1): after US1.
- US3 (P1): after Foundational — independent of US1/US2.
- US7 (P1): after Setup — can be done immediately ("Freeze New Channel Creation").
- US4 (P2): after US2 + US3.
- US5 (P2): after US4 + US3.
- US6 (P2): after US5.
- US8 (P3): after Foundational — independent of US1–US7.

### Parallel Opportunities

- Phase 1: T002, T003, T004 in parallel.
- Phase 2: T005, T006 in parallel (T007 after T005).
- US1: T008 and T009 in parallel; T010 after T009.
- US2: T014–T018 in parallel; T019 after them.
- US3 (T022, T025) can proceed in parallel with US1/US2 work.
- US7 (T026/T027) can proceed immediately, in parallel with template work.
- US8 (T040) can proceed in parallel once the metadata model (T006) exists.

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

1. Phase 1: Setup.
2. Phase 2: Foundational (naming + metadata) — CRITICAL.
3. Phase 3: US1 templates.
4. Phase 4: US2 one-click provisioning.
5. **STOP and VALIDATE**: Provision one matter end-to-end; confirm AI-ready, standardized.

This MVP (US1 + US2) delivers the core LKOS capability: standardized, automated, AI-ready
matter provisioning.

### Incremental Delivery (mapped to the migration plan)

1. MVP (US1 + US2) → standardized one-click provisioning.
2. US3 inventory + US7 freeze → scope locked, legacy growth stopped.
3. **Phase A** — US4 pilots (large/medium/small) → validate.
4. **Phase B** — US5 bulk provisioning of all open matters.
5. **Phase C** — US6 document migration (keep links until verified).
6. **Phase D** — US8 Litigation Knowledge Repository operational and ready.

### Definition of Done (from spec.md)

- All open matters have dedicated Teams (SC-001) and SharePoint sites (SC-002).
- Matter provisioning is automated and AI-ready with no separate AI upload (SC-003, SC-004).
- The Litigation Knowledge Repository exists and is ready (SC-007).
- No new matter channels are created in the legacy Clients Team (SC-006); it is used only for
  intake, referrals, and administration.
- All future development targets the LKOS architecture.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] label maps each task to a spec.md user story for traceability.
- Tasks ordered by priority: P1 stories (US1, US2, US3, US7) precede P2 (US4, US5, US6) and P3 (US8).
- Out of scope this sprint (deferred): closed-matter content migration, AI indexing of
  historical files, Power Automate document workflows, document generation, knowledge-graph
  implementation, and ChatGPT/Copilot/Claude/Lexis Protégé integrations / advanced AI agents.
