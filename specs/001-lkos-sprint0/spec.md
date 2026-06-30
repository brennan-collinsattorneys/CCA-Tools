# Feature Specification: LKOS Sprint 0 — Permanent Matter Architecture

**Feature Branch**: `001-lkos-sprint0`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Transition Collins & Collins from a single 'Clients' Team with matter channels to the permanent Legal Knowledge Operating System (LKOS) architecture. Establish the production information architecture (standardized Matter Team template, standardized SharePoint Matter Site template, Litigation Knowledge Repository for closed matters, automated provisioning), migrate every open matter to its own Team and SharePoint site, and freeze new channel creation in the legacy Clients Team. Target completion 3–5 days."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Standardized Matter Team & SharePoint Templates (Priority: P1)

The firm defines one standardized Matter Team template and one standardized SharePoint
Matter Site template so that every matter has identical structure: the same channels,
document libraries, metadata columns, permissions, versioning, and retention settings.

**Why this priority**: Standardized templates are the foundation everything else depends
on. Provisioning, migration, AI readiness, and the knowledge repository all reuse this
structure. Without it, nothing downstream can be automated.

**Independent Test**: Manually instantiate one matter from the templates and confirm it
contains all required channels, all document libraries, the agreed metadata columns,
correct permissions, versioning enabled, and retention configured — without any per-matter
customization.

**Acceptance Scenarios**:

1. **Given** the Matter Team template, **When** a matter Team is created from it, **Then**
   it contains the standardized channels (General, Administration, Pleadings, Discovery,
   Medical Records, Experts, Depositions, Motions, Trial, Settlement, AI Workspace).
2. **Given** the SharePoint Matter Site template, **When** a matter site is provisioned,
   **Then** it includes the standard document libraries, metadata columns, permissions,
   versioning, and retention settings.
3. **Given** a newly created matter Team, **When** it is inspected, **Then** it is
   automatically associated with a SharePoint site that uses the standard configuration.

---

### User Story 2 - One-Click Matter Provisioning Automation (Priority: P1)

A firm administrator provisions a brand-new matter through a single automated workflow that
creates the Team, SharePoint site, Matter ID, standard channels, document libraries,
security groups, metadata, optional Planner/Lists, and an AI registration placeholder — with
no manual assembly.

**Why this priority**: One-click provisioning is the core capability of LKOS and the
mechanism that enforces standardization and AI-readiness for all future matters. It is also
the engine used for bulk migration of existing open matters.

**Independent Test**: Run the provisioning workflow once for a test matter and confirm a
fully configured Team and SharePoint site (channels, libraries, security groups, metadata,
AI placeholder) are created end-to-end without manual steps.

**Acceptance Scenarios**:

1. **Given** a matter name and minimal inputs, **When** provisioning runs, **Then** a Team,
   SharePoint site, and Matter ID are created in a single workflow.
2. **Given** provisioning completes, **When** the matter is inspected, **Then** standard
   channels, document libraries, security groups, and metadata are present and correctly
   configured.
3. **Given** provisioning completes, **When** the matter is inspected, **Then** an AI
   registration placeholder exists so no separate "AI upload" process is ever required.
4. **Given** the matter naming standard, **When** provisioning runs, **Then** the created
   Team and site follow the standard `Matter Number – Client Last Name – Short Description`.

---

### User Story 3 - Matter Inventory & Migration List (Priority: P1)

The PM produces an authoritative master inventory of all matters (Matter ID, Matter Name,
Client Name, Status, Lead Attorney, Assigned Staff, existing Teams channel, existing file
locations, existing SharePoint location) and classifies each matter as Prospective, Open, or
Closed so the migration scope is unambiguous.

**Why this priority**: The inventory is the authoritative source for bulk provisioning and
defines exactly which matters receive Teams in this sprint (Open only). Migration cannot be
trusted or automated without it.

**Independent Test**: Open the inventory spreadsheet and confirm every existing matter
appears once, with all required columns populated and a valid status classification, and
that Open matters are clearly separable from Prospective and Closed.

**Acceptance Scenarios**:

1. **Given** existing matters across the Clients Team and file locations, **When** the
   inventory is compiled, **Then** every matter has all required columns populated.
2. **Given** the completed inventory, **When** matters are classified, **Then** each is
   exactly one of Prospective / Open / Closed.
3. **Given** the classified inventory, **When** the sprint scope is defined, **Then** only
   Open matters are selected for Teams/site provisioning in this sprint.

