<#
.SYNOPSIS
  Guided installer for the Python Analytics Environment.
.DESCRIPTION
  Prompts for Admin or User mode and calls the appropriate installer script.
#>

[CmdletBinding()]
param()

Write-Host "===== Python Analytics Environment Guided Setup ====="

$choice = Read-Host "Install as (A)dmin or (U)ser? [A/U]"
switch -Regex ($choice) {
  '^[Aa]' {
    $root = Read-Host "Miniconda root path [`C:\\ProgramData\\Miniconda3`]"
    if (-not $root) { $root = "C:\\ProgramData\\Miniconda3" }
    $includeAds = Read-Host "Include Azure Data Studio? (y/N)"
    $params = @{ MinicondaRoot = $root }
    if ($includeAds -match '^[Yy]') { $params.IncludeAzureDataStudio = $true }
    & "$PSScriptRoot\Install-Admin.ps1" @params
  }
  '^[Uu]' {
    $envName = Read-Host "Conda environment name [`Analytics`]"
    if (-not $envName) { $envName = "Analytics" }
    & "$PSScriptRoot\Install-User.ps1" -EnvName $envName
  }
  default {
    Write-Warning "No valid selection made. Exiting."
  }
}
