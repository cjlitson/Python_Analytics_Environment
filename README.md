# Python Analytics Environment Base — Fabric-Ready (Admin/User + AzDO Pilot/Prod)

This repo standardizes our Python analytics environment and distribution:

- **Admin** and **User** installers (PowerShell) for automated setup
- **Version pinning** via `environment.yml` (Python 3.11 + analyst packages)
- **Azure DevOps pipeline** to package (and optionally sign) a versioned ZIP
- **Pilot → Prod** environments in DevOps (optional approvals for Prod)

---

## Quick Start

### Local/manual distribution (works even without the pipeline)
1. Place this folder on a shared location (SharePoint/OneDrive/\\Share\python-analytics-env).
2. Open **PowerShell** and copy/paste the setup scripts:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ./setup/Install-Admin.ps1   # installs prerequisites like Miniconda, VS Code, Git, etc.
   ./setup/Install-User.ps1    # creates/updates the Analytics conda env and Jupyter kernel
   ```
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
- PowerShell installers: `setup/Install-Admin.ps1` and `setup/Install-User.ps1`
- Manual steps: see Quick Start for command-line equivalents
