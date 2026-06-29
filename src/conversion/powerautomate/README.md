# Power Automate — Channel-to-Workspace Conversion (US9)

This folder holds the exported Power Automate solution and design notes for converting existing
matter **channels** in the legacy Clients Team into their own standardized **workspaces**
(Team + SharePoint site), with mandatory human-approval gates.

> Scope: Power Automate is used here **only** for channel-to-workspace conversion. Power Automate
> document workflows remain out of scope for Sprint 0.

## Authentication

- The Power Platform CLI (`pac`) authenticates with the LKOS Entra ID service principal
  (see `docs/auth-setup.md`).
- The flow itself acts through governed **connections** (service account / service principal),
  not personal ad-hoc credentials.

## Flow design (to build — task T038)

1. **Trigger**: manual / scheduled, taking a batch of channels (or reading the validated Open
   set from the matter inventory).
2. **Per channel**: map channel → matter inputs (Matter ID, Client last name, short description).
3. **Provision**: invoke standardized provisioning (the `New-MatterWorkspace` equivalent) to
   create the Team + SharePoint site with standard channels, libraries, metadata, security
   groups, and the AI registration placeholder.
4. **Copy content**: move channel files into the new matter site, applying the metadata model.
5. **Approval gate (batch)**: pause for human approval before processing / committing each batch.
6. **Approval gate (cutover)**: pause for human verification/approval before removing legacy
   links/content; preserve legacy links until approved.

## Manual gates (task T039)

Use Power Automate **Approvals** (or the `Request-LkosApproval.ps1` semantics) at:
- Start of each conversion batch.
- Before cutover (legacy link/content removal).

## Runbook

Operational steps live in `docs/conversion-runbook.md` (task T041).
