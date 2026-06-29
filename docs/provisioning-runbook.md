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

## Instantiate a single matter from the templates (verification flow)

> Until the orchestrator (`New-MatterWorkspace.ps1`, task T022) is built, you can validate the
> templates manually with PnP/Graph as below.

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
