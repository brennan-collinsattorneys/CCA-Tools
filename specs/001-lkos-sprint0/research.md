# Phase 0 Research & Decisions: LKOS Sprint 0

## Decision 1 — Provisioning technology

**Decision**: Use PowerShell 7+ with Microsoft Graph and PnP PowerShell. SharePoint sites are
applied from PnP provisioning templates (XML); Teams are applied from a Teams team template
plus channel creation via Graph.

**Rationale**: PnP PowerShell + Graph is the firm-friendly, scriptable, idempotent path for
M365 provisioning and is well-suited to one-click and bulk runs from a single inventory source.

**Alternatives rejected**: Manual point-and-click creation (not standardized, not scalable);
Power Automate flows (deferred — listed out of scope for Sprint 0).

## Decision 2 — System of record vs collaboration split

**Decision**: SharePoint Online site = system of record (documents, metadata, retention,
versioning). Teams = collaboration only, linked to the site; closed matters get no Team.

**Rationale**: Directly implements Constitution Principles I & II and keeps the records layer
clean and governable.

## Decision 3 — AI-readiness mechanism

**Decision**: AI-readiness is a provisioning output, not a later step: a standard "AI Workspace"
channel, an AI-indexable metadata model on every library, and a machine-readable "AI
registration placeholder" (a configuration marker/list item per matter) that future indexing/
retrieval services consume.

**Rationale**: Implements Principle III; avoids any separate "AI upload" process; supports
future OCR, semantic indexing, vector indexing, and knowledge-graph integration without rework.

## Decision 4 — Naming standard enforcement

**Decision**: Enforce `Matter Number – Client Last Name – Short Description` centrally in a
naming helper consumed by all provisioning paths; store the canonical rule in
`config/naming-standard.json`.

**Rationale**: Implements Principle IV; guarantees consistency across single and bulk creation.

## Decision 5 — Migration source of truth

**Decision**: The PM's master inventory spreadsheet is the authoritative source for
classification and bulk provisioning. Bulk provisioning reads validated Open rows only.

**Rationale**: Single trusted list prevents drift and enables automation over manual creation.

## Decision 6 — Pilot-before-scale

**Decision**: Provision three representative matters (large/medium/small), validate against a
fixed checklist, fix templates/automation, then bulk-provision.

**Rationale**: De-risks production rollout within the 3–5 day window.

## Decision 7 — Closed-matter repository scope

**Decision**: Build and configure the Litigation Knowledge Repository (read-only, AI-indexable,
shared metadata model) but do NOT migrate closed-matter content this sprint.

**Rationale**: Spec/Definition of Done require the repository to exist and be ready; content
migration is explicitly out of scope.

## Open Questions

- Exact retention durations/labels per library — to be confirmed with firm records policy
  (default to a single standard retention label until specified).
- Final channel list confirmation — provided list is treated as the standard unless the firm
  amends it during template creation.