---

### User Story 4 - Pilot Migration of Three Representative Matters (Priority: P2)

The team selects three representative matters (large, medium, small) and provisions them as
pilots, validating permissions, documents, search, metadata, and Team/SharePoint structure
before scaling.

**Why this priority**: Piloting de-risks bulk provisioning. It must follow the templates and
provisioning automation (P1) but precede full rollout.

**Independent Test**: Provision the three pilots and run the validation checklist
(permissions, documents, search, metadata, Team structure, SharePoint structure); all pass
for all three.

**Acceptance Scenarios**:

1. **Given** the provisioning automation, **When** three pilot matters (large/medium/small)
   are provisioned, **Then** each matches the standardized structure.
2. **Given** a provisioned pilot, **When** validated, **Then** permissions, documents,
   search, metadata, and structure all pass the validation checklist.
3. **Given** pilot validation results, **When** issues are found, **Then** templates/
   automation are corrected before bulk provisioning begins.

---

### User Story 5 - Bulk Provisioning of All Open Matters (Priority: P2)

Using the PM's inventory as the source, all remaining open matters are provisioned
automatically into their own Teams and SharePoint sites, avoiding manual creation.

**Why this priority**: This realizes the "every open matter has its own Team and site" goal,
but depends on validated templates, automation, inventory, and pilots.

**Independent Test**: Run bulk provisioning from the inventory and confirm every Open matter
in the list now has a dedicated, standardized Team and SharePoint site.

**Acceptance Scenarios**:

1. **Given** the validated inventory of Open matters, **When** bulk provisioning runs,
   **Then** each Open matter gets a dedicated Team and SharePoint site.
2. **Given** bulk provisioning completes, **When** the inventory is reconciled, **Then**
   every Open matter is accounted for with no manual creation required.
3. **Given** the validated inventory, **When** bulk provisioning is initiated, **Then** the
   process pauses at a manual-approval checkpoint and proceeds only after explicit human
   approval.

---

### User Story 6 - Document Migration from Legacy Clients Team (Priority: P2)

Documents currently in the legacy Clients Team are moved into the corresponding new Matter
Teams/sites, maintaining links where appropriate until migration is verified.

**Why this priority**: Open matters need their working documents in the new architecture, but
this depends on the new sites existing (US5).

**Independent Test**: For a migrated matter, confirm its documents now reside in the new
SharePoint site and any maintained links still resolve until verification completes.

**Acceptance Scenarios**:

1. **Given** a provisioned open matter, **When** its legacy documents are migrated, **Then**
   the documents appear in the new matter's SharePoint site with metadata applied.
2. **Given** migration is in progress, **When** users access content, **Then** links from the
   legacy location remain functional until migration is verified.
3. **Given** documents are copied to the new site, **When** cutover (removing legacy links/
   content) is proposed, **Then** it occurs only after an explicit human verification/approval
   checkpoint.

---

### User Story 7 - Freeze New Channel Creation in Legacy Clients Team (Priority: P1)

New matter channel creation in the existing Clients Team is immediately stopped; all newly
accepted matters use the new provisioning process once available.

**Why this priority**: Freezing prevents the legacy problem from growing during the sprint and
is effectively a policy/configuration change that can take effect immediately.

**Independent Test**: Attempt (or review the control preventing) creation of a new matter
channel in the Clients Team and confirm it is blocked/governed; confirm new matters route to
provisioning instead.

**Acceptance Scenarios**:

1. **Given** the freeze is in effect, **When** someone attempts to create a new matter
   channel in the Clients Team, **Then** the action is prevented or governed by policy.
2. **Given** a newly accepted matter after the freeze, **When** it is set up, **Then** it is
   created via the provisioning process, not as a Clients Team channel.

---

### User Story 8 - Litigation Knowledge Repository for Closed Matters (Priority: P3)

A separate SharePoint site is created and configured to store historical/closed-matter case
files as read-only institutional knowledge, supporting AI indexing and using the same
metadata model where practical. No Teams are created for closed matters.

**Why this priority**: Required deliverable and Definition-of-Done item, but content migration
of closed matters is explicitly deferred — only the operational, ready-to-receive repository
must exist this sprint.

**Independent Test**: Open the repository site and confirm it is configured (libraries,
metadata model, read-only permissions for most users, AI-indexing support) and ready to
receive historical matters, with no associated Team.

