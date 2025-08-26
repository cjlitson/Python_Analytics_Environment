<# 
.SYNOPSIS
  Admin-level installer for Analytics Workstation prerequisites.
.DESCRIPTION
  Installs/ensures the following are available:
    - Miniconda (All Users) at C:\ProgramData\Miniconda3 (configurable)
    - Git
    - Visual Studio Code
    - ODBC Driver 18 for SQL Server
    - Azure CLI
    - AzCopy
    - (Optional) Azure Data Studio

  Uses winget where possible (with basic fallbacks).
#>

[CmdletBinding()]
param(
  [string]$MinicondaRoot = "C:\ProgramData\Miniconda3",
  [switch]$IncludeAzureDataStudio
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# -------------------------
# Helpers
# -------------------------
function Test-Command {
  param([Parameter(Mandatory)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Safe {
  param([Parameter(Mandatory)][scriptblock]$Script, [string]$What = "step")
  try {
    & $Script
  } catch {
    Write-Warning "Failed $What: $($_.Exception.Message)"
    throw
  }
}

function Install-WithWinget {
  param(
    [Parameter(Mandatory)][string]$IdOrName,
    [string]$OverrideArgs = ""
  )
  if (-not (Test-Command winget)) {
    Write-Information "winget not available; skipping winget install for '$IdOrName'."
    return $false
  }
  Write-Information "Installing/upgrading via winget: $IdOrName"
  $args = @("install","--id",$IdOrName,"--silent","--accept-package-agreements","--accept-source-agreements","--disable-interactivity")
  if ($OverrideArgs) { $args += "--override"; $args += $OverrideArgs }
  # Retry once if needed
  $ok = $true
  try {
    winget @args | Write-Verbose
  } catch {
    Start-Sleep -Seconds 3
    try { winget @args | Write-Verbose } catch { $ok = $false }
  }
  return $ok
}

# -------------------------
# Ensure winget (App Installer)
# -------------------------
function Install-WingetIfMissing {
  [CmdletBinding()]
  param()

  if (Test-Command winget) {
    Write-Information "winget already present."
    return
  }

  Write-Information "winget not found. Attempting to install Microsoft App Installer…"
  # Latest App Installer (winget) is delivered through Microsoft Store on most systems.
  # Fallback: direct package – may require Store/Services enabled.
  $appInstallerUrl = "https://aka.ms/getwinget"
  $dst = Join-Path $env:TEMP "AppInstaller.msixbundle"

  try {
    Invoke-WebRequest -Uri $appInstallerUrl -OutFile $dst -UseBasicParsing
    Add-AppxPackage -Path $dst -ErrorAction Stop
    Remove-Item $dst -Force
    Write-Information "App Installer installed."
  } catch {
    Write-Warning "Could not install winget via App Installer automatically: $($_.Exception.Message)"
    Write-Warning "If this device disables Microsoft Store, deploy winget centrally or install App Installer via your endpoint tool."
  }
}

# -------------------------
# Miniconda (All Users)
# -------------------------
function Ensure-Miniconda {
  [CmdletBinding()]
  param([string]$Root = "C:\ProgramData\Miniconda3")

  $condaExe = Join-Path $Root "Scripts\conda.exe"
  if (Test-Path $condaExe) {
    Write-Information "Miniconda already installed at $Root."
    return
  }

  Write-Information "Installing Miniconda (All Users) at $Root…"
  $url = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
  $exe = Join-Path $env:TEMP "Miniconda3-latest-Windows-x86_64.exe"

  Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
  $args = "/InstallationType=AllUsers /AddToPath=1 /RegisterPython=0 /S /D=$Root"
  Start-Process -FilePath $exe -ArgumentList $args -Wait
  Remove-Item $exe -Force

  if (-not (Test-Path $condaExe)) {
    throw "Miniconda install did not create $condaExe."
  }

  Write-Information "Miniconda installed."
}

# -------------------------
# ODBC Driver 18 for SQL Server
# -------------------------
function Ensure-ODBC18 {
  if (Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "Microsoft ODBC Driver 18 for SQL Server*"}) {
    Write-Information "ODBC Driver 18 already installed."
    return
  }
  Write-Information "Installing ODBC Driver 18 for SQL Server… (winget)"
  if (-not (Install-WithWinget -IdOrName "Microsoft.ODBCDriverForSQLServer")) {
    Write-Warning "winget ODBC install failed or unavailable. Trying direct download…"
    $url = "https://go.microsoft.com/fwlink/?linkid=2240479"  # x64 driver 18
    $msi = Join-Path $env:TEMP "msodbcsql18.msi"
    Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /qn IACCEPTMSODBCSQLLICENSETERMS=YES"
    Remove-Item $msi -Force
  }
}

# -------------------------
# Azure CLI
# -------------------------
function Ensure-AzCLI {
  if (Test-Command az) {
    Write-Information "Azure CLI already present."
    return
  }
  Write-Information "Installing Azure CLI…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzureCLI")) {
    $url = "https://aka.ms/installazurecliwindows"
    $msi = Join-Path $env:TEMP "azure-cli.msi"
    Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /qn"
    Remove-Item $msi -Force
  }
}

# -------------------------
# AzCopy
# -------------------------
function Ensure-AzCopy {
  if (Test-Command azcopy) {
    Write-Information "AzCopy already present."
    return
  }
  Write-Information "Installing AzCopy…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzCopy")) {
    $zipUrl = "https://aka.ms/downloadazcopy-v10-windows"
    $zip = Join-Path $env:TEMP "azcopy.zip"
    $dest = Join-Path $env:ProgramFiles "AzCopy"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $dest -Force
    Remove-Item $zip -Force
    $bin = Get-ChildItem -Path $dest -Recurse -Filter "azcopy.exe" | Select-Object -First 1
    if ($bin) {
      $envPath = [Environment]::GetEnvironmentVariable("Path","Machine")
      if ($envPath -notmatch [Regex]::Escape($bin.DirectoryName)) {
        [Environment]::SetEnvironmentVariable("Path", "$envPath;$($bin.DirectoryName)", "Machine")
      }
    }
  }
}

