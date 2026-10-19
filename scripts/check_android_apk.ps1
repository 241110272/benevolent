param(
    [string]$Apk = 'build/app/outputs/flutter-apk/app-debug.apk',
    [string]$Sdk = "$env:USERPROFILE/.codex/tools/android-sdk",
    [string]$NdkVersion = '28.2.13676358',
    [string]$BuildTools = '36.0.0'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$taskApk = (Resolve-Path -LiteralPath $Apk).Path
$taskTools = Join-Path $Sdk "build-tools/$BuildTools"
$taskLlvm = Join-Path $Sdk "ndk/$NdkVersion/toolchains/llvm/prebuilt/windows-x86_64/bin"
if (!$env:JAVA_HOME) {
    $taskJdk = Get-ChildItem "$env:USERPROFILE/.codex/tools/jdk21" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($taskJdk) { $env:JAVA_HOME = $taskJdk.FullName }
}
& "$taskTools/apksigner.bat" verify --verbose $taskApk
if ($LASTEXITCODE -ne 0) { throw 'Tanda tangan APK tidak valid.' }
& "$taskTools/zipalign.exe" -c -P 16 4 $taskApk
if ($LASTEXITCODE -ne 0) { throw 'ZIP alignment 16 KB tidak sesuai.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskStage = Join-Path (Get-Location) '.tools/apk-inspection'
New-Item -ItemType Directory -Force -Path $taskStage | Out-Null
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskApk)
$taskChecked = 0
try {
    foreach ($taskEntry in $taskArchive.Entries) {
        if ($taskEntry.FullName -notmatch '^lib/(arm64-v8a|x86_64)/([^/\\]+\.so)$') { continue }
        $taskAbi = $Matches[1]
        $taskName = $Matches[2]
        $taskFolder = Join-Path $taskStage $taskAbi
        New-Item -ItemType Directory -Force -Path $taskFolder | Out-Null
        $taskLibrary = Join-Path $taskFolder $taskName
        [IO.Compression.ZipFileExtensions]::ExtractToFile($taskEntry, $taskLibrary, $true)
        $taskDump = & "$taskLlvm/llvm-objdump.exe" -p $taskLibrary
        if ($LASTEXITCODE -ne 0) { throw "Tidak dapat membaca ELF $taskAbi/$taskName" }
        $taskLoads = @($taskDump | Select-String '^\s*LOAD .*align 2\*\*(\d+)')
        if ($taskLoads.Count -eq 0) { throw "Segmen LOAD tidak ditemukan: $taskAbi/$taskName" }
        foreach ($taskLoad in $taskLoads) {
            if ([int]$taskLoad.Matches[0].Groups[1].Value -lt 14) {
                throw "ELF alignment kurang dari 16 KB: $taskAbi/$taskName"
            }
        }
        $taskHeaders = & "$taskLlvm/llvm-readelf.exe" -Wl $taskLibrary
        if ($LASTEXITCODE -ne 0) { throw "Tidak dapat membaca program headers: $taskName" }
        $taskSegments = @()
        foreach ($taskLine in $taskHeaders) {
            if ($taskLine -match '^\s*(LOAD|GNU_RELRO)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+([RWE ]+)\s+0x') {
                $taskSegments += [pscustomobject]@{
                    Type = $Matches[1]
                    Address = [Convert]::ToUInt64($Matches[3].Substring(2), 16)
                    Memory = [Convert]::ToUInt64($Matches[6].Substring(2), 16)
                    Flags = $Matches[7].Trim()
                }
            }
        }
        foreach ($taskRelro in @($taskSegments | Where-Object Type -eq 'GNU_RELRO')) {
            $taskEnd = $taskRelro.Address + $taskRelro.Memory
            if ($taskEnd % 16384 -eq 0) { continue }
            # Android also permits RELRO to occupy its own LOAD segment. Its
            # rounded protection pages must not cover other writable/executable LOADs.
            # RELRO can include padding beyond that LOAD's own memory length.
            $taskOwn = @($taskSegments | Where-Object {
                $_.Type -eq 'LOAD' -and $_.Address -eq $taskRelro.Address -and $_.Memory -le $taskRelro.Memory
            })
            if ($taskOwn.Count -eq 0) { throw "RELRO berbagi halaman writable: $taskAbi/$taskName" }
            $taskProtectedStart = $taskRelro.Address - ($taskRelro.Address % 16384)
            $taskProtectedEnd = $taskEnd + ((16384 - ($taskEnd % 16384)) % 16384)
            $taskOverlap = @($taskSegments | Where-Object {
                $_.Type -eq 'LOAD' -and $_.Flags -match '[WE]' -and
                !($_.Address -eq $taskRelro.Address -and $_.Memory -le $taskRelro.Memory) -and
                $_.Address -lt $taskProtectedEnd -and ($_.Address + $_.Memory) -gt $taskProtectedStart
            })
            if ($taskOverlap.Count -gt 0) { throw "Proteksi RELRO menimpa LOAD lain: $taskAbi/$taskName" }
        }
        $taskChecked++
        Write-Output "PASS ELF/RELRO: $taskAbi/$taskName"
    }
} finally {
    $taskArchive.Dispose()
}
if ($taskChecked -eq 0) { throw 'Tidak ada pustaka native 64 bit yang diperiksa.' }
& "$taskTools/aapt.exe" dump badging $taskApk | Select-String '^(package:|sdkVersion:|targetSdkVersion:|native-code:|application-label:|launchable-activity:)'
if ($LASTEXITCODE -ne 0) { throw 'Metadata APK tidak dapat dibaca.' }
Get-FileHash -LiteralPath $taskApk -Algorithm SHA256 | Select-Object Algorithm, Hash
Write-Output "PASS: tanda tangan, ZIP alignment, dan $taskChecked pustaka 64 bit. Uji perangkat nyata masih diperlukan."
