# Provisioning Contract: New-MatterWorkspace

Single-workflow contract for one-click matter provisioning.

## Inputs

| Field | Required | Description |
|-------|----------|-------------|
| MatterID | yes | Unique matter identifier |
| ClientLastName | yes | For naming standard |
| ShortDescription | yes | For naming standard |
| LeadAttorney | yes | Owner assignment |
| AssignedStaff | no | Members for Team + groups |
| PracticeArea | no | May influence default libraries |

## Outputs (all produced in one run)

- Microsoft Team created from standard template with all standard channels.
- SharePoint site created from standard template (libraries, metadata columns, versioning,
  retention) and linked to the Team.
- Matter ID recorded and applied as site metadata.
- Security groups created/assigned (least privilege).
- Metadata model applied; naming standard `Matter Number – Client Last Name – Short
  Description` enforced on Team + site display names.
- Optional Planner plan (if adopted).
- Optional Microsoft List(s) (if adopted).
- AI registration placeholder emitted (machine-readable marker for future AI indexing).

## Behavior / Guarantees

- **Idempotent**: Re-running for an existing MatterID does not create duplicates; it reconciles
  to the standard configuration.
- **No manual steps**: A successful run yields a fully usable, AI-ready matter workspace.
- **Naming enforced**: Non-conforming names are normalized before creation.
- **Validation surface**: Output exposes enough detail to run the pilot validation checklist
  (permissions, documents, search, metadata, Team structure, SharePoint structure).

## Errors

- Missing required input → fail fast with actionable message; no partial Team/site left behind
  (or clearly flagged for cleanup).
- Insufficient permissions → fail with explicit tenant-permission guidance.
- Closed/Prospective status passed to bulk provisioning → skipped (only Open is provisioned).
