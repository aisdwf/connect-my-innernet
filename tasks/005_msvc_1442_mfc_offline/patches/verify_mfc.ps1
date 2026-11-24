# Verify every payload against manifest.json (SHA256 + exact byte size).
# manifest size is the real downloaded length, NOT the Visual Studio catalog size.
#
#   powershell -ExecutionPolicy Bypass -File .\verify_mfc.ps1 -Dir D:\MFC1442

param(
    [Parameter(Mandatory = $true)][string]$Dir,
    [string]$Manifest = (Join-Path $PSScriptRoot "manifest.json")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $Manifest)) { throw "manifest not found: $Manifest" }
if (-not (Test-Path $Dir)) { throw "dir not found: $Dir" }

$man = Get-Content -Raw -Encoding UTF8 $Manifest | ConvertFrom-Json
$bad = 0
$n = 0
$total = [int64]0
foreach ($p in $man.packages) {
    foreach ($x in $p.payloads) {
        $n++
        $path = Join-Path $Dir $x.fileName
        if (-not (Test-Path $path)) {
            Write-Host "MISSING $($x.fileName)"
            $bad++
            continue
        }
        $len = (Get-Item $path).Length
        $hash = (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLower()
        $total += $len
        if ($hash -ne $x.sha256.ToLower() -or $len -ne [int64]$x.size) {
            Write-Host "MISMATCH $($x.fileName)"
            Write-Host "  got  $hash $len"
            Write-Host "  want $($x.sha256) $($x.size)"
            $bad++
        } else {
            Write-Host "OK $($x.fileName)"
        }
    }
}
Write-Host ("files={0} bad={1} bytes={2}" -f $n, $bad, $total)
if ($bad -ne 0) { exit 1 }
exit 0
