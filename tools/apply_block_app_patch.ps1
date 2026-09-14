# Apply block_app patch so Unblock button works (unblockAndClose + overlay touch fix).
# Run after: flutter pub get
# Usage: .\tools\apply_block_app_patch.ps1   OR   pwsh -File tools\apply_block_app_patch.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$patchFile = Join-Path $scriptDir "block_app_patch\AppBlockingService.kt"
if (-not (Test-Path $patchFile)) {
    Write-Error "Patch file not found: $patchFile"
    exit 1
}

$cachePath = $env:LOCALAPPDATA + "\Pub\Cache\hosted\pub.dev"
if (-not (Test-Path $cachePath)) {
    $cachePath = $env:APPDATA + "\Pub\Cache\hosted\pub.dev"
}
$blockAppDir = Get-ChildItem -Path $cachePath -Filter "block_app-*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $blockAppDir) {
    Write-Error "block_app package not found in pub cache. Run 'flutter pub get' first."
    exit 1
}

$targetDir = Join-Path $blockAppDir.FullName "android\src\main\kotlin\com\block_app"
$targetFile = Join-Path $targetDir "AppBlockingService.kt"
if (-not (Test-Path $targetDir)) {
    Write-Error "Plugin path not found: $targetDir"
    exit 1
}

Copy-Item -Path $patchFile -Destination $targetFile -Force
Write-Host "Patch applied: $targetFile"
Write-Host "Rebuild the app (e.g. flutter run) for the Unblock button to work."
