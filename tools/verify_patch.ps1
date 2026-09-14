# Verify block_app patch was applied correctly
# Usage: .\tools\verify_patch.ps1

$ErrorActionPreference = "Stop"
$cachePath = $env:LOCALAPPDATA + "\Pub\Cache\hosted\pub.dev"
if (-not (Test-Path $cachePath)) {
    $cachePath = $env:APPDATA + "\Pub\Cache\hosted\pub.dev"
}
$blockAppDir = Get-ChildItem -Path $cachePath -Filter "block_app-*" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $blockAppDir) {
    Write-Host "ERROR: block_app package not found. Run 'flutter pub get' first." -ForegroundColor Red
    exit 1
}

$targetFile = Join-Path $blockAppDir.FullName "android\src\main\kotlin\com\block_app\AppBlockingService.kt"
if (-not (Test-Path $targetFile)) {
    Write-Host "ERROR: AppBlockingService.kt not found at: $targetFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $targetFile -Raw
if ($content -match "unblockAndClose") {
    Write-Host "✓ Patch applied: unblockAndClose method found" -ForegroundColor Green
} else {
    Write-Host "✗ Patch NOT applied: unblockAndClose method missing" -ForegroundColor Red
    Write-Host "  Run: .\tools\apply_block_app_patch.ps1" -ForegroundColor Yellow
    exit 1
}

if ($content -match "FLAG_NOT_FOCUSABLE") {
    Write-Host "✓ FLAG_NOT_FOCUSABLE present - overlay will block apps" -ForegroundColor Green
} else {
    Write-Host "✗ ERROR: FLAG_NOT_FOCUSABLE missing - apps won't be blocked!" -ForegroundColor Red
    Write-Host "  Re-apply the patch: .\tools\apply_block_app_patch.ps1" -ForegroundColor Yellow
    exit 1
}

if ($content -match "FLAG_NOT_TOUCH_MODAL.*inv\\(\\)") {
    Write-Host "✓ FLAG_NOT_TOUCH_MODAL removed - touches will work" -ForegroundColor Green
} elseif ($content -match "FLAG_NOT_TOUCH_MODAL") {
    Write-Host "✗ WARNING: FLAG_NOT_TOUCH_MODAL still present - button may not work" -ForegroundColor Yellow
    Write-Host "  Re-apply the patch: .\tools\apply_block_app_patch.ps1" -ForegroundColor Yellow
} else {
    Write-Host "✓ FLAG_NOT_TOUCH_MODAL handling present" -ForegroundColor Green
}

Write-Host ""
Write-Host "Patch verification complete. Rebuild the app (flutter run) for changes to take effect." -ForegroundColor Cyan
