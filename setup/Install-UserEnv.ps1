<#
.SYNOPSIS
  User-level installer: creates the 'Analytics' conda env, Jupyter kernel, and VS Code extensions.
#>
[CmdletBinding()]
param(
  [string]$EnvName = "Analytics"
)
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$conda = "$env:USERPROFILE\Miniconda3\Scripts\conda.exe"
if (-not (Test-Path $conda)) { $conda = "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe" }
if (-not (Test-Path $conda)) { throw "conda.exe not found. Ask IT to run Install-Admin.ps1 first." }
$repoRoot = Resolve-Path "$PSScriptRoot\.."
$envYml   = Join-Path $repoRoot "environment.yml"
if (-not (Test-Path $envYml)) { throw "environment.yml not found at $envYml" }
& $conda env remove -n $EnvName -y | Out-Null 2>$null
& $conda env create -n $EnvName -f $envYml -y
$py = "$env:USERPROFILE\Miniconda3\envs\$EnvName\python.exe"
if (-not (Test-Path $py)) { $py = "$env:LOCALAPPDATA\miniconda3\envs\$EnvName\python.exe" }
& $py -m ipykernel install --user --name $EnvName --display-name "Python 3.11 ($EnvName)"
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
Write-Host "`n✅ User environment ready." -ForegroundColor Green
Write-Host "In VS Code: Ctrl+Shift+P → 'Python: Select Interpreter' → Python 3.11 ($EnvName)"
