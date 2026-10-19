param([string]$Flutter = 'flutter')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if ($Flutter -eq 'flutter' -and !(Get-Command flutter -ErrorAction SilentlyContinue)) {
    $taskFlutter = Join-Path $env:USERPROFILE '.codex/tools/flutter/bin/flutter.bat'
    if (Test-Path -LiteralPath $taskFlutter) { $Flutter = $taskFlutter }
}
& $Flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
# Intentionally does not require cloud keys or the private release keystore.
& $Flutter build apk --debug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$taskApk = Join-Path (Get-Location) 'build/app/outputs/flutter-apk/app-debug.apk'
Write-Output "APK uji lokal: $taskApk"
Get-FileHash -LiteralPath $taskApk -Algorithm SHA256 | Select-Object Algorithm, Hash
Write-Output 'Build debug untuk pengujian. Bukan bundle Play Store; login/feed menunggu konfigurasi backend.'