# -------------------------
# Visual Studio Code
# -------------------------
function Ensure-VSCode {
  if (Test-Command code) {
    Write-Information "Visual Studio Code already present."
    return
  }
  Write-Information "Installing Visual Studio Code…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.VisualStudioCode")) {
    $url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    $exe = Join-Path $env:TEMP "VSCodeSetup.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    Start-Process -FilePath $exe -ArgumentList "/silent /mergetasks=!runcode" -Wait
    Remove-Item $exe -Force
  }
}

# -------------------------
# Git
# -------------------------
function Ensure-Git {
  if (Test-Command git) {
    Write-Information "Git already present."
    return
  }
  Write-Information "Installing Git…"
  if (-not (Install-WithWinget -IdOrName "Git.Git" -OverrideArgs "/VERYSILENT /NORESTART")) {
    $url = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
    $exe = Join-Path $env:TEMP "GitSetup.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    Start-Process -FilePath $exe -ArgumentList "/VERYSILENT /NORESTART" -Wait
    Remove-Item $exe -Force
  }
}

# -------------------------
# Azure Data Studio (optional)
# -------------------------
function Ensure-ADS {
  if (Get-StartApps | Where-Object { $_.Name -match "Azure Data Studio" }) {
    Write-Information "Azure Data Studio already present."
    return
  }
  Write-Information "Installing Azure Data Studio…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzureDataStudio")) {
    $url = "https://aka.ms/azuredatastudio-windows"
    $exe = Join-Path $env:TEMP "azuredatastudio.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    Start-Process -FilePath $exe -ArgumentList "/verysilent /norestart" -Wait
    Remove-Item $exe -Force
  }
}

# -------------------------
# Main
# -------------------------
Write-Information "===== Analytics Workstation Admin Setup ====="

# Ensure winget first
Install-WingetIfMissing

# Core tools
Ensure-Git
Ensure-VSCode
Ensure-ODBC18
Ensure-AzCLI
Ensure-AzCopy

# Miniconda (for all users)
Ensure-Miniconda -Root $MinicondaRoot

# Optional ADS
if ($IncludeAzureDataStudio) {
  Ensure-ADS
}

Write-Information "Admin setup complete. You can now run the user installer (Install-UserEnv.ps1) or Run-User.bat on each analyst machine."
