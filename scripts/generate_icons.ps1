$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
function Write-StepIcon([string]$relativePath, [int]$size) {
    $target = Join-Path $projectRoot $relativePath
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#E8DFFA'))
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#281531'))
    for ($step = 0; $step -lt 3; $step++) {
        $x = [single](($step * 0.155 + 0.245) * $size)
        $y = [single](((2 - $step) * 0.155 + 0.245) * $size)
        $edge = [single](0.21 * $size)
        $radius = [single](0.022 * $size)
        $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $path.AddArc($x, $y, $radius * 2, $radius * 2, 180, 90)
        $path.AddArc($x + $edge - $radius * 2, $y, $radius * 2, $radius * 2, 270, 90)
        $path.AddArc($x + $edge - $radius * 2, $y + $edge - $radius * 2, $radius * 2, $radius * 2, 0, 90)
        $path.AddArc($x, $y + $edge - $radius * 2, $radius * 2, $radius * 2, 90, 90)
        $path.CloseFigure()
        $graphics.FillPath($brush, $path)
        $path.Dispose()
    }
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $brush.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
Write-StepIcon 'web/favicon.png' 32
Write-StepIcon 'web/icons/Icon-192.png' 192
Write-StepIcon 'web/icons/Icon-512.png' 512
Write-StepIcon 'web/icons/Icon-maskable-192.png' 192
Write-StepIcon 'web/icons/Icon-maskable-512.png' 512
Write-StepIcon 'docs/store/icon-512.png' 512
foreach ($item in @(@('mdpi',48),@('hdpi',72),@('xhdpi',96),@('xxhdpi',144),@('xxxhdpi',192))) {
    Write-StepIcon "android/app/src/main/res/mipmap-$($item[0])/ic_launcher.png" $item[1]
}
$iconDirectory = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$contents = Get-Content -LiteralPath (Join-Path $iconDirectory 'Contents.json') -Raw | ConvertFrom-Json
foreach ($item in $contents.images) {
    if (!$item.filename) { continue }
    $edge = [int]([double]($item.size.Split('x')[0]) * [double]($item.scale.TrimEnd('x')))
    Write-StepIcon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($item.filename)" $edge
}
Write-Output 'Generated LangkahKerja icons from native step geometry.'
