# Legal Knowledge Operating System (LKOS) Constitution

<!--
Sync Impact Report
- Version change: (template) → 1.0.0
- Ratified for: Collins & Collins LKOS program (Sprint 0 and all future sprints)
- Modified principles: Initial ratification (all principles new)
- Added sections: Core Principles (5), Architecture Constraints, Delivery Workflow, Governance
- Removed sections: None
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ Constitution Check gate references these principles
  - .specify/templates/spec-template.md ✅ no change required
  - .specify/templates/tasks-template.md ✅ no change required
- Follow-up TODOs: None
-->

## Core Principles

### I. SharePoint Is the System of Record

All authoritative matter documents, metadata, and case files live in SharePoint, not
in Teams chat, local drives, or personal mailboxes. Teams surfaces and collaborates on
content; SharePoint owns it. Any workflow, automation, or integration MUST read from and
write authoritative data to SharePoint. Document libraries, metadata columns, versioning,
and retention settings are mandatory and standardized — not optional per-matter choices.

**Rationale**: A single, governed source of truth is the foundation for retention,
discovery, security, and every downstream AI and knowledge-management capability.

### II. Teams Is the Collaboration Workspace (Not Storage)

Microsoft Teams is the collaboration and communication layer for active matters only.
Teams MUST NOT be treated as a permanent records repository. Closed matters MUST NOT
retain a Team. Channels mirror the standardized matter structure and link back to the
SharePoint system of record rather than duplicating it.

**Rationale**: Separating collaboration from records prevents data sprawl and keeps the
records layer clean, governable, and audit-ready.

### III. AI Is a Core Component of Every Matter (AI-Ready by Default)

Every accepted matter is provisioned AI-ready from day one. The architecture MUST support
OCR, metadata extraction, semantic indexing, AI retrieval, future vector indexing, and
knowledge-graph integration without any separate "AI upload" step. AI readiness is a
property of provisioning, never a manual afterthought.

**Rationale**: Retrofitting AI onto unstructured archives is expensive and unreliable;
building it into the information architecture makes every future AI capability cheap.

### IV. Standardized Architecture for Every Accepted Matter

Every accepted matter receives the same architecture: the same Team template, the same
SharePoint site template, the same channels, libraries, metadata model, security groups,
and naming convention. Bespoke or hand-built matter structures are prohibited. New matters
are created only through the automated provisioning process.

**Rationale**: Standardization is what makes automation, search, AI, and bulk operations
possible across the entire matter portfolio.

### V. Closed Matters Become Institutional Knowledge

Closed matters are migrated into the Litigation Knowledge Repository as read-only
institutional knowledge, not active collaboration workspaces. The repository uses the same
metadata model where practical and supports AI indexing. Teams are never created for
closed matters.

**Rationale**: Past work is a firm asset. Preserving it as searchable, AI-indexable
knowledge — separate from active collaboration — compounds the firm's expertise over time.

## Architecture Constraints

- **One-click provisioning**: New matters MUST be created by a single automated workflow
  that produces Team, SharePoint site, Matter ID, standard channels, document libraries,
  security groups, metadata, and an AI registration placeholder. Manual creation is the
  exception, not the rule.
- **Naming standard**: A single consistent naming convention applies to every matter
  (e.g., `Matter Number – Client Last Name – Short Description`). Provisioning enforces it.
- **Legacy freeze**: After Sprint 0, no new matter channels are created in the legacy
  "Clients" Team. That Team is limited to intake, referrals, and administrative functions.
- **Least privilege**: Security groups govern access per matter; the Litigation Knowledge
  Repository is read-only for most users.
- **Retention & versioning**: Standardized retention and versioning settings apply to all
  matter sites and the knowledge repository.

## Delivery Workflow

- Work follows the Spec-Driven Development flow: constitution → spec → plan → tasks →
  implementation, using the `.specify` toolchain.
- Pilot-before-scale: representative large, medium, and small matters are provisioned and
  validated (permissions, documents, search, metadata, Team and SharePoint structure)
  before any bulk provisioning.
- The PM's matter inventory spreadsheet is the authoritative migration source list; bulk
  provisioning consumes it rather than relying on manual creation.
- Closed-matter content migration and other deferred capabilities (AI indexing of
  historical files, Power Automate document workflows, document generation, knowledge-graph
  implementation, and assistant integrations) are explicitly out of scope for Sprint 0 and
  scheduled for later sprints on top of this architecture.

## Governance

This constitution supersedes ad-hoc practices for matter information architecture at
Collins & Collins. All specs, plans, and tasks MUST verify compliance with these
principles; deviations MUST be documented and justified in the relevant plan's Complexity
Tracking section. Amendments require documented rationale, version increment per the policy
below, and a migration note when existing matters are affected.

- **Versioning policy**: Semantic versioning. MAJOR for principle removals or incompatible
  governance changes; MINOR for new principles or materially expanded guidance; PATCH for
  clarifications and wording.
- **Compliance review**: Every provisioning change and every new sprint is reviewed against
  these principles before release.

**Version**: 1.0.0 | **Ratified**: 2026-06-29 | **Last Amended**: 2026-06-29
