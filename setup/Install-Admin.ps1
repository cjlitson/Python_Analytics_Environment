<# 
.SYNOPSIS
  Admin-level installer for Python Analytics Environment prerequisites.
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

[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$MinicondaRoot = "C:\ProgramData\Miniconda3",
  [switch]$IncludeAzureDataStudio
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$commonParams = @{}
foreach ($k in @('WhatIf','Confirm')) {
  if ($PSBoundParameters.ContainsKey($k)) { $commonParams[$k] = $PSBoundParameters[$k] }
}

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
  [CmdletBinding(SupportsShouldProcess)]
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
  if ($PSCmdlet.ShouldProcess($IdOrName, "winget install")) {
    try {
      winget @args | Write-Verbose
    } catch {
      Start-Sleep -Seconds 3
      try { winget @args | Write-Verbose } catch { $ok = $false }
    }
  }
  return $ok
}

# -------------------------
# Ensure winget (App Installer)
# -------------------------
function Install-WingetIfMissing {
  [CmdletBinding(SupportsShouldProcess)]
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
    if ($PSCmdlet.ShouldProcess($dst, "Download App Installer")) {
      Invoke-WebRequest -Uri $appInstallerUrl -OutFile $dst -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess("App Installer package", "Install")) {
      Add-AppxPackage -Path $dst -ErrorAction Stop
    }
    if ($PSCmdlet.ShouldProcess($dst, "Remove installer")) {
      Remove-Item $dst -Force
    }
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
  [CmdletBinding(SupportsShouldProcess)]
  param([string]$Root = "C:\ProgramData\Miniconda3")

  $condaExe = Join-Path $Root "Scripts\conda.exe"
  if (Test-Path $condaExe) {
    Write-Information "Miniconda already installed at $Root."
    return
  }

  Write-Information "Installing Miniconda (All Users) at $Root…"
  $url = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
  $exe = Join-Path $env:TEMP "Miniconda3-latest-Windows-x86_64.exe"

  if ($PSCmdlet.ShouldProcess($exe, "Download Miniconda")) {
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
  }
  $args = "/InstallationType=AllUsers /AddToPath=1 /RegisterPython=0 /S /D=$Root"
  if ($PSCmdlet.ShouldProcess($exe, "Install Miniconda")) {
    Start-Process -FilePath $exe -ArgumentList $args -Wait
  }
  if ($PSCmdlet.ShouldProcess($exe, "Remove installer")) {
    Remove-Item $exe -Force
  }

  if (-not (Test-Path $condaExe)) {
    throw "Miniconda install did not create $condaExe."
  }

  Write-Information "Miniconda installed."
}

# -------------------------
# ODBC Driver 18 for SQL Server
# -------------------------
function Ensure-ODBC18 {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "Microsoft ODBC Driver 18 for SQL Server*"}) {
    Write-Information "ODBC Driver 18 already installed."
    return
  }
  Write-Information "Installing ODBC Driver 18 for SQL Server… (winget)"
  if (-not (Install-WithWinget -IdOrName "Microsoft.ODBCDriverForSQLServer" @PSBoundParameters)) {
    Write-Warning "winget ODBC install failed or unavailable. Trying direct download…"
    $url = "https://go.microsoft.com/fwlink/?linkid=2240479"  # x64 driver 18
    $msi = Join-Path $env:TEMP "msodbcsql18.msi"
    if ($PSCmdlet.ShouldProcess($msi, "Download ODBC driver")) {
      Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess($msi, "Install ODBC driver")) {
      Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /qn IACCEPTMSODBCSQLLICENSETERMS=YES"
    }
    if ($PSCmdlet.ShouldProcess($msi, "Remove installer")) {
      Remove-Item $msi -Force
    }
  }
}

# -------------------------
# Azure CLI
# -------------------------
function Ensure-AzCLI {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Test-Command az) {
    Write-Information "Azure CLI already present."
    return
  }
  Write-Information "Installing Azure CLI…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzureCLI" @PSBoundParameters)) {
    $url = "https://aka.ms/installazurecliwindows"
    $msi = Join-Path $env:TEMP "azure-cli.msi"
    if ($PSCmdlet.ShouldProcess($msi, "Download Azure CLI")) {
      Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess($msi, "Install Azure CLI")) {
      Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /qn"
    }
    if ($PSCmdlet.ShouldProcess($msi, "Remove installer")) {
      Remove-Item $msi -Force
    }
  }
}

