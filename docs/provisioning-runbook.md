# LKOS Provisioning Runbook

Operator guide for provisioning matters from the standardized templates. Authentication and
credentials are covered in [auth-setup.md](./auth-setup.md).

## Templates (source of truth)

| Template | File | Purpose |
|----------|------|---------|
| Matter Team | `templates/teams/matter-team-template.json` | Standard Team + channels (collaboration) |
| Matter metadata | `templates/sharepoint/matter-content-type.xml` | LKOS site columns + "LKOS Matter Document" content type |
| Matter Site | `templates/sharepoint/matter-site-template.xml` | System-of-record site: library, AI list, folders, permissions, versioning, retention |

The channel set in the Team template and the folder set in the site library are intentionally
identical and standardized across **every** matter. Do not customize per matter.

## Prerequisites

- Completed `config/lkos-settings.local.json` (tenant, client ID, cert thumbprint).
- App registration consented (see auth-setup.md).
- Connected session: `./src/common/Connect-LkosTenant.ps1 -Mode AppOnly` (or `-Mode Interactive`).

## One-click provisioning (recommended)

`New-MatterWorkspace.ps1` runs the entire flow in one command — security groups, Team + channels,
SharePoint site, metadata/retention, and the AI registration placeholder:

```powershell
./src/provisioning/New-MatterWorkspace.ps1 `
  -MatterId "2026-0142" `
  -ClientLastName "Nguyen" `
  -ShortDescription "MVA Personal Injury"
```

- Use `-WhatIf` for a dry run (prints what would happen, makes no changes).
- The script is **idempotent**: re-running for the same `MatterId` reuses the existing Team,
  groups, and site and reconciles them to the standard configuration.
- It connects app-only via `config/lkos-settings.local.json`; no interactive sign-in needed.
- Each stage (Connect, SecurityGroups, Team, Site, Metadata, AIRegistration) is reported; on
  failure the script tells you exactly which stage failed so you can re-run to reconcile.

### Building blocks (called by the orchestrator)

| Script | Responsibility |
|--------|----------------|
| `New-MatterSecurityGroups.ps1` | Create/reuse Owners/Members/ReadOnly Entra security groups |
| `New-MatterTeam.ps1` | Create/reuse Team + standard channels; resolve connected site |
| `New-MatterSite.ps1` | Apply content type + site template (library, folders, perms, versioning, retention) |
| `Set-MatterMetadata.ps1` | Stamp Matter ID/Client, set column defaults, apply retention label |
| `Register-MatterAIPlaceholder.ps1` | Add AI registration record (matter is AI-ready) |

## Update existing matters to the current template (in-place reconcile)

When the standard template changes, push **additive** changes to every existing matter:

```powershell
./src/migration/Update-AllMatters.ps1            # all matters (interactive approval gate)
./src/migration/Update-AllMatters.ps1 -MatterAlias 'matter-2026-0142' -WhatIf   # one matter, dry run
```

- Discovers matters by the `matter-` alias prefix (test matters excluded unless `-IncludeTestMatters`).
- Pauses at a **manual approval gate** (touches every matter); `-AutoApprove` for scheduled runs.
- For each matter: ensures the standard channels and re-applies the standard site configuration
  (content type, library, channel folders, AI list, metadata defaults, least-privilege permissions).
- **Additive only**: it adds what is missing. It does **not** rename or delete existing channels,
  columns, libraries, or content, and it does not restructure existing documents — rename/removal
  changes require deliberate one-off migrations. Keep template changes additive where possible.

## Instantiate a single matter from the templates (manual verification flow)

> The orchestrator above is the normal path. The manual steps below are useful for validating
> the templates in isolation during the pilot (US4).

1. **Apply the content type** (site columns + content type) to the target site:

```powershell
Connect-PnPOnline -Url $siteUrl -ClientId $clientId -Tenant $tenantId -Thumbprint $thumb
Invoke-PnPSiteTemplate -Path ./templates/sharepoint/matter-content-type.xml
```

2. **Apply the site template** with the matter's parameters (groups created by US2 tasks):

```powershell
Invoke-PnPSiteTemplate -Path ./templates/sharepoint/matter-site-template.xml -Parameters @{
    MatterId      = "2026-0142"
    OwnersGroup   = "LKOS-Matter-2026-0142-Owners"
    MembersGroup  = "LKOS-Matter-2026-0142-Members"
    ReadOnlyGroup = "LKOS-Matter-2026-0142-ReadOnly"
    RetentionLabel = "LKOS-Matter-Standard"
}
```

3. **Create the Team** from the template (tokens replaced by the provisioning script):

```powershell
# New-MatterTeam.ps1 (T017) reads templates/teams/matter-team-template.json, replaces
# {{MatterDisplayName}}, {{MatterId}}, {{ClientName}} (use Lkos.Naming for the display name),
# and POSTs to Graph /teams.
```

## Verification checklist (single matter)

Confirm the instantiated matter has the full standard structure:

- [ ] **Team channels**: General, Administration, Pleadings, Discovery, Medical Records,
      Experts, Depositions, Motions, Trial, Settlement, AI Workspace.
- [ ] **Library**: "Matter Documents" exists with the same folder set as the channels.
- [ ] **Content type**: "LKOS Matter Document" is the default content type on the library.
- [ ] **Metadata columns**: all `LKOS*` columns present; `LKOSMatterID` defaulted to the matter
      number; `LKOSMatterStatus` = Open; `LKOSAIIndexState` = Pending.
- [ ] **AI registration**: "LKOS AI Registration" list exists (matter is AI-ready by default).
- [ ] **Versioning**: major versions enabled with limits on the library.
- [ ] **Permissions**: role inheritance broken; Owners=Full Control, Members=Edit, ReadOnly=Read;
      no broad/anonymous sharing.
- [ ] **Retention**: retention label applied/recorded per `config/lkos-settings.json`.
- [ ] **Naming**: Team/site display name follows `Matter Number - Client Last Name - Short
      Description` (validate with `New-LkosMatterName`).

## Naming standard helper

```powershell
. ./src/common/Lkos.Naming.ps1
New-LkosMatterName -MatterNumber "2026-0142" -ClientLastName "Nguyen" -ShortDescription "MVA Personal Injury"
# DisplayName: 2026-0142 - Nguyen - MVA Personal Injury ; SiteAlias: matter-2026-0142
```

## Notes

- Keep `matter-content-type.xml` and `config/matter-metadata-model.json` in sync; field internal
  names are stable and must not be renamed once deployed.
- Bulk and one-click provisioning (US2/US5) reuse these exact templates — fix issues in the
  templates, never per matter.
