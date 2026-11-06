<#
.SYNOPSIS  Burn an .srt caption file into a clip (bold white, black outline, lower third).
           If -Srt is left out, uses the .srt with the same name as the clip.
.EXAMPLE   .\scripts\captions.ps1 clip1.mp4
           .\scripts\captions.ps1 clip1.mp4 -Srt "G:\My Drive\BTI Videos\raw\clip1.srt"
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$In,
    [string]$Srt = "",
    [string]$Out = ""
)
. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg
$inPath = Resolve-Clip $In
if (-not $Srt) { $Srt = [IO.Path]::ChangeExtension($inPath, ".srt") }
if (-not (Test-Path $Srt)) { throw "Caption file not found: $Srt  - make one with: python scripts\transcribe.py `"$inPath`"" }
if (-not $Out) { $Out = Get-OutPath $inPath "_captions" }

$work = Join-Path $env:TEMP "claude-video"
New-Item -ItemType Directory -Path $work -Force | Out-Null
$vf = Get-SubtitleFilter (Resolve-Path $Srt).Path $work

$ffArgs = @("-i", $inPath, "-vf", $vf,
            "-c:v", "libx264", "-crf", "$Crf", "-preset", "medium", "-pix_fmt", "yuv420p",
            "-c:a", "copy", "-movflags", "+faststart", $Out)
Push-Location $work
try { Invoke-Ffmpeg $ffArgs } finally { Pop-Location }
Show-Result $Out
