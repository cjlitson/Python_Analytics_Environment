<#
.SYNOPSIS
Configures per-user environment for the Analytics Workstation.
Creates the 'Analytics' conda env, Jupyter kernel, and VS Code extensions.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$EnvName = "Analytics"
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Locate conda.exe (user or local install)
$conda = "$env:USERPROFILE\Miniconda3\Scripts\conda.exe"
if (-not (Test-Path $conda)) { $conda = "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe" }
if (-not (Test-Path $conda)) { throw "conda.exe not found. Ask IT to run Install-Admin.ps1 first." }

# Locate environment.yml
$repoRoot = Resolve-Path "$PSScriptRoot\.."
$envYml   = Join-Path $repoRoot "environment.yml"
if (-not (Test-Path $envYml)) { throw "environment.yml not found at $envYml" }

# Remove old env and recreate from YAML
Write-Information "Recreating Conda environment: $EnvName"
if ($PSCmdlet.ShouldProcess("Conda env $EnvName","Remove")) {
  & $conda env remove -n $EnvName -y | Out-Null 2>$null
}
if ($PSCmdlet.ShouldProcess("Conda env $EnvName","Create")) {
  & $conda env create -n $EnvName -f $envYml -y
}

# Register Jupyter kernel
$py = "$env:USERPROFILE\Miniconda3\envs\$EnvName\python.exe"
if (-not (Test-Path $py)) { $py = "$env:LOCALAPPDATA\miniconda3\envs\$EnvName\python.exe" }
if ($PSCmdlet.ShouldProcess("Jupyter kernel $EnvName","Install")) {
  & $py -m ipykernel install --user --name $EnvName --display-name "Python 3.11 ($EnvName)"
}

# Install recommended VS Code extensions
$exts = @(
  "ms-python.python",
  "ms-python.vscode-pylance",
  "ms-toolsai.jupyter",
  "ms-mssql.mssql",
  "eamodio.gitlens",
  "charliermarsh.ruff",
  "ms-python.black-formatter",
  "ms-vscode.powershell"
)

foreach ($e in $exts) {
  if ($PSCmdlet.ShouldProcess("VS Code extension $e","Install")) {
    code --install-extension $e --force
  }
}

Write-Information "`n✅ User environment ready."
Write-Information "In VS Code: Ctrl+Shift+P → 'Python: Select Interpreter' → Python 3.11 ($EnvName)"

