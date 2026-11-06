# Shared settings and helpers. Every script loads this file.
# Change these paths if your Google Drive uses a different letter or folder.

$DriveRoot = "G:\My Drive\BTI Videos"
$RawDir    = Join-Path $DriveRoot "raw"
$FinalDir  = Join-Path $DriveRoot "final"
$LogoPath  = Join-Path $DriveRoot "assets\logo.png"

# Meta ad defaults
$Width     = 1080
$Height    = 1920
$Fps       = 30
$DefaultMaxSecs = 60
$Crf       = 20      # lower = better quality, bigger file

$ErrorActionPreference = "Stop"

function Assert-Ffmpeg {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        throw "ffmpeg not found. Install it with:  winget install ffmpeg   then open a new terminal."
    }
}

function Resolve-Clip([string]$Path) {
    # Accepts a full path, or just a file name inside the raw folder.
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    $inRaw = Join-Path $RawDir $Path
    if (Test-Path $inRaw) { return (Resolve-Path $inRaw).Path }
    throw "Clip not found: $Path (also looked in $RawDir)"
}

function Get-OutPath([string]$InPath, [string]$Suffix) {
    if (-not (Test-Path $FinalDir)) { New-Item -ItemType Directory -Path $FinalDir | Out-Null }
    $name = [IO.Path]::GetFileNameWithoutExtension($InPath)
    return Join-Path $FinalDir "$name$Suffix.mp4"
}

function Invoke-Ffmpeg([string[]]$FfArgs) {
    & ffmpeg -hide_banner -loglevel warning -stats -y @FfArgs
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed (exit code $LASTEXITCODE)" }
}

function Get-SubtitleFilter([string]$SrtPath, [string]$WorkDir) {
    # ffmpeg's subtitles filter dislikes Windows paths (the "C:" colon), so copy
    # the .srt into the working folder and refer to it by plain file name.
    Copy-Item $SrtPath (Join-Path $WorkDir "captions.srt") -Force
    $style = "FontName=Arial,FontSize=13,Bold=1,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=2,Shadow=0,Alignment=2,MarginV=60"
    return "subtitles=captions.srt:force_style='$style'"
}

function Show-Result([string]$OutPath) {
    $secs = & ffprobe -v error -show_entries format=duration -of csv=p=0 "$OutPath"
    $mb   = [math]::Round((Get-Item $OutPath).Length / 1MB, 1)
    Write-Host ""
    Write-Host "Saved: $OutPath" -ForegroundColor Green
    Write-Host ("Length: {0:N1} s   Size: {1} MB" -f [double]$secs, $mb)
}
