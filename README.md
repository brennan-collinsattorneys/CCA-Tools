# CCA-Tools — Legal Knowledge Operating System (LKOS)

Tooling and specifications for Collins & Collins' Legal Knowledge Operating System (LKOS):
the permanent Microsoft 365 information architecture for legal matters (standardized Teams +
SharePoint, automated provisioning, and a Litigation Knowledge Repository).

This repository uses [GitHub Spec Kit](https://github.com/github/spec-kit) for
Spec-Driven Development.

## Layout

- `.specify/` — Spec Kit toolchain (templates, scripts, constitution).
- `specs/001-lkos-sprint0/` — Sprint 0 specification, plan, design docs, and tasks.
  - `spec.md` — feature specification (user stories, requirements, success criteria)
  - `plan.md` — implementation plan and architecture
  - `tasks.md` — actionable, dependency-ordered task list
  - `research.md`, `data-model.md`, `contracts/`, `quickstart.md` — supporting design docs

## Guiding Principles

See `.specify/memory/constitution.md`:

1. SharePoint is the System of Record.
2. Teams is the Collaboration Workspace.
3. AI is a core component of every matter.
4. Every accepted matter receives the same standardized architecture.
5. Closed matters become institutional knowledge, not collaboration workspaces.

## Spec Kit workflow

`/speckit-constitution` → `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement`