**Acceptance Scenarios**:

1. **Given** the repository requirement, **When** the site is created, **Then** it is a
   standalone SharePoint site with no associated Team.
2. **Given** the repository site, **When** permissions are inspected, **Then** it is read-only
   for most users.
3. **Given** the repository site, **When** configured, **Then** it supports AI indexing and
   uses the same metadata model where practical and is ready to receive historical matters.

---

### User Story 9 - Power Automate Channel-to-Workspace Conversion with Manual Gates (Priority: P2)

The existing matter channels in the legacy Clients Team are converted into their own dedicated
workspaces (Team + SharePoint site) using a Power Automate conversion flow. The flow drives the
standardized provisioning, but the process stops at explicit manual-approval checkpoints so a
human can review before bulk runs, before each conversion batch, and before legacy content/links
are removed.

**Why this priority**: This is the mechanism (researched by the PO) for moving existing channel
content into the new architecture. It depends on standardized templates (US1) and provisioning
(US2) and the inventory (US3), and it must be human-gated to be safe in production.

**Independent Test**: Run the conversion flow against one existing channel and confirm it produces
a standardized workspace, pauses at the approval checkpoint, and only proceeds to cutover after
explicit human approval.

**Acceptance Scenarios**:

1. **Given** an existing matter channel in the Clients Team, **When** the conversion flow runs,
   **Then** a standardized Team + SharePoint site is produced matching the provisioning output.
2. **Given** a conversion batch is queued, **When** it reaches the approval checkpoint, **Then**
   the flow pauses and requires explicit human approval before continuing.
3. **Given** content has been copied to the new workspace, **When** cutover is proposed, **Then**
   legacy links/content are only removed after a human verifies and approves the cutover.
4. **Given** the conversion flow, **When** it authenticates to SharePoint/Teams, **Then** it uses
   governed Power Platform connections (service account / service principal), not personal ad-hoc
   credentials.

---

### User Story 10 - Rename/Removal Template Reconcile (Priority: P2)

After matters are created, the firm can evolve the standardized template and roll the changes out
to all existing matters in-place. Additive changes propagate via an idempotent reconcile;
rename and removal changes are applied through an explicit change-set with safety guardrails.

**Why this priority**: Without this, the firm is effectively locked into the first template
version (additive-only), forcing template perfection before any matter is created. This removes
that blocker while protecting against accidental data loss.

**Independent Test**: Define a change-set that renames one channel/column and removes one empty
channel; run it against a test matter and confirm the rename applies, the empty removal succeeds,
and a non-empty removal is blocked unless explicitly forced.

**Acceptance Scenarios**:

1. **Given** an additive template change, **When** the reconcile runs, **Then** every existing
   matter gains the new channel/library/column without duplications.
2. **Given** a rename change-set, **When** it runs, **Then** the targeted channels/column display
   names are renamed in place across matters (internal identifiers preserved).
3. **Given** a removal change-set for a non-empty object, **When** it runs without force, **Then**
   the removal is blocked and reported; with explicit force and approval it proceeds.
4. **Given** any destructive change-set, **When** it runs, **Then** a content report and an
   approval gate precede execution.

---

### Edge Cases

- What happens when a matter's status is ambiguous (e.g., dormant or partially closed)? It
  MUST be explicitly classified before provisioning; unclassified matters are excluded from
  bulk provisioning.
- How does the system handle a matter that already has a partial SharePoint location? The
  inventory records the existing location; migration consolidates into the standardized site.
- What happens if a matter name violates the naming standard? Provisioning normalizes/enforces
  the standard before creating the Team and site.
- How are duplicate or merged matters handled in the inventory? Each appears once;
  duplicates/merges are resolved before provisioning.
- What happens if document migration is interrupted? Legacy links are maintained until the
  migration for that matter is verified complete.
- What happens to prospective clients and closed matters during this sprint? They do NOT
  receive Teams; closed-matter content migration is out of scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The firm MUST define a single standardized Matter Team template containing the
  standard channels (General, Administration, Pleadings, Discovery, Medical Records, Experts,
  Depositions, Motions, Trial, Settlement, AI Workspace), kept consistent across all matters.
- **FR-002**: The firm MUST define a single standardized SharePoint Matter Site template with
  document libraries, metadata columns, permissions, versioning, and retention settings.
- **FR-003**: Every Matter Team MUST automatically receive the same standard SharePoint
  configuration.
