# Python Analytics Environment Base — Fabric-Ready (Admin/User + AzDO Pilot/Prod)

This repo standardizes our Python analytics environment and distribution:

- **Admin** and **User** installers (PowerShell) for automated setup
- **Windows installer** for environments where scripts are blocked
- **Version pinning** via `environment.yml` (Python 3.11 + analyst packages)
- **Azure DevOps pipeline** to package (and optionally sign) a versioned ZIP
- **Pilot → Prod** environments in DevOps (optional approvals for Prod)

---

## Quick Start

### Local/manual distribution (works even without the pipeline)
1. Place this folder on a shared location (SharePoint/OneDrive/\\Share\python-analytics-env).
2. Run the Windows installer `Python-Analytics-Env-Setup.exe` **or** use PowerShell installers if scripts are allowed:
   - `setup/Install-Admin.ps1` installs Miniconda, VS Code, Git, ODBC 18, Azure CLI, AzCopy, etc.
   - `setup/Install-User.ps1` creates/updates the **Analytics** conda env, adds a Jupyter kernel, and installs VS Code extensions.
3. If script execution is blocked, perform the steps manually:
   ```bash
   conda env create -n Analytics -f environment.yml
   python -m ipykernel install --user --name Analytics --display-name "Python 3.11 (Analytics)"
   code --install-extension ms-python.python ms-python.vscode-pylance ms-toolsai.jupyter ms-mssql.mssql "eamodio.gitlens" charliermarsh.ruff ms-python.black-formatter ms-vscode.powershell
   ```
4. In VS Code: **Python: Select Interpreter** → *Python 3.11 (Analytics)*
### CI/CD distribution (recommended)
1. DevOps pipeline builds a ZIP and publishes it as the **drop** artifact.
2. (Optional) Signing stage produces a **signed** artifact.
3. Pilot/Prod stages download the right artifact and make it available to end users.

---

## Pipeline knobs

- **Disable/enable auto runs**:  
  - Manual only:  
    ```yaml
    trigger: none
    pr: none
    ```
  - Auto on main (recommended with path filters):  
    ```yaml
    trigger:
      branches: { include: [ main ] }
      paths:
        include:
          - environment.yml
          - setup/**
          - azure-pipelines.yml
    pr:
    - main
    ```

- **Code signing** (optional):
  1. Library → **Secure files** → upload `codesign.pfx`.
  2. Pipeline variables → add secret **CODESIGN_PASSWORD**.
  3. In YAML set `EnableCodeSigning: 'true'`.

---

## Environments

Create two DevOps environments (one-time):
- **Pilot-Release** – no approvals (fast validation)
- **Prod-Release** – add approval(s) in Environment → *Checks*

---

## What to run
- Windows installer: `Python-Analytics-Env-Setup.exe`
- PowerShell installers (if allowed): `setup/Install-Admin.ps1` and `setup/Install-User.ps1`
- Manual steps: see Quick Start for command-line equivalents
## Windows Installer (no PowerShell UI)

We now ship a classic Windows installer built with **Inno Setup**. It:
- Creates a Python environment from `environment.yml` using **micromamba**
- Registers a Jupyter kernel
- (Optional) installs VS Code extensions if VS Code is present

### Build locally
1. Install Inno Setup: https://jrsoftware.org/isinfo.php
2. From repo root, fetch payload:
   ```powershell
   powershell -ExecutionPolicy Bypass -File installer/fetch-payload.ps1
   ```
3. Open `installer/build.iss` in Inno Setup Compiler and click **Build**.
4. Output is `Output/Python-Analytics-Env-Setup.exe`.

### Build in GitHub Actions (optional)

* Workflow: `.github/workflows/build-installer.yml`
* Trigger manually or push a tag `vX.Y.Z`.
* Download the installer from workflow artifacts.

### Run

After building or downloading `Python-Analytics-Env-Setup.exe`, launch it and follow the wizard prompts. For a silent install, run:

```powershell
./Python-Analytics-Env-Setup.exe /VERYSILENT
```

### Install defaults

* Root directory: `C:\Tools\python-analytics`
* Environment name: `Analytics`
* Jupyter kernel display name: `Python 3.11 (Analytics)`
