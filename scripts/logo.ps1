<#
.SYNOPSIS  Put the BTI logo in the top-right corner (15% of video width, slightly see-through).
.EXAMPLE   .\scripts\logo.ps1 clip1.mp4
           .\scripts\logo.ps1 clip1.mp4 -Logo "C:\path\other-logo.png" -Position bottom-right
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$In,
    [string]$Logo = "",
    [ValidateSet("top-right", "top-left", "bottom-right", "bottom-left")] [string]$Position = "top-right",
    [double]$SizePct = 15,
    [string]$Out = ""
)
. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg
$inPath = Resolve-Clip $In
if (-not $Logo) { $Logo = $LogoPath }
if (-not (Test-Path $Logo)) { throw "Logo not found: $Logo" }
if (-not $Out) { $Out = Get-OutPath $inPath "_logo" }

$pos = @{
    "top-right"    = "W-w-40:40"
    "top-left"     = "40:40"
    "bottom-right" = "W-w-40:H-h-40"
    "bottom-left"  = "40:H-h-40"
}[$Position]
$videoW = [int](& ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$inPath")
$logoW = [int]($videoW * $SizePct / 100)
$fc = "[1:v]scale=${logoW}:-1,format=rgba,colorchannelmixer=aa=0.85[lg];[0:v][lg]overlay=${pos}[v]"

$ffArgs = @("-i", $inPath, "-i", $Logo, "-filter_complex", $fc, "-map", "[v]", "-map", "0:a?",
            "-c:v", "libx264", "-crf", "$Crf", "-preset", "medium", "-pix_fmt", "yuv420p",
            "-c:a", "copy", "-movflags", "+faststart", $Out)
Invoke-Ffmpeg $ffArgs
Show-Result $Out
