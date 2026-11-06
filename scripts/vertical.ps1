<#
.SYNOPSIS  Convert a clip to 9:16 (1080x1920).
           -Mode blur : keeps the whole picture, fills the sides with a blurred copy (default)
           -Mode crop : fills the screen by cutting the left and right edges
.EXAMPLE   .\scripts\vertical.ps1 clip1.mp4 -Mode crop
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$In,
    [ValidateSet("blur", "crop")] [string]$Mode = "blur",
    [string]$Out = ""
)
. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg
$inPath = Resolve-Clip $In
if (-not $Out) { $Out = Get-OutPath $inPath "_9x16" }

if ($Mode -eq "crop") {
    $vf = "scale=${Width}:${Height}:force_original_aspect_ratio=increase,crop=${Width}:${Height},setsar=1,fps=$Fps"
    $ffArgs = @("-i", $inPath, "-vf", $vf)
} else {
    $fc = "[0:v]split[a][b];" +
          "[a]scale=${Width}:${Height}:force_original_aspect_ratio=increase,crop=${Width}:${Height},boxblur=20:5[bg];" +
          "[b]scale=${Width}:${Height}:force_original_aspect_ratio=decrease[fg];" +
          "[bg][fg]overlay=(W-w)/2:(H-h)/2,setsar=1,fps=$Fps[v]"
    $ffArgs = @("-i", $inPath, "-filter_complex", $fc, "-map", "[v]", "-map", "0:a?")
}
$ffArgs += @("-c:v", "libx264", "-crf", "$Crf", "-preset", "medium", "-pix_fmt", "yuv420p",
             "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", $Out)
Invoke-Ffmpeg $ffArgs
Show-Result $Out
