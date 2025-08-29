# installer/fetch-payload.ps1
# Downloads micromamba.exe and copies environment.yml into installer/payload

$ErrorActionPreference = 'Stop'
$payload = Join-Path $PSScriptRoot 'payload'
New-Item -ItemType Directory -Force -Path $payload | Out-Null

# 1) micromamba.exe (official)
$micromambaUrl = 'https://micro.mamba.pm/api/micromamba/win-64/latest'
$micromambaExe = Join-Path $payload 'micromamba.exe'
Write-Host "Downloading micromamba.exe..."
Invoke-WebRequest -UseBasicParsing -Uri $micromambaUrl -OutFile $micromambaExe
Write-Host "Saved -> $micromambaExe"

# 2) Copy top-level environment.yml into payload
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$envYmlSrc = Join-Path $repoRoot 'environment.yml'
if (-not (Test-Path $envYmlSrc)) {
  throw "environment.yml not found at $envYmlSrc"
}
Copy-Item -Force $envYmlSrc -Destination (Join-Path $payload 'environment.yml')
Write-Host "Copied -> payload\environment.yml"

Write-Host "Payload ready."
