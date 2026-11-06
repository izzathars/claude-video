<#
.SYNOPSIS  Cut a clip between two times (seconds or hh:mm:ss).
.EXAMPLE   .\scripts\trim.ps1 clip1.mp4 -Start 3 -End 45
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$In,
    [string]$Start = "0",
    [string]$End = "",
    [string]$Out = ""
)
. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg
$inPath = Resolve-Clip $In
if (-not $Out) { $Out = Get-OutPath $inPath "_trim" }

$ffArgs = @("-ss", $Start, "-i", $inPath)
if ($End) { $ffArgs = @("-ss", $Start, "-to", $End, "-i", $inPath) }
$ffArgs += @("-c:v", "libx264", "-crf", "$Crf", "-preset", "medium", "-pix_fmt", "yuv420p",
             "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", $Out)
Invoke-Ffmpeg $ffArgs
Show-Result $Out
