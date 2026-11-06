<#
.SYNOPSIS
  Turn one raw clip into a finished Meta ad: 9:16, captions, logo, loud enough, max 60 s.

.EXAMPLES
  .\scripts\meta-ad.ps1 clip1.mp4
  .\scripts\meta-ad.ps1 clip1.mp4 -Start 2.5
  .\scripts\meta-ad.ps1 clip1.mp4 -Srt "G:\My Drive\BTI Videos\raw\clip1.srt" -Mode crop
  .\scripts\meta-ad.ps1 clip1.mp4 -NoCaptions -NoLogo -MaxSecs 30
#>
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$In,
    [double]$Start = 0,                       # seconds to cut from the beginning
    [string]$Srt = "",                        # caption file; default: same name as clip, .srt
    [ValidateSet("blur", "crop")] [string]$Mode = "blur",
    [int]$MaxSecs = -1,
    [switch]$NoCaptions,
    [switch]$NoLogo,
    [string]$Out = ""
)

. "$PSScriptRoot\config.ps1"
Assert-Ffmpeg

$inPath = Resolve-Clip $In
if ($MaxSecs -lt 0) { $MaxSecs = $DefaultMaxSecs }
if (-not $Out) { $Out = Get-OutPath $inPath "_meta" }

$work = Join-Path $env:TEMP "claude-video"
New-Item -ItemType Directory -Path $work -Force | Out-Null

# --- video: resize to 9:16 ---------------------------------------------------
if ($Mode -eq "crop") {
    $v = "[0:v]scale=${Width}:${Height}:force_original_aspect_ratio=increase,crop=${Width}:${Height},setsar=1"
} else {
    $v = "[0:v]split[a][b];" +
         "[a]scale=${Width}:${Height}:force_original_aspect_ratio=increase,crop=${Width}:${Height},boxblur=20:5[bg];" +
         "[b]scale=${Width}:${Height}:force_original_aspect_ratio=decrease[fg];" +
         "[bg][fg]overlay=(W-w)/2:(H-h)/2,setsar=1"
}

# --- captions (applied before trimming so .srt timings still line up) ----------
if (-not $NoCaptions) {
    if (-not $Srt) { $Srt = [IO.Path]::ChangeExtension($inPath, ".srt") }
    if (Test-Path $Srt) {
        $v += "," + (Get-SubtitleFilter (Resolve-Path $Srt).Path $work)
    } else {
        Write-Host "No caption file found ($Srt) - exporting without captions." -ForegroundColor Yellow
        Write-Host "Make one first with:  python scripts\transcribe.py `"$inPath`"" -ForegroundColor Yellow
    }
}

$v += ",trim=start=$Start,setpts=PTS-STARTPTS,fps=$Fps"

# --- logo ----------------------------------------------------------------------
$inputs = @("-i", $inPath)
if (-not $NoLogo -and (Test-Path $LogoPath)) {
    $inputs += @("-i", $LogoPath)
    $logoW = [int]($Width * 0.15)
    $v += "[base];[1:v]scale=${logoW}:-1,format=rgba,colorchannelmixer=aa=0.85[lg];[base][lg]overlay=W-w-40:40"
} elseif (-not $NoLogo) {
    Write-Host "Logo not found at $LogoPath - exporting without logo." -ForegroundColor Yellow
}
$v += "[v]"

# --- audio: trim + loudness ---------------------------------------------------------
$hasAudio = (& ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$inPath")
$filter = $v
$maps = @("-map", "[v]")
if ($hasAudio) {
    $filter += ";[0:a]atrim=start=$Start,asetpts=PTS-STARTPTS,loudnorm=I=-14:TP=-1.5:LRA=11[a]"
    $maps += @("-map", "[a]")
}

$ffArgs = $inputs + @("-filter_complex", $filter) + $maps + @(
    "-t", "$MaxSecs",
    "-c:v", "libx264", "-preset", "medium", "-crf", "$Crf", "-pix_fmt", "yuv420p",
    "-c:a", "aac", "-b:a", "160k", "-ar", "48000",
    "-movflags", "+faststart",
    $Out
)

Push-Location $work      # so the subtitles filter can find captions.srt
try { Invoke-Ffmpeg $ffArgs } finally { Pop-Location }

Show-Result $Out
