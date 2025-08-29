# Python Analytics Environment Base — Fabric-Ready (Admin/User + AzDO Pilot/Prod)

This repo standardizes our Python analytics environment and distribution:

- **Admin** and **User** installers (PowerShell)
- **Version pinning** via `environment.yml` (Python 3.11 + analyst packages)
- **Azure DevOps pipeline** to package (and optionally sign) a versioned ZIP
- **Click-to-run launchers**: `Run-Setup.bat`, `Run-Admin.bat` and `Run-User.bat`
- **Pilot → Prod** environments in DevOps (optional approvals for Prod)

---

## Quick Start

### Local/manual distribution (works even without the pipeline)
1. Place this folder on a shared location (SharePoint/OneDrive/`\\Share\python-analytics-env`).
2. Run `Run-Setup.bat` and follow the prompts:
   - **Admin** option installs Miniconda (All Users), VS Code, Git, ODBC 18, Azure CLI, AzCopy, etc.
   - **User** option creates/updates the **Analytics** conda env, adds a Jupyter kernel, and installs VS Code extensions.
   *(Direct modes remain available via `Run-Admin.bat` and `Run-User.bat`.)*
3. In VS Code: **Python: Select Interpreter** → *Python 3.11 (Analytics)*

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

- Guided: `Run-Setup.bat` (prompts for Admin or User)
- IT: `Run-Admin.bat` (elevated)
- Analyst: `Run-User.bat`

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
