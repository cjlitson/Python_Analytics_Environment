# Python Analytics Environment Base — Fabric-Ready (Admin/User + AzDO Pilot/Prod)

This repo standardizes our Python analytics environment and distribution:

- **Admin** and **User** installers (PowerShell)
- **Version pinning** via `environment.yml` (Python 3.11 + analyst packages)
- **Azure DevOps pipeline** to package (and optionally sign) a versioned ZIP
- **Click-to-run launchers**: `Run-Admin.bat` and `Run-User.bat`
- **Pilot → Prod** environments in DevOps (optional approvals for Prod)

---

## Quick Start

### Local/manual distribution (works even without the pipeline)
1. Place this folder on a shared location (SharePoint/OneDrive/`\\Share\python-analytics-env`).
2. **IT (Admin)** runs `Run-Admin.bat` (right-click → *Run as administrator*).  
   Installs Miniconda (All Users), VS Code, Git, ODBC 18, Azure CLI, AzCopy, etc.
3. **Analysts (User)** run `Run-User.bat`.  
   Creates/updates the **Analytics** conda env, adds a Jupyter kernel, and installs VS Code extensions.
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

- IT: `Run-Admin.bat` (elevated)
- Analyst: `Run-User.bat`
