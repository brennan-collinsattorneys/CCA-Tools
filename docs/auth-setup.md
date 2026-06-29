# LKOS Authentication & Credentials Setup

This guide sets up the single credential that all LKOS local automation uses to connect to
Microsoft Graph, SharePoint Online, and the Power Platform (Power Automate): a dedicated
**Microsoft Entra ID app registration** (service principal).

> No personal passwords or client secrets are committed to this repo. App-only auth uses a
> **certificate** stored in your Windows certificate store. Tenant/Client IDs and the
> certificate thumbprint live in `config/lkos-settings.local.json` (git-ignored).

## Authentication modes

| Mode | Used for | How you authenticate |
|------|----------|----------------------|
| **Delegated (interactive)** | Manual checkpoints, pilots, anything run "as you" | Browser sign-in (MFA supported) |
| **App-only (unattended)** | Bulk provisioning, scheduled/scripted runs | Certificate (thumbprint) — no human present |

You will use **both**. Bulk runs use app-only; manual gates use interactive.

## Prerequisites

- PowerShell 7+
- Modules: `Install-Module PnP.PowerShell, Microsoft.Graph -Scope CurrentUser`
- Power Platform CLI (for US9 conversion): `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`
- Roles for the **person doing setup** (one-time): **Global Administrator** or
  **Privileged Role Administrator** (to grant admin consent), plus **SharePoint Administrator**
  and **Teams Administrator** for the operational steps.

## Step 1 — Register the Entra ID app + certificate

Run the helper (creates the app, generates a self-signed cert in `Cert:\CurrentUser\My`,
uploads the public key, and prints the values to record):

```powershell
./src/common/Register-LkosEntraApp.ps1 `
  -ApplicationName "LKOS-Provisioning" `
  -TenantDomain   "collinsattorneys.onmicrosoft.com"
```

> Why your own app: the shared "PnP Management Shell" multi-tenant app was retired (Sept 2024),
> so a tenant-owned app registration is required.

Record the printed **Application (client) ID**, **Tenant (directory) ID**, and **certificate
thumbprint** into `config/lkos-settings.local.json` (copy from `config/lkos-settings.local.sample.json`).

## Step 2 — Grant API permissions (admin consent)

In Entra admin center → App registrations → LKOS-Provisioning → **API permissions**, add the
following **Application** permissions and click **Grant admin consent**:

**Microsoft Graph**
- `Group.ReadWrite.All`
- `Directory.ReadWrite.All`
- `GroupMember.ReadWrite.All`
- `Team.Create`
- `Channel.Create`
- `TeamSettings.ReadWrite.All`
- `Sites.FullControl.All` *(or `Sites.Selected` for least privilege — see note)*

**SharePoint**
- `Sites.FullControl.All` *(or `Sites.Selected`)*

> **Least privilege (recommended):** use `Sites.Selected` and grant the app access only to the
> specific site collections it manages (per-site grant via Graph/PnP). This matches the LKOS
> constitution's least-privilege principle. Use tenant-wide `Sites.FullControl.All` only if
> per-site granting is impractical for the sprint timeline.

## Step 3 — Power Platform (for the US9 conversion flow)

1. In the target Power Platform environment, add the app's service principal as an
   **application user** with an appropriate security/Dataverse role.
2. Authenticate the CLI:

```powershell
pac auth create --tenant <TenantId> --applicationId <ClientId> --certificate <thumbprint-or-pfx>
```

Note: Power Automate flows act through **connections** (OAuth connection references to
SharePoint/Teams) created under a service account or service principal — the local credential
gets you into the environment to author, deploy, and trigger flows.

## Step 4 — Verify connections

```powershell
# Interactive (delegated)
./src/common/Connect-LkosTenant.ps1 -Mode Interactive

# App-only (certificate)
./src/common/Connect-LkosTenant.ps1 -Mode AppOnly
```

## What goes where (secrets hygiene)

- `config/lkos-settings.json` — committed; placeholders + non-secret structure (scopes, URLs templates).
- `config/lkos-settings.local.json` — **git-ignored**; your real Tenant ID, Client ID, thumbprint, env URL.
- Certificate — in `Cert:\CurrentUser\My`; never export a `.pfx` into the repo.
- Never commit client secrets. Prefer certificate auth everywhere.

## Values you must obtain from Azure / Microsoft 365

Provide these (Step 1 produces the last two):

| Value | Where to find it |
|-------|------------------|
| **Tenant ID** (Directory ID) | Entra admin center → Overview |
| **Primary domain** | e.g. `collinsattorneys.onmicrosoft.com` |
| **SharePoint root URL** | e.g. `https://collinsattorneys.sharepoint.com` |
| **SharePoint admin URL** | e.g. `https://collinsattorneys-admin.sharepoint.com` |
| **Application (client) ID** | Output of `Register-LkosEntraApp.ps1` (or the app's Overview) |
| **Certificate thumbprint** | Output of `Register-LkosEntraApp.ps1` |
| **Power Platform environment URL/ID** | Power Platform admin center → Environments |
| **Legacy Clients Team ID / SharePoint URL** | The existing Team and its connected site |
