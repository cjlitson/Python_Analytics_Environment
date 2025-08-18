param(
  [Parameter(Mandatory = $true)][string]$SourcePath,
  [Parameter(Mandatory = $true)][string]$DestUrl,
  [string]$SasToken = ""
)
Write-Host "Starting AzCopy..." -ForegroundColor Cyan
$target = if ($SasToken) { "$DestUrl$SasToken" } else { $DestUrl }
$log = Join-Path $PSScriptRoot ("azcopy_log_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
& azcopy copy $SourcePath $target --recursive=true --log-level=INFO | Tee-Object -FilePath $log
Write-Host "AzCopy complete. Log: $log" -ForegroundColor Green
