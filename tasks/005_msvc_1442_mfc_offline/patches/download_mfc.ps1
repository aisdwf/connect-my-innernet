# Download the x86/x64 MFC+ATL closure for MSVC 14.42.34433.
# Run this on a machine that can reach download.visualstudio.microsoft.com.
# Then copy the whole MFC1442 folder into the intranet and run verify_mfc.ps1.
#
#   powershell -ExecutionPolicy Bypass -File .\download_mfc.ps1 -Dest D:\MFC1442

param(
    [string]$Dest = ".\MFC1442",
    [string]$Manifest = (Join-Path $PSScriptRoot "manifest.json")
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not (Test-Path $Manifest)) { throw "manifest not found: $Manifest" }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$man = Get-Content -Raw -Encoding UTF8 $Manifest | ConvertFrom-Json
$jobs = @()
foreach ($p in $man.packages) {
    foreach ($x in $p.payloads) { $jobs += $x }
}

Write-Host ("packages={0} files={1}" -f @($man.packages).Count, $jobs.Count)
$i = 0
foreach ($x in $jobs) {
    $i++
    $out = Join-Path $Dest $x.fileName
    if ((Test-Path $out) -and ((Get-Item $out).Length -eq [int64]$x.size)) {
        Write-Host ("[{0}/{1}] skip {2}" -f $i, $jobs.Count, $x.fileName)
        continue
    }
    Write-Host ("[{0}/{1}] GET {2}" -f $i, $jobs.Count, $x.fileName)
    Invoke-WebRequest -Uri $x.url -OutFile $out -UseBasicParsing
}

Write-Host "download done, verifying..."
& (Join-Path $PSScriptRoot "verify_mfc.ps1") -Dir $Dest -Manifest $Manifest
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "OK. Copy this folder offline: $Dest"
