# IT Deployment — Step by Step (Pilot/Prod + Code Signing)

## 0) Create Azure DevOps Project & Repo
- Project: **Python-Analytics-Environment**
- Repo: **workstation-template** (import this repo)

## 1) Upload Code-Signing Certificate (recommended)
- Pipelines → **Library** → **Secure files** → Upload PFX as `codesign.pfx`
- Pipelines → **Library** → **Variable groups** → Create `workstation-secure`
  - Secret variable **CODESIGN_PASSWORD** = PFX password

## 2) Create Environments with Approvals
- Pipelines → **Environments** → New: `Pilot-Release` (add approvers)
- Pipelines → **Environments** → New: `Prod-Release` (add approvers)

## 3) Create the Pipeline
- Pipelines → New pipeline → select repo → YAML → `azure-pipelines.yml`
- Variables default to:
  - `EnableCodeSigning: true`
  - `CodeSignSecureFile: codesign.pfx`
  - `ReleasePilotEnvironmentName: Pilot-Release`
  - `ReleaseProdEnvironmentName: Prod-Release`

## 4) Run Pipeline
- **Build**: lints scripts; packages `python-analytics-env.zip`
- **Sign**: signs `.ps1` files using your PFX; outputs `python-analytics-env-signed.zip`
- **Release: Pilot**: waits for approval on `Pilot-Release`; publishes signed artifact
- **Release: Prod**: waits for approval on `Prod-Release`; publishes signed artifact

## 5) Rollout
- IT grabs the released artifact ZIP.
- On target machine:
  - **Admin**: `setup/Install-Admin.ps1` (apps; Power BI excluded—IT-managed elsewhere)
  - **User**: `setup/Install-UserEnv.ps1` (creates env, kernel, installs VS Code extensions)

## Version Pinning
- Edit `setup/app-versions.json`:
```json
{
  "Microsoft.VisualStudioCode": "",
  "Git.Git": "",
  "Anaconda.Miniconda3": "",
  "Microsoft.ODBCDriverForSQLServer.18": "",
  "Microsoft.AzureCLI": "",
  "Microsoft.Azure.AZCopy.10": "",
  "Microsoft.AzureDataStudio": ""
}
```
- Set values to freeze versions; leave empty for latest.

## Proxy / Offline
- Add to top of scripts if needed:
```
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
$env:HTTP_PROXY  = "http://proxy.company.com:8080"
```
- For offline: replace winget calls with internal MSIs + `msiexec /i ... /qn`.

## OneLake File Explorer
- Package MSIX separately as per policy (not auto-installed here).