# -------------------------
# AzCopy
# -------------------------
function Ensure-AzCopy {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Test-Command azcopy) {
    Write-Information "AzCopy already present."
    return
  }
  Write-Information "Installing AzCopy…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzCopy" @PSBoundParameters)) {
    $zipUrl = "https://aka.ms/downloadazcopy-v10-windows"
    $zip = Join-Path $env:TEMP "azcopy.zip"
    $dest = Join-Path $env:ProgramFiles "AzCopy"
    if ($PSCmdlet.ShouldProcess($zip, "Download AzCopy")) {
      Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    }
    if (Test-Path $dest) {
      if ($PSCmdlet.ShouldProcess($dest, "Remove existing AzCopy")) {
        Remove-Item $dest -Recurse -Force
      }
    }
    if ($PSCmdlet.ShouldProcess($dest, "Expand AzCopy")) {
      Expand-Archive -Path $zip -DestinationPath $dest -Force
    }
    if ($PSCmdlet.ShouldProcess($zip, "Remove archive")) {
      Remove-Item $zip -Force
    }
    $bin = Get-ChildItem -Path $dest -Recurse -Filter "azcopy.exe" | Select-Object -First 1
    if ($bin) {
      $envPath = [Environment]::GetEnvironmentVariable("Path","Machine")
      if ($envPath -notmatch [Regex]::Escape($bin.DirectoryName)) {
        if ($PSCmdlet.ShouldProcess("Machine Path", "Add AzCopy")) {
          [Environment]::SetEnvironmentVariable("Path", "$envPath;$($bin.DirectoryName)", "Machine")
        }
      }
    }
  }
}

# -------------------------
# Visual Studio Code
# -------------------------
function Ensure-VSCode {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Test-Command code) {
    Write-Information "Visual Studio Code already present."
    return
  }
  Write-Information "Installing Visual Studio Code…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.VisualStudioCode" @PSBoundParameters)) {
    $url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    $exe = Join-Path $env:TEMP "VSCodeSetup.exe"
    if ($PSCmdlet.ShouldProcess($exe, "Download VS Code")) {
      Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess($exe, "Install VS Code")) {
      Start-Process -FilePath $exe -ArgumentList "/silent /mergetasks=!runcode" -Wait
    }
    if ($PSCmdlet.ShouldProcess($exe, "Remove installer")) {
      Remove-Item $exe -Force
    }
  }
}

# -------------------------
# Git
# -------------------------
function Ensure-Git {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Test-Command git) {
    Write-Information "Git already present."
    return
  }
  Write-Information "Installing Git…"
  if (-not (Install-WithWinget -IdOrName "Git.Git" -OverrideArgs "/VERYSILENT /NORESTART" @PSBoundParameters)) {
    $url = "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
    $exe = Join-Path $env:TEMP "GitSetup.exe"
    if ($PSCmdlet.ShouldProcess($exe, "Download Git")) {
      Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess($exe, "Install Git")) {
      Start-Process -FilePath $exe -ArgumentList "/VERYSILENT /NORESTART" -Wait
    }
    if ($PSCmdlet.ShouldProcess($exe, "Remove installer")) {
      Remove-Item $exe -Force
    }
  }
}

# -------------------------
# Azure Data Studio (optional)
# -------------------------
function Ensure-ADS {
  [CmdletBinding(SupportsShouldProcess)]
  param()

  if (Get-StartApps | Where-Object { $_.Name -match "Azure Data Studio" }) {
    Write-Information "Azure Data Studio already present."
    return
  }
  Write-Information "Installing Azure Data Studio…"
  if (-not (Install-WithWinget -IdOrName "Microsoft.AzureDataStudio" @PSBoundParameters)) {
    $url = "https://aka.ms/azuredatastudio-windows"
    $exe = Join-Path $env:TEMP "azuredatastudio.exe"
    if ($PSCmdlet.ShouldProcess($exe, "Download Azure Data Studio")) {
      Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing
    }
    if ($PSCmdlet.ShouldProcess($exe, "Install Azure Data Studio")) {
      Start-Process -FilePath $exe -ArgumentList "/verysilent /norestart" -Wait
    }
    if ($PSCmdlet.ShouldProcess($exe, "Remove installer")) {
      Remove-Item $exe -Force
    }
  }
}

# -------------------------
# Main
# -------------------------
Write-Information "===== Python Analytics Environment Admin Setup ====="

# Ensure winget first
Install-WingetIfMissing @commonParams

# Core tools
Ensure-Git @commonParams
Ensure-VSCode @commonParams
Ensure-ODBC18 @commonParams
Ensure-AzCLI @commonParams
Ensure-AzCopy @commonParams

# Miniconda (for all users)
Ensure-Miniconda -Root $MinicondaRoot @commonParams

# Optional ADS
if ($IncludeAzureDataStudio) {
  Ensure-ADS @commonParams
}

Write-Information "Admin setup complete. You can now run the user installer (Install-User.ps1) on each analyst machine or use the Windows installer."
