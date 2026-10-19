param([string]$Flutter = 'flutter')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
python scripts/check_release.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $Flutter build appbundle --release --dart-define-from-file=config/env.json
exit $LASTEXITCODE