- **FR-004**: The system MUST provide automated provisioning that, in a single workflow,
  creates a Team, SharePoint site, Matter ID, standard channels, standard document libraries,
  security groups, metadata, optional Planner, optional Microsoft Lists, and an AI
  registration placeholder.
- **FR-005**: Provisioning MUST enforce a consistent matter naming standard (e.g.,
  `Matter Number – Client Last Name – Short Description`).
- **FR-006**: Newly provisioned matters MUST be AI-ready, supporting OCR, metadata
  extraction, semantic indexing, AI retrieval, future vector indexing, and knowledge-graph
  integration, with no separate "AI upload" process required.
- **FR-007**: The PM MUST produce an authoritative master inventory spreadsheet containing
  Matter ID, Matter Name, Client Name, Status (Open/Closed/Intake), Lead Attorney, Assigned
  Staff, Existing Teams Channel, Existing File Locations, and Existing SharePoint Location.
- **FR-008**: All matters MUST be classified as Prospective, Open, or Closed; only Open
  matters receive Teams during this sprint.
- **FR-009**: The firm MUST immediately freeze creation of new matter channels in the legacy
  Clients Team; newly accepted matters MUST use the provisioning process once available.
- **FR-010**: The team MUST validate the naming standard and finalize conventions for all
  future matters.
- **FR-011**: The team MUST select three representative matters (large, medium, small) and
  provision them as pilots before provisioning the remaining matters.
- **FR-012**: Pilot provisioning MUST be validated for permissions, documents, search,
  metadata, Team structure, and SharePoint structure.
- **FR-013**: The system MUST support bulk provisioning of all remaining open matters using
  the PM's inventory spreadsheet as the source, avoiding manual creation wherever possible.
- **FR-014**: Documents from the legacy Clients Team MUST be moved into the new Matter Teams/
  sites, maintaining links where appropriate until migration is verified.
- **FR-015**: The firm MUST create a separate Litigation Knowledge Repository SharePoint site
  for closed matters that stores historical case files, supports AI indexing, is read-only for
  most users, and uses the same metadata model where practical.
- **FR-016**: No Teams MUST be created for closed matters.
- **FR-017**: The Litigation Knowledge Repository MUST be operational and ready to receive
  historical matters by end of sprint, but closed-matter content migration MUST NOT occur this
  sprint unless time permits.
- **FR-018**: After the sprint, the legacy Clients Team MUST be used only for intake,
  referrals, and administrative functions, and all future development MUST target the LKOS
  architecture.
- **FR-019**: The firm MUST establish a dedicated Microsoft Entra ID app registration
  (service principal) as the credential for local automation, supporting interactive
  (delegated) sign-in for manual/pilot steps and certificate-based app-only authentication
  for unattended bulk operations, granted least-privilege admin-consented permissions to
  Microsoft Graph, SharePoint, and the Power Platform.
- **FR-020**: The conversion of existing matter channels in the legacy Clients Team into
  their own dedicated workspaces (Team + SharePoint site) MUST be performed using a Power
  Automate conversion flow, authored and deployed via the Power Platform, with the same
  standardized output as one-click provisioning.
- **FR-021**: The migration process MUST include explicit manual-intervention checkpoints
  where a human reviews and approves before proceeding: (a) before bulk provisioning of all
  open matters, (b) before each channel-to-workspace conversion batch, and (c) before legacy
  links/content are removed (cutover verification). Automated steps MUST pause at these gates
  until approved.
- **FR-022**: The system MUST be able to apply template changes to already-provisioned matters
  in-place. Additive changes (new channels, libraries, metadata columns, folders) MUST be
  pushable firm-wide via an idempotent reconcile. Rename and removal changes MUST be supported
  via an explicit, declarative change-set with a content report, a mandatory approval gate, and
  protection against deleting non-empty objects without explicit confirmation.

### Key Entities *(include if feature involves data)*

- **Matter**: A legal case/engagement. Attributes: Matter ID, Matter Name, Client Name,
  Status (Prospective/Open/Closed), Lead Attorney, Assigned Staff, naming-standard label,
  existing locations (Teams channel, file locations, SharePoint location).
- **Matter Team**: A Microsoft Team instantiated from the standard template for an Open
  matter, containing the standard channels; exists only for active matters.
- **Matter SharePoint Site**: The system-of-record site for a matter, with standard document
  libraries, metadata columns, permissions, versioning, and retention.
