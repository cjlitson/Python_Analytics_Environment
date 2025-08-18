<#
.SYNOPSIS
  Admin-only installer (no Power BI; IT-managed). Installs core apps with optional version pinning.
.PARAMETER VersionsJsonPath
  Path to a JSON file mapping winget IDs to versions. If a version is non-empty, it's passed to winget.
  Default: setup/app-versions.json
#>
[CmdletBinding()]
param(
  [string]$VersionsJsonPath = "$PSScriptRoot\app-versions.json",
  [switch]$IncludeAzureDataStudio,
  [switch]$IncludeOneLakeNote
)
$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script as Administrator."
  }
}
function Ensure-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install/Update 'App Installer' from Microsoft Store, then rerun." -ForegroundColor Yellow
    throw "winget not available"
  }
}
function Install-App([string]$Id, [string]$Version) {
  Write-Host "Installing $Id $(if($Version){"(version $Version)"}else{"(latest)"}) ..." -ForegroundColor Cyan
  $args = @("-e","--id",$Id,"--accept-package-agreements","--accept-source-agreements","--silent")
  if ($Version) { $args += @("--version",$Version) }
  winget install @args
}
Assert-Admin
Ensure-Winget
$VersionMap = Get-Content $VersionsJsonPath | ConvertFrom-Json
Install-App "Microsoft.VisualStudioCode"           $VersionMap."Microsoft.VisualStudioCode"
Install-App "Git.Git"                              $VersionMap."Git.Git"
Install-App "Anaconda.Miniconda3"                  $VersionMap."Anaconda.Miniconda3"
Install-App "Microsoft.ODBCDriverForSQLServer.18"  $VersionMap."Microsoft.ODBCDriverForSQLServer.18"
Install-App "Microsoft.AzureCLI"                   $VersionMap."Microsoft.AzureCLI"
Install-App "Microsoft.Azure.AZCopy.10"            $VersionMap."Microsoft.Azure.AZCopy.10"
if ($IncludeAzureDataStudio) {
  Install-App "Microsoft.AzureDataStudio"          $VersionMap."Microsoft.AzureDataStudio"
}
Write-Host "`n✅ Admin apps installed." -ForegroundColor Green
if ($IncludeOneLakeNote) {
  Write-Host "Note: OneLake File Explorer is an MSIX. Package/approve via IT if desired." -ForegroundColor Yellow
}
Write-Host "Next: Have users run setup/Install-UserEnv.ps1 (no admin required)."
