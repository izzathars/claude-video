<#
.SYNOPSIS  Join several clips into one video, in the order given.
           Clips are resized to match the first clip, so mixed sources are fine.
.EXAMPLE   .\scripts\join.ps1 intro.mp4, clip1.mp4, outro.mp4 -Out "G:\My Drive\BTI Videos\final\full.mp4"
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string[]]$Clips,
    [string]$Out = ""
)
. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg
$paths = $Clips | ForEach-Object { Resolve-Clip $_ }
if (-not $Out) { $Out = Get-OutPath $paths[0] "_joined" }

$size = (& ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$($paths[0])").Trim()
$w, $h = $size.Split("x")

$inputs = @(); $parts = ""; $chain = ""
for ($i = 0; $i -lt $paths.Count; $i++) {
    $inputs += @("-i", $paths[$i])
    $hasAudio = (& ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$($paths[$i])")
    $parts += "[${i}:v]scale=${w}:${h}:force_original_aspect_ratio=decrease,pad=${w}:${h}:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=$Fps[v$i];"
    if ($hasAudio) {
        $parts += "[${i}:a]aresample=48000,aformat=channel_layouts=stereo[a$i];"
    } else {
        # clip has no sound: add a silent track of the same length
        $dur = & ffprobe -v error -show_entries format=duration -of csv=p=0 "$($paths[$i])"
        $parts += "anullsrc=r=48000:cl=stereo,atrim=duration=$dur[a$i];"
    }
    $chain += "[v$i][a$i]"
}
$fc = $parts + $chain + "concat=n=$($paths.Count):v=1:a=1[v][a]"

$ffArgs = $inputs + @("-filter_complex", $fc, "-map", "[v]", "-map", "[a]",
            "-c:v", "libx264", "-crf", "$Crf", "-preset", "medium", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", $Out)
Invoke-Ffmpeg $ffArgs
Show-Result $Out