- **Matter Inventory**: The authoritative master list/spreadsheet of all matters and their
  classification; the source for migration and bulk provisioning.
- **Provisioning Workflow**: The single automated process that creates a fully configured,
  AI-ready matter (Team + site + groups + metadata + AI placeholder).
- **Security Group**: Access-control group governing who can access a given matter's content.
- **Metadata Model**: The standardized set of columns/terms applied across matter sites and
  the knowledge repository.
- **Litigation Knowledge Repository**: A standalone, read-only SharePoint site for closed
  matters as institutional knowledge, AI-indexable, with no associated Team.
- **Legacy Clients Team**: The existing single Team being frozen for new matter channels and
  repurposed for intake/referrals/administration.
- **Entra ID App Registration**: The service-principal identity (Tenant ID, Client ID,
  certificate) used by local automation to authenticate to Graph, SharePoint, and the Power
  Platform; supports delegated and app-only modes with least-privilege, admin-consented scopes.
- **Conversion Flow**: The Power Automate flow that converts an existing Clients Team channel
  into a standardized workspace, pausing at manual-approval checkpoints and using governed
  Power Platform connections.
- **Approval Checkpoint**: A required human review/approval gate before bulk provisioning,
  before each conversion batch, and before legacy cutover.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Open matters (per the authoritative inventory) have a dedicated,
  standardized Team by end of sprint.
- **SC-002**: 100% of Open matters have a dedicated, standardized SharePoint site by end of
  sprint.
- **SC-003**: A new matter can be fully provisioned (Team + site + channels + libraries +
  groups + metadata + AI placeholder) through one automated workflow with zero manual assembly
  steps.
- **SC-004**: 100% of newly provisioned matters are AI-ready with no separate AI-upload step
  required.
- **SC-005**: All three pilot matters (large/medium/small) pass the full validation checklist
  (permissions, documents, search, metadata, Team structure, SharePoint structure) before bulk
  provisioning begins.
- **SC-006**: Zero new matter channels are created in the legacy Clients Team after the freeze
  takes effect.
- **SC-007**: The Litigation Knowledge Repository exists, is read-only for most users, supports
  AI indexing, and is ready to receive historical matters by end of sprint.
- **SC-008**: The matter inventory accounts for 100% of existing matters, each with a single
  unambiguous classification (Prospective/Open/Closed).
- **SC-009**: Sprint 0 completes within the 3–5 day target window.
- **SC-010**: Local automation authenticates to Graph, SharePoint, and the Power Platform via
  the dedicated Entra ID app registration with no personal/ad-hoc credentials and no secrets
  committed to the repository.
- **SC-011**: Every channel-to-workspace conversion passes through its required manual-approval
  checkpoints; no legacy content/links are removed without an explicit human cutover approval.

## Assumptions

- The firm uses Microsoft 365 (Microsoft Teams + SharePoint Online) and has administrative
  rights sufficient to create templates, sites, security groups, and provisioning automation.
- "AI registration placeholder" means a standardized, machine-readable marker/configuration in
  each matter that future AI indexing/retrieval services will consume; building those services
  is out of scope this sprint.
- The standardized channel list provided is the firm's chosen practice set and may be
  finalized during template creation, but remains identical across all matters.
- The naming standard is `Matter Number – Client Last Name – Short Description` unless the firm
  finalizes a different single standard during the sprint.
- The PM owns and completes the inventory; engineering consumes it as the provisioning source.
- Network connectivity and licensing for Teams/SharePoint provisioning are available.
- Power Automate is IN SCOPE this sprint **only** as the channel-to-workspace conversion
  mechanism (US9). Power Automate **document workflows** (routing, approvals on documents,
  generation pipelines) remain OUT OF SCOPE and deferred.
- Closed-matter content migration, AI indexing of historical files, Power Automate document
  workflows, document generation, knowledge-graph implementation, and assistant integrations
  (ChatGPT, Copilot, Claude, Lexis Protégé) and advanced AI agents are explicitly OUT OF SCOPE
  for Sprint 0 and deferred to later sprints.
- Authentication for local automation uses a dedicated Microsoft Entra ID app registration
  (service principal). Certificate-based app-only auth is used for unattended bulk runs;
  interactive delegated sign-in is used for manual/pilot steps. Admin consent for app
  permissions requires a Global Administrator (or Privileged Role Administrator).
