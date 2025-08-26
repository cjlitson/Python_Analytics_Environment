<# 
.SYNOPSIS
Installs and configures admin-level prerequisites for the Analytics Workstation.
#>

# Show informational messages in console and pipelines
$InformationPreference = 'Continue'

function Install-WingetIfMissing {
    [CmdletBinding()]
    param()

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Information "winget not found. Installing App Installer (winget)..."
        
        # Example install logic for winget/App Installer
        $wingetUrl = "https://aka.ms/getwinget"
        $wingetInstaller = "$env:TEMP\AppInstaller.msi"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetInstaller
        Start-Process msiexec.exe -Wait -ArgumentList "/I `"$wingetInstaller`" /quiet /norestart"
        Remove-Item $wingetInstaller -Force
    }
    else {
        Write-Information "winget is already available."
    }
}

# Example: install Miniconda (update to match your environment)
$minicondaInstaller = "$env:TEMP\Miniconda3-latest-Windows-x86_64.exe"
if (-not (Test-Path "C:\ProgramData\Miniconda3\Scripts\conda.exe")) {
    Write-Information "Downloading Miniconda installer..."
    Invoke-WebRequest -Uri "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe" -OutFile $minicondaInstaller

    Write-Information "Installing Miniconda silently..."
    Start-Process -FilePath $minicondaInstaller -ArgumentList "/InstallationType=AllUsers /AddToPath=1 /RegisterPython=0 /S /D=C:\ProgramData\Miniconda3" -Wait
    Remove-Item $minicondaInstaller -Force
}
else {
    Write-Information "Miniconda already installed."
}

# Example: call winget function for VS Code or other tools
Install-WingetIfMissing
Write-Information "Admin setup complete."
