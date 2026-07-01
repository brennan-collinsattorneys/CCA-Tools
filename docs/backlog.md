# LKOS Backlog & Open Questions

A living list of decisions to figure out and workstreams deferred beyond Sprint 0. Update as items
are resolved (move to Done or into `specs/.../tasks.md` when they become concrete work).

Last updated: 2026-07-01 (channel template approved — see D1)

---

## A. Open decisions / awaiting input

### A2. Legacy "C&C- Civil Rights" channel classification
Draft inventory built at `inventory/civil-rights-inventory.draft.csv` (local, git-ignored — PII).
Open questions before conversion:
- Meaning of the **`(PC)`** tag (assumed "Prospective Client" → Eval).
- Meaning of **color/RW tags**: `(BLUE)`, `(PINK)`, `(PURPLE)`, `(RW.*)`.
- How to treat **Class Action / Administrative / Test** channels (exclude from per-matter conversion?).
- **Matter numbering** source (Clio matter numbers? manual? provisional scheme?).
- **Multi-channel clients** — consolidate into one matter with sub-topics, or separate matters
  (e.g., Chacon Adrian ×3; Allen Jacob "HAND" vs "INFECTION…"; Abarca "Dollar Store" vs "MDC").
- **Owner / next step**: Stakeholder + PM.
- **Status**: Awaiting input.

### A3. External analytics data source (SharePoint → Azure Storage sync)
- **What**: External collaborators will run data analysis on matter files; they want the data
  available as a source in **Azure Storage / Data Lake** (not the live SharePoint site).
- **Notes**: SharePoint does not natively sync to Azure Blob; requires a pipeline (Power Automate /
  Logic Apps / Azure Data Factory / Graph Data Connect / custom Function on Graph change
  notifications). A *backup* store is not a good analytics source. Likely needs OCR/text extraction
  first. See B2 for the build.
- **Questions to answer (with the external analysts)**: volume & cadence (real-time vs nightly);
  raw files vs extracted text/data; analytics tooling (Fabric / Synapse / Databricks / Power BI /
  custom); how external analysts authenticate to the Azure data source; per-matter isolation +
  privilege/ethical-wall requirements in Azure.
- **Owner / next step**: User to consult external members, then report back.
- **Status**: Blocked on external-team discussion.

### A4. Backup & data-protection strategy
- **What**: SharePoint's built-in protection is limited (93-day recycle bin, version history,
  30-day library restore) — not a long-term customer backup.
- **Options**: Microsoft 365 Backup (first-party) vs third-party (Veeam/AvePoint/etc. to Azure
  Blob); plus Purview retention + legal hold.
- **Owner / next step**: Decision on backup approach; verify M365 Backup licensing on tenant.
- **Status**: Open decision.

### A5. Purview retention label
- **What**: Provisioning wires a `LKOSRetentionLabel` field but no label is defined; retention is
  currently skipped. Define a firm retention label and put its id in `config/lkos-settings.json`
  (`retention.matterRetentionLabelId`) so provisioning applies it.
- **Owner / next step**: Records policy + admin.
- **Status**: Open.

### A6. Tenant default share-link type
- **What**: Tenant default share link is `AnonymousAccess` ("Anyone with the link"). Matter sites
  are already provisioned as guests-only/no-anonymous, but the tenant default is still permissive.
- **Recommendation**: Change tenant default to "Specific people".
- **Owner / next step**: SharePoint admin decision.
- **Status**: Recommended; not actioned.

---

## B. Future workstreams (post–Sprint 0)

### B1. Event-driven auto-provisioning in Azure Functions
- **What**: Run the provisioning scripts automatically when a new matter is created (target:
  Azure Functions, PowerShell).
- **Adaptations needed**: add a **Managed Identity** (or Key Vault) auth mode to
  `Connect-LkosTenant`; load config from **App Settings / environment / Key Vault** instead of the
  local json; consider **Durable Functions** or a Premium plan (provisioning runs ~2–4 min with
  retries, Consumption caps at 10 min); refactor scripts into an importable **PowerShell module**;
  add **429/backoff** handling; grant the managed identity the same Graph/SharePoint app roles.
- **Trigger**: likely a **Clio** webhook (existing channels carry Clio Matter IDs) or HTTP/queue.
- **Reusability**: core scripts are parameter-driven, idempotent, non-interactive → reusable as-is.
- **Status**: Deferred ("cross that bridge when we get there").

### B2. Matter data-lake sync to Azure Storage for analytics
- **What**: Build the SharePoint → Azure Data Lake pipeline that feeds A3, with per-matter
  isolation (RBAC, matter-scoped containers) and (likely) OCR/text extraction. Downstream of the
  AI-ready architecture (OCR / metadata / semantic + vector indexing).
- **Status**: Blocked on A3 answers.

### B3. Rename/removal template reconcile (US10)
- **What**: Build the destructive change-set reconcile (rename/remove channels, columns,
  libraries) with content report + approval gate. Tasks **T059–T065** are specced but not built.
- **Status**: Specced, not implemented. Channel template is approved (see D1); lower priority now.

### B4. Power Automate channel-to-workspace conversion (US9)
- **What**: Build the human-gated conversion flow that turns legacy channels into standardized
  matter workspaces. Tasks **T036–T041**.
- **Status**: Specced, not implemented; depends on A2 (channel classification).

### B5 & B6. Litigation Knowledge Repository + closed-matter migration (US8)
- **What**: Stand up the read-only, AI-indexable repository (T050–T053); closed-matter content
  migration remains deferred.
- **Status**: Specced, not implemented.

---

## C. Pending validations

### C1. Live external-access + status-change validation (T070)
- Grant a **test external guest** to a matter and change its status; confirm per-matter scoping.
- **Blocked on**: a throwaway external email address.

### C2. PM inventory population (T026 / T027)
- PM populates `inventory/matter-inventory.xlsx` (git-ignored) and classifies each matter
  (Eval / Pre-Litigation / Litigation / Closed). Importer validates instantly.
- **Status**: Awaiting PM data.

---

## D. Resolved

### D1. Standard channel template sign-off — APPROVED (2026-07-01)
Stakeholder approved the standard 11-channel matter template (General, Administration, Pleadings,
Discovery, Medical Records, Experts, Depositions, Motions, Trial, Settlement, AI Workspace) after
reviewing the test workspace. The current template is cleared for use.
