# Analytics Workstation Base — Fabric Ready (Admin/User + AzDO Pilot/Prod Release)

This repo standardizes the analytics workstation and includes:
- **Admin** and **User** installers
- **Version pinning** via JSON (change windows)
- **Azure DevOps multi-stage pipeline** (Build → Sign → Release: Pilot → Release: Prod)
- **Code signing enabled by default** using a PFX from Azure DevOps Secure Files
- **Environment approvals** for Pilot and Prod

## Quick Use
1. IT runs **Admin** installer on machines (VS Code, Git, Miniconda, ODBC18, Azure CLI, AzCopy).
2. Analysts run **User** installer (creates `Analytics` conda env, Jupyter kernel, VS Code extensions).
3. Azure DevOps builds, signs, and publishes versioned artifacts through **Pilot** then **Prod** (with approvals).

See `docs/IT-Deployment.md` for a step-by-step guide.
