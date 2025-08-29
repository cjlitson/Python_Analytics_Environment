<#
.SYNOPSIS
Configures per-user environment for the Analytics Workstation.
Creates the 'Analytics' conda env, Jupyter kernel, and VS Code extensions.
#>

[CmdletBinding()]
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

# Create or update env from YAML
$envDirs = @(
  "$env:USERPROFILE\Miniconda3\envs\$EnvName",
  "$env:LOCALAPPDATA\miniconda3\envs\$EnvName"
)
$envExists = $false
foreach ($d in $envDirs) {
  if (Test-Path $d) { $envExists = $true; break }
}
if ($envExists) {
  $resp = Read-Host "$EnvName environment already exists. Update from environment.yml? [y/N]"
  if ($resp -match '^[Yy]') {
    Write-Information "Updating Conda environment: $EnvName"
    & $conda env update -n $EnvName -f $envYml --prune
  } else {
    Write-Information "Skipping environment update."
  }
} else {
  Write-Information "Creating Conda environment: $EnvName"
  & $conda env create -n $EnvName -f $envYml -y
}

# Register Jupyter kernel
$py = "$env:USERPROFILE\Miniconda3\envs\$EnvName\python.exe"
if (-not (Test-Path $py)) { $py = "$env:LOCALAPPDATA\miniconda3\envs\$EnvName\python.exe" }
& $py -m ipykernel install --user --name $EnvName --display-name "Python 3.11 ($EnvName)"

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

foreach ($e in $exts) { code --install-extension $e --force }

Write-Information "`n✅ User environment ready."
Write-Information "In VS Code: Ctrl+Shift+P → 'Python: Select Interpreter' → Python 3.11 ($EnvName)"

