# Install already-verified VSIX into an existing MSVC 14.42.34433 toolset.
# Does not download anything. Run verify_mfc.ps1 first.
#
#   powershell -ExecutionPolicy Bypass -File .\install_atlmfc.ps1 -Dir D:\MFC1442
#
# Finds:
#   <VS>\VC\Tools\MSVC\14.42.34433
# and extracts each *.vsix so that
#   <toolset>\atlmfc\include
#   <toolset>\atlmfc\lib\x86
#   <toolset>\atlmfc\lib\x64
# appear. VSIX files are OPC zip; Contents\ is the toolset-relative tree.

param(
    [Parameter(Mandatory = $true)][string]$Dir,
    [string]$ToolsetRoot = ""
)

$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "verify_mfc.ps1") -Dir $Dir
if ($LASTEXITCODE -ne 0) { throw "verify failed, refuse to install" }

if (-not $ToolsetRoot) {
    $candidates = @()
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $inst = & $vswhere -all -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        foreach ($p in @($inst)) {
            if ($p) { $candidates += (Join-Path $p "VC\Tools\MSVC\14.42.34433") }
        }
    }
    $candidates += @(
        "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433",
        "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC\14.42.34433",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\14.42.34433",
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433"
    )
    $ToolsetRoot = $candidates | Where-Object { Test-Path (Join-Path $_ "bin") } | Select-Object -First 1
}
if (-not $ToolsetRoot -or -not (Test-Path $ToolsetRoot)) {
    throw "14.42.34433 toolset not found. Pass -ToolsetRoot explicitly. This package does NOT include cl.exe."
}
Write-Host "toolset = $ToolsetRoot"

Add-Type -AssemblyName System.IO.Compression.FileSystem
$vsix = Get-ChildItem -Path $Dir -Filter *.vsix
foreach ($v in $vsix) {
    Write-Host "extract $($v.Name)"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($v.FullName)
    try {
        foreach ($e in $zip.Entries) {
            if (-not $e.FullName.StartsWith("Contents/")) { continue }
            if ($e.FullName.EndsWith("/")) { continue }
            $rel = $e.FullName.Substring("Contents/".Length).Replace("/", "\")
            $target = Join-Path $ToolsetRoot $rel
            $parent = Split-Path $target -Parent
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
        }
    } finally {
        $zip.Dispose()
    }
}

$marker = Join-Path $ToolsetRoot "atlmfc\lib\x64\uafxcw.lib"
if (-not (Test-Path $marker)) { throw "install finished but missing $marker" }
Write-Host "OK $marker"
Write-Host "HTML Help Workshop (VC_HTML_Help_Workshop.msi + cab1.cab) is NOT extracted here."
Write-Host "If hhc.exe is required, install that MSI from this folder with msiexec, cab1.cab beside it."
